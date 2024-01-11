// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

error AddressNotAllowlistVerified();

contract Piper is Ownable, ERC721A {
    uint256 public immutable maxPerAddressDuringMint;
    uint256 public immutable collectionSize;
    uint256 public immutable amountForDevs;
    uint256 public immutable amountForAllowlist;

    struct SaleConfig {
        uint32 allowlistSaleStartTime;
        uint32 publicSaleStartTime;
        uint64 allowlistPriceWei;
        uint64 publicPriceWei;
    }

    SaleConfig public saleConfig;
    bytes32 public merkleRoot;

    // metadata URI
    string private _baseTokenURI;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 amountForDevs_,
        uint256 amountForAllowlist_
    ) ERC721A("Pied Piper", "PIPER") {
        require(
            maxBatchSize_ < collectionSize_,
            "MaxBarchSize should be smaller than collectionSize"
        );
        maxPerAddressDuringMint = maxBatchSize_;
        collectionSize = collectionSize_;
        amountForDevs = amountForDevs_;
        amountForAllowlist = amountForAllowlist_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(
            quantity <= amountForDevs,
            "Too many already minted before dev mint"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        _safeMint(msg.sender, quantity);
    }

    // Public Mint
    function publicSale(uint256 quantity) external payable callerIsUser {
        require(isPublicSaleOn(), "Public sale has not begun yet");
        require(
            totalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
            "Reached max quantity that one wallet can mint"
        );
        uint256 priceWei = quantity * saleConfig.publicPriceWei;

        _safeMint(msg.sender, quantity);
        refundIfOver(priceWei);
    }

    // Allowlist Mint
    function allowlistSale(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
        callerIsUser
    {
        require(isAllowlistSaleOn(), "Public sale has not begun yet");
        require(
            totalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
            "Reached max quantity that one wallet can mint"
        );
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Sender address is not in allowlist"
        );
        uint256 priceWei = quantity * saleConfig.allowlistPriceWei;

        _safeMint(msg.sender, quantity);
        refundIfOver(priceWei);
    }

    function isPublicSaleOn() public view returns (bool) {
        require(
            saleConfig.publicSaleStartTime != 0,
            "Public Sale Time is TBD."
        );

        return block.timestamp >= saleConfig.publicSaleStartTime;
    }

    function isAllowlistSaleOn() public view returns (bool) {
        require(
            saleConfig.allowlistSaleStartTime != 0,
            "Public Sale Time is TBD."
        );

        return block.timestamp >= saleConfig.allowlistSaleStartTime;
    }

    // Owner Controls

    // Public Views
    // *****************************************************************************
    function numberMinted(address minter) public view returns (uint256) {
        return _numberMinted(minter);
    }

    // Contract Controls (onlyOwner)
    // *****************************************************************************
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setupNonAuctionSaleInfo(
        uint32 allowlistSaleStartTime,
        uint32 publicSaleStartTime,
        uint64 allowlistPriceWei,
        uint64 publicPriceWei
    ) public onlyOwner {
        saleConfig = SaleConfig(
            allowlistSaleStartTime,
            publicSaleStartTime,
            allowlistPriceWei,
            publicPriceWei
        );
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // Internal Functions
    // *****************************************************************************

    function refundIfOver(uint256 price) internal {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}
