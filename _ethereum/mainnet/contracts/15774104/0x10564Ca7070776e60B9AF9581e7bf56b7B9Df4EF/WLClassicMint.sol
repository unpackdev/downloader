// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./PreSale.sol";
import "./IMMContract.sol";

contract WLClassicMint is PreSale {
    // template type and version
    bytes32 private constant TEMPLATE_TYPE = bytes32("WLClassicMint");
    uint256 private constant TEMPLATE_VERSION = 1;

    // maximum mint per public wallet
    uint256 public maxMintPerWallet;

    // maximum mint per each transaction
    uint256 public maxMintPerTx;

    // public sale mint price
    uint256 public mintPrice;

    //  public sale start time
    uint256 public startingTimestamp;

    // public sale end time
    uint256 public endingTimestamp;

    // tracks the number of times a public address has minted
    mapping(address => uint256) public mintCountPerWallet;

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
        uint256 price;
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
        mintPrice = publicSale.price;
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

    /***********************************************************************
                                 PUBLIC FUNCTIONS
     *************************************************************************/
    function hasSaleStarted() public view returns (bool) {
        return
            block.timestamp >= startingTimestamp &&
            block.timestamp <= endingTimestamp;
    }

    function mint(uint8 quantity)
        external
        payable
        callerIsUser
        whenSaleIsActive
        nonReentrant
    {
        require(hasSaleStarted(), "Sale is yet to start or its over");
        uint256 publicSaleQuantity = totalQuantity - presaleQuantity;
        require(supply < publicSaleQuantity, "Public Sale has sold out");
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

        mintCountPerWallet[_msgSender()] += quantity;
        supply += quantity;
        _safeMint(_msgSender(), quantity);
        _refundIfOver(mintPrice * quantity);
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

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function setStartTime(uint256 startTime) external onlyOwner {
        startingTimestamp = startTime;
    }

    function setEndTime(uint256 endTime) external onlyOwner {
        endingTimestamp = endTime;
    }
}
