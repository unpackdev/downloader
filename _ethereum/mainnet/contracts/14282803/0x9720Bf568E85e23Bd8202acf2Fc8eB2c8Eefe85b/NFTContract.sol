//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "./Pausable.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract APClubNFT is Ownable, ERC721A, ReentrancyGuard {
    using ECDSA for bytes32;

    address private payoutAddress;
    address public signerAddress;

    // // metadata URI
    string private _baseTokenURI;

    uint256 public collectionSize;
    uint256 public maxBatchSize;
    uint256 public currentSaleIndex;

    enum SaleStage {
        Whitelist,
        Auction,
        Public
    }
    struct SaleConfig {
        uint16 tierIndex;
        uint32 startTime;
        uint32 endTime;
        uint32 stageBatchSize;
        uint64 stageLimit;
        uint64 price;
        SaleStage stage;
    }
    SaleConfig[] public saleConfigs;

    mapping(string => bool) public ticketUsed;

    struct AuctionConfig {
        uint64 startPrice;
        uint64 endPrice;
        uint32 startTime;
        uint32 priceCurveLength;
        uint32 dropPriceInterval;
    }
    AuctionConfig public auctionConfig;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        address _signerAddress
    ) ERC721A("AP Club NFT", "AP") {
        collectionSize = collectionSize_;
        maxBatchSize = maxBatchSize_;
        payoutAddress = 0x890054c5755E148caAfc9bf54DD60175468b37C5;
        signerAddress = _signerAddress;
        currentSaleIndex = 0;

        SaleConfig memory whitelist1SaleConfig = SaleConfig({
            tierIndex: 1,
            startTime: 1645920000,
            endTime: 1645927200,
            stageBatchSize: 1,
            stageLimit: 22,
            price: 0.8 ether,
            stage: SaleStage.Whitelist
        });
        SaleConfig memory whitelist2SaleConfig = SaleConfig({
            tierIndex: 2,
            startTime: 1645927200,
            endTime: 1645938000,
            stageBatchSize: 1,
            stageLimit: 140,
            price: 1.2 ether,
            stage: SaleStage.Whitelist
        });
        SaleConfig memory auctionSaleConfig = SaleConfig({
            tierIndex: 1,
            startTime: 1645941600,
            endTime: 1645943700,
            stageBatchSize: 1,
            stageLimit: 159,
            price: 3 ether,
            stage: SaleStage.Auction
        });
        saleConfigs.push(whitelist1SaleConfig);
        saleConfigs.push(whitelist2SaleConfig);
        saleConfigs.push(auctionSaleConfig);

        auctionConfig = AuctionConfig({
            startPrice: 3 ether,
            endPrice: 1.5 ether,
            startTime: 1645941600,
            priceCurveLength: 30 minutes,
            dropPriceInterval: 5 minutes
        });
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function whitelistMint(
        uint256 quantity,
        string memory _ticket,
        bytes memory _signature
    ) external payable callerIsUser {
        checkMintQuantity(quantity);
        proceedSaleStageIfNeed();

        require(isSaleStageOn(SaleStage.Whitelist), "sale has not started yet");

        require(!ticketUsed[_ticket], "Ticket has already been used");
        require(
            isAuthorized(msg.sender, _ticket, _signature, signerAddress),
            "Ticket is invalid"
        );

        SaleConfig memory config = saleConfigs[currentSaleIndex];
        uint256 stageLimit = uint256(config.stageLimit);
        require(totalSupply() + 1 <= stageLimit, "reached max supply");

        uint256 price = uint256(config.price);
        require(price != 0, "allowlist sale has not begun yet");

        ticketUsed[_ticket] = true;
        checkEnoughPrice(price);
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable callerIsUser {
        checkMintQuantity(quantity);
        proceedSaleStageIfNeed();

        SaleConfig memory config = saleConfigs[currentSaleIndex];
        uint256 stageLimit = uint256(config.stageLimit);
        uint256 auctionBatchSize = uint256(config.stageBatchSize);
        SaleStage stage = config.stage;

        require(stage != SaleStage.Whitelist, "wrong stage");
        require(isSaleStageOn(stage), "sale has not started yet");
        require(
            totalSupply() + quantity <= stageLimit,
            "exceed auction mint amount"
        );
        require(quantity <= auctionBatchSize, "can not mint this many");

        if (stage == SaleStage.Auction) {
            uint256 totalCost = getAuctionPrice(block.timestamp) * quantity;
            checkEnoughPrice(totalCost);
            _safeMint(msg.sender, quantity);
        } else {
            uint256 publicPrice = uint256(config.price);
            checkEnoughPrice(publicPrice * quantity);
            _safeMint(msg.sender, quantity);
        }
    }

    function checkMintQuantity(uint256 quantity) private view {
        SaleConfig memory config = saleConfigs[currentSaleIndex];
        uint256 stageBatchSize = uint256(config.stageBatchSize);
        require(stageBatchSize >= quantity, "Exceed mint quantity limit.");
    }

    function proceedSaleStageIfNeed() private {
        while (saleConfigs.length > currentSaleIndex + 1) {
            SaleConfig memory config = saleConfigs[currentSaleIndex];
            uint256 nextStageSaleEndTime = uint256(config.endTime);

            if (block.timestamp >= nextStageSaleEndTime) {
                currentSaleIndex += 1;
            } else {
                return;
            }
        }
    }

    function checkEnoughPrice(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
    }

    function isSaleStageOn(SaleStage _stage) private view returns (bool) {
        if (saleConfigs.length <= currentSaleIndex) {
            return false;
        }

        SaleConfig memory config = saleConfigs[currentSaleIndex];
        uint256 stagePrice = uint256(config.price);
        uint256 stageSaleStartTime = uint256(config.startTime);
        SaleStage currentStage = config.stage;

        return
            stagePrice != 0 &&
            currentStage == _stage &&
            block.timestamp >= stageSaleStartTime;
    }

    function getAuctionPrice(uint256 currentTimestamp)
        public
        view
        returns (uint256)
    {
        AuctionConfig memory config = auctionConfig;
        uint256 auctionStartTime = uint256(config.startTime);
        uint256 auctionStartPrice = uint256(config.startPrice);
        uint256 auctionEndPrice = uint256(config.endPrice);
        uint256 auctionPriceCurveLength = uint256(config.priceCurveLength);

        if (currentTimestamp < auctionStartTime) {
            return auctionStartPrice;
        }
        if (currentTimestamp - auctionStartTime >= auctionPriceCurveLength) {
            return auctionEndPrice;
        } else {
            uint256 auctionDropInterval = uint256(config.dropPriceInterval);
            uint256 steps = (currentTimestamp - auctionStartTime) /
                auctionDropInterval;
            uint256 auctionDropPerStep = (auctionStartPrice - auctionEndPrice) /
                (auctionPriceCurveLength / auctionDropInterval);
            return auctionStartPrice - (steps * auctionDropPerStep);
        }
    }

    function setSaleConfig(
        uint256 _saleIndex,
        uint16 _tierIndex,
        uint32 _startTime,
        uint32 _endTime,
        uint32 _stageBatchSize,
        uint64 _stageLimit,
        uint64 _price,
        SaleStage _stage
    ) external onlyOwner {
        SaleConfig memory config = SaleConfig({
            tierIndex: _tierIndex,
            startTime: _startTime,
            endTime: _endTime,
            stageBatchSize: _stageBatchSize,
            stageLimit: _stageLimit,
            price: _price,
            stage: _stage
        });

        if (_saleIndex >= saleConfigs.length) {
            saleConfigs.push(config);
        } else {
            saleConfigs[_saleIndex] = config;
        }
    }

    function setAuctionConfig(
        uint64 auctionStartPriceWei,
        uint64 auctionEndPriceWei,
        uint32 _startTime,
        uint32 auctionPriceCurveLength,
        uint32 auctionDropInterval
    ) external onlyOwner {
        auctionConfig = AuctionConfig(
            auctionStartPriceWei,
            auctionEndPriceWei,
            _startTime,
            auctionPriceCurveLength,
            auctionDropInterval
        );
    }

    function setCurrentSaleIndex(uint256 _currentSaleIndex) external onlyOwner {
        currentSaleIndex = _currentSaleIndex;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(payoutAddress).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function mintForAirdrop(address _to, uint256 _mintAmount)
        external
        onlyOwner
    {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= collectionSize, "Exceed max supply");
        if (msg.sender == owner()) {
            _safeMint(_to, _mintAmount);
        }
    }

    function setMaxBatchSize(uint256 _newMaxBatchSize) external onlyOwner {
        maxBatchSize = _newMaxBatchSize;
    }

    function setCollectionSize(uint256 _newCollectionSize) external onlyOwner {
        collectionSize = _newCollectionSize;
    }

    function isTicketAvailable(string memory ticket, bytes memory signature)
        external
        view
        returns (bool)
    {
        return
            !ticketUsed[ticket] &&
            isAuthorized(msg.sender, ticket, signature, signerAddress);
    }

    function isAuthorized(
        address sender,
        string memory ticket,
        bytes memory signature,
        address _signerAddress
    ) private pure returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, ticket));
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        return _signerAddress == signedHash.recover(signature);
    }
}
