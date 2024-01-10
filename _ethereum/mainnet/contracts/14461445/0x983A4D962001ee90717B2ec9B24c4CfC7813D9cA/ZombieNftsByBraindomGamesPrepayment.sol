// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract ZombieNftsByBraindomGamesPrepayment is ReentrancyGuard {
    using SafeMath for uint256;

    address public owner = msg.sender;
    mapping(address => uint) public _balance;
    mapping(address => bool) _allowList;
    uint256 public minEthAmount = 0.03 ether;
    bool public isSendStarted;

    function balanceOf(address _address) external view returns (uint) {
        return _balance[_address];
    }

    function sendETH() external payable onlyAllowList callerIsUser() whenSaleStarted() {
        require(msg.value >= minEthAmount, "Message value less than minimum amount of ethereum");
        _balance[msg.sender] += msg.value;
    }

    function withdraw() external onlyOwner nonReentrant callerIsUser() {
        (bool isTransfered, ) = msg.sender.call{value: address(this).balance}("");
        require(isTransfered, "Transfer failed");
    }

    function addToAllowList(address[] calldata allowList) external onlyOwner {
        for(uint256 i = 0; i < allowList.length; i++)
            _allowList[allowList[i]] = true;
    }

    function removeFromAllowList(address _address) external onlyOwner {
        _allowList[_address] = false;
    }

    function toggleStart() external onlyOwner {
        isSendStarted = !isSendStarted;
    }

    function isAllowedToSend() public view returns(bool) {
        return _allowList[msg.sender] == true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Message sender is not the owner");
        _;
    }
    modifier whenSaleStarted() {
        require(isSendStarted == true, "Sending not started");
        _;
    }
    modifier onlyAllowList() {
        require(_allowList[msg.sender] == true, "Message sender is not allowed");
        _;
    }
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}