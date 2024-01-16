// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./MerkleProofUpgradeable.sol";

import "./BaseClassic.sol";
import "./IMMContract.sol";

contract PureWhitelist is BaseClassic {
    // template type and version
    bytes32 private constant TEMPLATE_TYPE = bytes32("PureWhitelist");
    uint256 private constant TEMPLATE_VERSION = 1;

    // minting price
    uint256 public mintPrice;

    // merklee root
    bytes32 public merkleRoot;

    struct ContractConfig {
        string contractURI;
        bool delayReveal;
        address[] payees;
        uint256[] shares;
        address royaltyRecipient;
        uint96 royaltyFraction;
        bytes32 merkleRoot;
    }

    struct SaleConfig {
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
        SaleConfig memory saleConfig
    ) external initializerERC721A initializer {
        __ReentrancyGuard_init();
        __ERC2771Context_init(trustedForwarder);
        __ERC721A_init(name, symbol);
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

    function mint(bytes32[] calldata _merkleProof, uint8 quantity)
        external
        payable
        whenSaleIsActive
        nonReentrant
    {
        require(hasSaleStarted(), "Sale is yet to start or its over");
        require(
            _isWhitelisted(_merkleProof, _msgSender()),
            "Address is not whitelisted"
        );
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

    function setMintPrice(uint256 price) public onlyOwner {
        mintPrice = price;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /***********************************************************************
                                INTERNAL FUNCTIONS
     *************************************************************************/
    function _isWhitelisted(bytes32[] calldata _merkleProof, address sender)
        private
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        return MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, leaf);
    }
}
