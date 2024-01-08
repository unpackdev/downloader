//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Strings.sol";

/**
 * Do you have diamond hands?
 * An experiment with NFTs that change over time. You will need to hodl to achieve diamond hands
 * 💎👐
 * NOT AUDITED NO ROADMAP. NFTS CHANGE ON TRANSFER- THIS IS A RUGPULL BY DESIGN
 *
 * Artwork designed by tsrounds
 * Emojis from OpenMoji – the open-source emoji and icon project. License: CC BY-SA 4.0
 */
contract DiamondHands is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIds;

    string[] public diamondUrls = [
        "QmaZzDSeregrZWHtkSG1F4cNB4XAg8B8Kkye4Jv1ZdeeQE",
        "QmbKiZSiVMVJqGXzBYAjv5tcL73Qk5aVSZBRYiLuZjJJDE",
        "QmbK2zaSjq6KqZ4M7EVeKEBEgfHMmBftKr9rbgsRhhZgmW",
        "QmdJ59croPkY3tjkxd92j21rzqEMY2Eyk9WzbaHEexTodM",
        "QmNxXs3xdJ4c8UyVm8hv7rXEYoNiwc2dYjNioCNxasuTqR",
        "QmYZRqxt88FpUZ2LteZBEb7nNU45nuzPTbsXtJ9thjN7Gb",
        "QmYzrLHsFyhZTwDYqBQosGTHMCVmKBujxmxHwDCo6AHzmw",
        "QmSsYWEEoNz8dNt6caqE5JU3ZmrZ1G5TDKb5RxPU2W5wFG"
    ];
    uint256 public numBlocksForDiamondHands = 2100000; // Roughly 1 year

    bool public settingsLocked = false;

    uint256 public constant MAX_DIAMOND_HANDS = 1000;
    uint256 public constant FOUNDER_1_RESERVE_AMOUNT = 35;
    uint256 public constant FOUNDER_2_RESERVE_AMOUNT = 15;
    address private constant FOUNDER_2_ADDR =
        0x61F516DA89646F9965c3E0f56a36AB66fdfd7f08;

    mapping(uint256 => uint256) public lastTransferBlockNum;

    // mint founder reserves
    constructor() ERC721("DiamondHands", "DH") {
        for (uint256 i = 0; i < FOUNDER_1_RESERVE_AMOUNT; i++) {
            _internalMint(_msgSender());
        }
        for (uint256 i = 0; i < FOUNDER_2_RESERVE_AMOUNT; i++) {
            _internalMint(FOUNDER_2_ADDR);
        }
    }

    // Used for testing. Might change this timeline if original guess at 1 yr is too long haha
    // This functionality can be pulled by calling lockSettings
    function setNumBlocksForDiamondHands(uint256 numBlocks) public onlyOwner {
        require(!settingsLocked, "Settings have been locked");
        numBlocksForDiamondHands = numBlocks;
    }

    // this will lock the above settings so owner cant modify either
    function lockSettings() public onlyOwner {
        settingsLocked = true;
    }

    /**
     * Public frontend to see current supply
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * External mint function
     */
    function I_Understand_How_This_NFT_Works_And_Realize_Its_A_Joke_And_Want_To_Mint_Anyway()
        external
        returns (uint256)
    {
        require(
            _tokenIds.current() < MAX_DIAMOND_HANDS,
            "All have been minted"
        );
        return _internalMint(_msgSender());
    }

    function _internalMint(address addr) private returns (uint256) {
        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();
        _safeMint(addr, tokenId);
        return tokenId;
    }

    // Returns a url to the image asset
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId < _tokenIds.current(), "Token doesn't exist");
        string memory ipfsId = diamondUrls[_tokenLevel(tokenId)];
        return string(abi.encodePacked("ipfs://", ipfsId));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        _reset(tokenId);
    }

    // Called on transfer, resets the value of lastTransferBlockNum of the current token to current block number
    function _reset(uint256 tokenId) private {
        lastTransferBlockNum[tokenId] = block.number;
    }

    // External function to query the level of a token
    function level(uint256 tokenId) external view returns (uint256) {
        return _tokenLevel(tokenId);
    }

    // Computes level of current token by time since last transfer
    function _tokenLevel(uint256 tokenId) private view returns (uint256) {
        uint256 lastBlock = lastTransferBlockNum[tokenId];
        if (lastBlock == 0) {
            return 0;
        }
        uint256 blockNumber = block.number;
        uint256 delta = blockNumber.sub(lastBlock);
        if (delta < 0) {
            return 0;
        }
        if (delta > numBlocksForDiamondHands) {
            return diamondUrls.length - 1;
        }
        uint256 deltaIndex = delta.mul(diamondUrls.length);
        return deltaIndex.div(numBlocksForDiamondHands);
    }
}
