// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";

contract Shop {
    address payable public owner;
    address public tokenAddress;

    event EthOrderPayment(string orderId, uint amount);
    event TokenOrderPayment(string orderId, uint amount);

    mapping(string => uint) private ethPayments;
    mapping(string => uint) private tokenPayments;

    constructor(address _tokenAddress, address _owner) {
        owner = payable(_owner);
        tokenAddress = _tokenAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    function payWithEth(string memory orderID) public payable {
        require(msg.value > 0, "Must send some ether");
        ethPayments[orderID] += msg.value;
        emit EthOrderPayment(orderID, ethPayments[orderID]);
    }

    function payWithToken(string memory orderID, uint256 amount) public {
        require(amount > 0, "Must send some tokens");
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        tokenPayments[orderID] += amount;
        emit TokenOrderPayment(orderID, tokenPayments[orderID]);
    }

    function withdrawEther() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // Function to withdraw ERC-20 tokens from the contract (only owner)
    function withdrawTokens() public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");   
        require(
            token.transfer(owner, balance),
            "Token transfer failed"
        );
    }

    function getTokenPayments(string memory orderID) public view returns (uint) {
        return tokenPayments[orderID];
    }

    function getEthPayments(string memory orderID) public view returns (uint) {
        return ethPayments[orderID];
    } 

    function updateTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function updateOwner(address _owner) public onlyOwner {
        owner = payable(_owner);
    }
}
