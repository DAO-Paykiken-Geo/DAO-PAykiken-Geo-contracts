// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
import {Base} from "./Base.test.sol";
import {Math} from "../contracts/base/Math.sol";
import {SwapTestBase} from "./Swap.test.sol";

abstract contract SwapFuzzBase is SwapTestBase {}

contract SwapFuzz is SwapFuzzBase {
    function testGetBuyRateFuzz(uint256 amountToBuy) public {
        amountToBuy = bound(amountToBuy, 1 * 10 ** paykikErc20.decimals(), swapDex.maxBuy());
        uint256 buyTokenPrice = swapDex.getBuyRate(amountToBuy);
        uint256 countInPaykiks = buyTokenPrice * 1e2;
        assertGe(countInPaykiks, amountToBuy);
    }

    function testSellRateFuzz(uint256 amountToSell) public {}
}
