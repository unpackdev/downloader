pragma solidity 0.7.6;

interface IDeployer01 {
    function deploy(
        address poolToken,
        address uniPool,
        address setting,
        string memory tradePair,
        bool reverse,
        uint8 oracle) external returns (address, address);
}
