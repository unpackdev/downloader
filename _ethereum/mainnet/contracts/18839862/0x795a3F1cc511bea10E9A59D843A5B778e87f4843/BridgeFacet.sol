// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LibDiamond.sol";
import "./LibAccessControl.sol";
import "./LibBridge.sol";
import "./GenericErrors.sol";
import "./LibUtil.sol";
import "./GenericErrors.sol";

/// @title Bridge Facet
/// @author FormalCrypto
/// @notice Provides functionality for managing method level bridge data
contract BridgeFacet  {
    /**
     * @dev Updates crosschain fee
     * @param _crosschainFee crosschain fee
     */
    function updateCrosschainFee(uint256 _crosschainFee) external {
        if(LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();

        if(_crosschainFee > 10000) revert IncorrectFeePercent();

        LibBridge.updateCrosschainFee(_crosschainFee);
    }

    /**
     * @dev Updates minimum fee for the specified chain
     * @param _chainId Specific chain id
     * @param _minFee Minimum fee
     */
    function updateMinFee(uint256 _chainId, uint256 _minFee) external {
        if(LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();

        LibBridge.updateMinFee(_chainId, _minFee);
    }

    /**
     * @dev Batch updates minimum fee for the specified chain
     * @param _chainId Specific chain id
     * @param _minFee Minimum fee
     */
    function batchUpdateMinFee(uint256[] calldata _chainId, uint256[] calldata _minFee) external {
        if(LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();

        uint256 length = _chainId.length;

        if (length != _minFee.length) revert InformationMismatch();

        for (uint256 i; i < length;) {

            LibBridge.updateMinFee(_chainId[i], _minFee[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Adds approved token for crosschain
     * @param _token Address of the token to be approved
     */
    function addApprovedToken(address _token) external {
        if(LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();

        if(LibUtil.isZeroAddress(_token)) revert NullAddrIsNotAnERC20Token();

        LibBridge.addApprovedToken(_token);
    }
    /**
     * @dev Removes approved token
     * @param _token Address of the token to be removed
     */

    function removeApprovedToken(address _token) external {
        if(LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();
        LibBridge.removeApprovedToken(_token);
    }

    /**
     * @dev Adds receiver contract for the specified chain
     * @param _chainId chain id
     * @param _contractTo Receiver contract address
     */
    function addContractTo(uint256 _chainId, address _contractTo) external {
        if(LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();
        LibBridge.addContractTo(_chainId, _contractTo);
    }

    /**
     * @dev Removes receiver contract address
     * @param _chainId Address of the contract to be removed
     */
    function removeContractTo(uint256 _chainId) external {
        if(LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();
        LibBridge.removeContractTo(_chainId);
    }

    /**
     * @dev Returns receiver contract address for specific chain
     * @param _chainId Chain id
     */
    function getContractTo(uint256 _chainId) external view returns (address) {
        if(LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();
        return LibBridge.getContractTo(_chainId);
    }

    /**
     * @dev Returns crosschain fee
     */
    function getCrosschainFee() external view returns (uint256) {
        return LibBridge.getCrosschainFee();
    }

    /**
     * @dev Returns minimum fee for specific chain
     * @param _chainId Chain id
     */
    function getMinFee(uint256 _chainId) external view returns (uint256) {
        return LibBridge.getMinFee(_chainId);
    }

    /**
     * @dev Check if token approved for crosschain
     * @param _token Address of the token to be checked
     */
    function isTokenApproved(address _token) external view returns (bool) {
        return LibBridge.getApprovedToken(_token);
    }
}