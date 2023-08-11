// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Vm.sol";
import "forge-std/console.sol";
import {Strings} from "../contracts/base/Strings.sol";
import "./Base.test.sol";

abstract contract GovernorTestBase is Base {
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

    function _holdPaykiks(address holder, uint256 amountToHold, uint256 timePeriod) internal {
        vm.startPrank(holder);
        paykikErc20.approve(address(holdContract), amountToHold);
        vm.stopPrank();

        bool isOk = holdContract.depositFrom(holder, timePeriod, amountToHold);
        assertEq(isOk, true);
    }

    function _sendUsdtOnGovernorBalance(uint256 amount) internal {
        vm.startPrank(usdtOwner);
        //2 * 1e4 * 10 ** usdtErc20.decimals()
        usdtErc20.transfer(address(governorDao), amount);
        vm.stopPrank();
    }

    function _createPoll(address pollReleaser, address pollTargetAddress, uint256 amountOfUsdtForTarget)
        internal
        returns (uint256)
    {
        vm.startPrank(pollReleaser);
        uint256 pollId = governorDao.createPoll(pollTargetAddress, amountOfUsdtForTarget);
        vm.stopPrank();

        return pollId;
    }

    function _submitVote(address who, uint256 pollId) internal {
        uint256 amount = paykikErc20.balanceOf(who);
        _approvePaykikForHold(who, amount);

        vm.startPrank(who);
        bool isOk = governorDao.submitVote(pollId);
        vm.stopPrank();

        assertEq(isOk, true);
    }

    function _cancelVotes(address who) internal {
        vm.startPrank(who);
        bool isOk = governorDao.cancelVotes();
        vm.stopPrank();

        assertEq(isOk, true);
    }

    function _mockDeadline(uint256 pollId) internal {
        vm.record();
        governorDao.getPoll(pollId);
        (bytes32[] memory reads,) = vm.accesses(address(governorDao));
        vm.store(address(governorDao), reads[4], bytes32(uint256(1)));
    }
}

