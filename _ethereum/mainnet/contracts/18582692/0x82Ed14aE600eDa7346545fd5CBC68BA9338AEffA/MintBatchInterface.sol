pragma solidity ^0.8.7;

interface MintBatchInterface {
    function mintBatch(address to, uint256[] memory ids) external;
}
