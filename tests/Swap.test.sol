// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
import {Base} from "./Base.test.sol";
import {Math} from "../contracts/base/Math.sol";

abstract contract SwapTestBase is Base {
    using Math for uint256;

    function _createUsersEoa(uint256 numberOfAccounts) internal returns (address[] memory) {
        address[] memory users = new address[](numberOfAccounts);
        for (uint256 i; i < users.length; i++) {
            address user = _createUserEoa(i + 1922);
            users[i] = user;
        }
        return users;
    }

    function _unlockFrozenPaykiksOnTeam() internal virtual {
        vm.startPrank(vm.addr(10));
        teamContract.send();

        uint256 teamBalance = paykikErc20.balanceOf(address(teamContract));
    }

    function _getRandomNumber(uint256 min, uint256 max) internal view returns (uint256) {
        require(min < max, "Invalid range: min must be less than max");

        uint256 randomNumber = uint256(keccak256(abi.encode(blockhash(block.number - 1), block.timestamp)));

        // Calculate the random number within the specified range
        randomNumber = (randomNumber % (max - min + 1)) + min;

        return randomNumber;
    }

    function _sellPaykikWithUsdtPoolMock(address seller, uint256 amountOfPaykiks, uint256 mockAmount)
        internal
        returns (uint256)
    {
        vm.mockCall(
            address(usdtErc20),
            abi.encodeWithSelector(usdtErc20.balanceOf.selector, address(governorDao)),
            abi.encode(mockAmount)
        );
        uint256 beforeTokenPriceInUsdt = swapDex.getSellRate(amountOfPaykiks);
        uint256 beforePaykikCirculation = swapDex.getCirculationPaykik();
        uint256 beforeGovernorUsdtPool = usdtErc20.balanceOf(address(governorDao));

        (, uint256 amountPaykiksToBuyRemainder) = amountOfPaykiks.tryMod(1e8);
        (, uint256 beforeRemainder) = beforeTokenPriceInUsdt.tryMod(1e8);
        console.log(
            "[ BEFORE BUY TRX ] PAYKIKS: %d.%d",
            amountOfPaykiks / 10 ** paykikErc20.decimals(),
            amountPaykiksToBuyRemainder
        );
        console.log(
            "[ BEFORE BUY TRX ] USDT: %d.%d pay FOR PAYKIKS",
            beforeTokenPriceInUsdt / 1e2 / 10 ** usdtErc20.decimals(),
            beforeRemainder
        );

        console.log(
            "[ BEFORE SELL TRX POOL INFO ] PAYKIKS Circulation: %d and Governor USDT Pool: %d",
            beforePaykikCirculation,
            beforeGovernorUsdtPool
        );

        vm.startPrank(seller);
        paykikErc20.approve(address(swapDex), amountOfPaykiks);
        vm.stopPrank();

        vm.startPrank(seller);
        bool isOk = swapDex.sell(amountOfPaykiks);
        vm.stopPrank();

        assertEq(isOk, true);
        (isOk, mockAmount) = mockAmount.trySub(beforeTokenPriceInUsdt / 1e2);

        if (isOk) {
            vm.mockCall(
                address(usdtErc20),
                abi.encodeWithSelector(usdtErc20.balanceOf.selector, address(governorDao)),
                abi.encode(uint256(mockAmount))
            );

            uint256 afterPaykiksCirculation = swapDex.getCirculationPaykik();
            uint256 afterGovernorUsdtPool = usdtErc20.balanceOf(address(governorDao));
            console.log(usdtErc20.balanceOf(address(governorDao)));

            try swapDex.getSellRate(amountOfPaykiks) returns (uint256 afterTokenPriceInUsdt) {
                (, uint256 afterRemainder) = afterTokenPriceInUsdt.tryMod(1e8);

                console.log(
                    "[ AFTER BUY TRX ] PAYKIKS: %d.%d",
                    amountOfPaykiks / 10 ** paykikErc20.decimals(),
                    amountPaykiksToBuyRemainder
                );

                console.log(
                    "[ AFTER BUY TRX ] pay USDT: %d.%d for PAYKIKS",
                    afterTokenPriceInUsdt / 1e2 / 10 ** usdtErc20.decimals(),
                    afterRemainder
                );
                console.log(
                    "[ AFTER SELL TRX POOL INFO ] PAYKIKS Circulation: %d and Governor USDT Pool: %d\n",
                    afterPaykiksCirculation,
                    afterGovernorUsdtPool 
                );
                return mockAmount;
            } catch {}
        }
    }

    function _sellPaykiksWithFloat(address seller, uint256 amountOfPaykiks) internal returns (bool) {
        uint256 beforeTokenPriceInUsdt = swapDex.getSellRate(amountOfPaykiks);
        uint256 beforePaykikCirculation = swapDex.getCirculationPaykik();
        uint256 beforeGovernorUsdtPool = usdtErc20.balanceOf(address(governorDao));
        if (beforeTokenPriceInUsdt / 1e2 > beforeGovernorUsdtPool) {
            return false;
        }

        (, uint256 amountPaykiksToSellRemainder) = amountOfPaykiks.tryMod(1e8);
        (, uint256 beforeRemainder) = beforeTokenPriceInUsdt.tryMod(1e8);
        // console.log(
        //     "[ BEFORE SELL TRX ] PAYKIKS: %d.%d",
        //     amountOfPaykiks / 10 ** paykikErc20.decimals(),
        //     amountPaykiksToSellRemainder
        // );
        // console.log(
        //     "[ BEFORE SELL TRX ] GET: %d.%d pay FOR PAYKIKS",
        //     beforeTokenPriceInUsdt / 1e2 / 10 ** usdtErc20.decimals(),
        //     beforeRemainder
        // );
        console.log("[ BEFORE SELL TRX ] PAYKIKS: %d", amountOfPaykiks);
        console.log("[ BEFORE SELL TRX ] GET: %d pay FOR PAYKIKS", beforeTokenPriceInUsdt);
        console.log(
            "[ BEFORE SELL TRX POOL INFO ] PAYKIKS Circulation: %d and Governor USDT Pool: %d",
            beforePaykikCirculation,
            beforeGovernorUsdtPool
        );

        vm.startPrank(seller);
        paykikErc20.approve(address(swapDex), amountOfPaykiks);
        vm.stopPrank();

        vm.startPrank(seller);
        bool isOk = swapDex.sell(amountOfPaykiks);
        vm.stopPrank();

        assertEq(isOk, true);

        if (beforeTokenPriceInUsdt / 1e2 > usdtErc20.balanceOf(address(governorDao))) {
            return false;
        }

        uint256 afterPaykikCirculation = swapDex.getCirculationPaykik();
        uint256 afterGovernorUsdtPool = usdtErc20.balanceOf(address(governorDao));
        uint256 afterTokenPriceInUsdt = swapDex.getSellRate(amountOfPaykiks);

        (, uint256 afterRemainder) = afterTokenPriceInUsdt.tryMod(1e8);

        console.log("[ AFTER BUY TRX ] PAYKIKS: %d", amountOfPaykiks);

        console.log("[ AFTER BUY TRX ] GET USDT: %d for PAYKIKS", afterTokenPriceInUsdt);
        console.log(
            "[ AFTER BUY TRX POOL INFO ] PAYKIKS Circulation: %d and Governor USDT Pool: %d\n",
            afterPaykikCirculation,
            afterGovernorUsdtPool
        );

        return true;
    }

    function _buyPaykiksWithFloat(address buyer, uint256 amountOfPaykiks) internal returns (uint256) {
        uint256 beforeTokenPriceInUsdt = swapDex.getBuyRate(amountOfPaykiks);
        uint256 beforePaykikCirculation = swapDex.getCirculationPaykik();
        uint256 beforeGovernorUsdtPool = usdtErc20.balanceOf(address(governorDao));

        (, uint256 amountPaykiksToBuyRemainder) = amountOfPaykiks.tryMod(1e8);
        (, uint256 beforeRemainder) = beforeTokenPriceInUsdt.tryMod(1e8);
        // console.log(
        //     "[ BEFORE BUY TRX ] PAYKIKS: %d.%d",
        //     amountOfPaykiks / 10 ** paykikErc20.decimals(),
        //     amountPaykiksToBuyRemainder
        // );
        // console.log(
        //     "[ BEFORE BUY TRX ] USDT: %d.%d pay FOR PAYKIKS",
        //     beforeTokenPriceInUsdt / 1e2 / 10 ** usdtErc20.decimals(),
        //     beforeRemainder
        // );
        console.log("[ BEFORE BUY TRX ] PAYKIKS: %d", amountOfPaykiks);
        console.log("[ BEFORE BUY TRX ] USDT: %d pay FOR PAYKIKS", beforeTokenPriceInUsdt);
        console.log(
            "[ BEFORE BUY TRX POOL INFO ] PAYKIKS Circulation: %d and Governor USDT Pool: %d",
            beforePaykikCirculation,
            beforeGovernorUsdtPool
        );

        vm.startPrank(buyer);
        usdtErc20.approve(address(swapDex), beforeTokenPriceInUsdt);
        vm.stopPrank();

        vm.startPrank(buyer);
        bool isOk = swapDex.buy(amountOfPaykiks);
        vm.stopPrank();

        assertEq(isOk, true);

        uint256 afterPaykikCirculation = swapDex.getCirculationPaykik();
        uint256 afterGovernorUsdtPool = usdtErc20.balanceOf(address(governorDao));
        uint256 afterTokenPriceInUsdt = swapDex.getBuyRate(amountOfPaykiks);

        (, uint256 afterRemainder) = afterTokenPriceInUsdt.tryMod(1e8);

        console.log("[ AFTER BUY TRX ] PAYKIKS: %d", amountOfPaykiks);

        console.log("[ AFTER BUY TRX ] pay USDT: %d for PAYKIKS", afterTokenPriceInUsdt);
        console.log(
            "[ AFTER BUY TRX POOL INFO ] PAYKIKS Circulation: %d and Governor USDT Pool: %d\n",
            afterPaykikCirculation,
            afterGovernorUsdtPool
        );

        return beforeTokenPriceInUsdt;
    }

    function _sellPaykiksForMassTest(address seller, uint256 amountOfPaykiks) internal returns (uint256) {
        uint256 beforeTokenPriceInUsdt = swapDex.getSellRate(amountOfPaykiks);
        uint256 beforePaykikCirculation = swapDex.getCirculationPaykik();
        uint256 beforeGovernorUsdtPool = usdtErc20.balanceOf(address(governorDao));

        (, uint256 beforeRemainderUsdt) = beforeTokenPriceInUsdt.tryMod(1e8);
        (, uint256 paykiksRemainder) = amountOfPaykiks.tryMod(1e8);

        // console.log(
        //     "[ BEFORE SELL TRX ] Sell %d.%d Paykiks", amountOfPaykiks / 10 ** paykikErc20.decimals(), paykiksRemainder
        // );
        // console.log(
        //     "[ BEFORE Sell TRX ] Get %d.%d Usdt",
        //     beforeTokenPriceInUsdt / 1e2 / 10 ** usdtErc20.decimals(),
        //     beforeRemainderUsdt
        // );

        console.log("[ BEFORE SELL TRX ] Sell %d Paykiks", amountOfPaykiks);
        console.log("[ BEFORE Sell TRX ] Get %d Usdt", beforeTokenPriceInUsdt);
        console.log(
            "[ BEFORE SELL TRX POOL INFO ] PAYKIKS Circulation: %d and Governor USDT Pool: %d",
            beforePaykikCirculation / 10 ** paykikErc20.decimals(),
            beforeGovernorUsdtPool / 10 ** usdtErc20.decimals()
        );

        vm.startPrank(seller);
        paykikErc20.approve(address(swapDex), amountOfPaykiks);
        vm.stopPrank();

        vm.startPrank(seller);
        bool isOk = swapDex.sell(amountOfPaykiks);
        vm.stopPrank();

        assertEq(isOk, true);
        uint256 afterPaykiksCirculation = swapDex.getCirculationPaykik();
        uint256 afterGovernorUsdtPool = usdtErc20.balanceOf(address(governorDao));

        try swapDex.getSellRate(amountOfPaykiks) returns (uint256 afterTokenPriceInUsdt) {
            (, uint256 afterRemainderUsdt) = afterTokenPriceInUsdt.tryMod(1e8);
            console.log("[ AFTER SELL TRX ] Sell %d Paykiks", amountOfPaykiks);
            console.log("[ AFTER Sell TRX ] Get %d Usdt", afterTokenPriceInUsdt);
            console.log(
                "[ AFTER SELL TRX POOL INFO ] PAYKIKS Circulation: %d and Governor USDT Pool: %d\n",
                afterPaykiksCirculation / 10 ** paykikErc20.decimals(),
                afterGovernorUsdtPool / 10 ** usdtErc20.decimals()
            );

            return afterTokenPriceInUsdt;
        } catch {}
        // uint256 afterTokenPriceInUsdt = swapDex.getSellRate(amountOfPaykiks);
    }

    function _buyPaykiksForMassTest(address buyer, uint256 amountOfPaykiks) internal returns (uint256) {
        uint256 beforeTokenPriceInUsdt = swapDex.getBuyRate(amountOfPaykiks);
        uint256 beforePaykikCirculation = swapDex.getCirculationPaykik();
        uint256 beforeGovernorUsdtPool = usdtErc20.balanceOf(address(governorDao));

        (, uint256 beforeRemainderUsdt) = beforeTokenPriceInUsdt.tryMod(1e8);
        (, uint256 paykiksRemainder) = amountOfPaykiks.tryMod(1e8);

        // console.log(
        //     "[ BEFORE BUY TRX ] Buy %d.%d Paykiks", amountOfPaykiks / 10 ** paykikErc20.decimals(), paykiksRemainder
        // );
        // console.log(
        //     "[ BEFORE BUY TRX ] Pay %d.%d Usdt",
        //     beforeTokenPriceInUsdt / 1e2 / 10 ** usdtErc20.decimals(),
        //     beforeRemainderUsdt
        // );
        console.log("[ BEFORE BUY TRX ] Buy %d Paykiks", amountOfPaykiks);
        console.log("[ BEFORE BUY TRX ] Pay %d Usdt", beforeTokenPriceInUsdt);
        console.log(
            "[ BEFORE BUY TRX POOL INFO ] PAYKIKS Circulation: %d and Governor USDT Pool: %d",
            beforePaykikCirculation,
            beforeGovernorUsdtPool
        );

        vm.startPrank(buyer);
        usdtErc20.approve(address(swapDex), beforeTokenPriceInUsdt);
        vm.stopPrank();

        vm.startPrank(buyer);
        bool isOk = swapDex.buy(amountOfPaykiks);
        vm.stopPrank();

        assertEq(isOk, true);

        uint256 afterPaykikCirculation = swapDex.getCirculationPaykik();
        uint256 afterGovernorUsdtPool = usdtErc20.balanceOf(address(governorDao));
        uint256 afterTokenPriceInUsdt = swapDex.getBuyRate(amountOfPaykiks);

        (, uint256 afterRemainderUsdt) = afterTokenPriceInUsdt.tryMod(1e8);
        // console.log(
        //     "[ AFTER BUY TRX ] Buy %d.%d Paykiks", amountOfPaykiks / 10 ** paykikErc20.decimals(), paykiksRemainder
        // );
        // console.log(
        //     "[ BEFORE BUY TRX ] Pay %d.%d Usdt",
        //     afterTokenPriceInUsdt / 1e2 / 10 ** usdtErc20.decimals(),
        //     afterRemainderUsdt
        // );
        console.log("[ AFTER BUY TRX ] Buy %d Paykiks", amountOfPaykiks);
        console.log("[ BEFORE BUY TRX ] Pay %d Usdt", afterTokenPriceInUsdt);
        console.log(
            "[ AFTER BUY TRX POOL INFO ] PAYKIKS Circulation: %d and Governor USDT Pool: %d\n",
            afterPaykikCirculation,
            afterGovernorUsdtPool
        );

        return beforeTokenPriceInUsdt;
    }

    function _buyPaykiksWithMock(address buyer, uint256 amountOfPaykiks) internal returns (uint256) {
        uint256 tokenPriceInUsdt = swapDex.getBuyRate(amountOfPaykiks);

        vm.startPrank(buyer);
        usdtErc20.approve(address(swapDex), tokenPriceInUsdt);
        vm.stopPrank();

        vm.mockCall(
            address(swapDex),
            abi.encodeWithSelector(swapDex.maxBuy.selector),
            abi.encode(uint256(1 * 1e5 * 10 ** paykikErc20.decimals()))
        );
        console.log(swapDex.maxBuy());
        vm.startPrank(buyer);
        bool isOk = swapDex.buy(amountOfPaykiks);
        vm.stopPrank();

        assertEq(isOk, true);

        return tokenPriceInUsdt;
    }

    function _buyPaykiks(address buyer, uint256 amountOfPaykiks) internal returns (uint256) {
        uint256 tokenPriceInUsdt = swapDex.getBuyRate(amountOfPaykiks);

        vm.startPrank(buyer);
        usdtErc20.approve(address(swapDex), tokenPriceInUsdt);
        vm.stopPrank();

        vm.startPrank(buyer);
        bool isOk = swapDex.buy(amountOfPaykiks);
        vm.stopPrank();

        assertEq(isOk, true);

        return tokenPriceInUsdt;
    }

    function _createUserEoa(uint256 privateKey) internal returns (address) {
        address user = vm.addr(privateKey);

        vm.startPrank(usdtOwner);
        usdtErc20.transfer(user, 40 * 1e4 * 10 ** usdtErc20.decimals());
        vm.stopPrank();

        return user;
    }

    function _sellPaykiksWithRevert(address seller, uint256 amount, bytes memory revertMsg) internal {
        uint256 amountOfUsdtWillBeReceived = swapDex.getSellRate(amount);

        vm.startPrank(seller);
        paykikErc20.approve(address(swapDex), amount);
        vm.stopPrank();

        vm.expectRevert(revertMsg);
        vm.startPrank(seller);
        swapDex.sell(amount);
        vm.stopPrank();
    }

    function _sellPaykiks(address seller, uint256 amount) internal returns (uint256) {
        uint256 amountOfUsdtWillBeReceived = swapDex.getSellRate(amount);

        vm.startPrank(seller);
        paykikErc20.approve(address(swapDex), amount);
        vm.stopPrank();

        vm.startPrank(seller);
        bool isOk = swapDex.sell(amount);
        vm.stopPrank();

        assertEq(isOk, true);

        return amountOfUsdtWillBeReceived;
    }

    // function _sendInitialAmountOfPaykiksToTeam() internal {
    //     vm.startPrank(paykikOwner);
    //     paykikErc20.transfer(address(teamContract), 19566179021730);
    //     vm.stopPrank();
    // }

    function _buyPaykiksWithRevert(address buyer, uint256 amountOfPaykiks, bytes memory revertMessage) internal {
        uint256 tokenPriceInUsdt = swapDex.getBuyRate(amountOfPaykiks);

        vm.startPrank(buyer);
        usdtErc20.approve(address(swapDex), tokenPriceInUsdt);
        vm.stopPrank();

        vm.expectRevert(revertMessage);
        vm.startPrank(buyer);
        bool isOk = swapDex.buy(amountOfPaykiks);
        vm.stopPrank();
    }

    function _unlockPaykiksFromTeam() internal returns (uint256) {
        vm.startPrank(vm.addr(10));
        uint256 unlockedAmount = teamContract.send();
        vm.stopPrank();

        return unlockedAmount;
    }

    function _sellEntirePaykikPool() internal returns (address[] memory) {
        address[] memory users = new address[](226);
        for (uint256 i; i < users.length; i++) {
            users[i] = _createUserEoa(i + 199);
        }

        for (uint256 j; j < users.length; j++) {
            if (paykikErc20.balanceOf(address(swapDex)) > swapDex.maxBuy()) {
                _buyPaykiks(users[j], swapDex.maxBuy());
            } else {
                _buyPaykiks(users[j], paykikErc20.balanceOf(address(swapDex)));
            }
        }

        return users;
    }
}

