// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ExampleExternalContract.sol";

contract Staker {
	ExampleExternalContract public exampleExternalContract;
	mapping(address => uint256) public balances;
	uint256 public constant threshold = 1 ether;
	uint256 public deadline = block.timestamp + 72 hours;
	bool public openForWithdraw = false;

	event Stake(address indexed user, uint256 amount);

	constructor(address exampleExternalContractAddress) {
		exampleExternalContract = ExampleExternalContract(
			exampleExternalContractAddress
		);
	}

	// stake() function
	function stake() public payable {
		require(block.timestamp < deadline, "Staking period has ended");
		balances[msg.sender] += msg.value;
		emit Stake(msg.sender, msg.value);
	}

	// execute() function
	function execute() public {
		require(block.timestamp >= deadline, "Deadline not reached");
		require(!exampleExternalContract.completed(), "Already completed");

		if (address(this).balance >= threshold) {
			exampleExternalContract.complete{ value: address(this).balance }();
		} else {
			openForWithdraw = true;
		}
	}

	// withdraw() function
	function withdraw() public {
		require(openForWithdraw, "Withdrawals not allowed");
		require(balances[msg.sender] > 0, "No balance to withdraw");

		uint256 amount = balances[msg.sender];
		balances[msg.sender] = 0;
		(bool success, ) = msg.sender.call{ value: amount }("");
		require(success, "Withdrawal failed");
	}

	// timeLeft() view function
	function timeLeft() public view returns (uint256) {
		if (block.timestamp >= deadline) {
			return 0;
		} else {
			return deadline - block.timestamp;
		}
	}

	// receive() function
	receive() external payable {
		stake();
	}
}
