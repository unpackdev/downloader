// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";

contract Router {
	event Stake(uint256 value);
	event Unstake(uint256 value);

	address public owner;
	address public trading;
	address public oracle;
	address public merkleTree;
	address public airdrop;
	address public backup;

	address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	mapping(address => uint256) public balanceOf;

	constructor() {
		owner = msg.sender;
	}

	function updateOwner(address _owner) public onlyOwner {
		owner = _owner;
	}

	function updateTrading(address _trading) public onlyOwner {
		trading = _trading;
	}

	function updateOracle(address _oracle) public onlyOwner {
		oracle = _oracle;
	}

	function updateMerkleTree(address _merkleTree) public onlyOwner {
		merkleTree = _merkleTree;
	}

	function updateAirdrop(address _airdrop) public onlyOwner {
		airdrop = _airdrop;
	}

	function updateBackup(address _backup) public onlyOwner {
		backup = _backup;
	}

	function stake(uint256 amount) public {
		IERC20(WETH).transferFrom(msg.sender, address(this), amount);
		balanceOf[msg.sender] += amount;
		emit Stake(amount);
	}

	function unstake() public {
		uint256 balanceSnapshot = balanceOf[msg.sender];
		balanceOf[msg.sender] = 0;
		IERC20(WETH).transfer(msg.sender, balanceSnapshot);
		emit Unstake(balanceSnapshot);
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "!owner");
		_;
	}

}