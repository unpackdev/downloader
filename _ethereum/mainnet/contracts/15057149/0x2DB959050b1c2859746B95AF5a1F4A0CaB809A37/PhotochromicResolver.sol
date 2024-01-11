// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ENS.sol";
import "./Strings.sol";

import "./PhotochromicRegistrar.sol";
import "./Resolver.sol";


struct ValidatedTextRecord {
    string key;
    string value;
    uint32 timestamp;
    EcdsaSig sig;
}

struct ValidatedAddrRecord {
    uint coinType;
    bytes value;
    uint32 timestamp;
    EcdsaSig sig;
}

contract PhotochromicResolver is Resolver {

    address private signerAddress;
    mapping(string => mapping(string => bytes32)) reverseRecords;

    constructor(
        ENS _ens,
        PhotochromicRegistrar _registrar,
        address _signerAddress
    ) ResolverValidated(_ens, _registrar) {
        signerAddress = _signerAddress;
    }

    function setPCRecords(
        bytes32 node,
        string memory userId,
        string[DATA_FIELDS] calldata contents,
        address sender,
        string memory profile
    ) external onlyOwner {
        photochromicTexts[node] = Validator.packPhotochromicRecord(
            userId, profile,
            Validator.packKYCData(contents),
            uint32(block.timestamp)
        );

        // Preserve original ENS resolver
        address oldResolver = ens.resolver(node);
        if (oldResolver != address(this)) resolvers[node] = oldResolver;

        // KYC data can be empty.
        if (bytes(contents[0]).length != 0) {
            emit TextChanged(node, Validator.PC_FIRSTNAME, Validator.PC_FIRSTNAME);
        }
        if (bytes(contents[1]).length != 0) {
            emit TextChanged(node, Validator.PC_LASTNAME, Validator.PC_LASTNAME);
        }
        if (bytes(contents[2]).length != 0) {
            emit TextChanged(node, Validator.PC_EMAIL, Validator.PC_EMAIL);
        }
        if (bytes(contents[3]).length != 0) {
            emit TextChanged(node, Validator.PC_BIRTHDATE, Validator.PC_BIRTHDATE);
        }
        if (bytes(contents[4]).length != 0) {
            emit TextChanged(node, Validator.PC_NATIONALITY, Validator.PC_NATIONALITY);
        }

        emit TextChanged(node, Validator.PC_USERID, Validator.PC_USERID);
        emit TextChanged(node, Validator.PC_PROFILE, Validator.PC_PROFILE);

        emit TextChanged(node, Validator.PC_USERID, Validator.PC_USERID);
        emit TextChanged(node, Validator.PC_PROFILE, Validator.PC_PROFILE);

        _addresses[node][60] = Validator.concatTimestamp(addressToBytes(sender), uint32(block.timestamp));
        emit TextChanged(node, "avatar", "avatar");
    }

    function clearPCRecords(bytes32 node) external onlyOwner {
        delete photochromicTexts[node];
        setAddr(node, 60, addressToBytes(address(0))); // COIN_TYPE_ETH
    }

    function setValidatedRecords(
        bytes32 node,
        ValidatedTextRecord[] calldata textRecords,
        ValidatedAddrRecord[] calldata addressRecords
    ) external authorised(node) {
        _setValidatedTextRecords(node, textRecords);
        _setValidatedAddrRecords(node, addressRecords);
    }

    function setValidatedTextRecords(bytes32 node, ValidatedTextRecord[] calldata list) external authorised(node) {
        _setValidatedTextRecords(node, list);
    }

    function _setValidatedTextRecords(bytes32 node, ValidatedTextRecord[] calldata list) internal {
        address holder = ens.owner(node);
        for (uint i = 0; i < list.length; i++) {
            bytes32 h = keccak256(abi.encode(holder, list[i].key, list[i].value, list[i].timestamp));
            address signer = ecrecover(h, list[i].sig.v, list[i].sig.r, list[i].sig.s);
            uint32 t = signer == signerAddress ? list[i].timestamp : 1; // 1 == invalid
            texts[node][list[i].key] = string(Validator.concatTimestamp(bytes(list[i].value), t));
            reverseRecords[list[i].key][list[i].value] = node;
        }
    }

    function setValidatedAddrRecords(bytes32 node, ValidatedAddrRecord[] calldata list) external authorised(node) {
        _setValidatedAddrRecords(node, list);
    }

    function _setValidatedAddrRecords(bytes32 node, ValidatedAddrRecord[] calldata list) internal {
        address holder = ens.owner(node);
        for (uint i = 0; i < list.length; i++) {
            bytes32 h = keccak256(abi.encode(holder, list[i].coinType, list[i].value, list[i].timestamp));
            address signer = ecrecover(h, list[i].sig.v, list[i].sig.r, list[i].sig.s);
            uint32 t = signer == signerAddress ? list[i].timestamp : 1; // 1 == invalid
            _addresses[node][list[i].coinType] = Validator.concatTimestamp(bytes(list[i].value), t);
        }
    }

    function lookup(string calldata key, string calldata value) external view returns (bytes32) {
        return reverseRecords[key][value];
    }

    function setValidityInfo(
        bytes32 node,
        uint32 expiryTime,
        uint32 livenessTime
    ) public onlyOwner {
        texts[node][Validator.KYC_VALIDITYINFO] = Validator.packValidityInfo(livenessTime, expiryTime);
    }

    function deleteValidityInfo(bytes32 node) external onlyOwner {
        delete texts[node][Validator.KYC_VALIDITYINFO];
    }

    function getValidityInfo(bytes32 node) public view returns (uint32, uint32) {
        string memory record = texts[node][Validator.KYC_VALIDITYINFO];
        return Validator.getValidityInfo(bytes(record));
    }

    function updateLiveness(
        bytes32 node,
        uint32 livenessTime
    ) external onlyOwner {
        (, uint32 expiryTime) = getValidityInfo(node);
        setValidityInfo(node, expiryTime, livenessTime);
    }

    function updateExpiry(
        bytes32 node,
        // The duration for which you want to renew (in seconds).
        // e.g. 86400 is a day.
        uint32 duration
    ) external onlyOwner {
        (uint32 livenessTime, uint32 expiryTime) = getValidityInfo(node);
        setValidityInfo(node, expiryTime + duration, livenessTime);
    }

    /**
     * Returns whether the given node (i.e. identity/domain/...) is still valid.
     * A node is valid if and only if:
     *  1. The node is still owned by the address used during the onboarding.
     *  2. The address record is not been overwritten.
     */
    function isValidNode(bytes32 node) external view returns (bool) {
        (ValidationStatus status, bytes memory a, ) = validatedAddr(node, 60);
        return status == ValidationStatus.VALIDATED && ens.owner(node) == bytesToAddress(a);
    }
}
