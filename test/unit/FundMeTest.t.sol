// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 STARTING_BALANCE = 10 ether; // are declared in the scope of the contract
    uint256 SEND_VALUE = 1 ether;

    function setUp() external {
        //fundMe = new FundMe();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // declered in the setUp() contract
    }

    function testMinimumDollarisFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // the next line should revert
        fundMe.fund(); // send 0 value
    }

    function testFundUpdatesFundedStruct() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER); // the next tx will be send by USER
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyTheOwnerCanWithdraw() public funded {
        vm.prank(USER); // because USER is not the owner of fundMe
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //assert
        uint256 endingOwnerBalnace = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalnace, startingOwnerBalance + startingFundMeBalance);
    }

    function testWithdrwaFromMulitFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startFunderIndex = 1;

        for (uint160 i = startFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalnace = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        assert(address(fundMe).balance == 0);
        assert(startingOwnerBalance + startingFundMeBalnace == fundMe.getOwner().balance);
    }
}
