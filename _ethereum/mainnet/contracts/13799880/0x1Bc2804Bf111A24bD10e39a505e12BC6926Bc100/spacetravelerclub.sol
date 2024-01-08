// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract SpaceTravelerClub is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    bool salesActive = false;
    bool presale = true;
    bool contractLocked = false;
    string public assetUri = "ipfs://QmP2qLLMaRyQSFcDCopExmRApQA5x6w2Qp7hMPAW6rVCMw/";
    uint256 amountMinted = 0;
    uint256 whitelistPrice = 60000000000000000;
    uint256 publicPrice = 70000000000000000;
    mapping (address => bool) whitelisted;

    constructor() ERC721("Space Traveler Club", "STC") {
        _tokenIdCounter.increment(); // Make sure we start at one

  
    }

    function lockContract() public onlyOwner {
        contractLocked = true;
    }

    function revealAssets(string calldata newUri) public onlyOwner {
        require(!contractLocked, "The contract is locked and therefore the asset URL is now immutable.");
        assetUri = newUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return assetUri;
    }

    // ========================================= WHITELIST FUNCTIONS
    // Add multiple addresses in the whitelist
    function addWhitelist(address[] calldata whitelistedAddress) public onlyOwner {
        for(uint256 i = 0; i < whitelistedAddress.length; i++) {
            whitelisted[whitelistedAddress[i]] = true;
        }
    }

    // Toggle access to the whitelist for a specific address
    function toggleWhitelisted(address whitelistedAddress) public onlyOwner {
        whitelisted[whitelistedAddress] = !whitelisted[whitelistedAddress];
    }

    // Allow checking to see if a specific address is whitelisted
    function isWhitelisted(address whitelistedAddress) view public returns(bool) {
        return whitelisted[whitelistedAddress];
    }

    // ========================================= MAIN FUNCTIONS 
    function toggleSales() public onlyOwner {
        salesActive = !salesActive;
    }

    function togglePresale() public onlyOwner {
        presale = !presale;
    }

    // Allow getting the price
    function getPrice() public view returns(uint256) {
        if(presale) return whitelistPrice; 
        else return publicPrice;
    }

    // Allow seeing how much mint have been done 
    function getMinted() public view returns(uint256) {
        return amountMinted;
    }

    // Allow minting from the reserve
    function mintReserve(address to, uint256 amount) public onlyOwner {
        require(amount + amountMinted <= 27, "You can't take more from the team reserve");

        for(uint256 i = 0; i < amount; i++) {
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
            amountMinted++;
        }
    }

    // Allow minting
    function safeMint(uint256 amount) public payable {
        require(salesActive, "Sales are not open yet");
        require(amount <= 5, "You can't take more than 5 in one transaction");
        require(amount + amountMinted <= 9999, "There is no more space in the club!");

        if(presale) { 
            require(whitelisted[msg.sender] == true, "You are not in the whitelist");
            require(msg.value >= whitelistPrice.mul(amount),"Not enough money");
        } else require(msg.value >= publicPrice.mul(amount),"Not enough money");

        for(uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
            amountMinted++;
        }
    }

    // Withdraw funds from the contract
    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}