// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./EnumerableMap.sol";
import "./EnumerableSet.sol";

contract PvlaceContract is ERC721, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    //Make sure this is the correct contract when deploying to Ethereum network
    address payable OWNER_PAYMENT_CONTRACT =
        0xFd61dC2784BFF8B636bBc78a43fE33c289457e92;

    // Public variables

    // !!! CHANGE SALE_START_TIMESTAMP to proper time.
    uint256 public constant SALE_START_TIMESTAMP = 1618257600;

    // Tokens revealed after 10 days!
    uint256 public constant REVEAL_TIMESTAMP =
        SALE_START_TIMESTAMP + (86400 * 10);

    uint256 public constant MAX_NFT_SUPPLY = 350;

    // This controls random index of minting order
    uint256 public startingIndexBlock;
    uint256 public startingIndex;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping(address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from token ID to whether the Hashmask was minted before reveal
    mapping(uint256 => bool) private _mintedBeforeReveal;


    constructor() public ERC721("PVLACE NFT", "PVLACE") {
        // tokenCounter = 1;
        _setBaseURI(
            "https://raw.githubusercontent.com/joeyiny/pvlacenftmetadata/main/"
        );
    }

    /**
     * @dev Mint NFT
     */
    function mintNFT(uint256 numberOfNfts) public payable {
        // Check all requirements
        // require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(numberOfNfts > 0, "You cannot mint 0 NFTs");
        require(
            numberOfNfts <= getNFTMaxAmount(),
            "You may not buy more than this number of NFTs at this price tier"
        );
        // require(
        //     totalSupply().add(numberOfNfts) <= MAX_NFT_SUPPLY,
        //     "Exceeds MAX_NFT_SUPPLY. Please mint less NFTs"
        // );
        require(
            getNFTPrice().mul(numberOfNfts) == msg.value,
            "ETH value sent is not correct"
        );

        //Safely mint the number of NFTs requested
        for (uint256 i = 0; i < numberOfNfts; i++) {
            uint256 mintIndex = totalSupply() + 1;
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
            withdraw();
        }

        /*
         * Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense.
         * ---
         * Sets the starting block index when the sale ends.
         */
        if (
            startingIndexBlock == 0 &&
            (totalSupply() == MAX_NFT_SUPPLY ||
                block.timestamp >= REVEAL_TIMESTAMP)
        ) {
            startingIndexBlock = block.number;
        }
    }

    /**
     * @dev Finalize starting index
     */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint256(blockhash(startingIndexBlock)) % MAX_NFT_SUPPLY;

        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex =
                uint256(blockhash(block.number - 1)) %
                MAX_NFT_SUPPLY;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * @dev Get NFT max purchase amount based on current supply.
     */
    function getNFTMaxAmount() public view returns (uint256) {
        require(
            block.timestamp >= SALE_START_TIMESTAMP,
            "Sale has not started"
        );
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");

        uint256 currentSupply = totalSupply();

        if (currentSupply >= 176) {
            return 10; // All tokens that cost 2 ETH and above can be bought 10 at a time
        } else if (currentSupply >= 111) {
            return 5; // Tokens 111 - 175 can only be bought 5 at a time
        } else if (currentSupply >= 51) {
            return 3; // Tokens 51 - 110 can only be bought 3 at a time
        } else {
            return 2; // First 50 tokens can only be bought 2 at a time
        }
    }

    /**
     * @dev Get current NFT Price based on bonding curve.
     */
    function getNFTPrice() public view returns (uint256) {
        require(
            block.timestamp >= SALE_START_TIMESTAMP,
            "Sale has not started"
        );
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");

        uint256 currentSupply = totalSupply();

        if (currentSupply >= 350) {
            return 10000000000000000000; // 350 10 ETH
        } else if (currentSupply >= 311) {
            return 2000000000000000000; // 311 - 349 2 ETH
        } else if (currentSupply >= 246) {
            return 1500000000000000000; // 246 - 310 1.5 ETH
        } else if (currentSupply >= 176) {
            return 1000000000000000000; // 176 - 245 1 ETH
        } else if (currentSupply >= 111) {
            return 700000000000000000; // 111 - 175 0.7 ETH
        } else if (currentSupply >= 51) {
            return 300000000000000000; // 51 - 110 0.3 ETH
        } else {
            return 100000000000000000; // 1 - 50 0.1 ETH
        }
    }

    /**
     * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
     */
    function changeBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    /**
     * @dev This returns the ID of the media assets for a given token.
     */
    function getMediaId(uint256 tokenId) public view returns (uint256 mediaId) {
        require(tokenId < MAX_NFT_SUPPLY, "NFT must be less than total supply");

        require(startingIndexBlock != 0, "NFT hasn't been revealed yet.");

        mediaId = (tokenId + startingIndex) % MAX_NFT_SUPPLY;
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    */
    function withdraw() public {
        uint balance = address(this).balance;
        OWNER_PAYMENT_CONTRACT.transfer(balance);
    }
}