/*
Very braindead token lock contract
created by @bantony21
*/

pragma solidity ^0.6.0; 

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenLock {
    
    IERC20 token = IERC20(0xd0Df3b1Cf729A29B7404c40D61C750008E631bA7);
    address beneficiary = 0xee96CAA78Bd77aC82562A2f65479440988B95DCa;
    uint256 releaseTime;

    constructor() public {
        releaseTime = block.timestamp + 16 days;
    }

    function tokenBal() public view returns(uint256) {
        return token.balanceOf(beneficiary);
    }

    function release() public returns(uint256) {
        require(block.timestamp > releaseTime);
        token.transfer(beneficiary, token.balanceOf(address(this)));
    }

}