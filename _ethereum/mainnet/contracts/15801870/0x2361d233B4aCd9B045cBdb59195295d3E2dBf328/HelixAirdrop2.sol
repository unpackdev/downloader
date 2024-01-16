// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./OpenSeaGasFreeListing.sol";
import "./Initializable.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AdminMintUpgradable.sol";
import "./UriManagerUpgradable.sol";
import "./RoyaltiesUpgradable.sol";

contract HelixAirdrop2 is
    Initializable,
    ERC721AQueryableUpgradeable,
    OwnableUpgradeable,
    AdminMintUpgradable,
    UriManagerUpgradable,
    RoyaltiesUpgradable
{
    function initialize(address royaltiesRecipient_, uint256 royaltiesValue_)
        public
        initializerERC721A
        initializer
    {
        __ERC721A_init("MYSTERY CAR", "MYSTERY CAR");
        __Ownable_init();
        __AdminManager_init_unchained();
        __AdminMint_init_unchained();
        __UriManager_init_unchained(
            "https://ipfs.io/ipfs/QmWWehiBXyCVuofC6p1wfey1miD36URdvExExxnekce4o4/",
            ".json"
        );
        __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
    }

    function isApprovedForAll(address owner_, address operator_)
        public
        view
        virtual
        override(ERC721AUpgradeable)
        returns (bool)
    {
        return
            super.isApprovedForAll(owner_, operator_) ||
            OpenSeaGasFreeListing.isApprovedForAll(owner_, operator_);
    }

    function _adminMint(address account_, uint256 amount_) internal override {
        _safeMint(account_, amount_);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721AUpgradeable)
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }

        return _buildUri(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(RoyaltiesUpgradable, ERC721AUpgradeable)
        returns (bool)
    {
        return
            RoyaltiesUpgradable.supportsInterface(interfaceId) ||
            ERC721AUpgradeable.supportsInterface(interfaceId);
    }
}
