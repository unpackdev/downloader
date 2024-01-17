// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./MintableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721RoyaltyUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./EnumerableMapUpgradeable.sol";

contract KongregateImxAssetV1 is MintableUpgradeable, PausableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, ERC721RoyaltyUpgradeable {

    string private _contractUri;

    function initialize (
        string memory name, 
        string memory symbol, 
        string memory contractUri,
        address imx, 
        address royaltyReceiver,   
        uint96 royaltyBasisPoints
        ) initializer public {
        __Pausable_init();
        __Mintable_init(imx);
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Royalty_init();
        setDefaultRoyalty(royaltyReceiver, royaltyBasisPoints);
        _contractUri = contractUri;
    }

    function _mintFor(
        address user,
        uint256 id,
        bytes memory blueprint
    ) internal override {
        string memory tokenUri = string(blueprint);

        _safeMint(user, id);
        _setTokenURI(id, tokenUri);
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // The following functions are overrides required by Solidity.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory) {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721RoyaltyUpgradeable)
        returns (bool) {
        return ERC721RoyaltyUpgradeable.supportsInterface(interfaceId);    
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        ERC721EnumerableUpgradeable._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721RoyaltyUpgradeable) {
        ERC721URIStorageUpgradeable._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

}
