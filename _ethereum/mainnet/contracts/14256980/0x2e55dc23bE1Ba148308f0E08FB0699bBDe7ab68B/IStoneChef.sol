pragma solidity ^0.6.12;

interface IStoneChef {
    function calcPrice(uint _Id) external view returns (uint256);
    function maxId() external view returns (uint256);
}
