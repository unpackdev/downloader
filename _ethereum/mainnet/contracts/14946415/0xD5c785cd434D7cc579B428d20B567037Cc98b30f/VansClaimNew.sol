// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

interface ClaimContract {
    function claimed(uint256 token) view external returns(bool);
}

contract VansClaim is IERC721Receiver, Ownable {
    uint256[60] internal tokenInventory;
    mapping(uint256 => bool) public claimed;
    bool public claimLive;

    IERC721 tokenContract;
    IERC721 dippiesContract;
    ClaimContract vanClaimContract;

    constructor(address dippiesToken, address vanToken, address claimContract) {
        dippiesContract = IERC721(dippiesToken);
        tokenContract = IERC721(vanToken);
        vanClaimContract = ClaimContract(claimContract);
    }

    function hasClaimed(uint256 id) external view returns(bool) {
        return vanClaimContract.claimed(id) || claimed[id];
    }
  
    function _claimableToken() internal view returns (uint256) {
        uint256 inventoryWordIndex;
        uint256 j;
        for (j = 0; j < 60; j++) {
            if (tokenInventory[j] != 0) {
                inventoryWordIndex = j;
                break;
            }
        }
        
        uint256 inventoryBitIndex;
        for (j = 0; j < 256; j++) {
            if ((tokenInventory[inventoryWordIndex] & (1 << j)) != 0) {
                inventoryBitIndex = j;
                break;
            }   
        }
        
        uint256 tokenId = inventoryWordIndex * 256 + inventoryBitIndex;
        return tokenId;
    }

    function claim(uint256[] calldata tokens) external {
        require(msg.sender == tx.origin);
        require(claimLive);
        uint256 tokenLength = tokens.length;

        for (uint256 i = 0; i < tokenLength; i++) {
            if(dippiesContract.ownerOf(tokens[i]) != msg.sender || vanClaimContract.claimed(tokens[i]) || claimed[tokens[i]]) {
                continue;
            }

            uint256 tokenId = _claimableToken();
            tokenContract.transferFrom(address(this), msg.sender, tokenId);
            toggleAvailable(tokenId);
            claimed[tokens[i]] = true;
        }
    }

    function toggleClaim() external onlyOwner {
        claimLive = !claimLive;
    }

    function emergencyClaim(address to, uint256[] calldata tokens) external onlyOwner {
        uint256 tokenLength = tokens.length;
        for (uint256 i = 0; i < tokenLength; i++) {
            tokenContract.transferFrom(address(this), to, tokens[i]);
        }
    }
  
    function toggleAvailable(uint256 tokenId) private {
        uint256 inventoryWordIndex = tokenId / 256;
        uint256 inventoryBitIndex = tokenId % 256;
        tokenInventory[inventoryWordIndex] = tokenInventory[inventoryWordIndex] ^ (1 << inventoryBitIndex);
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
        if(msg.sender == address(tokenContract)) {
            toggleAvailable(tokenId);
        }
      
        return this.onERC721Received.selector;
    }
}