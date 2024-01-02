// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;
import "./IKycManager.sol";

// KYC Specific Storage
contract RiverKYCStorage {
    /**
     * @dev Event for when the KYC manager reference is set
     *
     * @param oldManager The old manager
     * @param newManager The new manager
     */
    event SetKYCManager(address oldManager, address newManager);

    /**
     * @notice Pointer to kycManager
     */
    IKycManager public kycManager;
}
