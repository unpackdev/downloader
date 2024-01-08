// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./Math.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

/**
 * @title MetavotG2
 * https://metavots.com/
 */
contract MetavotG2 is ERC721Tradable, ReentrancyGuard {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Metavot G2", "MTVT2", _proxyRegistryAddress)
    {}

    uint256 public constant MINT_BATCH_SIZE = 5;
    uint256 public constant TRANSFER_BATCH_SIZE = 10;

    // Token ID counts. Indexes start at 1.
    uint256 public constant N_PREMINT = 101;
    uint256 public constant N_BOT = 10000;
    uint256 public constant N_TOTAL = N_PREMINT + N_BOT;
    bool public hasPreminted = false;
    uint256 public basePrice = 1e16;  // 0.01

    // Random indexing
    uint256 internal nonce = 0;
    uint256[N_BOT] internal indices;

    function tokenURI(uint256 tokenId)
        public
        pure
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "https://item.metavots.com/gen2/meta/",
                    Strings.toString(tokenId)
                )
            );
    }

    function ownerPremint() public nonReentrant onlyOwner {
        for (uint i = 1; i <= N_PREMINT; i++) {
            _safeMint(owner(), i);
        }
        hasPreminted = true;
    }

    function takeBalance() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function sendBalanceTo(address to) public payable onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    function numBought() public view returns (uint256) {
        return totalSupply() - (hasPreminted ? N_PREMINT : 0);
    }

    // https://etherscan.io/address/0x7bd29408f11d2bfc23c34f18275bbf23bb716bc7#code
    function randomBotIndex() private returns (uint256) {
        uint256 totalSize = N_BOT - numBought();
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    nonce,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % totalSize;
        uint256 value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            // Array position not initialized, so use position
            indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            indices[index] = indices[totalSize - 1];
        }
        nonce++;
        // Don't allow a zero index, start counting at N_PREMINT + 1
        return value + N_PREMINT + 1;
    }

    function setBasePrice(uint256 _basePrice) public onlyOwner {
        require(_basePrice >= 0);
        basePrice = _basePrice;
    }

    // Get the price in wei with early bird discount.
    function getPrice() public view returns (uint256) {
        uint256 numMinted = numBought();
        if (numMinted < 1000) {
            return 2 * basePrice;
        } else if (numMinted < 2000) {
            return 5 * basePrice;
        } else if (numMinted < 5000) {
            return 8 * basePrice;
        } else if (numMinted < 7500) {
            return 10 * basePrice;
        } else {
            return 15 * basePrice;
        }
    }

    function canMint(uint256 numToMint) public view returns (bool) {
        require(numToMint <= MINT_BATCH_SIZE, "numToMint exceeds MINT_BATCH_SIZE.");
        return totalSupply() + numToMint <= N_TOTAL;
    }

    function ownerMint(uint256 numToMint) public onlyOwner returns (uint[] memory) {
        require(canMint(numToMint), "Token limit reached.");
        uint[] memory ids = new uint[](numToMint);
		for (uint256 i = 0; i < numToMint; i++) {
			ids[i] = _mintRandomBot(_msgSender());
        }
        return ids;
    }

    function publicMint(uint256 numToMint) public payable nonReentrant returns (uint[] memory) {
        require(canMint(numToMint), "Token limit reached.");
        uint256 price = getPrice() * numToMint;
        require(msg.value >= price, "Insufficient payment.");
        // send back change to sender if necessary.
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
        uint[] memory ids = new uint[](numToMint);
		for (uint256 i = 0; i < numToMint; i++) {
			ids[i] = _mintRandomBot(_msgSender());
        }
        return ids;
    }

    function _mintRandomBot(address to) private returns (uint) {
        require(totalSupply() < N_TOTAL, "Token limit reached.");
        uint id = randomBotIndex();
        require(id > 0, "Token ID must be greater than 0");
        _safeMint(to, id);
        return id;
    }

    // Batch transfer up to 100 tokenIds.  Input must be sorted and deduped.
    function safeTransferFromBatch(address from, address to, uint256[] memory sortedAndDedupedTokenIds) public nonReentrant {
        uint length = sortedAndDedupedTokenIds.length;
        require(length <= TRANSFER_BATCH_SIZE, "Exceeded batch size.");
        uint lastTokenId = 0; 
        for (uint i=0; i<length; i++) {
            require(i == 0 || (sortedAndDedupedTokenIds[i] > lastTokenId), "Token IDs must be sorted and deduped.");
            lastTokenId = sortedAndDedupedTokenIds[i];
            safeTransferFrom(from, to, sortedAndDedupedTokenIds[i]);
        }
    }
}
