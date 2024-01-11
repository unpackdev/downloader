// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Roles.sol";
import "./ISupply.sol";

contract Supply is Roles, ISupply {
    mapping(uint256 => uint256) internal _currentSupply;
    mapping(uint256 => uint256) internal _maxSupply;
    uint256 public defaultMaxSupply;

    /// @inheritdoc ISupply
    function setDefaultMaxSupply(uint256 value) external onlyVaultAdmin {
        _setDefaultMaxSupply(value);
    }

    function _setDefaultMaxSupply(uint256 value) internal {
        require(value > 0, 'Supply: Default Max Ssupply cannot be null');
        emit DefaultMaxSupplyChanged(defaultMaxSupply, value);
        defaultMaxSupply = value;
    }

    /// @inheritdoc ISupply
    function setMaxSupply(uint256 supply, uint256 tokenId) external onlyVaultAdmin {
        emit MaxSupplyChanged(tokenId, _maxSupply[tokenId], supply);
        _setMaxSupply(supply, tokenId);
    }

    /// @inheritdoc ISupply
    function setBatchMaxSupply(uint256[] calldata supplies, uint256[] calldata tokenIds)
        external
        onlyVaultAdmin
    {
        for (uint256 i = 0; i < supplies.length; i++) {
            _setMaxSupply(supplies[i], tokenIds[i]);
        }
    }

    function _setMaxSupply(uint256 supply, uint256 tokenId) internal {
        require(
            supply + 1 > _currentSupply[tokenId],
            'Supply: current supply exceeds new max supply'
        );
        _maxSupply[tokenId] = supply;
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view override returns (bool) {
        return _exists(id);
    }

    /// @dev returns true if the supply of a given Id exists
    function _exists(uint256 id) internal view returns (bool) {
        return _currentSupply[id] > 0;
    }

    /// @dev returns true if the maximum supply of a given Id exists
    function _maxSupplyExists(uint256 id) internal view returns (bool) {
        return _maxSupply[id] > 0;
    }

    /// @inheritdoc ISupply
    function currentSupply(uint256 id) external view override returns (uint256) {
        return _currentSupply[id];
    }

    /// @inheritdoc ISupply
    function maxSupply(uint256 id) external view override returns (uint256) {
        return _maxSupply[id];
    }
}
