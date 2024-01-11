//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";

error ExceedingPublicCollectionSize();
error ExceedingTotalCollectionSize();
error ExceedingTreasurySize();
error IncorrectAmount();
error InvalidMerkleRoot();
error InvalidSalesConfigurationValue(string message);
error MaxMintPerAddressReached();
error NotEligibleToMint();
error PreSaleIsNotOpen();
error PublicSaleIsNotOpen();
error SaleInProgress();
error SaleIsNotConfigured();

contract PizzaBillionaire is ERC721A, Ownable, PaymentSplitter {
    enum SalesStatus {
        Closed,
        PreSale,
        PublicSale
    }

    struct SalesConfiguration {
        uint256 price;
        uint8 maxMintPerAddress;
    }

    string private _baseTokenURI;
    bytes32 private _merkleRoot;

    uint16 public immutable collectionSize;
    uint16 public immutable treasurySize;
    uint16 public remainingTreasurySize;

    SalesStatus public salesStatus;
    SalesConfiguration public salesConfiguration;

    constructor(
        uint16 collectionSize_,
        uint16 treasurySize_,
        address[] memory payees_,
        uint256[] memory shares_
    ) ERC721A("Pizza", "PIZZA") PaymentSplitter(payees_, shares_) {
        require(collectionSize_ > treasurySize_, "treasurySize_ is too big");
        require(
            payees_.length == shares_.length,
            "shares length must match payees length"
        );

        salesStatus = SalesStatus.Closed;

        collectionSize = collectionSize_;
        treasurySize = treasurySize_;
        remainingTreasurySize = treasurySize_;
    }

    function configureRound(uint256 price, uint8 maxMintPerAddress)
        external
        onlyOwner
    {
        if (price == 0) {
            revert InvalidSalesConfigurationValue("price cannot be 0");
        }

        if (maxMintPerAddress == 0) {
            revert InvalidSalesConfigurationValue(
                "maxMintPerAddress cannot be 0"
            );
        }

        if (salesStatus != SalesStatus.Closed) {
            revert SaleInProgress();
        }

        salesConfiguration = SalesConfiguration(price, maxMintPerAddress);
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        if (salesStatus != SalesStatus.Closed) {
            revert SaleInProgress();
        }

        if (root == 0) {
            revert InvalidMerkleRoot();
        }

        _merkleRoot = root;
    }

    function whitelistMint(uint8 quantity, bytes32[] calldata merkleProof)
        external
        payable
    {
        SalesConfiguration memory config = salesConfiguration;

        if (salesStatus != SalesStatus.PreSale) {
            revert PreSaleIsNotOpen();
        }

        if (config.maxMintPerAddress == 0 || config.price == 0) {
            revert SaleIsNotConfigured();
        }

        if (_numberMinted(msg.sender) + quantity > config.maxMintPerAddress) {
            revert MaxMintPerAddressReached();
        }

        // We should never get this during PreSale
        if (totalSupply() + quantity > collectionSize - treasurySize) {
            revert ExceedingPublicCollectionSize();
        }

        if (msg.value != config.price * quantity) {
            revert IncorrectAmount();
        }

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (MerkleProof.verify(merkleProof, _merkleRoot, leaf) == false) {
            revert NotEligibleToMint();
        }

        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint8 quantity) external payable {
        SalesConfiguration memory config = salesConfiguration;

        if (config.maxMintPerAddress == 0 || config.price == 0) {
            revert SaleIsNotConfigured();
        }

        if (salesStatus != SalesStatus.PublicSale) {
            revert PublicSaleIsNotOpen();
        }

        if (_numberMinted(msg.sender) + quantity > config.maxMintPerAddress) {
            revert MaxMintPerAddressReached();
        }

        if (totalSupply() + quantity > collectionSize - treasurySize) {
            revert ExceedingPublicCollectionSize();
        }

        if (msg.value != config.price * quantity) {
            revert IncorrectAmount();
        }

        _safeMint(msg.sender, quantity);
    }

    function giveawayMint(address to, uint8 quantity) external onlyOwner {
        if (quantity > remainingTreasurySize) {
            revert ExceedingTreasurySize();
        }

        // We should never actually reach this condition
        if (totalSupply() + quantity > collectionSize) {
            revert ExceedingTotalCollectionSize();
        }

        remainingTreasurySize -= quantity;

        _safeMint(to, quantity);
    }

    function setSalesStatus(SalesStatus status) external onlyOwner {
        salesStatus = status;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}
