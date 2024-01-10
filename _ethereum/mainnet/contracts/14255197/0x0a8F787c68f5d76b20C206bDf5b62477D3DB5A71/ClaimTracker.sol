// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Bitmaps.sol";
import "./IERC721WithTotalSupply.sol";


/*            _       _           _              
 *  _ __ ___ (_)_ __ (_)_ __ ___ (_)_______ _ __ 
 * | '_ ` _ \| | '_ \| | '_ ` _ \| |_  / _ \ '__|
 * | | | | | | | | | | | | | | | | |/ /  __/ |   
 * |_| |_| |_|_|_| |_|_|_| |_| |_|_/___\___|_|   
 * 
 * @title ClaimTracker
 * @author minimizer <me@minimizer.art>; https://minimizer.art/
 * 
 * Utility contract for claiming. References another contract of which each token 
 * can be claimed once. Uses BitMap for efficient tracking of claimed tokens.
 * 
 * Uses interface "IERC721WithTotalSupply" which is designed for contracts which 
 * have a totalSupply() but may not have implemented the full IERC721Metadata.
 */
contract ClaimTracker {
    
    using BitMaps for BitMaps.BitMap;
    
    address public claimContractAddress;
    BitMaps.BitMap private _claimed;

    constructor(address claimContractAddress_) {
        claimContractAddress = claimContractAddress_;
        
        require( IERC165(claimContractAddress_).supportsInterface(type(IERC721).interfaceId),
                 "Not valid contract" );
        
        require( _contract().totalSupply()>=0 ); //making sure contract supports the totalSupply() method, to be used later
    }
    
    // Returns a global list of all unclaimed tokens. 
    // This method is not gas efficient and should not be called from another contract.
    function allUnclaimedTokens() public view returns (uint[] memory) {
        return _tokensOfClaimStatus(false);
    }
    
    // Returns a global list of all claimed tokens. 
    // This method is not gas efficient and should not be called from another contract.
    function allClaimedTokens() public view returns (uint[] memory) {
        return _tokensOfClaimStatus(true);
    }
    
    // Returns a list of all unclaimed tokens owned by the caller. 
    // This method is not gas efficient and should not be called from another contract.
    function claimableTokens() public view returns (uint[] memory) {
        IERC721WithTotalSupply claimContract = _contract();
        
        uint tokenCount = claimContract.totalSupply();
        uint[] memory initialResult = new uint[](claimContract.balanceOf(msg.sender));
        uint index = 0;
        for (uint i = 0; i < tokenCount; i++) {
            if(claimContract.ownerOf(i) == msg.sender && !_claimed.get(i)) {
                initialResult[index] = i;
                index += 1;
            }
        }
        return _shortenArray(initialResult, index);
    }
    
    // Main method to be used by other contracts. Designed to allow claiming once
    // per token, given the caller is the owner.
    function _claimTokens(uint[] memory tokenIds_) internal {
        IERC721WithTotalSupply claimContract = _contract();
        
        for (uint i = 0; i < tokenIds_.length; i++) {
            uint tokenId = tokenIds_[i];
            require(claimContract.ownerOf(tokenId) == msg.sender, "Token not owned");
            require(!_claimed.get(tokenId), "Token already claimed");
            _claimed.set(tokenId);
        }
    }
    
    
    
    
    function _tokensOfClaimStatus(bool claimedStatus_) private view returns (uint[] memory) {
        uint[] memory initialResult = new uint[](_contract().totalSupply());
        uint index = 0;
        for (uint i = 0; i < initialResult.length; i++) {
            if(_claimed.get(i)==claimedStatus_) {
                initialResult[index] = i;
                index += 1;
            }
        }
        return _shortenArray(initialResult, index);
    }
    
    
    function _shortenArray(uint[] memory currentArray_, uint newLength_) private pure returns (uint[] memory) {
        uint[] memory newArray_ = new uint[](newLength_);
        for (uint i = 0; i < newLength_; i++) {
            newArray_[i] = currentArray_[i];
        }
        return newArray_;
    }
    
    function _contract() private view returns (IERC721WithTotalSupply) {
        return IERC721WithTotalSupply(claimContractAddress);
    }
    
    
    
}