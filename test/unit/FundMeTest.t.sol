// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user"); // makeaddr cheatcode
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether; // fake money using for starting the balance of USER
    uint256 constant GAS_PRICE = 1; // allows to set a value for our txGasPrice

    // with a value not 0, Otherwise the test of the function testFundUpdatesFundedDataStructure will be failed and reverted

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testminimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        //cheatCode
        vm.expectRevert(); // hey, the next line should revert
        //asser(this tx fails/reverts)
        fundMe.fund(); // fund() without value (0) / less than MINIMUM_USD
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // the nest tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArraysOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0); // 0 because we have only one funder (User) so far
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER); //USER can funded  // wa can use this two lines duplicated if
        fundMe.fund{value: SEND_VALUE}(); // with some money // we want to do test onlyOwner can withdraw after a number of withraw
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        // testing onlyOwner if working good
        vm.expectRevert(); // hey, the next line should revert
        vm.prank(USER); // USER try with even if not the owner (for test)
        fundMe.withdraw(); // test withdraw by USER
    }

    function testWithdrawWithASingleFunder() public funded {
        // // test withdrawing with the actual owner
        // arrange the test
        uint256 startingWonerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // act
        vm.prank(fundMe.getOwner()); // e,g gas cost: 200
        fundMe.withdraw();

        // assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingWonerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // create fake addresses for the test
        // Arrange setup
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // we cant start with (0) because its revert when we send SEND_VALUE
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // address()
            hoax(address(i), SEND_VALUE); // cheatcode for withraw from addresses that have ether
            // fund the fundMe
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingWonerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheapeWithdraw(); // anything between these pranks is going to be sent pretended-
        vm.stopPrank(); // to be by this address here (fundMe.getOwner())

        // assert
        assert(address(fundMe).balance == 0);
        assert(
            startingWonerBalance + startingFundMeBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // create fake addresses for the test
        // Arrange setup
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // we cant start with (0) because its revert when we send SEND_VALUE
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // address()
            hoax(address(i), SEND_VALUE); // cheatcode for withraw from addresses that have ether
            // fund the fundMe
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingWonerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw(); // anything between these pranks is going to be sent pretended-
        vm.stopPrank(); // to be by this address here (fundMe.getOwner())

        // assert
        assert(address(fundMe).balance == 0);
        assert(
            startingWonerBalance + startingFundMeBalance ==
                fundMe.getOwner().balance
        );
    }
}
