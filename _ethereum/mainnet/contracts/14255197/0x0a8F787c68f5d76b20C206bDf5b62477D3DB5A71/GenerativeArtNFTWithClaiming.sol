// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GenerativeArtNFT.sol";
import "./ClaimTracker.sol";

/*            _       _           _              
 *  _ __ ___ (_)_ __ (_)_ __ ___ (_)_______ _ __ 
 * | '_ ` _ \| | '_ \| | '_ ` _ \| |_  / _ \ '__|
 * | | | | | | | | | | | | | | | | |/ /  __/ |   
 * |_| |_| |_|_|_| |_|_|_| |_| |_|_/___\___|_|   
 * 
 * @title GenerativeArtNFT
 * @author minimizer <me@minimizer.art>; https://minimizer.art/
 * 
 * Extention of GenerativeArtNFT which implements claiming. References another 
 * contract and allows each token held of that contract to be used to mint 
 * one token of this contract.
 * 
 * As a deployment safety check, constructor requires both the address 
 * and symbol of the claim contract. If they don't match, the constructor fails.
 */
contract GenerativeArtNFTWithClaiming is GenerativeArtNFT, ClaimTracker  {
    
    bool public isClaimingActive = false;
    
    constructor(string memory name_, string memory symbol_, string memory initialWeb2BaseURI_, uint maxSupply_, 
                uint maxMintAtOnce_, uint numberToPremint_, uint initialPrice_,uint96 royaltyBasisPoints_,
                address claimContractAddress_, string memory claimContractSymbol_) 
    
    GenerativeArtNFT(name_, symbol_, initialWeb2BaseURI_, maxSupply_, 
                     maxMintAtOnce_, numberToPremint_, initialPrice_, royaltyBasisPoints_)
    ClaimTracker(claimContractAddress_) {
        
        require( keccak256(bytes(claimContractSymbol())) == keccak256(bytes(claimContractSymbol_)) , 
                 "Address/symbol mismatch" );
    }
    
    // Owner can activate claiming. 
    function setClaimingActive(bool isClaimingActive_) public onlyOwner onlyWhenNotFrozen {
        isClaimingActive = isClaimingActive_;
    }
    
    // Anyone can mint using claim tokens which they own once, provided claiming
    // is active and supply remains.
    function claimMintTokens(uint[] memory tokenIds_) public {
        require(isClaimingActive, "Claiming inactive");
        _claimTokens(tokenIds_);
        _mintTokens(tokenIds_.length);
    }
    
    // Convenience providing the name of the claim contract
    function claimContractName() public view returns (string memory) {
        return ERC721(claimContractAddress).name();
    }
    
    // Convenience providing the symbol of the claim contract
    function claimContractSymbol() public view returns (string memory) {
        return ERC721(claimContractAddress).symbol();
    }
    
    // Requires claiming to be deactivated in addition to other criteria 
    // specified in the superclass
    function freeze(string memory confirmation_) public override /*onlyOwner: checked in super class*/ { 
        require(!isClaimingActive, "Claiming active");
        super.freeze(confirmation_);
    }
}