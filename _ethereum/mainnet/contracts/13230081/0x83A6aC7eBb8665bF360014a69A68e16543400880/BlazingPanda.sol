// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./IERC721.sol";

/**
 * @title BlazingPanda contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract BlazingPanda is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint public constant MAX_TOKEN_PURCHASE = 10;
    uint public constant TOKEN_PRICE = 0.05 ether;
    bool saleIsActive = false;

    uint public maxTokenSupply = 15625;
    uint internal reservedTokens;
    uint internal mintedTokens ;
    string public baseURI;

    IERC721 immutable internal LootAvatar;
    constructor(address _lootavatar) 
            ERC721("BLAZING PANDA", "BPANDA") {
            LootAvatar = IERC721(_lootavatar) ;
    }

    /**
    * Set Base URI
    */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * Set some tokens aside
     */
    function reserveTokens(uint numTokens) public onlyOwner {
        require(numTokens > 0, "numTokens was not given");
        // require ( tokenId > 15000 && tokenId < 15626 , "Token ID invalid" ) ;
        require(reservedTokens.add(numTokens) <= maxTokenSupply, "Reserving numTokens would exceed max supply of tokens");

        // reserve tokens
        uint supply = reservedTokens.add(15000);
        uint i;
        for (i = 1; i <= numTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
        reservedTokens = reservedTokens.add(numTokens);
    }

    /**
     * Activate or deactivate the sale
     */
    function activateSale(bool active) public onlyOwner {
        if (active) {
            bytes memory tempString = bytes(baseURI);
            require(tempString.length != 0, "baseURI has not been set");
        }
        
        saleIsActive = active;
    }

    function LootClaim(uint256 tokenId) public {
        require(saleIsActive, "Sale is not active");
        require ( tokenId > 0 && tokenId < 8001 , "Token ID invalid" ) ;
        require ( LootAvatar.ownerOf(tokenId) == msg.sender , "Owner invalid" ) ;
        require ( ! _exists(tokenId) , "Token ID exists") ;
        _safeMint(msg.sender, tokenId );
    }

    /**
    * Mint Tokens
    */
    function mintTokens(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active");
        // require ( tokenId > 8000 && tokenId < 15001 , "Token ID invalid" ) ;
        require(numberOfTokens <= MAX_TOKEN_PURCHASE, "numberOfTokens exceeds maximum per tx");
        require(mintedTokens.add(numberOfTokens) <= 15000, "Purchase would exceed max supply of tokens");
        require(TOKEN_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        uint i;
        uint supply = mintedTokens.add(8000) ;
        for(i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
        mintedTokens = mintedTokens.add(numberOfTokens) ;
    }

    /**
     * Get the metadata for a given tokenId
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, Strings.toString(tokenId)))
            : "";
    }

    /**
     * Get current balance of contract (Owner only)
     */
    function getBalance() public view onlyOwner returns (uint)  {
        uint balance = address(this).balance;
        return balance;
    }

    /**
     * Withdraw all funds from contract (Owner only)
     */
    function withdrawFunds() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}