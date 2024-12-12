// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Inheritance} from "../src/Inheritance.sol";

contract InheritanceTest is Test {
    Inheritance public inheritance;
    address public owner;
    address public heir;
    address public newHeir;
    uint256 public constant THIRTY_DAYS = 30 days;

    function setUp() public {
        owner = makeAddr("owner");
        heir = makeAddr("heir");
        newHeir = makeAddr("newHeir");

        vm.deal(owner, 10 ether);
        vm.deal(heir, 10 ether);
        vm.deal(newHeir, 10 ether);
        
        vm.prank(owner);
        inheritance = new Inheritance(heir);

        vm.prank(owner);
        (bool success, ) = address(inheritance).call{value: 1 ether}("");
        require(success, "Transfer failed");
        
    }

    function test_Deployment() public view {
        assertEq(inheritance.owner(), owner);
        assertEq(inheritance.heir(), heir);
        assertEq(inheritance.lastWithdrawalTime(), block.timestamp);
    }

    function test_OwnerWithdraw() public {
        uint256 amount = 1 ether;

        uint256 initialOwnerBalance = owner.balance;

        vm.prank(owner);
        inheritance.withdraw(amount, address(0));

        assertEq(owner.balance, initialOwnerBalance + amount);
        assertEq(address(inheritance).balance, 0);
        assertEq(inheritance.lastWithdrawalTime(), block.timestamp);
    }

    function test_OwnerResetLastWithdrawalTime() public {
        vm.prank(owner);
        inheritance.withdraw(0, address(0));
        
        assertEq(inheritance.lastWithdrawalTime(), block.timestamp);
    }

    function test_RevertIf_InsufficientBalance() public {
        vm.prank(owner);
        vm.expectRevert("Insufficient balance");
        inheritance.withdraw(2 ether, address(0));
    }

    function test_HeirWithdraw() public {
        uint256 withdrawAmount = 1 ether;
        uint256 initialHeirBalance = heir.balance;

        // After 30 days
        vm.warp(block.timestamp + THIRTY_DAYS + 1);

        vm.prank(heir);
        inheritance.withdraw(withdrawAmount, newHeir);

        assertEq(heir.balance, initialHeirBalance + withdrawAmount);
        assertEq(address(inheritance).balance, 0);
        assertEq(inheritance.owner(), heir);
        assertEq(inheritance.heir(), newHeir);
        assertEq(inheritance.lastWithdrawalTime(), block.timestamp);
    }

    function test_RevertIf_HeirWithdrawsTooEarly() public {
        vm.prank(heir);
        vm.expectRevert("Only heir can withdraw after 30 days");
        inheritance.withdraw(1 ether, newHeir);
    }

    function test_RevertIf_HeirSetsZeroAddress() public {
        vm.warp(block.timestamp + THIRTY_DAYS + 1);
        
        vm.prank(heir);
        vm.expectRevert("Invalid new heir address");
        inheritance.withdraw(1 ether, address(0));
    }

    function test_RevertIf_UnauthorizedWithdraw() public {
        address unauthorized = makeAddr("unauthorized");
        
        vm.prank(unauthorized);
        vm.expectRevert("Only heir can withdraw after 30 days");
        inheritance.withdraw(1 ether, newHeir);
    }

function test_MultipleWithdrawIterations() public {
    uint256 withdrawAmount = 1 ether;
    uint256 initialHeirBalance = heir.balance;

    // After 30 days
    vm.warp(block.timestamp + THIRTY_DAYS + 1);

    // Heir withdraws
    vm.prank(heir);
    inheritance.withdraw(withdrawAmount, newHeir);

    assertEq(heir.balance, initialHeirBalance + withdrawAmount);
    assertEq(address(inheritance).balance, 0);
    assertEq(inheritance.owner(), heir);
    assertEq(inheritance.heir(), newHeir);
    assertEq(inheritance.lastWithdrawalTime(), block.timestamp);

    // After another 30 days
    vm.warp(block.timestamp + THIRTY_DAYS + 1);

    // eth deposit
    vm.prank(heir);
    (bool success, ) = address(inheritance).call{value: 1 ether}("");
    require(success, "Transfer failed");

    // New heir withdraws
    uint256 newHeirInitialBalance = newHeir.balance;
    vm.prank(newHeir);
    inheritance.withdraw(withdrawAmount, owner); 

    assertEq(newHeir.balance, newHeirInitialBalance + withdrawAmount);
    assertEq(address(inheritance).balance, 0);
    assertEq(inheritance.owner(), newHeir);
    assertEq(inheritance.heir(), owner); 
    assertEq(inheritance.lastWithdrawalTime(), block.timestamp);
}

}
