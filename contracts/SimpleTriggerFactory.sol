// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SimpleTrigger.sol";

contract SimpleTriggerFactory {
    event SimpleTriggerCreated(
        address indexed triggerAddress,
        address indexed owner
    );

    uint256 public triggerCount;
    mapping(uint256 => address) public triggers;

    function createSimpleTrigger(
        SimpleTrigger.TokenInfo[] memory _tokens,
        uint256 _stopLoss,
        uint256 _takeProfit,
        address _uniswapRouter,
        address _usdc
    ) external returns (SimpleTrigger) {
        SimpleTrigger trigger = new SimpleTrigger(
            _tokens,
            _stopLoss,
            _takeProfit,
            _uniswapRouter,
            _usdc
        );
        emit SimpleTriggerCreated(address(trigger), msg.sender);
        triggers[triggerCount] = address(trigger);
        triggerCount++;
        return trigger;
    }
}
