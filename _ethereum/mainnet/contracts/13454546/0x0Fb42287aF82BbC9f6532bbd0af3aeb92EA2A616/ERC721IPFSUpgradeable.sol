// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";

contract ERC721IPFSUpgradeable is ERC721Upgradeable {
    string private _ipfsHash;

    function __ERC721IPFS_init(string memory __ipfsHash) internal {
        _ipfsHash = __ipfsHash;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return string(bytes.concat("ipfs://", bytes(_ipfsHash), "/"));
    }

    uint256[49] private __gap;
}
