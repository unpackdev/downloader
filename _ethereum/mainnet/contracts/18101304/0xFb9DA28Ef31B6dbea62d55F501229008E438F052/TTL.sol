// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract TTL is ERC721, Ownable {
    using SafeMath for uint256;

    error TransferBeforeTimeLock(
        uint256 unlockTimestamp,
        uint256 timeRemaining
    );

    // Base URI
    string private _baseTokenURI;

    // Mapping from token ID to unlock timestamp
    mapping(uint256 => uint256) private _unlockTimestamps;
    mapping(uint256 => bool) private _isSold;

    constructor(string memory baseURI) ERC721("TTL", "TTL") {
        // Mint and time-lock the NFTs
        for (uint256 i = 1; i <= 3; i++) {
            uint256 timeMultiplier = (2 ** i) * 100; // 200, 400, 800
            _mint(msg.sender, i);
            _unlockTimestamps[i] = block.timestamp.add(
                timeMultiplier.mul(365 days)
            );
            _isSold[i] = false;
        }

        // Set the NFT base URI
        _baseTokenURI = baseURI;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
       
        if (_isSold[tokenId] == true && block.timestamp < _unlockTimestamps[tokenId]) {
            uint256 timeRemaining = _unlockTimestamps[tokenId].sub(
                block.timestamp
            );
            revert TransferBeforeTimeLock(
                _unlockTimestamps[tokenId],
                timeRemaining
            );
        }

        if (_isSold[tokenId] == false) {
            _isSold[tokenId] = true;
        }

        // Call parent function
        super._transfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Function to update base URI, only accessible by contract owner
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }
}