contract SwapTest is SwapTestBase {
    using Math for uint256;

    /**
     * Covered methods:
     *  [+] buy
     *  [+] getBuyRate
     *  [+] getCirculationPaykik
     *  [+] sell
     *  [-] getSellRate
     */

    function testRevert__buy__swapAmountMustBeMoreThanOne() public {
        /**
         * 1. User decides to buy 0.1 paykiks and tries to get buy rate
         * 2. User approves usdt recorded to calculated paykik price
         * 3. User tries to buy 0.1 paykiks
         * 4. User got revert with message "Swap amount must be more than 1 Paykik"
         */

        // erroredAmountOfPaykiks = 0.1 paykik
        uint256 erroredAmountOfPaykiks = 1 * 10 ** (paykikErc20.decimals() - 1);

        _buyPaykiksWithRevert(alice, erroredAmountOfPaykiks, bytes("Swap amount must be more than 1 Paykik"));
    }

    function testRevert__buy__youCantPurchaseThan() public {
        /**
         * 1. User decides to buy 10k paykiks and tries to get buy rate
         * 2. User approves usdt recorded to calculated paykik price
         * 3. User tries to buy 10k paykiks
         * 4. User got revert with message "You can't purchase more than 7999 Paykik"
         */
        uint256 erroredAmountOfPaykiks = 1 * 1e4 * 10 ** paykikErc20.decimals();
        _buyPaykiksWithRevert(alice, erroredAmountOfPaykiks, bytes("You can't purchase more than 7999 Paykik"));
    }

    function testRevert__buy__requestedAmountExceeds() public {
        /**
         * 1. User decides to buy 5k paykiks and tries to get buy rate
         * 2. User approves usdt recorded to calculated paykik price
         * 3. User got revert with message "Requested amount exceeds Paykik availible for purchase"
         */
        vm.mockCall(
            address(paykikErc20),
            abi.encodeWithSelector(paykikErc20.balanceOf.selector, address(swapDex)),
            abi.encode(1)
        );

        uint256 erroredAmountOfPaykiks = 1 * 1e3 * 10 ** paykikErc20.decimals();
        vm.expectRevert(bytes("Requested amount exceeds Paykik availible for purchase"));
        swapDex.getBuyRate(erroredAmountOfPaykiks);
    }

    function testRevert__buy__approvedUsdtIsLessThanRequestedAmount() public {
        /**
         *  1. User decides to buy 5k paykiks and tries to get buy rate
         *  2. User approves usdt NOT recorded to calculated paykik price
         *  3. User got revert with message "Aprooved tokens is less than requested amount"
         */

        uint256 amountPaykiksToBuy = 1 * 1e3 * 10 ** paykikErc20.decimals();
        uint256 tokenPriceInUsdt = swapDex.getBuyRate(amountPaykiksToBuy);
        tokenPriceInUsdt = tokenPriceInUsdt / 10 ** (paykikErc20.decimals() - usdtErc20.decimals());

        vm.startPrank(alice);
        usdtErc20.approve(address(swapDex), tokenPriceInUsdt - 1 * 1e2 * 10 ** usdtErc20.decimals());
        vm.stopPrank();

        vm.expectRevert(bytes("Aprooved USDT is less than requested amount"));
        vm.startPrank(alice);
        bool isOk = swapDex.buy(amountPaykiksToBuy);
        vm.stopPrank();
    }

    function test__buy__true() public {
        /**
         *  1. User decides to buy 1k paykiks and tries to get buy rate
         *  2. User approves usdt recorded to calculated paykik price
         *  3. User receives paykiks on his balance
         */

        uint256 amountPaykiksToBuy = 1 * 1e3 * 10 ** paykikErc20.decimals();
        _buyPaykiks(alice, amountPaykiksToBuy);
    }

    function testRevert__getBuyRate__GovernorPollShouldBeMoreThanOne() public {
        /**
         * 1. User is trying to buy 1k PAYKIKS while the balance of the swap contract is less than 1 USDT
         * 2. User got revert with message "Governor pool should be more than 1 USDT"
         */
        uint256 amountOfPaykiksToBuy = 1 * 1e3 * 10 ** paykikErc20.decimals();
        vm.mockCall(
            address(usdtErc20),
            abi.encodeWithSelector(usdtErc20.balanceOf.selector, address(governorDao)),
            abi.encode(1)
        );

        vm.expectRevert(bytes("Governor pool should be more than 1 USDT"));
        uint256 amountOfUsdtToPay = swapDex.getBuyRate(amountOfPaykiksToBuy);
    }

    function testRevert__getBuyRate__requestedAmountExceeds() public {
        /**
         *  1. User is trying to buy 1k PAYKIKS while the balance of swap contract is less than 1k PAYKIKS
         *  2. User got revert with message "Requested amount exceeds Paykik availible for purchase"
         */
        uint256 amountOfPaykiksToBuy = 1 * 1e3 * 10 ** paykikErc20.decimals();

        vm.mockCall(
            address(paykikErc20),
            abi.encodeWithSelector(paykikErc20.balanceOf.selector, address(swapDex)),
            abi.encode(1)
        );

        vm.expectRevert(bytes("Requested amount exceeds Paykik availible for purchase"));
        swapDex.getBuyRate(amountOfPaykiksToBuy);
    }

    function test__getBuyRate__uint256() public {
        /**
         *  1. User successfuly get buy rate
         */

        uint256 amountOfPaykiksToBuy = 1 * 1e3 * 10 ** paykikErc20.decimals();
        uint256 amountOfUsdtToPay = swapDex.getBuyRate(amountOfPaykiksToBuy) / 1e2;
        assertEq(amountOfUsdtToPay > amountOfPaykiksToBuy / 1e2, true);
    }

    function test__getCirculationPaykik__zero() public {
        /**
         * Check zero circulation when no one bought PAYKIKS and left the team
         */

        uint256 zeroCirculation = swapDex.getCirculationPaykik();
        assertEq(zeroCirculation, 0);
    }

    function test__getCirculationPaykik__someoneBoughtPaykiks() public {
        /**
         *  Check how does getCirculationPaykik function behave, if someone bought 1k paykiks
         */

        uint256 amountOfPaykiksToBuy = 1 * 1e3 * 10 ** paykikErc20.decimals();
        _buyPaykiks(alice, amountOfPaykiksToBuy);

        uint256 circulation = swapDex.getCirculationPaykik();
        assertEq(circulation, amountOfPaykiksToBuy);
    }

    function test__getCirculationPaykik__checkTeamPaykiksInclusion() public {
        /**
         *  Check how does getCirculationPaykik function behave, if two users bought 16k paykiks in sum
         *  and then team contract unlocked appropriate amount of paykiks
         */

        uint256 amountOfPaykiksToBuy = 7 * 1e3 * 10 ** paykikErc20.decimals();
        _buyPaykiks(alice, amountOfPaykiksToBuy);
        _buyPaykiks(bob, amountOfPaykiksToBuy);

        uint256 unlockedAmountOfPaykiks = _unlockPaykiksFromTeam();

        uint256 circulation = swapDex.getCirculationPaykik();
        assertEq(circulation, amountOfPaykiksToBuy * 2 + unlockedAmountOfPaykiks);
    }

    function test__sell__true() public {
        /**
         *  1. User bought 3k PAYKIKS
         *  2. User gets sell rate
         *  3. User approves 3k PAYKIKS for swapDex contract
         *  4. User tries to sell 3k PAYKIKS and pay 1% as a fee
         */

        uint256 amountPaykiksToBuy = 3 * 1e3 * 10 ** paykikErc20.decimals();
        uint256 differencesBetweenDecimals = 10 ** (paykikErc20.decimals() - usdtErc20.decimals());

        uint256 amountOfSpentUsdt = _buyPaykiks(alice, amountPaykiksToBuy);

        uint256 amountPaykiksToSell = amountPaykiksToBuy;

        uint256 amountOfReceivedUsdt = _sellPaykiks(alice, amountPaykiksToSell);
    }

    function testRevert__sell__swapAmountMustBeMoreThanOne() public {
        /**
         *  1. User bought 3k PAYKIKS
         *  2. User gets sell rate
         *  3. User approves 0.9 PAYKIKS for swapDex contract
         *  4. User tries to sell 0.9 PAYKIKS
         *  5. User gets revert message "Swap amount must be more than 1 Paykik"
         */

        uint256 amountPaykiksToBuy = 3 * 1e3 * 10 ** paykikErc20.decimals();
        uint256 amountOfSpentUsdt = _buyPaykiks(alice, amountPaykiksToBuy);

        uint256 erroneousAmountPaykiksToSell = 9 * 10 ** (paykikErc20.decimals() - 1);
        _sellPaykiksWithRevert(alice, erroneousAmountPaykiksToSell, bytes("Swap amount must be more than 1 Paykik"));
    }

    function testRevert__sell__approovedTokensIsLessThanRequested() public {
        /**
         *  1. User bought 3k PAYKIKS
         *  2. User gets sell rate
         *  3. User approves 2k PAYKIKS for swapDex contract
         *  4. User tries to sell 3k PAYKIKS
         *  5. User gets revert message "Aprooved tokens is less than requested amount"
         */

        uint256 amountPaykiksToBuy = 3 * 1e3 * 10 ** paykikErc20.decimals();
        uint256 amountOfSpentUsdt = _buyPaykiks(alice, amountPaykiksToBuy);

        uint256 amountOfPaykiksToSell = amountPaykiksToBuy;
        uint256 amountOfUsdtWillBeReceived = swapDex.getSellRate(amountOfPaykiksToSell);

        vm.startPrank(alice);
        paykikErc20.approve(address(swapDex), amountOfPaykiksToSell - 10 ** paykikErc20.decimals());
        vm.stopPrank();

        vm.expectRevert(bytes("Aprooved tokens is less than requested amount"));
        vm.startPrank(alice);
        bool isOk = swapDex.sell(amountOfPaykiksToSell);
        vm.stopPrank();
    }

    /**
     * !TODO:
     * 1. Проверить куплю/продажу нецелочисленных токенов
     * 2. Проверить работу Swap при продаже 1000 PAYKIK при условии наличия 100 USDT (за счет вывода из Governor'а USDT)
     */
    function test__mass_buy_sell() public {
        /**
         * 1. User[]1..10] bought 10k USDT
         * 2. User[1..10] buys [1k..7k...800,900...]
         */

        address[] memory users = new address[](30);
        for (uint256 i; i < users.length; i++) {
            address user = _createUserEoa(i + 1922);
            users[i] = user;
        }

        for (uint256 j; j < users.length; j++) {
            uint256 dozens;
            if ((j + 1) * 1e3 * 10 ** paykikErc20.decimals() < swapDex.maxBuy()) {
                dozens = 1e3;
            } else if ((j + 1) * 1e2 * 10 ** paykikErc20.decimals() < swapDex.maxBuy()) {
                dozens = 1e2;
            } else {
                dozens = 1e1;
            }
            console.log("[ %d BUY Iteration ]", j);
            _buyPaykiksForMassTest(users[j], (j + 1) * dozens * 10 ** paykikErc20.decimals());
        }

        for (uint256 x; x < users.length; x++) {
            uint256 dozens;
            if ((x + 1) * 1e3 * 10 ** paykikErc20.decimals() < swapDex.maxBuy()) {
                dozens = 1e3;
            } else if ((x + 1) * 1e2 * 10 ** paykikErc20.decimals() < swapDex.maxBuy()) {
                dozens = 1e2;
            } else {
                dozens = 1e1;
            }
            console.log("[ %d SELL Iteration ]", x);
            _sellPaykiksForMassTest(users[x], (x + 1) * dozens * 10 ** paykikErc20.decimals());
        }
    }

    function test__buyWithFloatAmounts__buy_sell() public {
        address[] memory users = new address[](20);
        for (uint256 i; i < users.length; i++) {
            address user = _createUserEoa(i + 1922);
            users[i] = user;
        }

        for (uint256 j; j < users.length; j++) {
            uint256 dozens;
            if ((j + 1) * 1e3 * 10 ** paykikErc20.decimals() < swapDex.maxBuy()) {
                dozens = 1;
            } else if ((j + 1) * 1e2 * 10 ** paykikErc20.decimals() < swapDex.maxBuy()) {
                dozens = 1;
            } else {
                dozens = 1;
            }
            uint256 amoutOfPaykiksToBuy = (j + 1) * dozens * 10 ** paykikErc20.decimals();
            vm.warp(j);
            uint256 generatedNumber =
                _getRandomNumber(5 * 10 ** (paykikErc20.decimals() - 4), 9 * 10 ** (paykikErc20.decimals() - 2));
            // + _generateRandomNumber(1 * 10 ** (paykikErc20.decimals() - 2), 9 * 10 ** (paykikErc20.decimals() - 2));
            console.log("[ %d BUY Iteration ]", j);
            _buyPaykiksWithFloat(users[j], amoutOfPaykiksToBuy + generatedNumber);
        }

        for (uint256 j; j < users.length; j++) {
            uint256 dozens;
            if ((j + 1) * 1e3 * 10 ** paykikErc20.decimals() < swapDex.maxBuy()) {
                dozens = 1;
            } else if ((j + 1) * 1e2 * 10 ** paykikErc20.decimals() < swapDex.maxBuy()) {
                dozens = 1;
            } else {
                dozens = 1;
            }
            uint256 amountOfPaykiksToSell = (j + 1) * dozens * 10 ** paykikErc20.decimals();
            vm.warp(j);
            uint256 generatedNumber =
                _getRandomNumber(5 * 10 ** (paykikErc20.decimals() - 4), 9 * 10 ** (paykikErc20.decimals() - 2));
            // + _generateRandomNumber(1 * 10 ** (paykikErc20.decimals() - 2), 9 * 10 ** (paykikErc20.decimals() - 2));
            console.log("[ %d SELL Iteration ]", j);
            bool isOk = _sellPaykiksWithFloat(users[j], amountOfPaykiksToSell + generatedNumber);
            if (!isOk) {
                break;
            }
        }
    }

    // function test__massBuyAndWithdrawUSDTFromGovernor() public {
    //     address[] memory users = new address[](30);
    //     uint256 mockAmount = 1 * 1e2 * 10 ** usdtErc20.decimals();

    //     for (uint256 i; i < users.length; i++) {
    //         address user = _createUserEoa(i + 1922);
    //         users[i] = user;
    //     }

    //     for (uint256 j; j < users.length; j++) {
    //         uint256 dozens;
    //         if ((j + 1) * 1e3 * 10 ** paykikErc20.decimals() < swapDex.maxBuy()) {
    //             dozens = 1e3;
    //         } else if ((j + 1) * 1e2 * 10 ** paykikErc20.decimals() < swapDex.maxBuy()) {
    //             dozens = 1e2;
    //         } else {
    //             dozens = 1e1;
    //         }
    //         console.log("[ %d BUY Iteration ]", j);
    //         _buyPaykiksForMassTest(users[j], (j + 1) * dozens * 10 ** paykikErc20.decimals());
    //     }

    //     for (uint256 x; x < users.length; x++) {
    //         uint256 dozens;
    //         if ((x + 1) * 1e3 * 10 ** paykikErc20.decimals() < swapDex.maxBuy()) {
    //             dozens = 1e3;
    //         } else if ((x + 1) * 1e2 * 10 ** paykikErc20.decimals() < swapDex.maxBuy()) {
    //             dozens = 1e2;
    //         } else {
    //             dozens = 1e1;
    //         }

    //         uint256 amountToSell = (x + 1) * dozens * 10 ** paykikErc20.decimals();
    //         console.log("[ %d SELL Iteration ]", x);
    //         mockAmount = _sellPaykikWithUsdtPoolMock(users[x], amountToSell, mockAmount);
    //     }
    // }

    function test__sellAfterEntirePaykikPoolSent__true() public {
        address[] memory users = _sellEntirePaykikPool();

        uint256 receivedAmountOfUsdt = _sellPaykiks(users[0], swapDex.maxBuy());

        assertGe(receivedAmountOfUsdt, 0);
    }

    function testRevert__buyAfterEntirePaykikPoolSent_requestedAmountExceedsPaykikAvailable() public {
        address[] memory users = _sellEntirePaykikPool();

        uint256 amountToBuy = 1 * 10 ** paykikErc20.decimals();
        vm.expectRevert(bytes("Requested amount exceeds Paykik availible for purchase"));
        swapDex.getBuyRate(amountToBuy);
    }

    function test__sellAfterEntirePaykikPoolSendAndUnlockedOnTeam() public {
        address[] memory users = _sellEntirePaykikPool();

        uint256 intPriceBeforeUnlocking = swapDex.getSellRate(swapDex.maxBuy()) / 1e8;
        (, uint256 remainderPriceBeforeUnlocking) = swapDex.getSellRate(swapDex.maxBuy()).tryMod(1e8);
        console.log(
            "[ BEFORE ] Sell rate Team Paykiks Unlocking: %d.%d", intPriceBeforeUnlocking, remainderPriceBeforeUnlocking
        );

        _unlockFrozenPaykiksOnTeam();

        uint256 intPriceAfterUnlocking = swapDex.getSellRate(swapDex.maxBuy()) / 1e8;
        (, uint256 remainderPriceAfterUnlocking) = swapDex.getSellRate(swapDex.maxBuy()).tryMod(1e8);
        console.log(
            "[ AFTER ] Sell rate Team Paykiks Unlocking: %d.%d", intPriceAfterUnlocking, remainderPriceAfterUnlocking
        );

        (uint256 receivedAmountOfUsdt) = _sellPaykiks(users[0], swapDex.maxBuy());
    }

    function test__buyAfterEntirePaykikPoolSendAndUnlockedOnTeam() public {
        address[] memory users = _sellEntirePaykikPool();

        _unlockFrozenPaykiksOnTeam();

        // Get the balance of the first address from team receivers
        uint256 amountToSell = paykikErc20.balanceOf(teamAddresses[0]);

        _sellPaykiks(teamAddresses[0], amountToSell);

        uint256 intUsdtToPay = swapDex.getBuyRate(amountToSell) / 1e2;
        (, uint256 remainderUsdtToPay) = intUsdtToPay.tryMod(10 ** usdtErc20.decimals());

        console.log(
            "[ AFTER SELL BUY RATE ] Buy rate: %d.%d for %d Paykiks",
            intUsdtToPay / 1e6,
            remainderUsdtToPay,
            amountToSell / 1e8
        );
    }

    function test__buy__lowAmounts() public {
        uint256 amount = 3 * 10 ** paykikErc20.decimals();
        uint256 firstAmount = 114 * 10 ** paykikErc20.decimals();

        uint256 firstBuy = _buyPaykiks(alice, firstAmount);
        console.log("[1] FOR %d PAYKIKS PAY %d USDT", firstAmount, firstBuy / 1e2);

        uint256 secondBuy = _buyPaykiks(alice, amount);
        console.log("[2] FOR %d PAYKIKS PAY %d USDT", amount, secondBuy / 1e2);

        uint256 thirdBuy = _buyPaykiks(alice, amount);
        console.log("[3] FOR %d PAYKIKS PAY %d USDT", amount, thirdBuy / 1e2);

        uint256 fourthBuy = _sellPaykiks(alice, amount);
        console.log("[4] FOR %d PAYKIKS PAY %d USDT", amount, fourthBuy / 1e2);

        uint256 fifthBuy = _sellPaykiks(alice, 100 * 10 ** paykikErc20.decimals());
        console.log("[5] FOR %d PAYKIKS PAY %d USDT", 100 * 10 ** paykikErc20.decimals(), fifthBuy / 1e2);
    }

    function testRevision11__buy_sell_100_by_1() public {
        address[] memory users = _createUsersEoa(100);

        uint256 amountToBuy = 1 * 10 ** paykikErc20.decimals();

        for (uint256 i; i < users.length; i++) {
            console.log("[ BUY ITERATION %d ]", i);
            _buyPaykiksForMassTest(users[i], amountToBuy);
        }

        for (uint256 j; j < users.length; j++) {
            console.log("[ SELL ITERATION %d ]", j);
            _sellPaykiksForMassTest(users[j], amountToBuy);
        }
    }

    function testRevision11__buy_sell_100_by_10() public {
        address[] memory users = _createUsersEoa(10);

        uint256 amountToBuy = 10 * 10 ** paykikErc20.decimals();

        for (uint256 i; i < users.length; i++) {
            console.log("[ BUY ITERATION %d ]", i);
            _buyPaykiksForMassTest(users[i], amountToBuy);
        }

        for (uint256 j; j < users.length; j++) {
            console.log("[ SELL ITERATION %d ]", j);
            _sellPaykiksForMassTest(users[j], amountToBuy);
        }
    }

    function testRevision11__buy_sell_1000_by_100() public {
        address[] memory users = _createUsersEoa(10);

        uint256 amountToBuy = 100 * 10 ** paykikErc20.decimals();

        for (uint256 i; i < users.length; i++) {
            console.log("[ BUY ITERATION %d ]", i);
            _buyPaykiksForMassTest(users[i], amountToBuy);
        }

        for (uint256 j; j < users.length; j++) {
            console.log("[ SELL ITERATION %d ]", j);
            _sellPaykiksForMassTest(users[j], amountToBuy);
        }
    }

    function testRevision11__buyMaxBuy() public {
        address[] memory users = _createUsersEoa(1);

        uint256 amountToBuy = 7999 * 10 ** paykikErc20.decimals();

        _buyPaykiksForMassTest(users[0], amountToBuy);
    }

    function testRevision11__buyFloatedAmount() public {
        address[] memory users = _createUsersEoa(1);

        uint256 amountToBuy = 555555555;
        _buyPaykiksForMassTest(users[0], amountToBuy);
    }

    function testRevision11__buy_sell_floated_555_by_111() public {
        address[] memory users = _createUsersEoa(5);

        uint256 amountToBuy = 11111111111;

        for (uint256 i; i < users.length; i++) {
            console.log("[ BUY ITERATION %d ]", i);
            _buyPaykiksForMassTest(users[i], amountToBuy);
        }

        for (uint256 j; j < users.length; j++) {
            console.log("[ SELL ITERATION %d ]", j);
            _sellPaykiksForMassTest(users[j], amountToBuy);
        }
    }

    function testRevision11__buy_sell_floated_5555_by_1111() public {
        address[] memory users = _createUsersEoa(5);

        uint256 amountToBuy = 111111111111;

        for (uint256 i; i < users.length; i++) {
            console.log("[ BUY ITERATION %d ]", i);
            _buyPaykiksForMassTest(users[i], amountToBuy);
        }

        for (uint256 j; j < users.length; j++) {
            console.log("[ SELL ITERATION %d ]", j);
            _sellPaykiksForMassTest(users[j], amountToBuy);
        }
    }

    function testRevision11__buy_sell_usdt_pool_mocked_to_1000() public {
        address[] memory users = _createUsersEoa(5);
        uint256 mockedAmountOfUsdt = 2  * 10 ** usdtErc20.decimals();

        _buyPaykiksForMassTest(alice, swapDex.maxBuy());

        _sellPaykikWithUsdtPoolMock(alice, swapDex.maxBuy(), mockedAmountOfUsdt);
    }

    function testRevision11__buy_sell__usdt_pool_mocked_to_1000_sell_22222() public {
        address[] memory users = _createUsersEoa(5);
        uint256 mockedAmountOfUsdt = 1 * 1e3 * 10 ** usdtErc20.decimals();
        uint256 amountPaykiksToSell = 222222222222;
        _buyPaykiksForMassTest(alice, swapDex.maxBuy());

        _sellPaykikWithUsdtPoolMock(alice, amountPaykiksToSell, mockedAmountOfUsdt);
    }

    function testRevision11__buy_sell_1000_by_100__entirePaykikPoolSold() public {
        address[] memory users = _sellEntirePaykikPool();

        uint256 amountToSell = 10000000000;

        for (uint256 k; k < 10; k++) {
            console.log("[ SELL ITERATION %d ]", k);
            _sellPaykiksForMassTest(users[k], amountToSell);
        }
    }

    function testRevision11__buy_sell_555_by_111__entirePaykikPoolSold() public {
        address[] memory users = _sellEntirePaykikPool();

        uint256 amountToSell = 11111111111;

        for (uint256 k; k < 5; k++) {
            console.log("[ SELL ITERATION %d ]", k);
            _sellPaykiksForMassTest(users[k], amountToSell);
        }
    }

    function testRevision11__buy_sell_maxBuy__entirePaykikPoolSold() public {
        address[] memory users = _sellEntirePaykikPool();

        uint256 amountToSell = swapDex.maxBuy();

        _sellPaykiksForMassTest(users[0], amountToSell);
    }

    function testRevision11__buy_sell_5555__entirePaykikPoolSold() public {
        address[] memory users = _sellEntirePaykikPool();

        uint256 amountToSell = 555555555555;

        _sellPaykiksForMassTest(users[0], amountToSell);
    }
}
