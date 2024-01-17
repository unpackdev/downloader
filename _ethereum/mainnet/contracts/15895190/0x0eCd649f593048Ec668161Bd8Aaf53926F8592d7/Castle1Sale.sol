// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./GremGoylesCastle1NFT.sol";
import "./console.sol";

contract Castle1Sale is ReentrancyGuard, Ownable {
    address public nftContract;
    mapping(uint8 => PurchaseRound) private _purchaseRounds;
    mapping(uint8 => bool) private _purchaseRoundExist;
    mapping(uint8 => bool) public roundIsPrivate;
    mapping(uint8 => mapping(address => bool)) public roundWhiteList;
    mapping(uint8 => mapping(address => bool)) public roundAirdropList;
    mapping(uint8 => mapping(address => uint8)) public roundMinted;
    mapping(uint8 => uint256) public roundWhiteListCount;
    mapping(uint8 => uint256) public roundAirdropListCount;
    mapping(uint8 => uint16) public roundLimitNft;
    string public currentRoundName;
    uint8 public currentRoundId;

    mapping(address => uint256) public bidTotalAmount;

    struct PurchaseRound {
        uint16 supply;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        uint256 whitelistPrice;
        uint16 minted;
    }
    event OpenPurchaseRound(
        uint8 id,
        uint16 supply,
        uint256 startTime,
        uint256 endTime,
        uint256 price,
        uint256 whitelistPrice,
        bool isPrivate
    );
    event PurchasedNft(uint8 roundId, uint256 price);
    modifier preventContractCalls{
        require(msg.sender == tx.origin,"Cannot be called from other smart contracts");
        _;
    }

    function withdrawAllTo(address payable _to)public onlyOwner{
        _to.transfer(address(this).balance);
    }
    
    constructor(
        address _nftContract
    ) {
        nftContract = _nftContract;
    }
    
    /**
     * @dev Open an event with box type, time duration and price, supply, ...
     * @param _id uint8: id of the event
     * @param _startTime uint256: start time of the event
     * @param _endTime uint256: end time of the event
     * @param _price uint256: price of the NFT
     * @param _supply uint256: supply of the NFT
     * @param _isPrivate bool: is the event private
     * @param _limitPerAddress uint16: limit quantity of the NFT an address can buy
     * Emit OpenPurchaseRound event
     */
    function openPurchaseRound(
        uint8 _id,
        uint16 _supply,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _price,
        uint256 _whitelistPrice,
        bool _isPrivate,
        uint16 _limitPerAddress,
        string memory roundName
    ) public onlyOwner roundNotExist(_id) {
        require(_endTime > _startTime, "End time must be after start time");
        require(_price > 0, "Price must be greater than 0");
        require(_supply > 0, "Supply must be greater than 0");
        currentRoundId = _id;
        currentRoundName = roundName;
        _purchaseRounds[_id] = PurchaseRound(
            _supply,
            _startTime,
            _endTime,
            _price,
            _whitelistPrice,
            0
        );

        _purchaseRoundExist[_id] = true;
        roundIsPrivate[_id] = _isPrivate;
        roundLimitNft[_id] = _limitPerAddress;

        emit OpenPurchaseRound(
            _id,
            _supply,
            _startTime,
            _endTime,
            _price,
            _whitelistPrice,
            _isPrivate
        );
    }
    function addRoundWhitelist(
        uint8 _roundId,
        address[] memory _addressWhitelist
    ) public onlyOwner {
        require(
            _purchaseRoundExist[_roundId] == true,
            "Purchase round does not exist"
        );
        for (uint256 i; i < _addressWhitelist.length; i++) {
            require(
                _addressWhitelist[i] != address(0),
                "Address whitelist cannot be the null address"
            );
            roundWhiteList[_roundId][_addressWhitelist[i]] = true;
            roundWhiteListCount[_roundId] += 1;
        }
    }
    function addRoundAirdropList(
        uint8 _roundId,
        address[] memory _addressAirdrop
    ) public onlyOwner {
        require(
            _purchaseRoundExist[_roundId] == true,
            "Purchase round does not exist"
        );
        for (uint256 i; i < _addressAirdrop.length; i++) {
            require(
                _addressAirdrop[i] != address(0),
                "Address airdrop cannot be the null address"
            );
            roundAirdropList[_roundId][_addressAirdrop[i]] = true;
            roundAirdropListCount[_roundId] += 1;
        }
    }
    modifier roundNotExist(uint8 _roundId) {
        require(
            _purchaseRoundExist[_roundId] == false,
            "Purchase round already exists"
        );
        _;
    }

    modifier roundAvailable(uint8 _roundId) {
        require(
            _purchaseRoundExist[_roundId] == true,
            "Purchase round does not exist"
        );
        PurchaseRound memory purchaseRound = _purchaseRounds[_roundId];
        require(
            purchaseRound.startTime <= block.timestamp &&
                purchaseRound.endTime >= block.timestamp,
            "Purchase round is not active"
        );
        require(
            purchaseRound.minted < purchaseRound.supply,
            "Purchase round is sold out"
        );
        _;
    }

    function setRoundStartTime(uint8 _roundId, uint256 _startTime)
        public
        onlyOwner
    {
        require(
            _purchaseRoundExist[_roundId] == true,
            "Purchase round does not exist"
        );
        require(_startTime >= block.timestamp, "Start time must be after now");
        PurchaseRound storage purchaseRound = _purchaseRounds[_roundId];
        require(
            purchaseRound.startTime > block.timestamp,
            "Cannot update starTime of a round after it has started"
        );
        purchaseRound.startTime = _startTime;
    }

    function setRoundEndtime(uint8 _roundId, uint256 _endTime)
        public
        onlyOwner
    {
        require(
            _purchaseRoundExist[_roundId] == true,
            "Purchase round does not exist"
        );
        require(_endTime >= block.timestamp, "End time must be after now");
        PurchaseRound storage purchaseRound = _purchaseRounds[_roundId];
        require(
            purchaseRound.endTime > block.timestamp,
            "Cannot update endTime of a round after it has ended"
        );
        purchaseRound.endTime = _endTime;
    }

    /**
     * @dev getRoundInfo
     * @param _roundId uint8: id of the event
     */
    function getRoundInfo(uint8 _roundId)
        public
        view
        returns (PurchaseRound memory purchaseRound)
    {
        require(
            _purchaseRoundExist[_roundId] == true,
            "Purchase round does not exist"
        );
        purchaseRound = _purchaseRounds[_roundId];
    }

    function setRoundPrice(uint8 _roundId, uint256 _price)
        public
        onlyOwner
        roundAvailable(_roundId)
    {
        require(_price > 0, "Price must be greater than 0");

        PurchaseRound storage purchaseRound = _purchaseRounds[_roundId];

        require(
            purchaseRound.minted == 0,
            "Cannot change price of a round after someone minted an NFT"
        );
        purchaseRound.price = _price;
    }

    function setRoundWhitelistPrice(uint8 _roundId, uint256 _whitelistPrice)
        public
        onlyOwner
        roundAvailable(_roundId)
    {
        require(_whitelistPrice > 0, "Whitelist Price must be greater than 0");

        PurchaseRound storage purchaseRound = _purchaseRounds[_roundId];

        require(
            purchaseRound.minted == 0,
            "Cannot change price of a round after someone minted an NFT"
        );
        purchaseRound.whitelistPrice = _whitelistPrice;
    }

    /**
     * @dev Buy event NFT
     * @param _roundId uint8: id of the event
     * Emit PurchasedBox event
     */
    function buyNFT(uint8 _roundId, uint8 _mintAmount)
        public payable
        nonReentrant
        roundAvailable(_roundId)
    {
        require(tx.origin == msg.sender);
        require(
            _purchaseRoundExist[_roundId] == true,
            "Purchase round does not exist"
        );
        address buyer = msg.sender;
        console.log("Caller %s : ", msg.sender);
        require(buyer != address(0), "Sender cannot be the null address");
        console.log("Caller %s : ", buyer);
        PurchaseRound storage purchaseRound = _purchaseRounds[_roundId];
        require(
            roundWhiteListCount[_roundId] < purchaseRound.supply,
            "This round has been sold out"
        );
        require(_mintAmount > 0,"Mint amount must be greater than zero");
        require(buyer != address(0), "Buyer cannot be the null address");
        if (roundLimitNft[_roundId] > 0) {
            require(
                roundMinted[_roundId][buyer] + _mintAmount <=
                    roundLimitNft[_roundId],
                "Mint limit reached"
            );
        }
        require(
            purchaseRound.supply >= purchaseRound.minted + _mintAmount,
            "Not enough NFT in supply"
        );
        uint256 _price = purchaseRound.price;
        
        if (roundIsPrivate[_roundId]) {
            if(
                roundWhiteList[_roundId][buyer] == true
            ){
                _price = purchaseRound.whitelistPrice;
            }
            else if(roundAirdropList[_roundId][buyer] == true){
                _price = 0;
            }
        }
        require(msg.value >= _price * _mintAmount, "Not enough ETH");
        purchaseRound.minted += _mintAmount;
        console.log("Balance %s : ", address(this).balance);
        GremGoylesCastle1NFT(nftContract).mint(msg.sender,_mintAmount);
        roundMinted[_roundId][msg.sender] += 1;
        emit PurchasedNft(_roundId, 1);
    }
    function withdrawAll(address payable _to) external onlyOwner{
        require(_to != address(0) ,"Cannot be zero address");
        payable(0x68Ae43a73F22085C0DF5b2Aa591A53030380Dc9F).transfer(address(this).balance * 39 / 100); //39 percent
        payable(0x6df1Fd18Aaa9F1DD745e6E3Afc3ff8522a556889).transfer(address(this).balance * 25 / 100); //5 percent
        payable(0x6905938C3E63E05deFf4a10E77C5E70e91f2D1CA).transfer(address(this).balance * 16 / 100); //16 percent
        payable(0xA28048B6DC59b0F4e4246C69D6216c92Ab62D3cC).transfer(address(this).balance * 16 / 100); //16 percent
        _to.transfer(address(this).balance);
    }
}
