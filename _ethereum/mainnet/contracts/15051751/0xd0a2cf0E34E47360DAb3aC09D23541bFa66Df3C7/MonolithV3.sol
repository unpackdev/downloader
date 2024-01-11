// SPDX-License-Identifier: MIT

/**
 /$$$$$$$$ /$$   /$$  /$$$$$$ 
| $$_____/| $$  / $$ /$$__  $$
| $$      |  $$/ $$/| $$  \ $$
| $$$$$    \  $$$$/ | $$  | $$
| $$__/     >$$  $$ | $$  | $$
| $$       /$$/\  $$| $$  | $$
| $$$$$$$$| $$  \ $$|  $$$$$$/
|________/|__/  |__/ \______/ 
                              
*/

pragma solidity ^0.8.4;

import "./ERC721XUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./MerkleProof.sol";
import "./console.sol";

interface BadgeNFT {
    function balanceOf(address _to) external returns (uint256);
}

error WithdrawToZeroAddress();
error WithdrawToNonOwner();
error WithdrawZeroBalance();
error OnlyMonolithMintAddress();

// general errors
error MaxSupplyExceeded();
error TooManyTokensRequestedInOneTransaction();
error TooManyTokensPerWallet();
error MintingPaused();
error RefundsInProgressOrGracePeriodNotEnded();
error ReleaseFundsFailed();
error InvalidArguments();

// dutch auction errors
error DutchAuctionNotStarted();
error DutchAuctionBidTooLow();
error DutchAuctionFinished();
error DutchAuctionInProgress();
error NotEntitledToRefund();
error RefundFailed();

// whitelist errors
error WhitelistNotActive();
error WhitelistBidTooLow();
error WhitelistAllowanceExceeded();
error WhitelistAlreadyMinted();
error NotOnTheWhitelist();

// public sale errors
error PublicSaleNotActive();
error PublicSaleBidTooLow();

// private errors
error PrivateAllowanceExceeded();

// v3 errors
error DeprecatedMethod();

