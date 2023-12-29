// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LibFeeCollector.sol";
import "./LibUtil.sol";

/// @title Lib Bridge
/// @author FormalCrypto
/// @notice Provides functionality to manage bridge data
library LibBridge {
    bytes32 internal constant BRIDGE_STORAGE_POSITION =
        keccak256("bridge.storage.position");

    struct BridgeStorage {
        uint256 crosschainFee;
        mapping(uint256 => uint256) minFee;
        mapping(address => bool) approvedTokens;
        mapping(uint256 => address) contractTo;
    }

    /**
     * @dev Fetch local storage
     */
    function _getStorage() internal pure returns (BridgeStorage storage bs) {
        bytes32 position = BRIDGE_STORAGE_POSITION;
        assembly {
            bs.slot := position
        }
    }

    /**
     * @dev Update crosschainFee
     * @param _crosschainFee Crosschain fee
     */
    function updateCrosschainFee(uint256 _crosschainFee) internal {
        BridgeStorage storage bs = _getStorage();

        bs.crosschainFee = _crosschainFee;
    }

    /**
     * @dev Updates minimum fee for the specified chain
     * @param _chainId Chain id
     * @param _minFee minmum fee
     */
    function updateMinFee(uint256 _chainId, uint256 _minFee) internal {
        BridgeStorage storage bs = _getStorage();

        bs.minFee[_chainId] = _minFee;
    }

    /**
     * @dev Adds approved token for crosschain
     * @param _token Address of approved token
     */
    function addApprovedToken(address _token) internal {
        BridgeStorage storage bs = _getStorage();

        bs.approvedTokens[_token] = true;
    }

    /**
     * Removes approved token
     * @param _token Address of token to remove
     */
    function removeApprovedToken(address _token) internal {
        BridgeStorage storage bs = _getStorage();

        bs.approvedTokens[_token] = false;
    }

    /**
     * @dev Adds receiver contract for the specified chain
     * @param _chainId Chain id
     * @param _contractTo Receiver contract address
     */
    function addContractTo(uint256 _chainId, address _contractTo) internal {
        BridgeStorage storage bs = _getStorage();

        bs.contractTo[_chainId] = _contractTo;
    }

    /**
     * @dev Removes receiver contract
     * @param _chainId Chain id
     */
    function removeContractTo(uint256 _chainId) internal {
        BridgeStorage storage bs = _getStorage();

        if (bs.contractTo[_chainId] == address(0)) return;

        bs.contractTo[_chainId] = address(0);
    }

    /**
     * @dev Returns receiver contract for the specified chain
     * @param _chainId Chain id
     */
    function getContractTo(uint256 _chainId) internal view returns (address) {
        BridgeStorage storage bs = _getStorage();

        return bs.contractTo[_chainId];
    }

    /**
     * @dev Returns crosschainFee
     */
    function getCrosschainFee() internal view returns (uint256) {
        return _getStorage().crosschainFee;
    }

    /**
     * @dev Returns minimum fee for the specified chain
     * @param _chainId Chain id
     */
    function getMinFee(uint256 _chainId) internal view returns (uint256) {
        return _getStorage().minFee[_chainId];
    }

    /**
     * @dev Checks if token added to approved list
     * @param _token Address of the token to check
     */
    function getApprovedToken(address _token) internal view returns (bool) {
        return _getStorage().approvedTokens[_token];
    }

    /**
     * @dev Returns all fee data for the specified chain
     * @param _chainId Chain id
     * @return Crosschain fee
     * @return Minimum fee
     */
    function getFeeInfo(uint256 _chainId) internal view returns (uint256, uint256) {
        BridgeStorage storage bs = _getStorage();
        return (bs.crosschainFee, bs.minFee[_chainId]);
    }
}