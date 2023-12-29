// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract TokenWithdraw {
    address public tokenAddress;
    address public owner;
    uint public fee;
    uint public totalWithdraw;
    uint256 _decimals;
    uint256 _amount;

    event Withdraw(address withdrawUser, uint amount);
    event Deposit(address depositUser, uint amount);

    constructor(address _tokenAddress, uint _fee) {
        tokenAddress = _tokenAddress;
        owner = msg.sender;
        fee = _fee;
    }

    function withdraw(uint amount) external payable {

        _decimals = 10 ** 18;
        _amount = amount * _decimals;
        
        require(msg.value == amount * fee, "Incorrect ETH amount");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= _amount, "Not enough tokens available");

        bool checkapproval = IERC20(tokenAddress).approve(address(this), _amount);
        require(checkapproval, "Not approved this contract");

        bool success = IERC20(tokenAddress).transferFrom(address(this), msg.sender, _amount);
        require(success, "Token transfer failed");

        totalWithdraw += amount;
        emit Withdraw(msg.sender, amount);
    }

    function setFee(uint256 _fee) external {
        require(msg.sender == owner, "Only owner can change Fee");
        fee = _fee;
    }

    function totalDeposit() public view returns(uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function feeCollect() external {
        require(msg.sender == owner, "Only owner can collect ETH");
        payable(owner).transfer(address(this).balance);
    }

    function tokenCollect() external {
        require(msg.sender == owner, "Only owner can collect Token");

        bool checkapproval = IERC20(tokenAddress).approve(address(this), IERC20(tokenAddress).balanceOf(address(this)));
        require(checkapproval, "Not approved this contract");

        IERC20(tokenAddress).transferFrom(address(this), owner, IERC20(tokenAddress).balanceOf(address(this)));
    }

}