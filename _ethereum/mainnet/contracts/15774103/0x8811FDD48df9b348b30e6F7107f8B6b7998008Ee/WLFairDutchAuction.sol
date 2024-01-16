// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./PreSale.sol";
import "./IMMContract.sol";

contract WLFairDutchAuction is PreSale {
    // template type and version
    bytes32 private constant TEMPLATE_TYPE = bytes32("WLFairDutchAuction");
    uint256 private constant TEMPLATE_VERSION = 1;

    // maximum mint per public address
    uint256 public maxMintPerWallet;

    // maximum mint per each transaction
    uint256 public maxMintPerTx;

    // auction starting price
    uint256 public startingPrice;

    // auction ending price
    uint256 public endingPrice;

    // auction final price
    uint256 public finalPrice;

    // amount to decrease at specific time interval
    uint256 public priceDecrement;

    // time minting starts for the public
    uint256 public startingTimestamp;

    // time minting ends for the public
    uint256 public endingTimestamp;

    // time to decrease price
    uint256 public decrementFrequency;

    // tracks the number of times a public address has minted
    mapping(address => uint256) public mintCountPerWallet;

    // track the amount of funds placed as bids by minter
    mapping(address => uint256) public bidsPerWallet;

    struct ContractConfig {
        string contractURI;
        bool delayReveal;
        address[] payees;
        uint256[] shares;
        address royaltyRecipient;
        uint96 royaltyFraction;
        bytes32 merkleRoot;
    }

    struct PublicSaleConfig {
        uint256 quantity;
        uint256 maxMint;
        uint256 maxMintTx;
        uint256 startPrice;
        uint256 endPrice;
        uint256 decrement;
        uint256 frequency;
        uint256 startTime;
        uint256 endTime;
    }

    function initialize(
        address owner,
        address trustedForwarder,
        string memory name,
        string memory symbol,
        ContractConfig memory contractConfig,
        PublicSaleConfig memory publicSale,
        PreSaleConfig memory preSale
    ) external initializerERC721A initializer {
        __ReentrancyGuard_init();
        __ERC2771Context_init(trustedForwarder);
        __ERC721A_init(name, symbol);
        __BasePreSale_init(preSale);
        __TokenMetadata_init();
        _setOwnership(owner);
        _setDefaultRoyalty(
            contractConfig.royaltyRecipient,
            contractConfig.royaltyFraction
        );
        _setSaleState();

        contractURI = contractConfig.contractURI;
        paymentAddresses = contractConfig.payees;
        paymentPercentages = contractConfig.shares;
        delayReveal = contractConfig.delayReveal;
        merkleRoot = contractConfig.merkleRoot;
        totalQuantity = publicSale.quantity;
        maxMintPerWallet = publicSale.maxMint;
        maxMintPerTx = publicSale.maxMintTx;
        startingPrice = publicSale.startPrice;
        endingPrice = publicSale.endPrice;
        priceDecrement = publicSale.decrement;
        decrementFrequency = publicSale.frequency;
        startingTimestamp = publicSale.startTime;
        endingTimestamp = publicSale.endTime;
    }

    /***********************************************************************
                                    CONTRACT METADATA
     *************************************************************************/

    // Returns the module type of the template.
    function contractType() external pure returns (bytes32) {
        return TEMPLATE_TYPE;
    }

    // Returns the version of the template.
    function contractVersion() external pure returns (uint8) {
        return uint8(TEMPLATE_VERSION);
    }

    /***********************************************************************
                                        MODIFIERS
     *************************************************************************/

    modifier whenSaleIsActive() {
        require(isSaleActive, "Public sale is not active");
        _;
    }

    modifier whenSaleHasEnded() {
        require(block.timestamp >= endingTimestamp, "Minting has not ended");
        _;
    }

    /***********************************************************************
                                PUBLIC FUNCTIONS
     *************************************************************************/

    function hasSaleStarted() public view returns (bool) {
        return
            block.timestamp >= startingTimestamp &&
            block.timestamp <= endingTimestamp;
    }

    function currentPrice() public view returns (uint256) {
        require(
            block.timestamp >= startingTimestamp,
            "Auction has not started!"
        );
        // time elapsed since auction started
        uint256 timeElapsed = block.timestamp - startingTimestamp;

        // total of price decrements that has taken place
        uint256 totalDecrement = (timeElapsed / decrementFrequency) *
            priceDecrement;

        if (finalPrice > 0) {
            return finalPrice;
        }

        if (totalDecrement >= startingPrice - endingPrice) {
            return endingPrice;
        }

        return startingPrice - totalDecrement;
    }

    function mint(uint8 quantity)
        external
        payable
        callerIsUser
        whenSaleIsActive
        nonReentrant
    {
        require(hasSaleStarted(), "Auction is yet to start or its over");
        uint256 publicSaleQuantity = totalQuantity - presaleQuantity;
        require(supply < publicSaleQuantity, "Auction has sold out");
        require(
            supply + quantity <= publicSaleQuantity,
            "Exceeds total NFTs remaining"
        );

        if (maxMintPerTx > 0) {
            require(
                quantity <= maxMintPerTx,
                "Exceeds mints allowed per transaction"
            );
        }

        if (maxMintPerWallet > 0) {
            require(
                mintCountPerWallet[_msgSender()] + quantity <= maxMintPerWallet,
                "Exceeds mints allowed per wallet"
            );
        }

        uint256 mintPrice = currentPrice();

        // set final price.
        if (supply + quantity == publicSaleQuantity) {
            finalPrice = mintPrice;
        }

        mintCountPerWallet[_msgSender()] += quantity;
        bidsPerWallet[_msgSender()] += (mintPrice * quantity);
        supply += quantity;
        _safeMint(_msgSender(), quantity);
        _refundIfOver(mintPrice * quantity);
    }

    /***********************************************************************
                                ONLY OWNER FUNCTIONS
     *************************************************************************/

    function refund(address recipient) external {
        _refund(recipient);
    }

    function _refund(address recipient)
        internal
        onlyOwner
        whenSaleHasEnded
        nonReentrant
    {
        require(
            bidsPerWallet[recipient] > 0,
            "Address is not eligible for refund"
        );

        require(finalPrice > 0, "Final price is not set");

        uint256 balance = bidsPerWallet[recipient] -
            (finalPrice * mintCountPerWallet[recipient]);

        bidsPerWallet[recipient] = 0;
        (bool success, ) = payable(recipient).call{value: balance}("");
        require(success, "Refund failed");
    }

    /**===========================================================================
                                    Setter Functions
    ============================================================================== */

    function setTotalQuantity(uint256 quantity) external onlyOwner {
        totalQuantity = quantity;
    }

    function setMaxMint(uint256 maxMint) external onlyOwner {
        maxMintPerWallet = maxMint;
    }

    function setMaxMintTx(uint256 maxMintTx) external onlyOwner {
        maxMintPerTx = maxMintTx;
    }

    function setStartPrice(uint256 startPrice) external onlyOwner {
        startingPrice = startPrice;
    }

    function setEndPrice(uint256 endPrice) external onlyOwner {
        endingPrice = endPrice;
    }

    function setFinalPrice(uint256 price) external onlyOwner {
        finalPrice = price;
    }

    function setPriceDecrement(uint256 decrement) external onlyOwner {
        priceDecrement = decrement;
    }

    function setStartTime(uint256 startTime) external onlyOwner {
        startingTimestamp = startTime;
    }

    function setEndTime(uint256 endTime) external onlyOwner {
        endingTimestamp = endTime;
    }

    function setDecrementFrequency(uint256 frequency) external onlyOwner {
        decrementFrequency = frequency;
    }
}
