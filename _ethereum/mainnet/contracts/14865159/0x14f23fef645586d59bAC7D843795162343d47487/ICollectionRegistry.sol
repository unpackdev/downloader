pragma solidity 0.8.12;
interface ICollectionRegistry {
    function isJumyCollection(address collection) external view returns (bool);
}
