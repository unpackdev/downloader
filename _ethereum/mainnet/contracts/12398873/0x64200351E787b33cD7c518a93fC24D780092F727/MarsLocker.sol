// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Holder.sol";
import "./IERC721Receiver.sol";
import "./ERC165.sol";


import "./Mars.sol";

/**
 * MarsLocker Contract
 * @dev Locks Mars NFTs until a certain timestamp is reached. 
 */
contract MarsLocker is Ownable, IERC721Receiver, ERC165, ERC721Holder {
    using SafeMath for uint256;

    uint256 private _releaseTimestamp;
    
    Mars private _mars;

    /**
     * @dev Sets immutable values of contract.
     */
    constructor (
        uint256 releaseTimestamp_
    ) {
        _releaseTimestamp = releaseTimestamp_;
    }

    function releaseTimestamp() public view returns (uint256) {
        return _releaseTimestamp;
    }

    function marsAddress() public view returns (address) {
        return address(_mars);
    }

    /**
     * @dev Sets Mars contract address. Can only be called once by owner.
     */
    function setMarsAddress(address payable marsAddress_) public onlyOwner {
        require(address(_mars) == address(0), "Already set");
        
        _mars = Mars(marsAddress_);
    }

    function release(address to, uint256 numOfNFTs) public onlyOwner {
        require(_mars.balanceOf(address(this)) >= numOfNFTs, "Release amount exceeds balance of Locker");
        require(block.timestamp >= _releaseTimestamp, "Release timestamp not reached");

        for (uint j = 0; j < numOfNFTs; j++) {
            uint tokenId = _mars.tokenOfOwnerByIndex(address(this), j);
            _mars.safeTransferFrom(address(this), to, tokenId);
        }
    }
}