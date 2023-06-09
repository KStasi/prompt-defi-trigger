// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract SimpleTrigger is AutomationCompatible {
    struct TokenInfo {
        address token;
        AggregatorV3Interface priceFeed;
        uint24 poolFee;
    }

    address public owner;
    uint256 public stopLoss; // in USDC
    uint256 public takeProfit; // in USDC

    ISwapRouter public uniswapRouter;
    TokenInfo[] public tokens;
    address public usdc;

    constructor(
        TokenInfo[] memory _tokens,
        uint256 _stopLoss,
        uint256 _takeProfit,
        address _uniswapRouter,
        address _usdc
    ) {
        for (uint i = 0; i < _tokens.length; i++) {
            tokens.push(_tokens[i]);
        }
        stopLoss = _stopLoss;
        takeProfit = _takeProfit;
        uniswapRouter = ISwapRouter(_uniswapRouter);
        owner = msg.sender;
        usdc = _usdc;
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
                TransferHelper.safeTransferFrom(
                    tokens[i].token,
                    owner,
                    address(this),
                    balance
                );

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
            (, int256 price, , , ) = tokens[i].priceFeed.latestRoundData();
            uint256 balance = IERC20(tokens[i].token).balanceOf(address(this));
            totalValue += balance * uint256(price);
        }
        upkeepNeeded = (totalValue <= stopLoss || totalValue >= takeProfit) && totalValue > 0;
        return upkeepNeeded;
    }
}