contract GovernorTest is GovernorTestBase {
    using Strings for uint256;
    /* 
        Covered methods:
            [+] CreatePoll
            [+] getPoll
            [+] Spend
            [+] submitVote
            [+] finishPoll
            [-] cancelVotes
    */

    uint256 amountOfUsdtForTarget;

    function setUp() public override {
        super.setUp();
        amountOfUsdtForTarget = 3 * 1e3 * 10 ** usdtErc20.decimals();
    }

    /*          TESTS ON METHOD {Governor::createPoll}          */
    function testRevert__createPoll__youAreNotInDao() public {
        /* 
            1. User tries to create a poll with no paykiks on his Paykik contract balance
            2. User got revert with message "This function is availible only to DAO memebers"
        */
        vm.expectRevert(bytes("This function is availible only to DAO memebers"));
        _createPoll(alice, bob, amountOfUsdtForTarget);
    }

    function testRevert__createPoll__youAreNotInDao_viaNoHeld() public 
    /* 
            1. User gets buyRate to buy paykiks for usdt
            2. User approves usd_sendUsdtOnGovernorBalancet for paykiks recorded to buyRate
            2. User tries to create a poll with no held paykiks on his Hold contract balance
            3. User got revert with message "This function is availible only to DAO memebers"
        */
    {
        uint256 amountOfPaykikToBuy = 1 * 1e3 * 10 ** paykikErc20.decimals();

        vm.expectRevert(bytes("This function is availible only to DAO memebers"));
        _createPoll(alice, bob, amountOfUsdtForTarget);
    }

    function test__createPoll__uint256() public returns (uint256) {
        /* 
            1. User gets buyRate to buy paykiks for usdt
            2. User approves usdt for paykiks recorded to buyRate
            3. User holds paykiks on Hold contract with proper deadline
            4. User creates poll
            5. User gets uint256 as a result
        */
        _sendUsdtOnGovernorBalance(2 * 1e4 * 10 ** usdtErc20.decimals());
        uint256 amountOfPaykikToBuy = 1 * 1e3 * 10 ** paykikErc20.decimals();

        // Implementation of step #1-2
        _buyPaykikErc20(alice, amountOfPaykikToBuy);

        // Implementation of step #3
        _holdPaykiks(alice, amountOfPaykikToBuy, block.timestamp + governorDao.deadlineDelta());

        uint256 pollId = _createPoll(alice, bob, amountOfUsdtForTarget);
        assertEq(pollId, 0);
        return pollId;
    }

    /*          TESTS ON METHOD {Governor::Spend}            */
    function testRevert__Spend__governorHasntEnoughUSDT() public {
        /* 
            1. Swap/InCome contract trigger Governor::Spend
            2. Governor contract revert "There is not enough USDT on Governor contract balance"
        */

        // Initialize Governor balance on USDT contract
        uint256 amountOfUsdtOnBalance = 5 * 1e3 * 10 ** usdtErc20.decimals();
        _getUsdtErc20(address(governorDao), amountOfUsdtOnBalance);

        // Raise requested usdt over existed
        uint256 amountOfRequestedUsdt = 6 * 1e3 * 10 ** usdtErc20.decimals();

        vm.expectRevert(bytes("There is not enough USDT on Governor contract balance"));
        vm.startPrank(address(swapDex));
        governorDao.Spend(alice, amountOfRequestedUsdt);
        vm.stopPrank();
    }

    function test__Spend__bool_true() public {
        /* 
            1. Swap/InCome contract trigger Governor::Spend
            2. Governor contract spent "amount" of USDT on Swap/InCome to receiver address
        */
        address receiver = vm.addr(111);
        uint256 amountOfUsdtOnBalance = 5 * 1e3 * 10 ** usdtErc20.decimals();
        _getUsdtErc20(address(governorDao), amountOfUsdtOnBalance);

        uint256 amountOfRequestedUsdt = amountOfUsdtOnBalance;

        vm.startPrank(address(swapDex));
        governorDao.Spend(receiver, amountOfRequestedUsdt);
        vm.stopPrank();

        assertEq(usdtErc20.balanceOf(receiver), amountOfRequestedUsdt);
    }

    /*          TESTS ON METHOD {Governor::getPoll}          */
    function testRevert__getPoll__voteWithProvededIdNotFound() public {
        /*
            1. User tries to get non-existed Poll
            2. User got revert with message "The entered Poll ID was not found"
         */
        uint256 pollId = 1;

        vm.expectRevert(bytes("The entered Poll ID was not found"));
        governorDao.getPoll(pollId);
    }

    function test__getPoll__uint256_address_address_uint256_uint256() public {
        /*
            1. User tries to get Poll information by "pollId"
            2. User got poll information
        */
        _sendUsdtOnGovernorBalance(2 * 1e4 * 10 ** usdtErc20.decimals());
        uint256 pollId = test__createPoll__uint256();

        (,,, uint256 deadline,,) = governorDao.getPoll(pollId);

        // Just check if deadline equal to "current timestamp + 21 days"
        assertEq(deadline, block.timestamp + governorDao.deadlineDelta());
    }

    /*          TESTS ON METHOD {Governor::submitVote}          */
    function testRevert__submitVote__pollExpired() public {
        /*
            1. User tries to submit expired vote
            2. User got revert with message "This poll has expired"
        */
        _sendUsdtOnGovernorBalance(2 * 1e4 * 10 ** usdtErc20.decimals());
        uint256 pollId = test__createPoll__uint256();

        uint256 expiringTimestamp = block.timestamp + governorDao.deadlineDelta() + 20;

        // Mock block.timestamp with expiringTimestamp
        vm.warp(expiringTimestamp);

        vm.expectRevert(bytes("This poll has expired"));
        vm.startPrank(alice);
        governorDao.submitVote(pollId);
        vm.stopPrank();
    }

    function testRevert__submitVote__youMustHoldMoreThanZeroPaykiks() public {
        /* TODO: ??? Посмотреть на этот автотест
            1. User tries to submit vote without paykiks on Paykik contract balance
            2. User got revert with message "You must have more than 0 paykiks"
        */
        _sendUsdtOnGovernorBalance(2 * 1e4 * 10 ** usdtErc20.decimals());
        uint256 pollId = test__createPoll__uint256();

        address userWithoutPaykiks = vm.addr(9871);

        vm.expectRevert("You must hold more than 0 Paykik for this function");
        vm.startPrank(userWithoutPaykiks);
        governorDao.submitVote(pollId);
        vm.stopPrank();
    }

    function test__submitVote__checkAllowance() public {
        /*
            1. User tries to approve some part of paykiks balance
            2. User tries to submits vote
            3. User got revert with message "You must approve an entire paykik balance. Your balance: <alicePaykikBalance>"
        */
        _sendUsdtOnGovernorBalance(2 * 1e4 * 10 ** usdtErc20.decimals());
        uint256 amountPaykiksOnBalance = 2 * 1e3 * 10 ** paykikErc20.decimals();
        uint256 amountPaykiksToHold = amountPaykiksOnBalance / 2;

        uint256 pollId = test__createPoll__uint256();

        // Amount paykiks which user bought != approved paykiks for hold
        _buyPaykikErc20(alice, amountPaykiksOnBalance);

        uint256 alicePaykikBalance = paykikErc20.balanceOf(alice);
        assertEq(alicePaykikBalance, amountPaykiksOnBalance);

        vm.expectRevert("Aprooved tokens is less than requested amount");
        vm.startPrank(alice);
        governorDao.submitVote(pollId);
        vm.stopPrank();
    }

    function test__submitVote__bool_true() public {
        /*
            1. User approve entire paykiks balance
            2. User tries to submit vote
            3. User got true as boolean result
        */
        _sendUsdtOnGovernorBalance(2 * 1e4 * 10 ** usdtErc20.decimals());
        uint256 amountPaykiksOnBalance = 2 * 1e3 * 10 ** paykikErc20.decimals();
        uint256 pollId = test__createPoll__uint256();

        _buyPaykikErc20(alice, amountPaykiksOnBalance);
        _approvePaykikForHold(alice, amountPaykiksOnBalance);

        vm.startPrank(alice);
        governorDao.submitVote(pollId);
        vm.stopPrank();
    }

    function testRevert__submitVote__youAlreadyVoted() public {
        /*
            1. User approve entire paykiks balance
            2. User tries to submit vote
            3. User got true as boolean result
            4. User tries to submit vote again
            5. User got revert with message "You have already submitted your vote"
        */

        // Set up initial state
        uint256 amountPaykiksOnBalance = 2 * 1e3 * 10 ** paykikErc20.decimals();
        _sendUsdtOnGovernorBalance(amountPaykiksOnBalance);

        uint256 pollId = test__createPoll__uint256();

        _buyPaykikErc20(alice, amountPaykiksOnBalance);
        _approvePaykikForHold(alice, amountPaykiksOnBalance);

        vm.startPrank(alice);
        governorDao.submitVote(pollId);
        vm.stopPrank();

        // Trying to vote again
        vm.expectRevert(bytes("You have already submitted your vote"));
        vm.startPrank(alice);
        governorDao.submitVote(pollId);
        vm.stopPrank();
    }

    /*          TESTS ON METHOD {Governor::finishPoll}          */
    function testRevert__finishPoll__pollWithProvidedIdNotFound() public {
        /*
            1. User tries to finish poll with non-existed "pollId"
            2. User got revert with message "The entered Poll ID was not found"
        */
        uint256 nonExistedPoll = 1;

        vm.expectRevert(bytes("The entered Poll ID was not found"));
        vm.startPrank(alice);
        governorDao.finishPoll(nonExistedPoll);
        vm.stopPrank();
    }

    function testRevert__finishPoll__trxAlreadySent() public {
        /**
         * 1. User tries to finish poll
         * 2. User got revert with message "The transaction was already sent"
         */
        uint256 pollId = test__createPoll__uint256();

        // Mock sent attribute of Poll
        vm.record();
        governorDao.getPoll(pollId);
        (bytes32[] memory reads,) = vm.accesses(address(governorDao));
        vm.store(address(governorDao), reads[6], bytes32(uint256(1)));

        (,,,,, bool sent) = governorDao.getPoll(pollId);

        vm.warp(99999999999);
        vm.expectRevert(bytes("The transaction was already sent"));
        governorDao.finishPoll(pollId);
    }

    function testRevert__finishPoll__contractDoesNotHasEnoughFunds() public {
        /*
            1. User tries to finish poll
            2. User got revert with message "Not enough funds on the contract balance"
        */
        uint256 pollId = test__createPoll__uint256();

        uint256 amountOfPaykiksOnGovernor = amountOfUsdtForTarget / 2;

        // Send USDT required for finishing poll divided by 2
        _getUsdtErc20(address(governorDao), amountOfPaykiksOnGovernor);

        // Mocking Governor USDT balance
        vm.mockCall(
            address(usdtErc20),
            abi.encodeWithSelector(usdtErc20.balanceOf.selector, address(governorDao)),
            abi.encode(1)
        );

        vm.warp(99999999999);
        vm.expectRevert(bytes("Not enough funds on the contract balance"));
        governorDao.finishPoll(pollId);
    }

    function testRevert__finishPoll__theShareOfParticipatingTokensCantBeLessThan50() public {
        /*  
            1. User1 with 40% paykiks of circulating creates vote to send USDT to himself
            2. User2 with 60% paykiks of circulating ignores vote
            3. User1 tries to finishPoll after 21 days
            4. User1 got revert with message "The share of tokens in this poll must be more than 50%. Current partcipation rate:<>"
        */

        // Set up initial state of Governor
        uint256 pollExecutedUsdtAmount = 1 * 1e3 * 10 ** usdtErc20.decimals();
        _sendUsdtOnGovernorBalance(10 ** usdtErc20.decimals());

        // Set up voters with 60% and 40% participationRate
        uint256 amountOfMajorPercentOfPaykiks = 6 * 1e3 * 10 ** paykikErc20.decimals();
        uint256 amountOfMinorPercentOfPaykiks = 4 * 1e3 * 10 ** paykikErc20.decimals();

        _buyPaykiks(alice, amountOfMajorPercentOfPaykiks);
        _buyPaykiks(bob, amountOfMinorPercentOfPaykiks);

        // Create poll
        uint256 pollId = _createPoll(bob, bob, pollExecutedUsdtAmount * 2);

        _submitVote(bob, pollId);

        vm.expectRevert();
        vm.startPrank(bob);
        governorDao.finishPoll(pollId);
        vm.stopPrank();
    }

    function test__finishPoll__bool_true() public {
        /**
         * 1. User1 with 40% paykiks of circulating creates vote to send USDT to himself
         * 2. User2 with 60% paykiks of circulating submits vote
         * 3. User1 tries to finishPoll after 21 days
         * 4. Poll becomes finished
         */

        // Set up initial state of Governor
        uint256 pollExecutedUsdtAmount = 1 * 1e3 * 10 ** usdtErc20.decimals();
        _sendUsdtOnGovernorBalance(10 ** usdtErc20.decimals());

        // Set up voters with 60% and 40% participationRate
        uint256 amountOfMajorPercentOfPaykiks = 6 * 1e3 * 10 ** paykikErc20.decimals();
        uint256 amountOfMinorPercentOfPaykiks = 4 * 1e3 * 10 ** paykikErc20.decimals();

        _buyPaykiks(alice, amountOfMajorPercentOfPaykiks);
        _buyPaykiks(bob, amountOfMinorPercentOfPaykiks);

        // Create poll
        uint256 pollId = _createPoll(bob, bob, pollExecutedUsdtAmount * 2);

        _submitVote(alice, pollId);

        vm.warp(99999999999);
        vm.startPrank(bob);
        governorDao.finishPoll(pollId);
        vm.stopPrank();
    }

    function testRevert__cancelVotes__youHaveNotVotedYet() public {
        /**
         * 1. User tries to cancel votes
         * 2. User got revert with message "You haven't submitted your vote yet"
         */

        // Set up initial state of Governor
        uint256 pollExecutedUsdtAmount = 1 * 1e3 * 10 ** usdtErc20.decimals();
        _sendUsdtOnGovernorBalance(10 ** usdtErc20.decimals());

        // Set up voters with 60% and 40% participationRate
        uint256 amountOfMajorPercentOfPaykiks = 6 * 1e3 * 10 ** paykikErc20.decimals();
        uint256 amountOfMinorPercentOfPaykiks = 4 * 1e3 * 10 ** paykikErc20.decimals();

        _buyPaykiks(alice, amountOfMajorPercentOfPaykiks);
        _buyPaykiks(bob, amountOfMinorPercentOfPaykiks);

        // Create poll
        uint256 pollId = _createPoll(bob, bob, pollExecutedUsdtAmount * 2);

        vm.expectRevert("You haven't submitted your vote yet");
        vm.startPrank(alice);
        bool isOk = governorDao.cancelVotes();
        vm.stopPrank();
    }

    function testRevert__cancelVotes__youDontHaveHoldToCancel() public {
        /**
         * 1. User1 creates poll
         * 2. User1 submits vote
         * 3. User1 withdraws paykiks after 21 days
         * 4. User1 tries to cancel votes
         * 5. User1 got revert with message "You don't have any tokens on hold"
         */

        // Set up initial state of Governor
        uint256 pollExecutedUsdtAmount = 1 * 1e3 * 10 ** usdtErc20.decimals();
        _sendUsdtOnGovernorBalance(10 ** usdtErc20.decimals());

        

        // Set up voters with 60% and 40% participationRate
        uint256 amountOfMajorPercentOfPaykiks = 6 * 1e3 * 10 ** paykikErc20.decimals();
        uint256 amountOfMinorPercentOfPaykiks = 4 * 1e3 * 10 ** paykikErc20.decimals();

        _buyPaykiks(alice, amountOfMajorPercentOfPaykiks);
        _buyPaykiks(bob, amountOfMinorPercentOfPaykiks);

        // Create poll
        uint256 pollId = _createPoll(bob, bob, pollExecutedUsdtAmount * 2);

        _submitVote(alice, pollId);

        vm.warp(99999999999);
        vm.startPrank(alice);
        holdContract.withdraw();
        vm.stopPrank();

        vm.expectRevert("You don't have any tokens on hold");
        vm.startPrank(alice);
        governorDao.cancelVotes();
        vm.stopPrank();
    }

    function test__cancelVotes__bool() public {
        /**
         * 1. User1 creates poll
         * 2. User1 submits vote
         * 3. User1 cancels vote
         * 4. Poll's amount zeroed
         */

        // Set up initial state of Governor
        uint256 pollExecutedUsdtAmount = 1 * 1e3 * 10 ** usdtErc20.decimals();
        _sendUsdtOnGovernorBalance(10 ** usdtErc20.decimals());

        // Set up voters with 60% and 40% participationRate
        uint256 amountOfMajorPercentOfPaykiks = 6 * 1e3 * 10 ** paykikErc20.decimals();
        uint256 amountOfMinorPercentOfPaykiks = 4 * 1e3 * 10 ** paykikErc20.decimals();

        _buyPaykiks(alice, amountOfMajorPercentOfPaykiks);
        _buyPaykiks(bob, amountOfMinorPercentOfPaykiks);

        // Create poll
        uint256 pollId = _createPoll(bob, bob, pollExecutedUsdtAmount * 2);

        _submitVote(alice, pollId);

        // Cancel votes
        vm.startPrank(alice);
        governorDao.cancelVotes();
        vm.stopPrank();

        // Hold must equal to 0
        vm.startPrank(alice);
        (, uint256 amount) = holdContract.getMe();
        vm.stopPrank();

        assertEq(amount, 0);

        // Poll.totalVoted must equal to 0
        (,,,, uint256 totalVoted,) = governorDao.getPoll(pollId);

        assertEq(totalVoted, 0);
    }

    function test__multipleCancelVotes__bool() public {
        /**
         * 1. User1 creates poll(1)
         * 2. User1 submits vote(1)
         * 3. User1 submits vote(2)
         * 4. User1 submits vote(2)
         * 5. User1 cancels vote
         * 6. Poll's amount zeroed
         */

        // Set up initial state of Governor
        uint256 pollExecutedUsdtAmount = 1 * 1e3 * 10 ** usdtErc20.decimals();
        _sendUsdtOnGovernorBalance(10 ** usdtErc20.decimals());

        // Set up voters with 60% and 40% participationRate
        uint256 amountOfMajorPercentOfPaykiks = 6 * 1e3 * 10 ** paykikErc20.decimals();
        uint256 amountOfMinorPercentOfPaykiks = 4 * 1e3 * 10 ** paykikErc20.decimals();

        _buyPaykiks(alice, amountOfMajorPercentOfPaykiks);
        _buyPaykiks(bob, amountOfMinorPercentOfPaykiks);

        // Create poll
        uint256 pollId = _createPoll(bob, bob, pollExecutedUsdtAmount * 2);
        _submitVote(alice, pollId);

        // Buy more PAYKIKS and create & submit one more poll
        _buyPaykiks(alice, amountOfMinorPercentOfPaykiks / 3);
        uint256 secondPollId = _createPoll(bob, bob, pollExecutedUsdtAmount * 2);
        _submitVote(alice, secondPollId);

        // Cancel votes
        vm.startPrank(alice);
        governorDao.cancelVotes();
        vm.stopPrank();

        // Hold must equal to 0
        vm.startPrank(alice);
        (, uint256 amount) = holdContract.getMe();
        vm.stopPrank();

        assertEq(amount, 0);

        // Poll(1).totalVoted must equal to 0
        (,,,, uint256 totalVoted,) = governorDao.getPoll(pollId);
        assertEq(totalVoted, 0);

        // Poll(2).totalVoted must equal to 0
        (,,,, uint256 secondTotalVoted,) = governorDao.getPoll(secondPollId);
        assertEq(secondTotalVoted, 0);
    }
}
