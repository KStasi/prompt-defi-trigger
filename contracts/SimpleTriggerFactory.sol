// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SimpleTrigger.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    bytes checkData;
    bytes offchainConfig;
    uint96 amount;
}

interface KeeperRegistrarInterface {
    function registerUpkeep(
        RegistrationParams calldata requestParams
    ) external returns (uint256);
}

contract SimpleTriggerFactory {
    LinkTokenInterface public link;
    KeeperRegistrarInterface public registrar;
    SimpleTrigger public simpleTriggerImplementation;
    string public name = "SimpleTrigger";
    bytes public encryptedEmail = "0x";
    uint32 public gasLimit = 1000000;
    uint96 public amount = 5 ether;

    uint256 public triggerCount;
    mapping(uint256 => address) public triggers;

    constructor(address _link, address _registrar, address _uniswapRouter) {
        link = LinkTokenInterface(_link);
        registrar = KeeperRegistrarInterface(_registrar);
        simpleTriggerImplementation = new SimpleTrigger(_uniswapRouter);
    }

    function createAccount(
        SimpleTrigger.TokenInfo[] memory _tokens,
        uint256 _stopLoss,
        uint256 _takeProfit,
        address _owner,
        address _usdc,
        uint256 salt
    ) public returns (SimpleTrigger trigger) {
        // 1. Create a new SimpleTrigger proxy contract
        address addr = getAddress(
            _tokens,
            _stopLoss,
            _takeProfit,
            _owner,
            _usdc,
            salt
        );
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return SimpleTrigger(payable(addr));
        }
        trigger = SimpleTrigger(
            payable(
                new ERC1967Proxy{salt: bytes32(salt)}(
                    address(simpleTriggerImplementation),
                    abi.encodeCall(
                        SimpleTrigger.initialize,
                        (_tokens, _stopLoss, _takeProfit, _owner, _usdc)
                    )
                )
            )
        );
        triggerCount++;
        triggers[triggerCount] = address(trigger);

        // 2. Fund the contract with LINK
        link.transferFrom(msg.sender, address(this), amount);
        RegistrationParams memory params = RegistrationParams(
            name,
            encryptedEmail,
            address(trigger),
            gasLimit,
            address(msg.sender),
            "0x",
            "0x",
            amount
        );
        link.approve(address(registrar), params.amount);
        uint256 upkeepID = registrar.registerUpkeep(params);
        require(upkeepID > 0, "Registration failed");
    }

    function getAddress(
        SimpleTrigger.TokenInfo[] memory _tokens,
        uint256 _stopLoss,
        uint256 _takeProfit,
        address _owner,
        address _usdc,
        uint256 salt
    ) public view returns (address) {
        return
            Create2.computeAddress(
                bytes32(salt),
                keccak256(
                    abi.encodePacked(
                        type(ERC1967Proxy).creationCode,
                        abi.encode(
                            address(simpleTriggerImplementation),
                            abi.encodeCall(
                                SimpleTrigger.initialize,
                                (_tokens, _stopLoss, _takeProfit, _owner, _usdc)
                            )
                        )
                    )
                )
            );
    }
}
