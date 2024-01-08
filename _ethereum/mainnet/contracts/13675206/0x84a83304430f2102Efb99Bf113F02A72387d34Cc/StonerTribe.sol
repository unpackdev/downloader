// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./console.sol";

/** 
*  ____________________________    _______  _____________________  _____________________.________________________ 
*   /   _____/\__    ___/\_____  \   \      \ \_   _____/\______   \ \__    ___/\______   \   \______   \_   _____/ 
*   \_____  \   |    |    /   |   \  /   |   \ |    __)_  |       _/   |    |    |       _/   ||    |  _/|    __)_  
*   /        \  |    |   /    |    \/    |    \|        \ |    |   \   |    |    |    |   \   ||    |   \|        \ 
*  /_______  /  |____|   \_______  /\____|__  /_______  / |____|_  /   |____|    |____|_  /___||______  /_______  / 
*          \/                    \/         \/        \/         \/                     \/            \/        \/  
*/

/**
 * @title Stoner Tribe ERC-721 Smart Contract
 */

contract StonerTribe is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {

    string public STONERTRIBE_PROVENANCE = "";
    string private baseURI;
    uint256 public constant MAX_TOKENS = 9420;
    uint256 public constant RESERVED_TOKENS = 20;
    uint256 public numTokensMinted = 0;

    // PUBLIC MINT
    uint256 public constant TOKEN_PRICE = 42000000000000000; // 0.00 ETH
    uint256 public constant MAX_TOKENS_PURCHASE = 20;
    bool public mintIsActive = false;

    constructor() ERC721("Tribe", "TRBE") {}

    // PUBLIC MINT
    function flipMintState() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function mintToken(uint256 numberOfTokens) external payable nonReentrant{
        require(!paused(), "Pausable: paused"); // Toggle if pausing should suspend minting
        require(mintIsActive, "Mint is not active.");
        require(numberOfTokens <= MAX_TOKENS_PURCHASE, "You went over max tokens per transaction.");
        require(numTokensMinted + numberOfTokens <= MAX_TOKENS, "Not enough tokens left to mint that many");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, "You sent the incorrect amount of ETH.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = numTokensMinted;
            if (numTokensMinted < MAX_TOKENS) {
                numTokensMinted++;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    // BURN IT 
    function burn(uint256 tokenId) external virtual {
	    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
	    _burn(tokenId);
    }

    // OWNER FUNCTIONS
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function reserveTokens() external onlyOwner {
        uint256 mintIndex = numTokensMinted;
        for (uint256 i = 0; i < RESERVED_TOKENS; i++) {
            numTokensMinted++;
            _safeMint(msg.sender, mintIndex + i);
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
        STONERTRIBE_PROVENANCE = provenanceHash;
    }

    // Toggle this function if pausing should suspend transfers
    function _beforeTokenTransfer(
	    address from,
	    address to,
	    uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
	    require(!paused(), "Pausable: paused");
	    super._beforeTokenTransfer(from, to, tokenId);
    }
}
