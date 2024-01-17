// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./BaseClassic.sol";
import "./IMMContract.sol";

contract ClassicMint is BaseClassic {
    // template type and version
    bytes32 private constant TEMPLATE_TYPE = bytes32("ClassicMint");
    uint256 private constant TEMPLATE_VERSION = 2;

    // minting price
    uint256 public mintPrice;

    struct ContractConfig {
        bool delayReveal;
        string contractURI;
        string baseURI;
        string previewURI;
    }

    struct SaleConfig {
        uint256 quantity;
        uint256 maxMint;
        uint256 maxMintTx;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        address[] payees;
        uint256[] shares;
        address royaltyRecipient;
        uint96 royaltyFraction;
    }

    function initialize(
        address owner,
        address trustedForwarder,
        string memory name,
        string memory symbol,
        ContractConfig memory contractConfig,
        SaleConfig memory saleConfig
    ) external initializerERC721A initializer {
        __ReentrancyGuard_init();
        __ERC2771Context_init(trustedForwarder);
        __ERC721A_init(name, symbol);
        __TokenMetadata_init(contractConfig.baseURI, contractConfig.previewURI);
        __PrimarySale_init(saleConfig.payees, saleConfig.shares);
        _setOwnership(owner);
        _setDefaultRoyalty(
            saleConfig.royaltyRecipient,
            saleConfig.royaltyFraction
        );
        _setSaleState();

        contractURI = contractConfig.contractURI;
        delayReveal = contractConfig.delayReveal;
        totalQuantity = saleConfig.quantity;
        mintPrice = saleConfig.price;
        maxMintPerWallet = saleConfig.maxMint;
        maxMintPerTx = saleConfig.maxMintTx;
        startingTimestamp = saleConfig.startTime;
        endingTimestamp = saleConfig.endTime;
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
                                PUBLIC FUNCTIONS
     *************************************************************************/

    function mint(uint8 quantity)
        external
        payable
        whenSaleIsActive
        callerIsUser
        nonReentrant
    {
        require(hasSaleStarted(), "Sale is yet to start or its over");
        require(totalSupply() < totalQuantity, "NFTs have sold out");
        require(
            totalSupply() + quantity <= totalQuantity,
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
        _safeMint(_msgSender(), quantity);
        _refundIfOver(mintPrice * quantity);
    }

    /***********************************************************************
                                ONLY OWNER FUNCTIONS
     *************************************************************************/

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }
}
