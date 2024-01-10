pragma solidity ^0.6.0;

interface IRegistry {
    function getVaultsInfo()
        external
        view
        returns (
            address[] memory vaultsAddresses,
            address[] memory controllerArray,
            address[] memory tokenArray,
            address[] memory strategyArray,
            bool[] memory isWrappedArray,
            bool[] memory isDelegatedArray
        );
}
