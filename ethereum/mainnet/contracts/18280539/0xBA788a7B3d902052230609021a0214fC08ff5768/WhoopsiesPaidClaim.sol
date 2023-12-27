// SPDX-License-Identifier: MIT

/// @title ERC721 Implementation of Whoopsies v2 Collection
pragma solidity ^0.8.21;

import "./IERC721.sol";
import "./IWhoopsiesV2.sol";
import "./Ownable.sol";

/// @custom:security-contact captainunknown7@gmail.com
contract WhoopsiesPaidClaim is Ownable {
    address constant whoopsiesv1 = 0x565AbC3FEaa3bC3820B83620f4BbF16B5c4D47a3;
    address constant whoopsiesv2 = 0x646Eb9B8E6bED62c0e46b67f3EfdEF926Fb9D621;
    uint96 public claimPriceFlatFee;
    uint96 public claimPricePerTokenFee;
    bool public isClaimable;

    error InsufficientPayment();
    error ClaimsNotOpen();

    constructor() {
        isClaimable = false;
        _initializeOwner(msg.sender);
    }

    function claimV2NFTs(uint256[] calldata requestedTokenIds) public payable {
        if(!isClaimable) revert ClaimsNotOpen();
        unchecked {
            if(msg.value < (claimPriceFlatFee + (claimPricePerTokenFee * requestedTokenIds.length))) revert InsufficientPayment();    
        }

        // Transfer v1 tokens to contract for claim
        for (uint256 i; i < requestedTokenIds.length;) {
            IERC721(whoopsiesv1).transferFrom(msg.sender, address(this), requestedTokenIds[i]);
            unchecked {
                i++;
            }
        }

        // Claim v2
        IWhoopsiesV2(whoopsiesv2).toggleV2ClaimActive();
        IWhoopsiesV2(whoopsiesv2).claimV2NFTs(requestedTokenIds);
        IWhoopsiesV2(whoopsiesv2).toggleV2ClaimActive();

        // Send v2 to caller
        for (uint256 i; i < requestedTokenIds.length;) {
            IERC721(whoopsiesv2).transferFrom(address(this), msg.sender, requestedTokenIds[i]);
            unchecked {
                i++;
            }
        }
    }

    function toggleIsClaimable() public onlyOwner {
        isClaimable = !isClaimable;
    }

    function setClaimPrice(uint96 newClaimFlatFee, uint96 newClaimPerTokenFee) public onlyOwner {
        claimPriceFlatFee = newClaimFlatFee;
        claimPricePerTokenFee = newClaimPerTokenFee;
    }

    function reclaimWhoopsiesOwnership() public onlyOwner {
        Ownable(whoopsiesv2).transferOwnership(msg.sender);
    }

    function withdrawETH() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external view returns(bytes4) {
        if(msg.sender == whoopsiesv2) return 0x150b7a02;
        return 0x00000000;
    }
}