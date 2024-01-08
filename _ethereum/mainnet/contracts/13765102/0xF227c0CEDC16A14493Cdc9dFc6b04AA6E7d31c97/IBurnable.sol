pragma solidity ^0.8.4;

interface IBurnable {
    function balanceOf(address account, uint256 id) external returns (uint256) ;
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
    function burnBatch(
        address account, 
        uint256[] memory ids, 
        uint256[] memory amounts
    ) external;
}