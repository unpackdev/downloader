// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

/**
 *    .--.--.       ,---,.   .--.--.
 *   /  /    '.   ,'  .'  \ /  /    '.
 *  |  :  /`. / ,---.' .' ||  :  /`. /
 *  ;  |  |--`  |   |  |: |;  |  |--`
 *  |  :  ;_    :   :  :  /|  :  ;_
 *   \  \    `. :   |    ;  \  \    `.
 *    `----.   \|   :     \  `----.   \
 *    __ \  \  ||   |   . |  __ \  \  |
 *   /  /`--'  /'   :  '; | /  /`--'  /
 *  '--'.     / |   |  | ; '--'.     /
 *    `--'---'  |   :   /    `--'---'
 *              |   | ,'
 *              `----'
 * @title Spoiled Banana Society Season 1 Draft Token ERC-721 Smart Contract
 */

contract SBSDraftTokenSeasonOne is ERC721, Ownable, Pausable, ReentrancyGuard {

    string public SPOILEDBANANASOCIETY_PROVENANCE = "";
    string private baseURI;
    uint256 public constant RESERVED_TOKENS = 20;
    uint256 public constant TOKEN_PRICE = 20000000000000000; // 0.02 ETH or 20000000000000000 WEI
    uint256 public numTokensMinted = 0;
    uint256 public numTokensBurned = 0;

    // PUBLIC MINT
    bool public mintIsActive = false;

    constructor() ERC721("Banana Best Ball Season 1", "BBB") {}

    // PUBLIC MINT
    function flipMintState() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function mint(uint256 numberOfTokens) external payable nonReentrant {
        require(mintIsActive, "Mint is not active");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, "You sent the incorrect amount of ETH");
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = numTokensMinted;
            numTokensMinted++;
            _safeMint(msg.sender, mintIndex);
        }
    }

    // TOTAL SUPPLY
    function totalSupply() external view returns (uint) { 
        return numTokensMinted - numTokensBurned;
    }

    // BURN IT 
    function burn(uint256 tokenId) public virtual {
	    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
	    _burn(tokenId);
        numTokensBurned++;
    }

    // OWNER FUNCTIONS
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function reserveTokens(uint256 numberOfTokens, address recipientAddress) external onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = numTokensMinted;
            numTokensMinted++;
            _safeMint(msg.sender, mintIndex);
            transferFrom(msg.sender, recipientAddress, mintIndex);
        }
    }

    function setPaused(bool _setPaused) external onlyOwner {
	    return (_setPaused) ? _pause() : _unpause();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        SPOILEDBANANASOCIETY_PROVENANCE = provenanceHash;
    }

    // function _beforeTokenTransfer(
	//     address from,
	//     address to,
	//     uint256 tokenId
    // ) internal virtual override(ERC721) {
	//     require(!paused(), "Pausable: paused");
	//     super._beforeTokenTransfer(from, to, tokenId);
    // }

}

