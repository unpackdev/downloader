// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LibFeeCollector.sol";
import "./LibAccessControl.sol";
import "./LibDiamond.sol";
import "./LibAsset.sol";
import "./ReentrancyGuard.sol";
import "./GenericErrors.sol";

/// @title Fee Manager Facet
/// @author FormalCrypto
/// @notice Provides functionality for managing fees and partners data
contract FeeManagerFacet is ReentrancyGuard{

    event MainPartnerChanged(address newMainPartner);

    /**
     * @dev Updates main partner
     * @param _mainPartner Address of the main partner
     */
    function updateMainPartner(address _mainPartner) external {
        if (LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();

        if (_mainPartner == address(this)) revert CannotAuthoriseSelf();

        LibFeeCollector.updateMainPartner(_mainPartner);

        emit MainPartnerChanged(_mainPartner);
    }

    /**
     * @dev Updates main fee
     * @param _mainFee Main fee
     */
    function updateMainFee(uint256 _mainFee) external {
        if (LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();

        if (_mainFee > 10000) revert IncorrectFeePercent();

        LibFeeCollector.updateMainFee(_mainFee);
    }

    /**
     * @dev Update default partner fee
     * @param _defaultPartnerFeeShare Default partner fee
     */
    function updateDefaultPartnerFeeShare(uint256 _defaultPartnerFeeShare) external {
        if (LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();
        if(_defaultPartnerFeeShare > 10000) revert IncorrectFeePercent();
        LibFeeCollector.updateDefaultPartnerFeeShare(_defaultPartnerFeeShare);
    }

    /**
     * @dev Adds partner 
     * @param _partner Partner address
     * @param _partnerFeeShare Partner fee
     */
    function addPartnerInfo(address _partner, uint256 _partnerFeeShare) external {
        if (LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();

        if (_partnerFeeShare > 10000) revert IncorrectFeePercent();
        if (_partner == address(this)) revert CannotAuthoriseSelf();

        LibFeeCollector.addPartner(_partner, _partnerFeeShare);
    }

    /**
     * @dev Removes partner info
     * @param _partner Partner address
     */
    function removePartnerInfo(address _partner) external {
        if (LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();

        (bool isPartner,) = LibFeeCollector.getPartnerInfo(_partner);
        if (!isPartner) return;

        LibFeeCollector.removePartner(_partner);
    }

    /**
     * @dev Returns partner info
     * @param _partner Parnter address
     */
    function getPartnerInfo(address _partner) external view returns (bool, uint256) {
        return LibFeeCollector.getPartnerInfo(_partner);
    }

    /**
     * @dev Returns fee amount that partner has accumulated
     * @param _token Address of the token
     */
    function getFeeBalance(address _token) external view returns (uint256) {
        return LibFeeCollector.getFeeAmount(_token, msg.sender);
    }

    /**
     * @dev Batch fee amount that partner has accumulated 
     * @param _tokens List of address of the tokens
     */
    function batchGetFeeBalance(address[] calldata _tokens) external view returns (uint256[] memory) {
        uint256 length = _tokens.length;
        uint256[] memory balances = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            balances[i] = LibFeeCollector.getFeeAmount(_tokens[i], msg.sender);
        }

        return balances;
    }

    /**
     * @dev Returns main partner and main fee
     * @return Mainf partner
     * @return Main fee
     */
    function getMainInfo() external view returns (address, uint256) {
        address mainPartner = LibFeeCollector.getMainPartner();
        uint256 mainFee = LibFeeCollector.getMainFee();
        return (mainPartner, mainFee);
    }

    /**
     * @dev Withdraw accumulated fee of specific token
     * @param _token Address of the token
     * @param _amount Amount to be withdrawl
     */
    function withdrawFee(address _token, uint256 _amount) external nonReentrant {
        uint256 totalFee = LibFeeCollector.getFeeAmount(_token, msg.sender);
        if (totalFee < _amount) revert InvalidAmount();

        LibFeeCollector.decreaseFeeAmount(_amount, msg.sender, _token);
        LibAsset.transferAsset(_token, payable(msg.sender), _amount);
    }
}