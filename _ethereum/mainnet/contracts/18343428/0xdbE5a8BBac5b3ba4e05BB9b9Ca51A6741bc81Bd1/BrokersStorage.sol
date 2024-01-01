// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BitMaps.sol";
import "./IBrokers.sol";

abstract contract BrokersStorage is IBrokers {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using BitMaps for BitMaps.BitMap;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice Mapping of users and their nonce
    mapping(address => BitMaps.BitMap) internal _nonce;

    /// -----------------------------------------------------------------------
    /// Setter functions
    /// -----------------------------------------------------------------------

    /// @dev Update nonce of a user address
    /// @param _owner User's address
    /// @param __nonce Nonce to be updated
    function _setNonce(address _owner, uint256 __nonce) internal {
        _nonce[_owner].set(__nonce);
    }

    /// -----------------------------------------------------------------------
    /// Getter functions
    /// -----------------------------------------------------------------------

    /// @dev Get nonce status of a user and nonce value
    /// @param _owner User's address
    /// @param __nonce Nonce value to check
    function getNonce(
        address _owner,
        uint256 __nonce
    ) public view returns (bool) {
        return _nonce[_owner].get(__nonce);
    }
}
