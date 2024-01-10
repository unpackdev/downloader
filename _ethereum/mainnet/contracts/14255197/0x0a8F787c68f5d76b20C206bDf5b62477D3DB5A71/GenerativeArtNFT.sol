// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Freezable.sol";
import "./HTML5AndJavascriptCodeGenerator.sol";

/*            _       _           _              
 *  _ __ ___ (_)_ __ (_)_ __ ___ (_)_______ _ __ 
 * | '_ ` _ \| | '_ \| | '_ ` _ \| |_  / _ \ '__|
 * | | | | | | | | | | | | | | | | |/ /  __/ |   
 * |_| |_| |_|_|_| |_|_|_| |_| |_|_/___\___|_|   
 * 
 * @title GenerativeArtNFT
 * @author minimizer <me@minimizer.art>; https://minimizer.art/
 * 
 * Generic smart contract intended to allow for high-quality implementation of 
 * generative art NFT based on pure JavaScript/HTML5 Canvas. This contract can 
 * create a self-contained HTML file with all included artwork code. 
 * 
 * Key features:
 *  - Contract initializes with a pre-determined supply and number of 
 *    tokens to pre-mint.
 *  - Owner can set price, max tokens to mint at once and whether sale is active.
 *  - Generates a unique hash for each mint, which the art uses to source entropy. 
 *    This hash is based on the contract address, token id as well as the minter's
 *    address and block number.
 *  - The artwork's code is saved on the contract.
 *  - Full art rendering code (HTML+JavaScript) for each token can be generated.
 *  - Owner can freeze contract, after which the artwork or URIs are immutable.
 *  - Contract implements simple version of ERC-2981 with one royalty percentage
 *    for all tokens.
 *  - Owner can reduce supply of tokens available to be minted.
 *  - Gas optimization: token creation block number and token creation address 
 *    are stored in such a way to save on gas costs:
 *      1) Since sequential tokens minted in the same transaction will share the 
 *         block number, it is only saved for the first one. Higher numbered 
 *         tokens will look back until they find a saved one.
 *      2) The minter's address will be the same as the owner's address until
 *         the token is transfered. Therefore it is not saved at mint time, 
 *         but rather only at the time of the first transfer.
 *         
 * Earlier version of this contract, designed for use with p5js or similar 
 * libraries, is deployed to mainnet for Waves 
 * (contract 0x46f1c444a9b10173c52ee7351eBa1e49C8bC5851).
 */
