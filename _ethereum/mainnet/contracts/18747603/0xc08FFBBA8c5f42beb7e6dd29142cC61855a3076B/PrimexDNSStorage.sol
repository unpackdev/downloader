// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./ERC165Upgradeable.sol";

import "./IPrimexDNSStorage.sol";

abstract contract PrimexDNSStorage is IPrimexDNSStorage, ERC165Upgradeable {
    address public override registry;

    /**
     * @notice check the scheme below for additional info
     */
    uint256 public override delistingDelay;
    uint256 public override adminWithdrawalDelay;

    /* solhint-disable max-line-length */
    //                                          =========================================================
    //                                            "delistingDelay" and "adminWithdrawalDelay" explained
    //                                          =========================================================

    //                  * Lenders can’t add liquidity to Bucket.         * Keepers can close all positions opened                * Admin can withdraw all funds from the bucket to Treasury.
    //                  * New positions or orders can’t be opened          through this Bucket.                                  * Admin can withdraw to Treasury all PMX rewards granted to
    //                    in this Bucket.                                * Lenders can withdraw their funds, which became          this bucket for liquidity mining (except already withdrawn amount).
    //                  * Lenders can withdraw existing deposits,          available after all positions were closed by
    //                    traders can close existing positions.            keepers.
    //
    //                |----------------delistingDelay------------------|---------------adminWithdrawalDelay------------------|---------------------------------------------------------------
    //                |                                                |                                                     |
    //      ----------|------------------------------------------------|-----------------------------------------------------|---------------------------------------------------------------
    //                |                                        delistingDeadline                                        adminDeadline
    //      -= bucket is DEPRECATED =-                      -= bucket is DELISTED =-
    //
    //
    /* solhint-enable max-line-length */

    address public override pmx;
    address public override treasury;
    mapping(string => BucketData) public override buckets;
    mapping(string => DexData) public override dexes;
    mapping(uint256 => address) public override cmTypeToAddress;
    address public override dexAdapter;
    address public override aavePool;

    // action to token to fee amount
    mapping(OrderType => mapping(address => uint256)) public override feeRates;

    string[] internal dexesNames;
}

abstract contract PrimexDNSStorageV2 is IPrimexDNSStorageV2, PrimexDNSStorage {
    mapping(OrderType => FeeRestrictions) public override feeRestrictions;
}
