// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Initializable.sol";
import "./StringsUpgradeable.sol";

import "./MetadataUriStorageV1.sol";

abstract contract MetadataUriV1 is Initializable {
    using MetadataUriStorageV1 for MetadataUriStorageV1.Layout;

    function __MetadataUriV1_init(
        string memory _uriPrefix,
        string memory _uriSuffix
    ) onlyInitializing internal {
        _setUriPrefix(_uriPrefix);
        _setUriSuffix(_uriSuffix);
    }

    function _setUriPrefix(string memory _uriPrefix) internal virtual {
        MetadataUriStorageV1.layout()._uriPrefix = _uriPrefix;
    }

    function _setUriSuffix(string memory _uriSuffix) internal virtual {
        MetadataUriStorageV1.layout()._uriSuffix = _uriSuffix;
    }

    function _buildTokenUri(uint256 _tokenId) internal view virtual returns (string memory) {
        return string(abi.encodePacked(MetadataUriStorageV1.layout()._uriPrefix, StringsUpgradeable.toString(_tokenId), MetadataUriStorageV1.layout()._uriSuffix));
    }

    function setUriPrefix(string memory _uriPrefix) public virtual;

    function setUriSuffix(string memory _uriSuffix) public virtual;
}
