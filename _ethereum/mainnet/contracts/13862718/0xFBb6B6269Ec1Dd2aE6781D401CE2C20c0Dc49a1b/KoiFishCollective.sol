// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

/**
 * @title KoiFishCollective contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract KoiFishCollective is ERC721Enumerable, Pausable, Ownable {
    using SafeMath for uint256;

    string public constant KOI_PROVENANCE = "43fb437b18ec1c27eed81a62dcd0915781ac907f1513f41e8a0842ab21c1c6c";
    uint256 public constant KOI_PRICE = 50000000000000000; // 0.05 ETH
    uint256 public constant MINT_LIMIT = 20;

    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint256 public maxKoi;
    uint256 public revealTimestamp;

    string private baseURI;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 saleStart
    ) ERC721(name, symbol) {
        maxKoi = maxSupply;
        revealTimestamp = saleStart + (86400 * 5);
    }

    // reserve koi
    function reserveKoi(uint256 numTokens) external onlyOwner {
        require(totalSupply() + numTokens <= maxKoi, "Reserve exceeds max tokens");
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    // set reveal timestamp
    function setRevealTimestamp(uint256 revealTimeStamp) external onlyOwner {
        revealTimestamp = revealTimeStamp;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    // toggle sale state
    function flipSaleState() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    // mint koi
    function mintKoi(uint256 numTokens) external whenNotPaused payable {
        require(numTokens <= MINT_LIMIT, "Mint exceeds token limit");
        require(totalSupply() + numTokens <= maxKoi, "Mint exceeds max tokens");
        require(KOI_PRICE * numTokens <= msg.value,"Insufficient funds for mint");

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < maxKoi) {
                _safeMint(msg.sender, mintIndex);
            }
        }
        if (
            startingIndexBlock == 0 &&
            (totalSupply() == maxKoi || block.timestamp >= revealTimestamp)
        ) {
            startingIndexBlock = block.number;
        }
    }

    // set starting index if necessary
    function setStartingIndex() external {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint256(blockhash(startingIndexBlock)) % maxKoi;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint256(blockhash(block.number - 1)) % maxKoi;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }

    // set starting index block if necessary
    function emergencySetStartingIndexBlock() external onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        startingIndexBlock = block.number;
    }
 
    /**
     * Return 0 decimals for adding the token to metamask.
     */
    function decimals() public pure returns (uint8) {
        return 0;
    }
}