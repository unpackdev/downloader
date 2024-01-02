// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title IKycManager
 * @author River
 * @notice The interface for River's KYC Manager contract
 */
interface IKycManager {
    enum KycType {
        NON_KYC,
        US_KYC,
        GENERAL_KYC
    }

    struct User {
        KycType kycType;
        bool isBanned;
    }

    function onlyNotBanned(address investor) external view;

    function onlyKyc(address investor) external view;

    function isBanned(address investor) external view returns (bool);

    function isKyc(address investor) external view returns (bool);

    function isUSKyc(address investor) external view returns (bool);

    function isNonUSKyc(address investor) external view returns (bool);

    function isStrict() external view returns (bool);
}
