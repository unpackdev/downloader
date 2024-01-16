pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import "./StakeHouseRegistry.sol";
import "./savETHRegistry.sol";
import "./SlotSettlementRegistry.sol";

/// @title The main module allowing the universe to mint tokens for a new KNOT
abstract contract Banking {

    /// @notice Member added to a given Stakehouse and derivative shares minted
    event MemberAddedAndSharesIssued(address indexed stakeHouse, bytes memberId, address indexed applicant);

    /// @notice Address of SLOT minting and management contract
    SlotSettlementRegistry public slotRegistry;

    /// @notice Address of dETH minting and management contract
    savETHRegistry public saveETHRegistry;

    /// @notice Adds a member to a stake house, issues shares and then mints SaveETH and sETH tokens
    /// @param _stakeHouse Address of the stake house
    /// @param _applicant ID of member being added to the StakeHouse i.e. validator BLS pub key
    /// @param _applicant Account adding the member to the StakeHouse and receiving tokenised shares
    function _addMember(address _stakeHouse, bytes calldata _memberId, address _applicant, uint256 _savETHIndex) internal {
        // register KNOT in stake house
        StakeHouseRegistry(_stakeHouse).addMember(_applicant, _memberId);

        // issue default shares for a KNOT with 32 ETH
        saveETHRegistry.mintSaveETHBatchAndDETHReserves(_stakeHouse, _memberId, _savETHIndex);
        slotRegistry.mintSLOTAndSharesBatch(_stakeHouse, _memberId, _applicant);

        emit MemberAddedAndSharesIssued(_stakeHouse, _memberId, _applicant);
    }
}
