// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// solhint-disable

import "./ECDSA.sol";

function _isWhale(
    address _whale,
    bytes calldata _signature,
    address _signer
) pure returns (bool) {
    return _recover(_getWitness(true, _whale), _signature) == _signer;
}

function _requireWhale(bytes calldata _signature, address _signer) view {
    require(
        _isWhale(msg.sender, _signature, _signer),
        "Not whitelisted or wrong whale/dolphin type"
    );
}

function _isDolphin(
    address _dolphin,
    bytes calldata _signature,
    address _signer
) pure returns (bool) {
    return _recover(_getWitness(false, _dolphin), _signature) == _signer;
}

function _requireDolphin(bytes calldata _signature, address _signer) view {
    require(
        _isDolphin(msg.sender, _signature, _signer),
        "Not whitelisted or wrong whale/dolphin type"
    );
}

function _recover(bytes32 _hash, bytes calldata _signature)
    pure
    returns (address)
{
    return ECDSA.recover(_hash, _signature);
}

function _getWitness(bool _whale, address _user) pure returns (bytes32) {
    return
        ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(_whale, _user))
        );
}
