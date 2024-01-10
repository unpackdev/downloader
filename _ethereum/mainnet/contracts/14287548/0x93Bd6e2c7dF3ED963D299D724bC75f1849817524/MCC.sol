// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "ERC721A.sol";
import "Counters.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "MerkleProof.sol";
import "Strings.sol";

contract MCC is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    uint256 public immutable maxSupply = 10000;
    uint256 public immutable maxSupplyPresale = 200;

    uint256 public maxTokensPerTx = 10;
    uint256 public maxTokensPerTxPresale = 2;
    uint256 public maxTokensPerWalletPresale = 2;

    struct SaleConfig {
        uint32 presaleStartTime;
        uint32 publicSaleStartTime;
        uint64 price;
        uint64 presalePrice;
    }

    SaleConfig public saleConfig;

    bool public revealed;

    bytes32 public merkleRoot;

    string private _baseTokenURI;
    string private notRevealedUri;
    address payable private ownerWallet;

    mapping(address => uint256) private _tokensClaimedInPresale;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _initNotRevealedUri,
        uint256 maxBatchSize_,
        address payable ownerAddress
    ) ERC721A(name_, symbol_, maxBatchSize_) {
        setNotRevealedURI(_initNotRevealedUri);
        ownerWallet = ownerAddress;
    }

    function presaleMint(uint256 quantity, bytes32[] memory proof)
        external
        payable
    {
        uint256 price = uint256(saleConfig.presalePrice);
        require(price != 0, "presale has not begun yet");
        uint256 presaleStartTime = uint256(saleConfig.presaleStartTime);
        require(
            presaleStartTime != 0 && block.timestamp >= presaleStartTime,
            "presale has not started yet"
        );
        require(
            totalSupply() + quantity <= maxSupplyPresale,
            "reached max presale supply"
        );
        if (
            MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) {
            require(
                quantity <= maxTokensPerTxPresale,
                "Presale transaction limit exceeded"
            );
            require(
                _tokensClaimedInPresale[msg.sender] + quantity <=
                    maxTokensPerWalletPresale,
                "You cannot mint any more NFTs during the presale"
            );
            require(
                price * quantity <= msg.value,
                "Ether value sent is not correct"
            );
            _safeMint(msg.sender, quantity);
        } else {
            revert("Not on the presale list");
        }
        _tokensClaimedInPresale[msg.sender] += quantity;
    }

    function publicSaleMint(uint256 quantity) external payable {
        SaleConfig memory config = saleConfig;
        uint256 price = uint256(config.price);
        require(price != 0, "public sale has not begun yet");
        uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
        require(
            publicSaleStartTime != 0 && block.timestamp >= publicSaleStartTime,
            "public sale has not started yet"
        );
        require(quantity <= maxTokensPerTx, "sale transaction limit exceeded");
        require(totalSupply() + quantity <= maxSupply, "reached max supply");
        require(
            price * quantity <= msg.value,
            "Ether value sent is not correct"
        );
        _safeMint(msg.sender, quantity);
    }

    function ownerMint(address _to, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "reached max supply");
        _safeMint(_to, quantity);
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setPublicSaleStartTime(uint32 timestamp) external onlyOwner {
        saleConfig.publicSaleStartTime = timestamp;
    }

    function setPresaleStartTime(uint32 timestamp) external onlyOwner {
        saleConfig.presaleStartTime = timestamp;
    }

    function setPrice(uint64 price) external onlyOwner {
        saleConfig.price = price;
    }

    function setPresalePrice(uint64 price) external onlyOwner {
        saleConfig.presalePrice = price;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMaxTokensPerTx(
        uint256 _maxTokensPerTx,
        uint256 _maxTokensPerTxPresale
    ) external onlyOwner {
        maxTokensPerTx = _maxTokensPerTx;
        maxTokensPerTxPresale = _maxTokensPerTxPresale;
    }

    function setMaxTokensPerWalletPresale(uint256 _maxTokensPerWalletPresale)
        external
        onlyOwner
    {
        maxTokensPerWalletPresale = _maxTokensPerWalletPresale;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setOwnerWallet(address payable _ownerWallet) public onlyOwner {
        ownerWallet = _ownerWallet;
    }

    function withdrawSales() external onlyOwner nonReentrant {
        (bool success, ) = ownerWallet.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnerOfToken(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return notRevealedUri;
        }
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }
}
