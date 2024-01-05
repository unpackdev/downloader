pragma solidity ^0.8.0;

interface CollectionManager {
    function tokenURI(uint256) external view returns (string memory);
}
