// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC1155Upgradeable.sol";
import "./SafeMathUpgradeable.sol";

abstract contract ERC1155WithMetadata is ERC1155Upgradeable {
    // tokenURIs  for each token
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => address) private _creators;

    function __ERC1155WithMetadata_init(string memory uri_)
        internal
        initializer
    {
        __ERC1155_init_unchained(uri_);
    }

    /**
     * @dev Return tokenURI for id.
     */
    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _tokenURIs[id];
    }

    /**
     * @dev Method to know if a token has already been minted or not
     */
    function minted(uint256 id) public view returns (bool) {
        return _creators[id] != address(0);
    }

    /**
     * @dev returns `id`'s creator
     * throws if not minted
     */
    function creator(uint256 id) public view returns (address creatorFromId) {
        address _creator = _creators[id];
        require(_creator != address(0), 'ERC1155: Not Minted');
        return _creator;
    }

    /**
     * @dev sets metadata for id
     */
    function _setMetadata(
        uint256 id,
        string memory tokenURI,
        address _creator
    ) internal {
        if (bytes(tokenURI).length > 0) {
            _tokenURIs[id] = tokenURI;
            emit URI(tokenURI, id);
        }
        _creators[id] = _creator;
    }

    /**
     * @dev used when burning a token
     */
    function _removeMetadata(uint256 id) internal {
        delete _tokenURIs[id];
        delete _creators[id];
    }
}
