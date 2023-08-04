// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import { Test, console } from "forge-std/Test.sol";
import { FundMe } from "../../src/FundMe.sol";
import { DeployFundMe } from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint constant SEND_VALUE = 0.1 ether;
    uint constant STARTING_BALANCE = 100 ether;
    uint constant GAS_PRICE = 1;

    function setUp() external {
        (fundMe, ) = (new DeployFundMe()).run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testDemo() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint version = fundMe.getVersion();
        console.log(version);
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund{ value: 1e15 }();
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{ value: SEND_VALUE }();
        _ ;
    }

    function testFundsGotReflected() public funded {
        uint funds = fundMe.getAmountFundedBy(USER);
        assertEq(funds, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        uint startingOwnerBalance = fundMe.i_owner().balance;
        uint startingFundMeBalance = address(fundMe).balance;

        uint gasStart = gasleft();

        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.i_owner());
        fundMe.withdraw();

        uint gasEnd = gasleft();
        uint gasUsed = (gasStart - gasEnd) * tx.gasprice;

        uint endingOwnerBalance = fundMe.i_owner().balance;
        uint endingFundMeBalance = address(fundMe).balance;

        console.log(gasUsed); // 10667
        console.log(endingOwnerBalance - startingOwnerBalance - startingFundMeBalance); // 0

        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
    }

    function testWithdrawWithMultipleFunders() public funded {
        uint160 noOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for( uint160 index = startingFunderIndex; index < noOfFunders; index++ ) {
            hoax(address(index), STARTING_BALANCE);
            fundMe.fund{ value: SEND_VALUE }();
        }

        uint startingOwnerBalance = fundMe.i_owner().balance;
        uint startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.i_owner());
        fundMe.withdraw();
        vm.stopPrank();

        uint endingOwnerBalance = fundMe.i_owner().balance;
        uint endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
    }
}