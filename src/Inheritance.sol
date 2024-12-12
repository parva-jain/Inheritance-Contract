// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Inheritance is ReentrancyGuard {
    address public owner;
    address public heir;
    uint256 public lastWithdrawalTime;

    constructor(address _heir) {
        require(_heir != address(0), "Invalid heir address");
        owner = msg.sender;
        heir = _heir;
        lastWithdrawalTime = block.timestamp;
    }

    function withdraw(uint256 amount, address newHeir) external nonReentrant {
        require(address(this).balance >= amount, "Insufficient balance");
        if (msg.sender == owner) {
            if (amount == 0) {
                lastWithdrawalTime = block.timestamp;
                return;
            }
            (bool success,) = payable(owner).call{value: amount}("");
            require(success, "Failed to send Ether");
            lastWithdrawalTime = block.timestamp;
        } else {
            require(msg.sender == heir && block.timestamp > (lastWithdrawalTime + 30 days), "Only heir can withdraw after 30 days");
            require(newHeir != address(0), "Invalid new heir address");
            (bool success,) = payable(heir).call{value: amount}("");
            require(success, "Failed to send Ether");
            owner = heir;
            heir = newHeir;
            lastWithdrawalTime = block.timestamp;
        }
    }


    receive() external payable {}

}
