// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @author jpegmint.xyz

import "./MultiOwnable.sol";
import "./ERC721Royalties.sol";
import "./ERC721.sol";

contract ERC721Artist is ERC721, ERC721Royalties, MultiOwnable {

    /// VARIABLES ///
    uint256 public totalSupply;
    
    mapping(uint256 => string) private _tokenURIs;
    
    /// CONSTRUCTOR ///
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    /// ERC165 INTERFACES ///
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Royalties, MultiOwnable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //   __  __ _____ _   _ _______ _____ _   _  _____ 
    //  |  \/  |_   _| \ | |__   __|_   _| \ | |/ ____|
    //  | \  / | | | |  \| |  | |    | | |  \| | |  __ 
    //  | |\/| | | | | . ` |  | |    | | | . ` | | |_ |
    //  | |  | |_| |_| |\  |  | |   _| |_| |\  | |__| |
    //  |_|  |_|_____|_| \_|  |_|  |_____|_| \_|\_____|
    //                                                
                                         
    /**
     * @dev Mint a token.
     *
     * @param to      Address to mint to.
     * @param tokenId Desired tokenId.
     * @param uri     Metadata uri for the token.
     */
    function mint(address to, uint256 tokenId, string memory uri) public onlyOwner {

        _safeMint(to, tokenId);

        if (bytes(uri).length > 0) {
            _setTokenURI(tokenId, uri);
        }

        totalSupply++;
    }

    /**
     * @dev Burn a token. Allows re-minting same tokenId after burn.
     *
     * @param tokenId The tokenId to burn.
     */
    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        
        _burn(tokenId);
        
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        totalSupply--;
    }
 
    //   __  __ ______ _______       _____       _______       
    //  |  \/  |  ____|__   __|/\   |  __ \   /\|__   __|/\    
    //  | \  / | |__     | |  /  \  | |  | | /  \  | |  /  \   
    //  | |\/| |  __|    | | / /\ \ | |  | |/ /\ \ | | / /\ \  
    //  | |  | | |____   | |/ ____ \| |__| / ____ \| |/ ____ \ 
    //  |_|  |_|______|  |_/_/    \_\_____/_/    \_\_/_/    \_\
    //

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Updates the metadata uri for a token.
     *
     * @param tokenId The tokenId to update.
     * @param uri     The new metadata uri.
     */
    function setTokenURI(uint256 tokenId, string memory uri) external onlyOwner {
        if (bytes(uri).length > 0) {
            _setTokenURI(tokenId, uri);
        }
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    //   _____   ______     __      _   _______ _____ ______  _____ 
    //  |  __ \ / __ \ \   / //\   | | |__   __|_   _|  ____|/ ____|
    //  | |__) | |  | \ \_/ //  \  | |    | |    | | | |__  | (___  
    //  |  _  /| |  | |\   // /\ \ | |    | |    | | |  __|  \___ \ 
    //  | | \ \| |__| | | |/ ____ \| |____| |   _| |_| |____ ____) |
    //  |_|  \_\\____/  |_/_/    \_\______|_|  |_____|______|_____/ 
    //                                                             

    /**
     * @dev Sets the contract roylaties for all tokens.
     *
     * @param recipient The royalty recipient's address.
     * @param basisPoints The royalty bps. 100% is 10,000, 10% is 1,000, 0% is 0.
     */
    function setRoyalties(address recipient, uint256 basisPoints) public override onlyOwner {
        _setRoyalties(recipient, basisPoints);
    }
}
