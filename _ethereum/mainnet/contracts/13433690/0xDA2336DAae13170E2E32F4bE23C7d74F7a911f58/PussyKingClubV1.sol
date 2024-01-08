pragma solidity ^0.8.7;


import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract PussyKingClubV1 is Initializable, ContextUpgradeable, UUPSUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _pussyIdTracker;
    
     event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    struct Pussy {
        string Name;
        uint256 PussyId;
        address King;
    }

    struct Auction {
        bool IsStillInProgress;
        uint256 MinPrice;
        uint256 PussyId;
        uint256 AuctionEndTime;
    }

    struct Offer {
        uint256 PussyId;
        uint256 Value;
        address Bidder;
    }
    
    struct Author {
        address Wallet;
        uint8 Part;
    }
    
    bool private _presaleTransferBlock;

    string private _baseTokenURI;
    string private _name;
    string private _symbol;
    address payable private _admin;

    uint256 private _earnedEth;
    uint256 public minBidStep;

    mapping(address => uint256) private _balances;

    mapping(uint256 => Pussy) private _pussies;
    mapping(uint256 => Auction) private _auctions;
    mapping(uint256 => Offer) private _offers;

    function initialize() public initializer {
        __Context_init();
        __UUPSUpgradeable_init();
        _presaleTransferBlock = true;
        minBidStep = 1 * (10 ** 17);

        _name = "PussyKing";
        _symbol = "PUSS";
        _baseTokenURI = "https://pussykingclub.com/";
        _admin = payable(0xDc8b4685332E44F8c3761765c6634B24c036A549);
    }

    function ownerOf(uint256 pussyId) external view returns (address) {
        return _ownerOf(pussyId);
    }

    function _ownerOf(uint256 pussyId) internal view returns (address) {
        address king = _pussies[pussyId].King;
        require(king != address(0), "King query for nonexistent pussy");
        return king;
    }

    function totalSupply() external view returns (uint256) {
        return _pussyIdTracker.current();
    }

    function balanceOf(address king) external view returns (uint256) {
        require(king != address(0), "Balance query for the zero king");
        return _balances[king];
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 pussyId) external view returns (string memory) {
        require(_pussies[pussyId].PussyId != 0, "Invalid pussyId");

        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, pussyId.toString())) : "";
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 pussyId
    ) external payable {
        require(_presaleTransferBlock == false, "Presale is underway");
        require(_msgSender() == from);
        require(_ownerOf(pussyId) == from, "Transfer of pussy that is not own");
        require(to != address(0), "Transfer to the zero king");
        require(_auctions[pussyId].IsStillInProgress == false, "Auction is still in progress");

        _balances[from] -= 1;
        _balances[to] += 1;
        _pussies[pussyId].King = to;

        emit Transfer(from, to, pussyId);
    }

    function uploadPussies(string[] memory pussies) external {
        require(_msgSender() == _admin, "Method is available only to author");
        for(uint8 i = 0; i < pussies.length; i++){
            require(_pussyIdTracker.current() < 100, "Max pussies");
            _pussyIdTracker.increment();
            uint256 pussyId = _pussyIdTracker.current();
            _pussies[pussyId] = Pussy(pussies[i], pussyId, payable(address(0)));
        }
    }

    function uploadPussy(string memory pussyName) external {
        require(_msgSender() == _admin, "Method is available only to author");
        require(_pussyIdTracker.current() < 100, "Max pussies");
        _pussyIdTracker.increment();
        uint256 pussyId = _pussyIdTracker.current();
        _pussies[pussyId] = Pussy(pussyName, pussyId, payable(address(0)));
    }
    
     function authorAuctions(uint256[] memory pussyIds, uint256 startPrice, uint256 auctionTimeInDate) external {
        require(_msgSender() == _admin, "Method is available only to author");
        for(uint8 i = 0; i < pussyIds.length; i++){
            uint256 pussyId = pussyIds[i];
            require(_pussies[pussyId].PussyId != 0, "Invalid pussyId");
            Pussy memory pussy = _pussies[pussyId];
            require(pussy.King == address(0), "Sender not author");

            startAuction(pussyId, startPrice, auctionTimeInDate);
        }
    }
    
    function authorAuction(uint256 pussyId, uint256 startPrice, uint256 auctionTimeInDate) external {
        require(_pussies[pussyId].PussyId != 0, "Invalid pussyId");
        Pussy memory pussy = _pussies[pussyId];
        require(pussy.King == address(0) && _msgSender() == _admin, "Sender not author");

        startAuction(pussyId, startPrice, auctionTimeInDate);
    }

    function auctionPussy(uint256 pussyId, uint256 startPrice, uint256 auctionTimeInDate) external {
        require(_pussies[pussyId].PussyId != 0, "Invalid pussyId");
        Pussy memory pussy = _pussies[pussyId];
        require(pussy.King == _msgSender(), "Sender not King of pussy");

        startAuction(pussyId, startPrice, auctionTimeInDate);
    }

    function startAuction(uint256 pussyId, uint256 startPrice, uint256 auctionTimeInDate) private {
        require(startPrice >= 1 * (10 ** 18), "Min price 1 eth"); // more then 1 eth
        require(_auctions[pussyId].IsStillInProgress == false, "Auction is still in progress");
        require(60 >= auctionTimeInDate && auctionTimeInDate >= 1, "60 >= auctionTimeInDate >= 1");

        uint256 auctionEndTime = block.timestamp + auctionTimeInDate * 24 * 60;
        _auctions[pussyId] = Auction(true, startPrice, pussyId, auctionEndTime);
    }

    function pussyOf(uint256 pussyId) public view returns (string memory, uint256, address) {
        require(_pussies[pussyId].PussyId != 0, "Invalid pussyId"); 
        Pussy memory pussy = _pussies[pussyId];
        return (pussy.Name, pussy.PussyId, pussy.King);
    }
    
    function auctionOf(uint256 pussyId) public view returns (bool, uint256, uint256, uint256) {
        require(_pussies[pussyId].PussyId != 0, "Invalid pussyId");
        Auction memory auction = _auctions[pussyId];
        return (auction.IsStillInProgress, auction.MinPrice, auction.PussyId, auction.AuctionEndTime);
    }
    
    function offerOf(uint256 pussyId) public view returns (uint256,  uint256, address) {
        require(_pussies[pussyId].PussyId != 0, "Invalid pussyId");
        Offer memory offer = _offers[pussyId];
        return (offer.PussyId, offer.Value, offer.Bidder);
    }

    function placeBid(uint256 pussyId) external payable {
        require(_pussies[pussyId].PussyId != 0, "Invalid pussyId");

        Auction memory auction = _auctions[pussyId];
        require(msg.value >= auction.MinPrice, "Auction min price > value");
        require(auction.AuctionEndTime > block.timestamp, "Auction is over");
        
        Offer storage offer = _offers[pussyId];
        require(msg.value >= offer.Value + minBidStep, "Insufficient price");

        if (offer.Bidder != address(0)) {
            AddressUpgradeable.sendValue(payable(offer.Bidder), offer.Value);
        }

        _offers[pussyId] = Offer(pussyId, msg.value, _msgSender());
    }

    function becomePussyKing(uint256 pussyId) external {
        require(_pussies[pussyId].PussyId != 0, "Invalid pussyId");

        Auction memory auction = _auctions[pussyId];
        require(auction.IsStillInProgress, "Auction is not still in progress");
        require(auction.AuctionEndTime < block.timestamp, "The end time of the auction has not yet come");

        Offer memory offer = _offers[pussyId];
        require(offer.Bidder != address(0), "Bidder is zero");


        Pussy memory pussy = _pussies[pussyId];
        uint256 authorReward = 0;
        address from = pussy.King;
        address to = offer.Bidder;
        if(from == address(0)){
            authorReward = offer.Value;
        } else {
            uint256 authorCommision = offer.Value / 5;
            AddressUpgradeable.sendValue(payable(from), offer.Value - authorCommision);
            authorReward = authorCommision;
            _balances[from] -= 1;
        }

        _earnedEth += authorReward;
        _balances[to] += 1;
        _pussies[pussyId] = Pussy(pussy.Name, pussyId, to);
        _offers[pussyId] = Offer(pussyId, 0, address(0));
        _auctions[pussyId] = Auction(false, 0, pussyId, 0);

        emit Transfer(from, to, pussyId);
    }

    function abortAuction(uint256 pussyId) external {
        require(_offers[pussyId].Bidder == address(0), "Has bid");
        address king = _pussies[pussyId].King;
        require(_msgSender() == king || (king == address(0) && _msgSender() == _admin));
        _auctions[pussyId] = Auction(false, 0, pussyId, 0);
    }

    function releaseEarn() external {
        require(_msgSender() == _admin, "Method is available only to admin");

        Author[] memory authors = new Author[](4);
        authors[0] = Author(0x3acaC2b1010553b7F075F7f38eB864a2397472F2, 40);
        authors[1] = Author(0x87cE18C38ff1B42FF491077825ED47F163E01235, 40);
        authors[2] = Author(0x3ab9C686BF000593622327B0Cbcb7B341c370097, 10);
        authors[3] = Author(0x130c69A4683EDEd5C5De668b89c6bfc788e84DE1, 10);

        uint256 currentRelease = _earnedEth;
        for(uint8 i = 0; i < authors.length; i++) {
            Author memory author = authors[i];
            uint256 authorShare = currentRelease / 100 * author.Part;
            AddressUpgradeable.sendValue(payable(author.Wallet), authorShare);
            _earnedEth -= authorShare;
        }
    }
    
    function finishPresale() external {
        require(_msgSender() == _admin, "Method is available only to admin");
        _presaleTransferBlock = false;
    }

    function changeContractAdmin(address newAdmin) external {
        require(_msgSender() == _admin, "Method is available only to admin");
        _admin = payable(newAdmin);
    }

    function owner() public view returns (address) {
        return _admin;
    }

    function _authorizeUpgrade(address) internal override {
        require(_msgSender() == _admin, "Method is available only to admin");
    }
}