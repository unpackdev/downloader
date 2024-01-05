// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract MillionDollarRat is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // emitted by {depositGoldenRatToSewer} on success
    event GoldenRatDeposited(address indexed owner, address indexed sewer);

    // This is the provenance record of all artwork in existence
    string public constant RATS_PROVENANCE = "60f27f7b882a5c8f31453d36f99fa1cc67b3c254934e4f327f66059599cf10e0";

    // opens Apr 29 3pm EST | 1619722800
    uint256 public constant SALE_START_TIMESTAMP = 1619722800;

    // The sale lasts for 21 days
    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + 3 weeks;

    // Sale price tiers
    uint256 private constant TIER_1_PRICE = 50000000000000000; // 0.05 ETH
    uint256 private constant TIER_2_SUPPLY_THRESHOLD = 51;
    uint256 private constant TIER_2_PRICE = 150000000000000000; // 0.15 ETH
    uint256 private constant TIER_3_SUPPLY_THRESHOLD = 251;
    uint256 private constant TIER_3_PRICE = 180000000000000000; // 0.18 ETH
    uint256 private constant TIER_4_SUPPLY_THRESHOLD = 1251;
    uint256 private constant TIER_4_PRICE = 200000000000000000; // 0.20 ETH
    uint256 private constant TIER_5_SUPPLY_THRESHOLD = 2051;
    uint256 private constant TIER_5_PRICE = 220000000000000000; // 0.22 ETH
    uint256 private constant TIER_6_SUPPLY_THRESHOLD = 2851;
    uint256 private constant TIER_6_PRICE = 400000000000000000; //  0.4 ETH
    uint256 private constant TIER_7_SUPPLY_THRESHOLD = 3251;
    uint256 private constant TIER_7_PRICE = 450000000000000000; // 0.45 ETH
    uint256 private constant TIER_8_SUPPLY_THRESHOLD = 3301;
    uint256 private constant TIER_8_PRICE = 500000000000000000; // 0.5 ETH

    // ETH-USD price at deployment: $2300
    uint256 private constant GOLDEN_RAT_PRIZE = 435 ether;
    uint256 private constant GOLDEN_RAT_THRESHOLD = GOLDEN_RAT_PRIZE + 50 ether;

    uint256 public constant MAX_RAT_SUPPLY = 3311;
    uint256 private constant RAT_PACK_LIMIT = 10;
    uint256 private constant GOLDEN_RAT_TOKEN_ID = 0;
    string private constant PLACEHOLDER_SUFFIX = "placeholder.json";
    string private constant METADATA_INFIX = "/metadata/";

    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    address private _sewer;

    // current metadata base prefix
    string private _baseTokenUri;

    // ===============================================================

    /*
     * @dev MillionDollarRat must be deployed after Sewer, and expects to receive
     *  its address in the constructor.
     */
    constructor(address sewer) ERC721("Million Dollar Rat", "MDRAT") {
        require(sewer != address(0), "Sewer not specified");

        // store Sewer address
        _sewer = sewer;

        // mint the Golden Rat
        _safeMint(address(this), totalSupply());
    }

    /**
     * @dev Returns rat price in the current tier.
     */
    function getRatPrice() public view returns (uint256) {
        require(
            block.timestamp >= SALE_START_TIMESTAMP,
            "Sale has not started"
        );
        require(totalSupply() < MAX_RAT_SUPPLY, "Sale has ended");

        uint256 currentSupply = totalSupply();

        if (currentSupply >= TIER_8_SUPPLY_THRESHOLD) {
            return TIER_8_PRICE;
        } else if (currentSupply >= TIER_7_SUPPLY_THRESHOLD) {
            return TIER_7_PRICE;
        } else if (currentSupply >= TIER_6_SUPPLY_THRESHOLD) {
            return TIER_6_PRICE;
        } else if (currentSupply >= TIER_5_SUPPLY_THRESHOLD) {
            return TIER_5_PRICE;
        } else if (currentSupply >= TIER_4_SUPPLY_THRESHOLD) {
            return TIER_4_PRICE;
        } else if (currentSupply >= TIER_3_SUPPLY_THRESHOLD) {
            return TIER_3_PRICE;
        } else if (currentSupply >= TIER_2_SUPPLY_THRESHOLD) {
            return TIER_2_PRICE;
        } else {
            return TIER_1_PRICE;
        }
    }

    /**
     * @dev Mint `numberOfRats` rats. Price slippage is okay between tiers.
     *  It's a feature.
     *
     *  - Only mints until `MAX_RAT_SUPPLY` is reached.
     *  - Mints up to `RAT_PACK_LIMIT` per request.
     *  - Reverts if minting will exceed MAX_RAT_SUPPLY.
     *
     *  `msg.value` must equal number of rats to be minted multiplied by
     *  the current price.
     */
    function mintRats(uint256 numberOfRats) public payable nonReentrant {
        require(totalSupply() < MAX_RAT_SUPPLY, "Sale has ended");
        require(numberOfRats > 0, "Cannot sell 0 Rats");
        require(numberOfRats <= RAT_PACK_LIMIT, "Buy limit exceeded");
        require(
            (totalSupply() + numberOfRats) <= MAX_RAT_SUPPLY,
            "Exceeds MAX_RAT_SUPPLY"
        );
        require(
            (getRatPrice() * numberOfRats) == msg.value,
            "ETH sent is not correct"
        );

        for (uint256 i = 0; i < numberOfRats; i++) {
            _safeMint(msg.sender, totalSupply());
        }

        /**
         * Source of "randomness". Theoretically miners could influence this but
         * not worried for the scope of this project
         */
        /**
         * [Stuck]
         * If not all rats have been minted, block.timestamp > REVEAL_TIMESTAMP,
         * and no one is calling {mintRats} past that point, the code below is not
         * executed, and thus startingIndexBlock is not set. We fix that in {reveal}.
         */
        if (
            startingIndexBlock == 0 &&
            (totalSupply() == MAX_RAT_SUPPLY ||
                block.timestamp >= REVEAL_TIMESTAMP)
        ) {
            startingIndexBlock = block.number;
        }
    }

    /**
     * @dev Call after the sale ends or when reveal period begins. This sets
     *  `startingIndex` for rats.
     */
    function reveal() public {
        require(startingIndex == 0, "Starting index is already set");
        require(
            block.timestamp >= REVEAL_TIMESTAMP ||
                totalSupply() == MAX_RAT_SUPPLY,
            "Before reveal OR full drop"
        );

        // account for the [Stuck] scenario, see {mintRats}
        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }

        uint256 _start =
            uint256(blockhash(startingIndexBlock)) % MAX_RAT_SUPPLY;

        if (
            (_start > block.number)
                ? ((_start - block.number) > 255)
                : ((block.number - _start) > 255)
        ) {
            _start = uint256(blockhash(block.number - 1)) % MAX_RAT_SUPPLY;
        }

        if (_start == 0) {
            _start = _start + 1;
        }

        startingIndex = _start;
    }

    /*
     * @dev Award Golden Rat (tokenId = 0) to the owner of `tokenId`.
     *  Only callable after {reveal} has been explicitly called.
     *
     *  Reverts if `tokenId` has not been minted.
     *  Prevents duplicate transfer.
     *  Reverts if transfer is to contract owner or contract address.
     */
    function awardGoldenRat(uint256 tokenId) public onlyOwner nonReentrant {
        require(startingIndex > 0, "Golden Rat not yet revealed");
        require(_exists(tokenId), "Unknown winner rat, tokenId");
        require(
            ownerOf(GOLDEN_RAT_TOKEN_ID) == address(this),
            "Already awarded"
        );
        require(
            (ownerOf(tokenId) != owner()) &&
                (ownerOf(tokenId) != address(this)) &&
                (tokenId > 0),
            "Cannot award to self"
        );
        require(
            address(this).balance >= GOLDEN_RAT_THRESHOLD,
            "Prize threshold not reached"
        );

        _safeTransfer(
            ownerOf(GOLDEN_RAT_TOKEN_ID),
            ownerOf(tokenId),
            GOLDEN_RAT_TOKEN_ID,
            ""
        );

        //payable(_sewer).transfer(GOLDEN_RAT_PRIZE);
        (bool sent, ) = payable(_sewer).call{value: GOLDEN_RAT_PRIZE}("");

        require(sent, "ETH Transfer Failed");
    }

    /**
     * @dev Withdraw owner's ETH from this contract. This is only
     *  callable after {reveal} has been explicitly called.
     */
    function withdraw(uint256 amount) public onlyOwner nonReentrant {
        require(startingIndex > 0, "Golden Rat not yet revealed");

        require(
            !_exists(GOLDEN_RAT_TOKEN_ID) ||
                ownerOf(GOLDEN_RAT_TOKEN_ID) != address(this),
            "Award Golden Rat first"
        );

        require(
            (amount > 0) && (amount <= address(this).balance),
            "Invalid amount"
        );

        //payable(msg.sender).transfer(amount);
        (bool sent, ) = payable(msg.sender).call{value: amount}("");

        require(sent, "ETH Transfer Failed");
    }

    /*
     * @dev After the Golden Rat has been awarded, the owner can send it to
     *  the Sewer contract by calling this.
     */
    function depositGoldenRatToSewer() public {
        require(msg.sender != owner(), "Owner not allowed to do that");
        require(msg.sender != address(this), "Contract not allowed to do that");

        require(
            ownerOf(GOLDEN_RAT_TOKEN_ID) == msg.sender,
            "Not the owner of Golden Rat"
        );

        safeTransferFrom(msg.sender, _sewer, GOLDEN_RAT_TOKEN_ID);

        _burn(GOLDEN_RAT_TOKEN_ID);

        emit GoldenRatDeposited(msg.sender, _sewer);
    }

    // no trailing slash, please
    function setTokenURI(string memory newUri) public onlyOwner {
        _baseTokenUri = newUri;
    }

    function placeholderURI() internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _baseTokenUri,
                    METADATA_INFIX,
                    PLACEHOLDER_SUFFIX
                )
            );
    }

    function indexedTokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _baseTokenUri,
                    METADATA_INFIX,
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    function ratTokenURI() public view returns (string memory) {
        require(startingIndex > 0, "Before reveal");
        require(msg.sender == _sewer, "And you are?");

        return
            string(abi.encodePacked(_baseTokenUri, METADATA_INFIX, "0.json"));
    }

    /**
     * @dev Golden Rat is minted first, and its tokenId is 0. The URI for the
     *   Golden Rat always points to 0.json.  Before reveal this function returns
     *   placeholder URI for all tokens; after the reveal it returns adjusted
     *   URIs based on `startingIndex` transform for all tokens except Golden Rat.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Unknown tokenId");

        string memory result;

        if (startingIndex > 0) {
            uint256 mappedTokenId =
                (tokenId == GOLDEN_RAT_TOKEN_ID)
                    ? GOLDEN_RAT_TOKEN_ID
                    : ((tokenId + startingIndex) >= MAX_RAT_SUPPLY)
                    ? ((tokenId + startingIndex) % MAX_RAT_SUPPLY) + 1
                    : (tokenId + startingIndex) % MAX_RAT_SUPPLY;

            result = indexedTokenURI(mappedTokenId);
        } else {
            result = placeholderURI();
        }

        return result;
    }
}