pragma solidity 0.6.6;

interface IAToken {
    function balanceOf(address _user) external view returns(uint256);
}
