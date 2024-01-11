/*
 ____  ____  ____  ____ ___  _      _  ____  ________  _
/   _\/  __\/  _ \/_   \\  \//     / |/  _ \/  __/\  \//
|  /  |  \/|| / \| /   / \  /      | || / \||  \   \  / 
|  \__|    /| |-||/   /_ / /    /\_| || \_/||  /_  / /  
\____/\_/\_\\_/ \|\____//_/     \____/\____/\____\/_/  
*/

// SPDX-License-Identifier: MIT                                                        
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

contract CrazyJoey is ERC721Enumerable, Ownable {
    using SafeMath for uint256;     
    using Counters for Counters.Counter;
    
    // Issuer of Token IDs
    Counters.Counter private _tokenIds;
    
    uint public constant MAX_SUPPLY = 5005;
    uint public constant MAX_PER_MINT = 10;
    uint public constant PRICE = 0.046 ether;

    // IPFS root
    string public baseTokenURI;
    // Reserved NFT's for the CZ Team
    uint public teamReserve = 250; 
    // Once metadata is frozen, the IPFS root cannot be updated by the contract owner 
    bool public isMetadataFrozen = false;  
    // Is sale active
    bool public isSaleActive = false;      

    constructor(string memory baseURI) ERC721("CrazyJoey", "CZ") {
        setBaseURI(baseURI);
    }        

    function mint (uint count) public payable {
        uint totalMinted = _tokenIds.current();
        
        require(isSaleActive, "Sale is not ACTIVE");
        require(totalMinted.add(count) <= MAX_SUPPLY.sub(teamReserve), "Not enough NFTs");
        require(count > 0 && count <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(msg.value >= PRICE.mul(count), "Not enough ether to purchase NFTs.");
        
        for (uint i = 0; i < count; i++) {
            _mintSingleNFT();
        }
    }

    function _mintSingleNFT() private {
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }

    /* -- Overrides -- */

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /* -- OnlyOwner --*/
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        require(!isMetadataFrozen, "Metadata is frozen");
        baseTokenURI = _baseTokenURI;
    }  

    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function freezeMetadata() public onlyOwner {
        isMetadataFrozen = true;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function reserve(uint256 _reserveAmount) public onlyOwner {
        // reserving should not exceed max supply
        require(_tokenIds.current().add(_reserveAmount) < MAX_SUPPLY, "Not enough NFTs");

        // reserving should not exceed team's reserves
        require(
            _reserveAmount > 0 && _reserveAmount <= teamReserve,
            "Not enough reserve left for team"
        );

        for (uint256 i = 0; i < _reserveAmount; i++) {
            _mintSingleNFT();
        }

        teamReserve = teamReserve.sub(_reserveAmount);
    }
}