// SPDX-License-Identifier: MIT

// mfer avatars by heresmy.eth

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";

contract MferAvatars is ERC721, Ownable {

    // Constructor to initialize the ERC721 token with a name and symbol
    constructor() ERC721("mfer avatars", "mferavatars") {}

    // Address of the original token contract
    address ogMfersContract = 0x79FCDEF22feeD20eDDacbB2587640e45491b757f;
    
    // Address to which funds will be withdrawn
    address public paymentAddress = 0x2119ff364fbF1Ae11688f781104caADa673D0194;

    // Metadata properties
    string private _metadataBaseURI;
    string private _metadataExtension;

    // Cost to mint a token
    uint public cost = 0.069 ether;

    // Maximum supply of OG tokens
    uint private _maxSupply = 10021;

    // Current supply counter OG tokens
    uint256 private _currentSupply = 0;

    // Array to store minted token IDs
    uint256[] private _mintedTokens;

    // Flag to check if minting is enabled
    bool public mintingEnabled = false;

    // Event to be emitted when minting cost is updated
    event MintingCostUpdated(uint newCost);

    // functions to mint a new token
    function safeMint(uint256 tokenId) payable public {
        _mint(tokenId, msg.value, false);
    }

    function ownerMint(uint256 tokenId) public onlyOwner {
        _mint(tokenId, 0, true);
    }

    function bulkSafeMint(uint256[] memory tokenIds) payable public {
        uint256 totalCost = cost * tokenIds.length;
        require(mintingEnabled, "Minting is currently disabled");
        require(msg.value >= totalCost, string(abi.encodePacked("Total cost is ", Strings.toString(totalCost))));

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(tokenIds[i], msg.value, false);
        }
    }

    function bulkOwnerMint(uint256[] memory tokenIds) public onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(tokenIds[i], 0, true);
        }
    }

    function _mint(uint256 tokenId, uint256 value, bool owner) internal {
        require(mintingEnabled || owner == true, "Minting is currently disabled");
        require(!_exists(tokenId), "Token already minted");
        require(value >= cost || owner == true, string(abi.encodePacked("Price is ", Strings.toString(cost))));
        require(tokenId < _maxSupply, "Token ID exceeds maximum OG supply");

        // The avatar token is minted to the wallet holding the OG mfer token
        address mferOwner = ownerOfMfer(tokenId);
        _safeMint(mferOwner, tokenId);
        _currentSupply += 1; 
        _mintedTokens.push(tokenId);
    }

    // Function to get the owner of a token from the original contract
    function ownerOfMfer(uint256 tokenId) public view returns (address) {
        return IERC721(ogMfersContract).ownerOf(tokenId);
    }

    // Internal function to get the base URI for metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return _metadataBaseURI;
    }

    // Function to get the full URI for a token's metadata
    function tokenURI(uint256 token) public view override(ERC721) returns(string memory) {
        return string(abi.encodePacked(_metadataBaseURI, Strings.toString(token), _metadataExtension));
    }

    // Function to get the list of minted token IDs
    function getMintedTokens() public view returns (uint256[] memory) {
        return _mintedTokens;
    }

     // Function to get the maximum supply of tokens
    function maxSupply() public view returns(uint256) {
        return _maxSupply;
    }

    // Function to get the total supply of tokens
    function totalSupply() public view returns(uint256) {
        return _currentSupply;
    }

    /* Owner functions */

    // Owner only function to toggle minting on or off
    function toggleMinting() public onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

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
}