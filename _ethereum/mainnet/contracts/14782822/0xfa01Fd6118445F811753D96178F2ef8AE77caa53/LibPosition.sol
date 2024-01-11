// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.5;

import "./ClonesUpgradeable.sol";

library LibPosition {
    function predictDeterministicAddress(
        bytes32 _derivativeHash,
        bool _isLong,
        address _positionImplementationAddress,
        address _factoryAddress
    ) internal pure returns (address) {
        return _predictDeterministicAddress(_derivativeHash, _isLong, _positionImplementationAddress, _factoryAddress);
    }

    function predictAndCheckDeterministicAddress(
        bytes32 _derivativeHash,
        bool _isLong,
        address _positionImplementationAddress,
        address _factoryAddress
    ) internal view returns (address, bool) {
        address predicted = _predictDeterministicAddress(
            _derivativeHash,
            _isLong,
            _positionImplementationAddress,
            _factoryAddress
        );
        bool isDeployed = _isContract(predicted);
        return (predicted, isDeployed);
    }

    function deployOpiumPosition(
        bytes32 _derivativeHash,
        bool _isLong,
        address _positionImplementationAddress
    ) internal returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_derivativeHash, _isLong ? "L" : "S"));
        return ClonesUpgradeable.cloneDeterministic(_positionImplementationAddress, salt);
    }

    function _predictDeterministicAddress(
        bytes32 _derivativeHash,
        bool _isLong,
        address _positionImplementationAddress,
        address _factoryAddress
    ) private pure returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_derivativeHash, _isLong ? "L" : "S"));
        return ClonesUpgradeable.predictDeterministicAddress(_positionImplementationAddress, salt, _factoryAddress);
    }

    /// @notice checks whether a contract has already been deployed at a specific address
    /// @return bool true if a contract has been deployed at a specific address and false otherwise
    function _isContract(address _address) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_address)
        }
        return size > 0;
    }
}
