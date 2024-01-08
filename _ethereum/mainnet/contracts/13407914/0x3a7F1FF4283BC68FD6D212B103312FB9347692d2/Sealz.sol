// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

/**
 * @title ERC-721 Smart Contract
 */

contract Sealz is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {

    uint256 public constant TOKEN_PRICE = 60000000000000000; // 0.06 ETH
    uint256 public constant PRESALE_TOKEN_PRICE = 60000000000000000; // 0.06 ETH
    uint256 public constant MAX_TOKENS_PURCHASE = 20;
    uint256 public constant MAX_TOKENS_PRESALE = 20;
    uint256 public constant RESERVED_TOKENS = 6;
    uint256 public constant MAX_TOKENS = 9999;
    uint256 public tokenIndex = 0;
    bool public mintIsActive = false;
    bool public presaleIsActive = false;
    mapping (address => bool) public presaleWhitelist;
    string private baseURI;

    constructor() ERC721("SEALz", "SLZ") {}

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function initPresaleWhitelist(address[] memory whitelist) external onlyOwner {
	    for (uint i; i < whitelist.length; i++) {
		    presaleWhitelist[whitelist[i]] = true;
	    }
    }
  
    function reserveTokens() public onlyOwner {
        uint256 mintIndex = tokenIndex;
        uint256 i;
        for (i = 0; i < RESERVED_TOKENS; i++) {
            tokenIndex++;
            _safeMint(msg.sender, mintIndex + i);
        }
    }

    function flipMintState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function flipPresaleState() public onlyOwner {
	    presaleIsActive = !presaleIsActive;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function mintPresale(uint256 numberOfTokens) public payable {
	    require(presaleIsActive, "Presale is not active");
	    require(presaleWhitelist[msg.sender] == true, "You are not on the presale whitelist or have already minted");
	    require(numberOfTokens <= MAX_TOKENS_PRESALE, "You went over max tokens per transaction.");
	    require(totalSupply() + numberOfTokens <= MAX_TOKENS, "Not enough tokens left to mint that many");
	    require(TOKEN_PRICE * numberOfTokens <= msg.value, "You sent the incorrect amount of ETH.");
	    for (uint256 i = 0; i < numberOfTokens; i++) {
		    uint256 mintIndex = tokenIndex;
		    if (totalSupply() < MAX_TOKENS) {
			    tokenIndex++;
			    _safeMint(msg.sender, mintIndex);
		    }
	    }
	    presaleWhitelist[msg.sender] = false;
    }

    function mintSealz(uint256 numberOfTokens) public payable {
        require(!paused(), "Pausable: paused"); // Toggle if pausing should suspend minting
        require(mintIsActive, "Mint is not active.");
        require(numberOfTokens <= MAX_TOKENS_PURCHASE, "You went over max tokens per transaction.");
        require(totalSupply() + numberOfTokens <= MAX_TOKENS, "Not enough tokens left to mint that many");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, "You sent the incorrect amount of ETH.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = tokenIndex;
            if (totalSupply() < MAX_TOKENS) {
                tokenIndex++;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function burn(uint256 tokenId) public virtual {
	    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
	    _burn(tokenId);
    }
}
