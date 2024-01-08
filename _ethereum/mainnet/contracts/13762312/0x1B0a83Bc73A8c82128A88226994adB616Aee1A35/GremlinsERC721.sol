// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @author jpegmint.xyz

import "./GremlinsAccessControl.sol";
import "./ERC721RoyaltiesUpgradeable.sol";
import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./StorageSlotUpgradeable.sol";

/*
 ██████╗ ██████╗ ███████╗███╗   ███╗██╗     ██╗███╗   ██╗███████╗    ███████╗██████╗  ██████╗███████╗██████╗  ██╗
██╔════╝ ██╔══██╗██╔════╝████╗ ████║██║     ██║████╗  ██║██╔════╝    ██╔════╝██╔══██╗██╔════╝╚════██║╚════██╗███║
██║  ███╗██████╔╝█████╗  ██╔████╔██║██║     ██║██╔██╗ ██║███████╗    █████╗  ██████╔╝██║         ██╔╝ █████╔╝╚██║
██║   ██║██╔══██╗██╔══╝  ██║╚██╔╝██║██║     ██║██║╚██╗██║╚════██║    ██╔══╝  ██╔══██╗██║        ██╔╝ ██╔═══╝  ██║
╚██████╔╝██║  ██║███████╗██║ ╚═╝ ██║███████╗██║██║ ╚████║███████║    ███████╗██║  ██║╚██████╗   ██║  ███████╗ ██║
 ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝    ╚══════╝╚═╝  ╚═╝ ╚═════╝   ╚═╝  ╚══════╝ ╚═╝
*/
contract GremlinsERC721 is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    ERC721RoyaltiesUpgradeable,
    GremlinsAccessControl
{
    // Path to metadata files.
    string public baseURI;

    //  ██████╗ ██████╗ ███╗   ██╗███████╗████████╗██████╗ ██╗   ██╗ ██████╗████████╗ ██████╗ ██████╗ 
    // ██╔════╝██╔═══██╗████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║   ██║██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗
    // ██║     ██║   ██║██╔██╗ ██║███████╗   ██║   ██████╔╝██║   ██║██║        ██║   ██║   ██║██████╔╝
    // ██║     ██║   ██║██║╚██╗██║╚════██║   ██║   ██╔══██╗██║   ██║██║        ██║   ██║   ██║██╔══██╗
    // ╚██████╗╚██████╔╝██║ ╚████║███████║   ██║   ██║  ██║╚██████╔╝╚██████╗   ██║   ╚██████╔╝██║  ██║
    //  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝

    // Constructor
    constructor() initializer {
        __GremlinsAccessControl_base_init();
    }

    // Proxy initializer
    function initialize(string memory name_, string memory symbol_) external initializer {
        __GremlinsAccessControl_proxy_init();
        __ERC721_init(name_, symbol_);
        __ERC721Royalties_init();
        __ERC721URIStorage_init();
    }


    // ███╗   ███╗██╗███╗   ██╗████████╗██╗███╗   ██╗ ██████╗ 
    // ████╗ ████║██║████╗  ██║╚══██╔══╝██║████╗  ██║██╔════╝ 
    // ██╔████╔██║██║██╔██╗ ██║   ██║   ██║██╔██╗ ██║██║  ███╗
    // ██║╚██╔╝██║██║██║╚██╗██║   ██║   ██║██║╚██╗██║██║   ██║
    // ██║ ╚═╝ ██║██║██║ ╚████║   ██║   ██║██║ ╚████║╚██████╔╝
    // ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝ 

    function mint(address to, uint256 tokenId, string calldata _tokenURI) external onlyWhitelisted(to) {
        _mint(to, tokenId);

        if (bytes(_tokenURI).length != 0) {
            _setTokenURI(tokenId, _tokenURI);
        }
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }


    // ███╗   ███╗███████╗████████╗ █████╗ ██████╗  █████╗ ████████╗ █████╗ 
    // ████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗
    // ██╔████╔██║█████╗     ██║   ███████║██║  ██║███████║   ██║   ███████║
    // ██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║  ██║██╔══██║   ██║   ██╔══██║
    // ██║ ╚═╝ ██║███████╗   ██║   ██║  ██║██████╔╝██║  ██║   ██║   ██║  ██║
    // ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Access control for _setTokenURI.
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyMetadataAdmin {
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev Store and update new base uri.
     */
    function setBaseURI(string memory newURI) external onlyMetadataAdmin {
        baseURI = newURI;
    }

    /**
     * @dev Return the base URI for OpenZeppelin default TokenURI implementation.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    // ██████╗  ██████╗ ██╗   ██╗ █████╗ ██╗  ████████╗██╗███████╗███████╗
    // ██╔══██╗██╔═══██╗╚██╗ ██╔╝██╔══██╗██║  ╚══██╔══╝██║██╔════╝██╔════╝
    // ██████╔╝██║   ██║ ╚████╔╝ ███████║██║     ██║   ██║█████╗  ███████╗
    // ██╔══██╗██║   ██║  ╚██╔╝  ██╔══██║██║     ██║   ██║██╔══╝  ╚════██║
    // ██║  ██║╚██████╔╝   ██║   ██║  ██║███████╗██║   ██║███████╗███████║
    // ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝   ╚═╝╚══════╝╚══════╝

    /**
     * @dev Sets contract-wide royalties.
     */
    function setRoyalties(address recipient, uint256 basisPoints) external override onlyOwner {
        _setRoyalties(recipient, basisPoints);
    }


    // ███████╗██████╗  ██████╗ ██╗ ██████╗ ███████╗    ██╗███╗   ██╗████████╗███████╗██████╗ ███████╗ █████╗  ██████╗███████╗███████╗
    // ██╔════╝██╔══██╗██╔════╝███║██╔════╝ ██╔════╝    ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝██╔════╝
    // █████╗  ██████╔╝██║     ╚██║███████╗ ███████╗    ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝█████╗  ███████║██║     █████╗  ███████╗
    // ██╔══╝  ██╔══██╗██║      ██║██╔═══██╗╚════██║    ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔══╝  ██╔══██║██║     ██╔══╝  ╚════██║
    // ███████╗██║  ██║╚██████╗ ██║╚██████╔╝███████║    ██║██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║╚██████╗███████╗███████║
    // ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝ ╚═════╝ ╚══════╝    ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝╚══════╝

    // ERC165 Interfaces
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721RoyaltiesUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId)
        ;
    }
}
