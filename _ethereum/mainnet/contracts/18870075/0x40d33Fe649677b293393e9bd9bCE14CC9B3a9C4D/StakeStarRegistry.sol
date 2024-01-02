// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./PoRAddressList.sol";
import "./Utils.sol";

contract StakeStarRegistry is
    Initializable,
    AccessControlUpgradeable,
    PoRAddressList
{
    enum ValidatorStatus {
        MISSING,
        PENDING,
        ACTIVE,
        EXITING,
        EXITED
    }

    event AddOperatorToAllowList(uint64 operatorId);
    event RemoveOperatorFromAllowList(uint64 operatorId);
    event ValidatorStatusChange(
        bytes publicKey,
        ValidatorStatus statusFrom,
        ValidatorStatus statusTo
    );

    mapping(uint64 => bool) public allowListOfOperators;
    mapping(bytes => ValidatorStatus) public validatorStatuses;
    bytes[] public validatorPublicKeys;

    function initialize() public initializer {
        _setupRole(Utils.DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addOperatorToAllowList(
        uint64 operatorId
    ) public onlyRole(Utils.DEFAULT_ADMIN_ROLE) {
        require(!allowListOfOperators[operatorId], "operator already added");
        allowListOfOperators[operatorId] = true;
        emit AddOperatorToAllowList(operatorId);
    }

    function removeOperatorFromAllowList(
        uint64 operatorId
    ) public onlyRole(Utils.DEFAULT_ADMIN_ROLE) {
        require(allowListOfOperators[operatorId], "operator not added");
        delete allowListOfOperators[operatorId];
        emit RemoveOperatorFromAllowList(operatorId);
    }

    function initiateActivatingValidator(
        bytes memory publicKey
    ) public onlyRole(Utils.STAKE_STAR_ROLE) {
        require(
            validatorStatuses[publicKey] == ValidatorStatus.MISSING,
            "validator status not MISSING"
        );
        validatorStatuses[publicKey] = ValidatorStatus.PENDING;
        validatorPublicKeys.push(publicKey);
        emit ValidatorStatusChange(
            publicKey,
            ValidatorStatus.MISSING,
            ValidatorStatus.PENDING
        );
    }

    function confirmActivatingValidator(
        bytes memory publicKey
    ) public onlyRole(Utils.MANAGER_ROLE) {
        require(
            validatorStatuses[publicKey] == ValidatorStatus.PENDING,
            "validator status not PENDING"
        );
        validatorStatuses[publicKey] = ValidatorStatus.ACTIVE;
        emit ValidatorStatusChange(
            publicKey,
            ValidatorStatus.PENDING,
            ValidatorStatus.ACTIVE
        );
    }

    function initiateExitingValidator(
        bytes memory publicKey
    ) public onlyRole(Utils.MANAGER_ROLE) {
        require(
            validatorStatuses[publicKey] == ValidatorStatus.ACTIVE,
            "validator status not ACTIVE"
        );
        validatorStatuses[publicKey] = ValidatorStatus.EXITING;
        emit ValidatorStatusChange(
            publicKey,
            ValidatorStatus.ACTIVE,
            ValidatorStatus.EXITING
        );
    }

    function confirmExitingValidator(
        bytes memory publicKey
    ) public onlyRole(Utils.STAKE_STAR_ROLE) {
        require(
            validatorStatuses[publicKey] == ValidatorStatus.EXITING,
            "validator status not EXITING"
        );
        validatorStatuses[publicKey] = ValidatorStatus.EXITED;
        emit ValidatorStatusChange(
            publicKey,
            ValidatorStatus.EXITING,
            ValidatorStatus.EXITED
        );
    }

    function verifyOperators(
        uint64[] memory operatorIds
    ) public view returns (bool) {
        for (uint8 i = 0; i < operatorIds.length; i++) {
            if (!allowListOfOperators[operatorIds[i]]) return false;
        }

        return true;
    }

    function getValidatorPublicKeysLength() public view returns (uint256) {
        return validatorPublicKeys.length;
    }

    function getValidatorPublicKeys(
        ValidatorStatus status
    ) public view returns (bytes[] memory publicKeys) {
        publicKeys = new bytes[](countValidatorPublicKeys(status));

        uint256 index = 0;
        for (uint256 i = 0; i < validatorPublicKeys.length; i++) {
            bytes memory publicKey = validatorPublicKeys[i];
            if (validatorStatuses[publicKey] == status) {
                publicKeys[index++] = publicKey;
            }
        }
    }

    function getValidatorPublicKeys(
        uint32 offset,
        uint32 count
    ) public view returns (bytes[] memory publicKeys) {
        publicKeys = new bytes[](count);

        for (
            uint32 i = 0;
            i < count && i + offset < validatorPublicKeys.length;
            i++
        ) {
            publicKeys[i] = validatorPublicKeys[i + offset];
        }
    }

    function countValidatorPublicKeys(
        ValidatorStatus status
    ) public view returns (uint256 count) {
        count = 0;

        for (uint256 i = 0; i < validatorPublicKeys.length; i++) {
            if (status == validatorStatuses[validatorPublicKeys[i]]) {
                count++;
            }
        }
    }

    function getPoRAddressListLength() public view returns (uint256) {
        return countValidatorPublicKeys(ValidatorStatus.ACTIVE);
    }

    function getPoRAddressList(
        uint256 startIndex,
        uint256 endIndex
    ) public view returns (string[] memory) {
        uint256 length = getPoRAddressListLength();
        if (length == 0) {
            return new string[](0);
        }

        uint256 normalizedEndIndex = endIndex < length - 1
            ? endIndex
            : length - 1;
        if (startIndex > normalizedEndIndex) {
            return new string[](0);
        }

        string[] memory addressList = new string[](
            normalizedEndIndex - startIndex + 1
        );
        bytes[] memory publicKeys = getValidatorPublicKeys(
            ValidatorStatus.ACTIVE
        );
        uint256 relativeIndex = 0;
        uint256 returnIndex = 0;

        for (uint256 i = 0; i < publicKeys.length; i++) {
            bytes memory publicKey = publicKeys[i];
            if (publicKey.length > 0) {
                if (relativeIndex >= startIndex && relativeIndex <= endIndex) {
                    addressList[returnIndex] = toString(publicKey);
                    returnIndex++;
                }
                relativeIndex++;
            }
        }

        return addressList;
    }

    function toString(bytes memory data) private pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}
