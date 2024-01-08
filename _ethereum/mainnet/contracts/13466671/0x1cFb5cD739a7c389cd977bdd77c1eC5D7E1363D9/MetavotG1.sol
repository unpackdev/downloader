// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./Math.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

/**
 * @title MetavotG1
 * https://metavots.com/
 */
contract MetavotG1 is ERC721Tradable, ReentrancyGuard {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Metavot G1", "MTVT1", _proxyRegistryAddress)
    {}
    address public factoryAddress = address(0);

    uint256 public constant BATCH_SIZE = 10;

    // Token ID counts. Indexes start at 1.
    uint256 public constant N_CANON = 100;
    uint256 public constant N_BOT = 2245;
    uint256 public constant N_TOTAL = N_CANON + N_BOT;

    // Random indexing
    uint256 internal nonce = 0;
    uint256[N_BOT] internal indices;

    // Grant minting permission to factory after minting the factory
    function setFactoryAddress(address _factoryAddress) public onlyOwner {
        factoryAddress = _factoryAddress;
    }

    function isCanonicle(uint256 tokenId) public pure returns (bool) {
        return tokenId > 0 && tokenId <= N_CANON;
    }

    function tokenURI(uint256 tokenId)
        public
        pure
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "https://item.metavots.com/gen1/meta/", // test
                    Strings.toString(tokenId)
                )
            );
    }

    function ownerPremint() public nonReentrant onlyOwner {
        for (uint i = 1; i <= N_CANON; i++) {
            _safeMint(owner(), i);
        }
    }

    function sendBalanceTo(address to) public payable onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    // https://etherscan.io/address/0x7bd29408f11d2bfc23c34f18275bbf23bb716bc7#code
    function randomBotIndex() private returns (uint256) {
        uint256 totalSize = N_TOTAL - totalSupply();  // this requires premint happened already
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
        // Don't allow a zero index, start counting at N_CANON + 1
        return value + N_CANON + 1;
    }

    function canMint() public view returns (bool) {
        return totalSupply() < N_TOTAL;
    }

    function mintRandomBot(address to) external nonReentrant onlyOwner returns (uint) {
        require(canMint(), "Token limit reached.");
        uint id = randomBotIndex();
        require(id > 0, "Token ID must be greater than 0");
        _safeMint(to, id);
        return id;
    }

    // Batch transfer up to 100 tokenIds.  Input must be sorted and deduped.
    function safeTransferFromBatch(address from, address to, uint256[] memory sortedAndDedupedTokenIds) public {
        uint length = sortedAndDedupedTokenIds.length;
        require(length <= BATCH_SIZE, "Exceeded batch size.");
        uint lastTokenId = 0; 
        for (uint i=0; i<length; i++) {
            require(i == 0 || (sortedAndDedupedTokenIds[i] > lastTokenId), "Token IDs must be sorted and deduped.");
            lastTokenId = sortedAndDedupedTokenIds[i];
            safeTransferFrom(from, to, sortedAndDedupedTokenIds[i]);
        }
    }
}
