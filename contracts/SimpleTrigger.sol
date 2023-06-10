// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleTrigger is AutomationCompatible, UUPSUpgradeable, Initializable {
    struct TokenInfo {
        address token;
        AggregatorV3Interface priceFeed;
        uint256 decimalMultiplier;
        uint24 poolFee;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    address public owner;
    uint256 public stopLoss; // in USDC
    uint256 public takeProfit; // in USDC

    ISwapRouter public immutable uniswapRouter;
    TokenInfo[] public tokens;
    address public usdc;

    event SimpleTriggerInitialized(address indexed owner);

    constructor(address _uniswapRouter) {
        uniswapRouter = ISwapRouter(_uniswapRouter);
    }

    function initialize(
        TokenInfo[] memory _tokens,
        uint256 _stopLoss,
        uint256 _takeProfit,
        address _owner,
        address _usdc
    ) public virtual initializer {
        _initialize(_tokens, _stopLoss, _takeProfit, _owner, _usdc);
    }

    function _initialize(
        TokenInfo[] memory _tokens,
        uint256 _stopLoss,
        uint256 _takeProfit,
        address _owner,
        address _usdc
    ) internal virtual {
        for (uint i = 0; i < _tokens.length; i++) {
            tokens.push(_tokens[i]);
        }
        stopLoss = _stopLoss;
        takeProfit = _takeProfit;
        owner = _owner;
        usdc = _usdc;

        emit SimpleTriggerInitialized(owner);
    }

    function checkUpkeep(
        bytes calldata
    ) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = _checkUpkeep();
    }

    function performUpkeep(bytes calldata) external override {
        bool upkeepNeeded = _checkUpkeep();
        require(upkeepNeeded, "Upkeep is not needed.");

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 balance = IERC20(tokens[i].token).balanceOf(address(this));
            if (balance > 0) {
                TransferHelper.safeApprove(
                    tokens[i].token,
                    address(uniswapRouter),
                    balance
                );

                ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                    .ExactInputSingleParams({
                        tokenIn: tokens[i].token,
                        tokenOut: usdc,
                        fee: tokens[i].poolFee,
                        recipient: owner,
                        deadline: block.timestamp,
                        amountIn: balance,
                        amountOutMinimum: 0,
                        sqrtPriceLimitX96: 0
                    });

                uniswapRouter.exactInputSingle(params);
            }
        }
    }

    function _checkUpkeep() internal view returns (bool upkeepNeeded) {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i].token);
            (, int256 price, , , ) = tokens[i].priceFeed.latestRoundData();
            uint256 balance = token.balanceOf(address(this));
            totalValue +=
                (balance * uint256(price)) /
                tokens[i].decimalMultiplier;
        }
        upkeepNeeded =
            (totalValue <= stopLoss || totalValue >= takeProfit) &&
            totalValue > 0;
        return upkeepNeeded;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override onlyOwner {
        (newImplementation);
    }
}