contract GenerativeArtNFT is IERC2981, ERC721, Ownable, Freezable {
    
    using SafeMath for uint;
    using Strings for uint;
    using Strings for bytes;
    
    //to save gas, block numbers are only stored for the first of a series of mints
    mapping (uint => uint) private _tokenCreationBlockNumbers;
    //to save gas, the minter's address is only stored the first time token is transferred
    mapping (uint => address) private _tokenCreationAddresses;
    
    string public baseURI;
    string public renderingCode;
    uint public totalSupply = 0;
    uint public maxSupply;
    uint public maxMintAtOnce;
    uint public price = 0;
    bool public isSaleActive = false;
    
    uint96 private _royaltyBasisPoints;

    constructor(string memory name_, string memory symbol_, string memory baseURI_, uint maxSupply_, 
                uint maxMintAtOnce_, uint numberToPremint_, uint initialPrice_, uint96 royaltyBasisPoints_) 
    ERC721(name_, symbol_) {
        setBaseURI(baseURI_);
        maxSupply = maxSupply_;
        maxMintAtOnce = maxMintAtOnce_;
        
        mintTokens(numberToPremint_);
        price = initialPrice_;
        
        setRoyaltyInBasisPoints(royaltyBasisPoints_);
    }
    
    // Provide the hash of the token id. This runs the keccak256 hashing algorithm over contract
    // address, block number of mint, address of minter, and token id to produce a unique value.
    function tokenHash(uint tokenId_) public view returns(bytes32) {
        require(tokenId_ < totalSupply, "Invalid token");
        return bytes32(keccak256(abi.encodePacked(address(this), 
                                                  tokenCreationBlockNumbers(tokenId_), 
                                                  tokenCreationAddresses(tokenId_), 
                                                  tokenId_)));
    }
    
    // Block number of when the token was minted. Multiple tokens minted together
    // will share a block number, which is only stored once for the first token.
    // The logic will look backwards to find the appropriate value.
    function tokenCreationBlockNumbers(uint tokenId_) public view returns(uint) {
        for(uint i = tokenId_; i>0; i--) {
            if(_tokenCreationBlockNumbers[i]>0) {
                return _tokenCreationBlockNumbers[i];
            }
        }
        return _tokenCreationBlockNumbers[0];
    }
    
    // Minter's address. Since this matches the owner's address up until when 
    // the token is transferred, at the time of the first transfer the owner's
    // address will be saved as the minter. 
    function tokenCreationAddresses(uint tokenId_) public view returns(address) {
        address savedAddress = _tokenCreationAddresses[tokenId_];
        return savedAddress != address(0) ? savedAddress : ownerOf(tokenId_);
    }
    
    // Mint the specified number of tokens to the caller. Sale must be active, 
    // and number of tokens must be less than max mint at once as well as 
    // remaining supply. Exact payment required.
    // Owner can mint more than the max mint at once and while the sale is not active.
    // Owner (or anyone else) cannot exceed max supply.
    function mintTokens(uint numTokens_) public payable {
        require(msg.sender == owner() || numTokens_ > 0, "Invalid num tokens");
        require(msg.sender == owner() || numTokens_ <= maxMintAtOnce, "Exceeds max mint");
        require(msg.sender == owner() || isSaleActive, "Sale inactive");
        
        require(msg.value == numTokens_.mul(price), "Incorrect payment");
        
        _mintTokens(numTokens_);
    }
    
    // Internal mint method can be used by derived classes.
    function _mintTokens(uint numTokens_) internal {
        require(totalSupply + numTokens_ <= maxSupply, "Exceeds supply");
        
        // Store this once for all the mints.
        // When looking up later we will work our way back to it.
        _tokenCreationBlockNumbers[totalSupply] = block.number;
        
        for(uint i = 0; i < numTokens_; i++) {
            _safeMint(msg.sender, totalSupply);
            totalSupply = totalSupply + 1;
        }
    }
    
    // Convenience method, allowing access to all tokens of a given address.
    // Not gas efficient, not for use from other contracts
    function tokensOfOwner(address owner_) external view returns(uint[] memory ) {
        uint tokenCount = balanceOf(owner_);
        uint[] memory result = new uint[](tokenCount);
        uint index = 0;
        for (uint i = 0; i < totalSupply; i++) {
            if(ownerOf(i) == owner_) {
                result[index] = i;
                index += 1;
            }
        }
        return result;
    }
    
    // Owner can set how many tokens can be minted at once. Only relevant when supply remains.
    function setMaxMintAtOnce(uint maxMintAtOnce_) public onlyOwner {
        maxMintAtOnce = maxMintAtOnce_;
    }
    
    // Owner can activate the sale. Only relevant when supply remains.
    function setSaleActive(bool isSaleActive_) public onlyOwner onlyWhenNotFrozen {
        isSaleActive = isSaleActive_;
    }
    
    // Owner can set the price of future mints.
    function setPrice(uint price_) public onlyOwner {
        price = price_;
    }
    
    // Owner can set the max supply, only to reduce. 
    // This must be a number lower than current max supply 
    // and larger than or equal to current supply
    function setMaxSupply(uint maxSupply_) public onlyOwner {
        require(maxSupply_ < maxSupply && maxSupply_ >= totalSupply, "Invalid max supply");
        maxSupply = maxSupply_;
    }
    
    // Owner can store rendering code (in javascript) which will be persisted forever to re-produce the art
    // Once contract is frozen this can no longer be changed.
    function setRenderingCode(string memory renderingCode_) public onlyOwner onlyWhenNotFrozen {
        renderingCode = renderingCode_;
    }
    
    // Owner can set the base URI
    // Once contract is frozen this can no longer be changed.
    function setBaseURI(string memory baseURI_) public onlyOwner onlyWhenNotFrozen { 
        baseURI = baseURI_;
    }
    
    // Set the royalty amount, specified in basis points
    // All tokens have the same royalty amount
    // Used by ERC-2981 implementation
    // Royalty info can be changed after the contract is frozen
    function setRoyaltyInBasisPoints(uint96 royaltyBasisPoints_) public onlyOwner { 
        _royaltyBasisPoints = royaltyBasisPoints_;
    }
    
    
    // Implementation of royaltyInfo for ERC-2981
    function royaltyInfo(uint256, uint256 salePrice_) external view override returns (address, uint256) {
        return (owner(), (salePrice_ * _royaltyBasisPoints) / 10000);
    }
    
    // Owner can transfer accumulated funds from contract.
    function withdrawAll() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    // Owner can freeze the contract, subsequently specified fields are immutable.
    function freeze(string memory confirmation_) public virtual onlyOwner {
        require(!isSaleActive, "Sale active");
        require(keccak256(bytes(confirmation_)) == keccak256(bytes("confirmed to freeze")), 'Invalid confirmation');
        _freeze();
    }
    
    
    // Retrieve the rendering code in plain text, for a given token, by combining the token id 
    // and hash with the rendering code. This assumes the language is javascript.
    function renderingCodeForToken(uint tokenId_) public view returns (string memory) {
        return HTML5AndJavascriptCodeGenerator.fullRenderingCode(name(), tokenId_, tokenHash(tokenId_), renderingCode);
    }
    
    // Similar to the above plain-text version, this retrieves the rendering code in Base64 encoding. This is 
    // useful in cases where the encoding is required or helpful for transmission.
    function renderingCodeForTokenInBase64(uint tokenId_) public view returns (string memory) {
        return HTML5AndJavascriptCodeGenerator.fullRenderingCodeInBase64(name(), tokenId_, tokenHash(tokenId_), renderingCode);
    }
    
    // Retrieve the URI which provides the metadata for this token. This is the standard ERC-721 interface
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Contract supports ERC-721 and ERC-2981
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId) || type(IERC2981).interfaceId == interfaceId;
    }
    
    
    // Using the ERC-721 hook to save the owner as the original minter and preserve
    // the entropy details
    function _beforeTokenTransfer(address from_, address /*to is unused*/, uint256 tokenId_) internal virtual override {
        //if there is currently no minter address, the current owner is the minter
        //we need to remember that so the hash doesn't change so let's store it
        if(_tokenCreationAddresses[tokenId_]==address(0) && from_ != address(0)) {
            _tokenCreationAddresses[tokenId_] = from_;
        }
    }
    
}