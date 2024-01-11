pragma solidity 0.7.6;

interface IDeployer02 {
    function deploy(
        address owner,
        address poolToken,
        address setting,
        string memory tradePair) external returns (address);
}