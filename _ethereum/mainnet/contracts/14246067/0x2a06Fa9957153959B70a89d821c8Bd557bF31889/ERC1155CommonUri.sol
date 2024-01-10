// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155CommonUri.sol";

abstract contract ERC1155CommonUri is IERC1155CommonUri {

    mapping (uint256 => string) internal commonURIs;
    mapping (uint256 => address) internal commonURIOwners;
    mapping (uint256 => uint256) internal tokenHashtoUriMap;

    function getCommonUri(uint256 uriId) external view override returns (string memory result) {

        return commonURIs[uriId];

    }
    function _setCommonUri(uint256 uriId, string memory value) internal {

        commonURIs[uriId] = value;
        commonURIOwners[uriId] = msg.sender;

    }
    function _setCommonUriOf(uint256 uriId, uint256 tokenHash) internal {

        tokenHashtoUriMap[tokenHash] = uriId;

    }

    function _commonUriOf(uint256 tokenHash) internal view returns (string memory result) {

        return commonURIs[tokenHashtoUriMap[tokenHash]];

    }
    function commonUriOf(uint256 tokenHash) external view override returns (string memory result) {

        return _commonUriOf(tokenHash);

    }

    /// @notice mint tokens of specified amount to the specified address
    /// @param recipient the mint target
    /// @param tokenHash the token hash to mint
    /// @param amount the amount to mint
    function mintWithCommonUri(
        address recipient,
        uint256 tokenHash,
        uint256 amount,
        uint256 uriId
    ) virtual external override {
        // does nothing
    }

}
