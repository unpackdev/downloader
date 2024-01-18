pragma solidity 0.8.10;

interface ERC20Interface {
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) view external returns (uint256 balance);
}