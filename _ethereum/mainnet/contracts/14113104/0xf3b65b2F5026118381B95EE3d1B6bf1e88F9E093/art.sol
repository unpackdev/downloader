// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#   %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*        .*.   &@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             &@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#/.              &@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@%*                      #@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@.                          %@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@(                   /*@/     (@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@(                    (@*@@@&/./@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@,                    .#@@@@@@@@@@@@@%,./@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@,                     *@@@@@@@@@@@@#   *@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@/                        .**%@@@@@@,  #@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@%                       ,.    %@@@@/ ,@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@,                   &%,       #@@@@( (@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@.                    ,/       (@@@@@, @@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@,                              @@@@@&. %@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@#                        /** .(#@@@@@@. &@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@*                      ,@&%&@@@@@@@@@@, %@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@.                          %@@@@@@@@@# *@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@.       ,(#%%&&,    *%&%%@@@@@@@@@@@# *@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@/    .@@@@@@@@@@@@@&*     #@@@@@@@@* #@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@%     %@@@@@@@@@@@@@@@(  #@@@@@@@* /@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@(     /@@@@@@@@@@@@@@@@@@@@@@%. (@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@&,     (@@@@@@@@@@@@@@@@@/  ,@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@*      ,(%&&@@&&#*   .(@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&%/.        ,(&@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

import "./ERC721.sol";
import "./Ownable.sol";

/// @title A contract for Genesis Fine Art Collection by ratDAO
/// @author Phillip
/// @notice NFT Minting

contract ratDAOArt is ERC721, Ownable {

    // token ID
    uint16 private tokenId;

    // mapping for token URIs
    mapping(uint256 => string) private tokenURIs;

    // treasury wallet address
    address private treasury;


    constructor() ERC721("Genesis Fine Art Collection by ratDAO", "ART") {

    }

    /**
     * Mint Artwork
     */
    function mint() external returns (string memory) {
        require(_msgSender() != address(0));
        require(_msgSender() == owner() || _msgSender() == treasury, "Caller is not allowed to mint.");
        require(bytes(tokenURIs[tokenId + 1]).length != 0, "Next token does not exist.");

        tokenId++;
        _safeMint(_msgSender(), tokenId);
        
        return tokenURIs[tokenId];
    }

    /**
     * Set Token URI
     * _tokenId must be in [1, tokenId + 1]
     */
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external onlyOwner returns (string memory) {
        require(_tokenId > 0);
        require(_tokenId < tokenId + 2);
        tokenURIs[_tokenId] = _tokenURI;
        return tokenURIs[_tokenId];
    }

    /**
     * Override tokenURI
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");
        return tokenURIs[_tokenId];
    }

    /**
     * Set Treasury
     */
    function setTreasury(address _treasury) external onlyOwner returns (address) {
        treasury = _treasury;
        return treasury;
    }

    /**
     * Get Treasury
     */
    function getTreasury() external view onlyOwner returns (address) {
        return treasury;
    }

    /**
     * Get Token URI
     */
    function getTokenURI(uint256 _tokenId) external view onlyOwner returns (string memory) {
        return tokenURIs[_tokenId];
    }
}