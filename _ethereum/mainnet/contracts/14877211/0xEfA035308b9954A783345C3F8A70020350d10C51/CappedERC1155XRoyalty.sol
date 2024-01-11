// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC1155XSupply.sol";
import "./ERC2981.sol";
import "./Strings.sol";

abstract contract CappedERC1155XRoyalty is ERC2981, ERC1155XSupply {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Base metadata URI
    string private _baseTokenUri;

    // Base metadata URI extension
    string private _baseExtension;

    // Max supply for each tokenId;
    mapping(uint256 => uint256) public tokenMaxSupplies;

    // Maximum royalty percentage (10%, 2 decimals)
    uint256 public constant MAX_ROYALTIES = 1000;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenUri_,
        string memory baseExtension_
    ) ERC1155X(baseTokenUri_) {
        _name = name_;
        _symbol = symbol_;
        _baseTokenUri = baseTokenUri_;
        _baseExtension = baseExtension_;
    }

    modifier withinLimit(uint256 tokenId, uint256 quantity) {
        require(
            totalSupply(tokenId) + quantity <= tokenMaxSupplies[tokenId],
            "Maximum supply reached"
        );
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function _setSupply(uint256 tokenId, uint256 newSupply) internal {
        require(
            newSupply >= totalSupply(tokenId),
            "New supply less than current supply"
        );
        tokenMaxSupplies[tokenId] = newSupply;
    }

    function _updateRoyalty(address _royaltyReceiver, uint96 _royaltyPercent)
        internal
    {
        require(
            _royaltyPercent <= MAX_ROYALTIES,
            "Royalties cannot be more than 10%"
        );
        _setDefaultRoyalty(_royaltyReceiver, _royaltyPercent);
    }

    function _setBaseUri(string memory baseUri) internal {
        _baseTokenUri = baseUri;
    }

    function _setBaseExtension(string memory baseExtension) internal {
        _baseExtension = baseExtension;
    }

    /**
     * @dev See {IERC1155-uri}.
     */
    function uri(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _baseTokenUri,
                    Strings.toString(_tokenId),
                    _baseExtension
                )
            );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155X, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
