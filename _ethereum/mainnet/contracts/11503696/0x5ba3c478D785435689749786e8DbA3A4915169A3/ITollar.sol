pragma solidity 0.7.5;

interface ITollar {
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    function rebase(int256 supplyDelta) external returns (uint256);
    function totalSupply() external returns (uint256);
    function balanceOf(address who) external returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner_, address spender) external returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    
    function transferOwnership(address newOwner) external;
    function addTransaction(address destination, bytes memory data) external;
    function removeTransaction(uint index) external;
}
