// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721AFacet.sol";
import "./AccessControlModifiers.sol";
import "./BaseNFTLib.sol";
import "./BaseNFTModifiers.sol";
import "./URIStorageLib.sol";
import "./URIStorageFacet.sol";
import "./PaymentSplitterFacet.sol";
import "./RoyaltyStandardFacet.sol";
import "./RoyaltyStandardLib.sol";

error NonExistentToken();
error AlreadyInitialized();

// Inherit from other facets in the BaseNFTFacet
// Why inherit to one facet instead of deploying Each Facet Separately?
// Because its cheaper for end customers to just store / cut one facet address

contract BaseNFTFacet is
    SaleStateModifiers,
    AccessControlModifiers,
    ERC721AFacet,
    RoyaltyStandardFacet,
    URIStorageFacet
{
    function setTokenMeta(
        string memory _name,
        string memory _symbol,
        uint96 _defaultRoyalty
    ) public onlyOwner whenNotPaused {
        ERC721ALib.ERC721AStorage storage s = ERC721ALib.erc721AStorage();
        s._name = _name;
        s._symbol = _symbol;
        RoyaltyStandardLib._setDefaultRoyalty(_defaultRoyalty);
    }

    function devMint(address to, uint256 quantity)
        public
        payable
        onlyOperator
        whenNotPaused
    {
        BaseNFTLib._safeMint(to, quantity);
    }

    function devMintUnsafe(address to, uint256 quantity)
        public
        payable
        onlyOperator
        whenNotPaused
    {
        BaseNFTLib._unsafeMint(to, quantity);
    }

    function devMintWithTokenURI(address to, string memory _tokenURI)
        public
        payable
        onlyOperator
        whenNotPaused
    {
        uint256 tokenId = BaseNFTLib._safeMint(to, 1);
        URIStorageLib.setTokenURI(tokenId, _tokenURI);
    }

    function saleState() public view returns (uint256) {
        return BaseNFTLib.saleState();
    }

    function setSaleState(uint256 _saleState)
        public
        onlyOperator
        whenNotPaused
    {
        BaseNFTLib.setSaleState(_saleState);
    }

    function setMaxMintable(uint256 _maxMintable)
        public
        onlyOperator
        whenNotPaused
    {
        return BaseNFTLib.setMaxMintable(_maxMintable);
    }

    function maxMintable() public view returns (uint256) {
        return BaseNFTLib.maxMintable();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!ERC721ALib._exists(tokenId)) {
            revert NonExistentToken();
        }

        return URIStorageLib.tokenURI(tokenId);
    }

    function allOwners() external view returns (address[] memory) {
        return BaseNFTLib.allOwners();
    }

    function allTokensForOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        return BaseNFTLib.allTokensForOwner(_owner);
    }
}