contract MonolithV3 is
    Initializable,
    OwnableUpgradeable,
    ERC721XUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    address public ownerWallet;
    address public monolithMintAddress;
    string internal _rootURI;

    // CONSTANTS
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PER_TX = 10;
    uint256 public constant MAX_PER_BADGE = 2;
    uint256 public constant REFUND_GRACE_PERIOD = 4 days;
    uint256 public devMintSupply;
    uint256 public floorPrice;
    uint256 public discountRate;
    uint256 public whitelistSupply;
    uint256 public daStartPrice;

    // EVENTS
    event BidReceived(uint256 remainingSupply);
    event DutchAuctionHasEnded(uint256 timestamp);
    event WhitelistHasEnded(uint256 timestamp);
    event PublicSaleHasEnded(uint256 timestamp);
    event PrivateMintHasEnded(uint256 timestamp);

    // STRUCTS
    struct Bidder {
        address bidder;
        uint80 spent;
        uint8 daQuantity;
        uint8 whitelistQuantity;
        uint8 publicSaleQuantity;
    }

    struct MintStatus {
        uint8 paused;
        uint8 whitelistActive;
        uint8 publicSaleActive;
        uint16 whitelistMints;
        uint16 publicSaleMints;
        uint16 privateMints;
        uint16 maxSupply;
        uint32 totalBids;
        uint80 whitelistPrice;
        uint80 publicSalePrice;
    }

    struct DAStatus {
        uint32 refunds;
        uint32 dutchAuctionSupply;
        uint32 totalBids;
        uint32 startsAt;
        uint32 endsAt;
        uint80 lastPrice;
    }

    MintStatus public mintStatus;
    DAStatus public dutchAuctionStatus;

    // MAPPINGS
    mapping(address => Bidder) public bids;

    BadgeNFT public badgeNFT;

    uint32 public whitelistMints;

    function initialize(
        string memory name_,
        string memory symbol_,
        address ownerWallet_,
        uint256 _floorPrice,
        uint256 _discountRate,
        uint256 _maxSupply,
        uint256 _daStartPrice
    ) external initializer {
        __ERC721Psi_init(name_, symbol_);
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        ownerWallet = ownerWallet_;
        _rootURI = "";
        daStartPrice = _daStartPrice;

        dutchAuctionStatus = DAStatus({
            totalBids: 0,
            refunds: 0,
            startsAt: 0,
            endsAt: 0,
            dutchAuctionSupply: 0,
            lastPrice: uint80(_daStartPrice)
        });

        discountRate = _discountRate;
        floorPrice = _floorPrice;
        devMintSupply = 300;
        whitelistSupply = 1424;
        whitelistMints = 0;

        mintStatus = MintStatus({
            totalBids: 0,
            paused: 0,
            whitelistActive: 0,
            publicSaleActive: 0,
            whitelistPrice: 0,
            publicSalePrice: 0,
            whitelistMints: 0,
            publicSaleMints: 0,
            privateMints: 0,
            maxSupply: uint8(_maxSupply)
        });
    }

    /* solhint-disable-next-line no-empty-blocks */
    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function setOwnerWallet(address _ownerWallet) public onlyOwner {
        ownerWallet = _ownerWallet;
    }

    function getBatchHead(uint256 tokenId) public view {
        _getBatchHead(tokenId);
    }

    function getBaseURI() public view returns (string memory) {
        return _rootURI;
    }

    function setDevSupply(uint256 _devMintSupply) public onlyOwner {
        devMintSupply = _devMintSupply;
    }

    function setWhitelistSupply(uint256 _whitelistSupply) public onlyOwner {
        whitelistSupply = _whitelistSupply;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _rootURI = _baseURI;
    }

    function getTokenParams(uint256 tokenId) internal pure returns (string memory) {
        return string(abi.encodePacked("?id=", tokenId.toString()));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory tokenParams = getTokenParams(tokenId);
        return bytes(_rootURI).length > 0 ? string(abi.encodePacked(_rootURI, tokenParams)) : "";
    }

    // mint utils
    function refund(address _to, uint80 amount) internal {
        if (amount > 0) {
            AddressUpgradeable.sendValue(payable(_to), uint256(amount));
        }
    }

    function setBadgeContract(address _nft) external onlyOwner {
        badgeNFT = BadgeNFT(_nft);
    }

    function getBidData() public view returns (Bidder memory) {
        return bids[msg.sender];
    }

    function setMintStatus(
        uint8 _paused,
        uint8 _whitelistActive,
        uint8 _publicSaleActive,
        uint256 _whitelistPrice,
        uint256 _publicSalePrice
    ) external onlyOwner {
        MintStatus memory status = mintStatus;
        status = MintStatus({
            totalBids: status.totalBids,
            paused: _paused,
            whitelistActive: _whitelistActive,
            publicSaleActive: _publicSaleActive,
            whitelistPrice: uint80(_whitelistPrice),
            publicSalePrice: uint80(_publicSalePrice),
            whitelistMints: status.whitelistMints,
            publicSaleMints: status.publicSaleMints,
            privateMints: status.privateMints,
            maxSupply: status.maxSupply
        });
        mintStatus = status;
    }

    function setDAStatus(
        uint256 _startsAt,
        uint256 _duration,
        uint256 _dutchAuctionSupply,
        uint256 _floorPrice
    ) external onlyOwner {
        DAStatus memory status = dutchAuctionStatus;
        floorPrice = _floorPrice;
        status = DAStatus({
            totalBids: status.totalBids,
            refunds: status.refunds,
            startsAt: uint32(_startsAt),
            endsAt: uint32(_startsAt + _duration),
            dutchAuctionSupply: uint32(_dutchAuctionSupply),
            lastPrice: status.lastPrice
        });
        dutchAuctionStatus = status;
    }

    // dutch auction
    function bid(uint256 amount) external payable nonReentrant {
        DAStatus memory daStatus = dutchAuctionStatus;

        // check gates
        if (block.timestamp < daStatus.startsAt || daStatus.startsAt == 0) {
            revert DutchAuctionNotStarted();
        }
        if (block.timestamp > daStatus.endsAt) {
            revert DutchAuctionFinished();
        }
        if (amount > MAX_PER_TX) {
            revert TooManyTokensRequestedInOneTransaction();
        }

        if (daStatus.totalBids + amount > daStatus.dutchAuctionSupply) {
            revert MaxSupplyExceeded();
        }
        if (daStatus.totalBids + amount == daStatus.dutchAuctionSupply) {
            daStatus.endsAt = uint32(block.timestamp);
        }

        Bidder memory bidder = bids[msg.sender];

        uint80 currentPrice = _calculatePrice(daStatus);
        if (msg.value < currentPrice * amount) {
            revert DutchAuctionBidTooLow();
        }

        // update current bidder info
        bidder.daQuantity = bidder.daQuantity + uint8(amount);
        bidder.spent = bidder.spent + uint80(msg.value);
        bids[msg.sender] = bidder;

        // update dutch auction status
        daStatus.totalBids = daStatus.totalBids + uint8(amount);
        daStatus.lastPrice = currentPrice;
        dutchAuctionStatus = daStatus;

        emit BidReceived(daStatus.dutchAuctionSupply - daStatus.totalBids);
    }

    function refundAndMintDutchAuction(address _to) external nonReentrant onlyOwner {
        DAStatus memory status = dutchAuctionStatus;

        if (uint80(block.timestamp) < status.endsAt) {
            revert DutchAuctionInProgress();
        }

        Bidder memory bidder = bids[_to];
        if (bidder.daQuantity == 0) {
            revert NotEntitledToRefund();
        }

        uint80 refundPrice = status.lastPrice;

        if (status.totalBids < status.dutchAuctionSupply) {
            refundPrice = uint80(floorPrice);
        }
        uint80 refundAmount = bidder.spent - refundPrice * bidder.daQuantity;
        refund(_to, refundAmount);
        status.refunds = status.refunds + bidder.daQuantity;
        dutchAuctionStatus = status;
        // mint
        _safeMint(_to, uint256(bidder.daQuantity));
    }

    function calculatePrice() public view returns (uint80) {
        DAStatus memory status = dutchAuctionStatus;
        return _calculatePrice(status);
    }

    function _calculatePrice(DAStatus memory status) internal view returns (uint80) {
        uint256 currentTime = block.timestamp;
        if (currentTime > status.endsAt) {
            currentTime = status.endsAt;
        }

        if (status.startsAt == 0) {
            return 1 ether;
        }

        uint256 interval = 10 minutes;
        uint256 elapsed = (currentTime - status.startsAt) / interval;
        uint256 discount = discountRate * elapsed;
        uint256 currentPrice = daStartPrice - discount;
        if (currentPrice < floorPrice) {
            currentPrice = floorPrice;
        }

        return uint80(currentPrice);
    }

    function getRefundInfo(address _to) external view returns (uint256) {
        DAStatus memory status = dutchAuctionStatus;
        Bidder memory bidder = bids[_to];

        if (bidder.spent == 0) {
            return 0;
        }

        uint80 refundAmount = bidder.spent - status.lastPrice * bidder.daQuantity;

        return uint256(refundAmount);
    }

    function releaseFunds() external onlyOwner nonReentrant {
        DAStatus memory status = dutchAuctionStatus;
        if (status.refunds < status.totalBids && block.timestamp < status.endsAt + REFUND_GRACE_PERIOD) {
            revert RefundsInProgressOrGracePeriodNotEnded();
        }

        AddressUpgradeable.sendValue(payable(ownerWallet), address(this).balance);
    }

    // whitelist
    function whitelistMint(uint256 _quantity) external payable nonReentrant {
        revert DeprecatedMethod();
    }

    function publicMint(uint256 quantity) external payable nonReentrant {
        MintStatus storage status = mintStatus;

        // check gates
        if (status.publicSaleActive == 0) {
            revert PublicSaleNotActive();
        }
        if (status.paused == 1) {
            revert MintingPaused();
        }
        if (status.totalBids + quantity > MAX_SUPPLY) {
            revert MaxSupplyExceeded();
        }
        if (msg.value < uint256(status.publicSalePrice)) {
            revert PublicSaleBidTooLow();
        }

        Bidder memory bidder = bids[msg.sender];

        _safeMint(msg.sender, quantity);
        uint80 refundAmount = uint80(msg.value) - uint80(status.publicSalePrice * quantity);
        refund(msg.sender, refundAmount);

        status.totalBids = status.totalBids + 1;
        mintStatus = status;

        bidder.whitelistQuantity += uint8(quantity);
        bids[msg.sender] = bidder;

        if (status.totalBids + 1 == MAX_SUPPLY) {
            status.paused = 1;
            emit WhitelistHasEnded(block.timestamp);
        }
    }

    function devMint(
        address[] memory _to,
        uint256[] memory _quantity,
        uint256 _totalAmount
    ) public onlyOwner {
        if (_minted + _totalAmount > devMintSupply) revert MintExceedsDevSupply();
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], _quantity[i]);
        }
    }

    /* solhint-disable-next-line no-empty-blocks */
    receive() external payable {}

    // v3
    function whitelistMintV2(uint256 quantity) external payable nonReentrant {
        uint256 balance = badgeNFT.balanceOf(msg.sender);

        if (balance == 0) {
            revert NotOnTheWhitelist();
        }

        MintStatus storage status = mintStatus;

        // check gates
        if (status.whitelistActive == 0) {
            revert WhitelistNotActive();
        }
        if (status.paused == 1) {
            revert MintingPaused();
        }
        if (whitelistMints + quantity > whitelistSupply) {
            revert WhitelistAllowanceExceeded();
        }
        if (msg.value < uint256(status.whitelistPrice) * quantity) {
            revert WhitelistBidTooLow();
        }

        _safeMint(msg.sender, quantity);
        uint80 refundAmount = uint80(msg.value) - uint80(status.whitelistPrice * quantity);
        refund(msg.sender, refundAmount);

        if (whitelistMints + quantity == whitelistSupply) {
            status.whitelistActive = 0;
            emit WhitelistHasEnded(block.timestamp);
            mintStatus = status;
        }
        whitelistMints = uint32(whitelistMints + quantity);
    }
}
