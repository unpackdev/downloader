// SPDX-License-Identifier: MIT

// mfer avatars: customs
// by heresmy.eth

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";

contract MferAvatarsCustoms is ERC721, Ownable {

    // Constructor to initialize the ERC721 token with a name and symbol
    constructor() ERC721("mfer avatars customs", "mferavatarscustoms") {}
    
    // Address to which funds will be withdrawn
    address public paymentAddress;

    // Metadata properties
    string private _metadataBaseURI;
    string private _metadataExtension;

    // Cost to mint a token
    uint public cost;

    // Current supply counter OG tokens
    uint256 private _currentSupply = 0;

    // Flag to check if minting is enabled
    bool public mintingEnabled = false;

    // Event to be emitted when minting cost is updated
    event MintingCostUpdated(uint newCost);

    // Public function to mint a new token
    function safeMint(address to) public payable onlyOwner {
        require(mintingEnabled, "Minting is currently disabled");
        require(msg.value >= cost, string(abi.encodePacked("Price is ", Strings.toString(cost))));
        
        _safeMint(to, _currentSupply);
        _currentSupply += 1; 
    }

    // Owner only function to mint a new token
    function ownerMint(address to) public onlyOwner {        
        _safeMint(to, _currentSupply);
        _currentSupply += 1; 
    }

    // Internal function to get the base URI for metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return _metadataBaseURI;
    }

    // Function to get the full URI for a token's metadata
    function tokenURI(uint256 token) public view override(ERC721) returns(string memory) {
        return string(abi.encodePacked(_metadataBaseURI, Strings.toString(token), _metadataExtension));
    }

    // Function to get the total supply of tokens
    function totalSupply() public view returns(uint256) {
        return _currentSupply;
    }

    /* Owner functions */

    // Owner only function to set the payment address
    function setPaymentAddresses(address payment) public onlyOwner {
        paymentAddress = payment;
    }

    // Owner only function to withdraw all funds from the contract
    function withdraw() public onlyOwner {
        (bool sent,) = payable(paymentAddress).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    // Owner only function to set the base URI for metadata
    function setMetadataBaseURI(string memory uri) public onlyOwner {
        _metadataBaseURI = uri;
    }

    // Owner only function to set the metadata extension
    function setMetadataExtenstion(string memory extension) public onlyOwner {
        _metadataExtension = extension;
    }

    // Owner only function to set the cost to mint a token
    function setMintingCost(uint newCost) public onlyOwner {
        cost = newCost;
        emit MintingCostUpdated(newCost);
    }

    // Owner only function to toggle minting on or off
    function toggleMinting() public onlyOwner {
        mintingEnabled = !mintingEnabled;
    }
}