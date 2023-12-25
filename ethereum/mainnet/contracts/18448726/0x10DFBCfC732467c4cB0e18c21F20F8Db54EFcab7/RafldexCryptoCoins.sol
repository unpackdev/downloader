// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./Strings.sol";
import "./IERC721.sol";
import "./MerkleProof.sol";

contract RafldexCryptoCoins_V1_2 is Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    address constant vrfCoordinator =
        0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    address constant link_token_contract =
        0x514910771AF9Ca656af840dff83E8264EcF986CA;
    bytes32 private keyHash =
        0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

    uint16 private requestConfirmations = 3;
    uint32 private callbackGasLimit = 2500000;
    uint32 private numWords = 1;
    uint64 private subscriptionId = 810;

    struct RandomResult {
        uint256 randomNumber;
        uint256 nomalizedRandomNumber;
    }
    struct RaffleInfo {
        uint256 id;
        uint256 size;
    }

    mapping(uint256 => RandomResult) public requests;
    mapping(uint256 => RaffleInfo) public chainlinkRaffleInfo;

    event TokenAdded(address _address);
    event CollectionWhitelisted(address _collection, uint256 _rafflesnumber);
    event UserBlacklisted(address _address);
    event AddedTokenPayment(address _address);
    event RequestFulfilled(
        uint256 requestId,
        uint256 randomNumber,
        uint256 indexed raffleId
    );
    event RequestSent(uint256 requestId, uint32 numWords);
    event RaffleCreated(
        uint256 indexed raffleId
     //   address[] coinAddress,
    //    uint256[] amount
    );
    event RaffleDrawn(
        uint256 indexed raffleId,
        address indexed winner,
        uint256 amountRaised,
        uint256 randomNumber
    );
    event EntryBought(
        uint256 indexed raffleId,
        address indexed buyer,
        uint256 currentSize,
        uint256 numberEntries
    );
      event EntryGifted(
        uint256 indexed raffleId,
        address indexed gifter,
        address indexed buyer,
        uint256 currentSize,
        uint256 numberEntries
    );

    event RaffleSetNotToCancel(uint256 indexed raffleId, address creator);
    event RaffleCancelled(uint256 indexed raffleId, uint256 amountRaised);
    event SetWinnerTriggered(uint256 indexed raffleId, uint256 amountRaised);
    event RaffleRootChanged(uint256 indexed raffleId, bytes32 root);

    struct EntriesBought {
        address player;
        uint256 currentEntriesLength;
        uint256 entries;
    }
    mapping(uint256 => EntriesBought[]) public entriesList;

    enum STATUS {
        CREATED,
        PENDING_DRAW,
        DRAWING,
        DRAWN,
        CANCELLED
    }

    struct RaffleStruct {
        STATUS status;
        uint256 endTime;
        address[] collateralAddress;
        uint256[] collateralAmount;
        uint256 entriesSupply;
        uint256 pricePerEntry;
        uint256 maxEntriesUser;
        address winner;
        uint256 randomNumber;
        address creator;
        uint256 platformPercentage;
        address tokenPayment;
        uint256 entriesSold;
        bool canCancel;
        bytes32 root;
    }


    RaffleStruct[] public raffles;

    struct RaffleCreationHolder {
        uint256 startTime;
        uint256 endTime;
        uint256 countRaffles;
    }

    mapping(bytes32 => RaffleCreationHolder) public raffleCreationData;
    mapping(address => uint256) public numberRafflesMonthCollection;
    mapping(bytes32 => uint256) public entriesInfo;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    address payable private platformWallet =
        payable(0x2300Ae69d7D1Ea0457aD79e822422888e3Ee3e87);

    uint256 public CHAINLINK_RAFFLE_FEE = 0.015 ether;
    uint256 public HOLDER_CREATE_RAFFLE_FEE = 0.02 ether;
    uint256 public HOLDER_CREATE_RAFFLE_FEE_DISCOUNT = 0.01 ether;
    uint256 public CANCELATION_RAFFLE_FEE_BASE = 0 ether;
    uint256 public SUBSCRIPTION_PRICE = 0.5 ether;
    uint256 public COMMISSION_HOLDERS = 500; //5 %
    uint256 public COMMISSION_HOLDERS_DISCOUNT = 350; //3.5%
    uint256 public COMMISSION_SUBSCRIBERS = 300; //3%
    uint256 public COMMISSION_SUBSCRIBERS_DISCOUNT = 150; //1.5%

    mapping(address => bool) public TokenAddresses;
    mapping(address => bool) public TokenPaymentAddresses;
    mapping(address => bool) public DiscountTokenPayments;

    bool public createEnabledHolders = true;
    bool public createEnabledSubscribers = true;

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }
    mapping(bytes32 => RoleData) private _roles;

    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link_token_contract);
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyRole(bytes32 role, address account) {
        _checkRole(role, account);
        _;
    }

    function createRaffleOperator(
        uint256 _endTime,
        address[] memory _collateralAddress,
        uint256[] memory _collateralAmount,
        address _tokenPayment,
        uint256 _pricePerEntry,
        uint256 _maxEntriesRaffle,
        uint256 _maxEntriesUser,
                bytes32 _root

    ) external payable onlyRole(OPERATOR_ROLE, msg.sender) returns (uint256) {
        require(
            _endTime > getCurrentTime(),
            "End time can't be < as current time."
        );
        require(_maxEntriesRaffle > 0, "No entries");
        require(
            _maxEntriesUser > 0 && _maxEntriesUser <= _maxEntriesRaffle,
            "Min entries user > 0 and <= max entries raffle"
        );
        require(
            _collateralAddress.length == _collateralAmount.length,
            "Require same length"
        );

        if (_tokenPayment != address(0)) {
            require(
                TokenPaymentAddresses[_tokenPayment],
                "Token Address not added "
            );
        }
        uint256 totalEth;
        for (uint256 i = 0; i < _collateralAddress.length; i++) {
            require(_collateralAmount[i] > 0, "Amount can't be null");
            if (_collateralAddress[i] == address(0)) {
                totalEth += _collateralAmount[i];
            } else {
                require(
                    TokenAddresses[_collateralAddress[i]],
                    "Token Address not added "
                );
                /*
                require(
                    IERC20(_collateralAddress[i]).balanceOf(msg.sender) >=
                        _collateralAmount[i],
                    "Need to have in wallet equal or more than ERC20 Token price"
                );*/
                safeTransferFrom(
                    msg.sender,
                    address(this),
                    _collateralAddress[i],
                    _collateralAmount[i]
                );
            }
        }

        require(msg.value == totalEth, "Total mismatched");

        uint256 _commissionInBasicPoints = 0;

        RaffleStruct memory raffle = RaffleStruct({
            status: STATUS.CREATED,
            endTime: _endTime,
            collateralAddress: _collateralAddress,
            collateralAmount: _collateralAmount,
            pricePerEntry: _pricePerEntry,
            entriesSupply: _maxEntriesRaffle,
            maxEntriesUser: _maxEntriesUser,
            winner: address(0),
            randomNumber: 0,
            creator: msg.sender,
            platformPercentage: _commissionInBasicPoints,
            tokenPayment: _tokenPayment,
            entriesSold: 0,
            canCancel: true,
                        root: _root

        });

        raffles.push(raffle);

        uint256 idRaffle = raffles.length - 1;

        EntriesBought memory entryBought = EntriesBought({
            player: address(0),
            currentEntriesLength: 0,
            entries: 0
        });
        entriesList[idRaffle].push(entryBought);

        delete entriesList[idRaffle][0];

        emit RaffleCreated(idRaffle);
        return idRaffle;
    }

    function createRaffleSubscriber(
        uint256 _endTime,
        address[] memory _collateralAddress,
        uint256[] memory _collateralAmount,
        address _tokenPayment,
        uint256 _pricePerEntry,
        uint256 _maxEntriesRaffle,
        uint256 _maxEntriesUser,
        bytes32 _root
    ) external payable nonReentrant returns (uint256) {
        require(
            _endTime > getCurrentTime(),
            "End time can't be < as current time."
        );
        require(
            createEnabledSubscribers,
            "Create raffle noot set for subscribers."
        );
    
        require(msg.value >= CHAINLINK_RAFFLE_FEE, "Invalid funds provided");

        require(_maxEntriesRaffle > 0, "No entries");
        require(
            _maxEntriesUser > 0 && _maxEntriesUser <= _maxEntriesRaffle,
            "Min entries user > 0 and <= max entries raffle"
        );
        require(
            _collateralAddress.length == _collateralAmount.length,
            "Require same length"
        );

        if (_tokenPayment != address(0)) {
            require(
                TokenPaymentAddresses[_tokenPayment],
                "Token Address not added "
            );
        }
        uint256 totalEth;
        for (uint256 i = 0; i < _collateralAddress.length; i++) {
            require(_collateralAmount[i] > 0, "Amount can't be null");
            if (_collateralAddress[i] == address(0)) {
                totalEth += _collateralAmount[i];
            } else {
                require(
                    TokenAddresses[_collateralAddress[i]],
                    "Token Address not added "
                );
            
                safeTransferFrom(
                    msg.sender,
                    address(this),
                    _collateralAddress[i],
                    _collateralAmount[i]
                );
            }
        }
        require(msg.value >= totalEth + CHAINLINK_RAFFLE_FEE , "Total mismatched");

        uint256 _commissionInBasicPoints = 0;

        if (DiscountTokenPayments[_tokenPayment]) {
            _commissionInBasicPoints = COMMISSION_SUBSCRIBERS_DISCOUNT;
        } else {
            _commissionInBasicPoints = COMMISSION_SUBSCRIBERS;
        }
        platformWallet.transfer(CHAINLINK_RAFFLE_FEE);

        RaffleStruct memory raffle = RaffleStruct({
            status: STATUS.CREATED,
            endTime: _endTime,
            collateralAddress: _collateralAddress,
            collateralAmount: _collateralAmount,
            pricePerEntry: _pricePerEntry,
            entriesSupply: _maxEntriesRaffle,
            maxEntriesUser: _maxEntriesUser,
            winner: address(0),
            randomNumber: 0,
            creator: msg.sender,
            platformPercentage: _commissionInBasicPoints,
            tokenPayment: _tokenPayment,
            entriesSold: 0,
            canCancel: true,
            root: _root
        });

        raffles.push(raffle);

        uint256 idRaffle = raffles.length - 1;

        EntriesBought memory entryBought = EntriesBought({
            player: address(0),
            currentEntriesLength: 0,
            entries: 0
        });
        entriesList[idRaffle].push(entryBought);

        delete entriesList[idRaffle][0];

        emit RaffleCreated(idRaffle);
        return idRaffle;
    }

    function createRaffleHolder(
        address createRaffleCollection,
        uint256 createRaffleTokenId,
        uint256 _endTime,
        address[] memory _collateralAddress,
        uint256[] memory _collateralAmount,
        address _tokenPayment,
        uint256 _pricePerEntry,
        uint256 _maxEntriesRaffle,
        uint256 _maxEntriesUser
    ) external payable nonReentrant returns (uint256) {
        require(
            _endTime > getCurrentTime(),
            "End time can't be < as current time."
        );
        require(createEnabledHolders, "Create raffle not set for holders.");

        require(_maxEntriesRaffle > 0, "No entries");
        require(
            _maxEntriesUser > 0 && _maxEntriesUser <= _maxEntriesRaffle,
            "Min entries user > 0 and <= max entries raffle"
        );
        require(
            _collateralAddress.length == _collateralAmount.length,
            "Require same length"
        );

        if (_tokenPayment != address(0)) {
            require(
                TokenPaymentAddresses[_tokenPayment],
                "Token Address not added "
            );
        }


        IERC721 createraffleNFT = IERC721(createRaffleCollection);
        require(
            createraffleNFT.ownerOf(createRaffleTokenId) == msg.sender,
            "Not the owner of tokenId"
        );

        bytes32 hash = keccak256(
            abi.encode(createRaffleCollection, createRaffleTokenId)
        );

        if (raffleCreationData[hash].endTime > getCurrentTime()) {
            require(
                numberRafflesRemainingPerNFT(
                    createRaffleCollection,
                    createRaffleTokenId
                ) > 0,
                "Created too many raffles with your NFT you hold."
            );
            raffleCreationData[hash].countRaffles++;
        } else {
            raffleCreationData[hash].startTime = getCurrentTime();
            raffleCreationData[hash].endTime = getCurrentTime() + 30 days;
            raffleCreationData[hash].countRaffles = 1;
        }

        uint256 totalEth;
        for (uint256 i = 0; i < _collateralAddress.length; i++) {
            require(_collateralAmount[i] > 0, "Amount can't be null");
            if (_collateralAddress[i] == address(0)) {
                totalEth += _collateralAmount[i];
            } else {
                require(
                    TokenAddresses[_collateralAddress[i]],
                    "Token Address not added "
                );
          
                safeTransferFrom(
                    msg.sender,
                    address(this),
                    _collateralAddress[i],
                    _collateralAmount[i]
                );
            }
        }


       uint256 _commissionInBasicPoints = 0;
        if (DiscountTokenPayments[_tokenPayment]) {
            require(
                msg.value >=
                    HOLDER_CREATE_RAFFLE_FEE_DISCOUNT + CHAINLINK_RAFFLE_FEE + totalEth,
                "Invalid funds provided"
            );
            platformWallet.transfer(HOLDER_CREATE_RAFFLE_FEE_DISCOUNT + CHAINLINK_RAFFLE_FEE);

            _commissionInBasicPoints = COMMISSION_HOLDERS_DISCOUNT;
        } else {
            require(
                msg.value >= HOLDER_CREATE_RAFFLE_FEE + CHAINLINK_RAFFLE_FEE + totalEth,
                "Invalid funds provided"
            );
            platformWallet.transfer(HOLDER_CREATE_RAFFLE_FEE + CHAINLINK_RAFFLE_FEE);

            _commissionInBasicPoints = COMMISSION_HOLDERS;
        }


        RaffleStruct memory raffle = RaffleStruct({
            status: STATUS.CREATED,
            endTime: _endTime,
            collateralAddress: _collateralAddress,
            collateralAmount: _collateralAmount,
            pricePerEntry: _pricePerEntry,
            entriesSupply: _maxEntriesRaffle,
            maxEntriesUser: _maxEntriesUser,
            winner: address(0),
            randomNumber: 0,
            creator: msg.sender,
            platformPercentage: _commissionInBasicPoints,
            tokenPayment: _tokenPayment,
            entriesSold: 0,
            canCancel: true,
                        root: bytes32(0)

        });

        raffles.push(raffle);

        uint256 idRaffle = raffles.length - 1;

        EntriesBought memory entryBought = EntriesBought({
            player: address(0),
            currentEntriesLength: 0,
            entries: 0
        });
        entriesList[idRaffle].push(entryBought);

        delete entriesList[idRaffle][0];

        emit RaffleCreated(idRaffle);
        return idRaffle;
    }


    function giftEntry(
        uint256 _raffleId,
        uint256 _numberEntries,
        address _user,
        bytes32[] memory proof
    ) external payable {
        RaffleStruct storage raffle = raffles[_raffleId];
        require(raffle.endTime > getCurrentTime(), "Raffle Closed on time");
        require(raffle.status == STATUS.CREATED, "Raffle is not in CREATED");
        if (raffle.root != bytes32(0)) {
            require(
                isValid(
                    proof,
                    raffle.root,
                    keccak256(abi.encodePacked(msg.sender))
                ),
                "Not part of Whitelist"
            );
        }

        require(
            _numberEntries > 0 && _numberEntries <= raffle.maxEntriesUser,
            "Number entries can't be 0 or more than max entries per user."
        );
        require(
            _user != address(0) && _user != msg.sender,
            "Address cant't be null address / msg sender"
        );
        require(
            raffle.entriesSold + _numberEntries <=
                raffles[_raffleId].entriesSupply,
            "Raffle has reached max entries"
        );

        if (raffle.tokenPayment == address(0)) {
            require(
                msg.value == raffle.pricePerEntry * _numberEntries,
                "msg.value must be equal to the price"
            );
        } else {
            IERC20(raffle.tokenPayment).transferFrom(
                msg.sender,
                address(this),
                raffle.pricePerEntry * _numberEntries
            );
        }

        bytes32 hash = keccak256(abi.encode(msg.sender, _raffleId));
        require(
            entriesInfo[hash] + _numberEntries <= raffle.maxEntriesUser,
            "Max entries user reached."
        );

        entriesInfo[hash] += _numberEntries;
        EntriesBought memory entryBought = EntriesBought({
            player: _user,
            currentEntriesLength: uint256(raffle.entriesSold + _numberEntries),
            entries: _numberEntries
        });
        entriesList[_raffleId].push(entryBought);
        raffle.entriesSold += _numberEntries;

        emit EntryGifted(
            _raffleId,
            msg.sender,
            _user,
            raffle.entriesSold,
            _numberEntries
        );
    }



    function buyEntry(
        uint256 _raffleId,
        uint256 _numberEntries,
        bytes32[] memory proof
    ) external payable {
        RaffleStruct storage raffle = raffles[_raffleId];

        require(raffle.endTime > getCurrentTime(), "Raffle Closed on time");
        require(raffle.status == STATUS.CREATED, "Raffle is not in CREATED");
        require(
            _numberEntries > 0 && _numberEntries <= raffle.maxEntriesUser,
            "Number entries can't be 0 or more than max entries per user."
        );
        require(msg.sender != address(0), "Address cant't be null address");
        require(
            raffle.entriesSold + _numberEntries <=
                raffles[_raffleId].entriesSupply,
            "Raffle has reached max entries"
        );
             if (raffle.root != bytes32(0)) {
            require(
                isValid(
                    proof,
                    raffle.root,
                    keccak256(abi.encodePacked(msg.sender))
                ),
                "Not part of the Whitelist"
            );
        }

        if (raffle.tokenPayment == address(0)) {
            require(
                msg.value == raffle.pricePerEntry * _numberEntries,
                "msg.value must be equal to the price"
            );
        } else {
     
            IERC20(raffle.tokenPayment).transferFrom(
                msg.sender,
                address(this),
                raffle.pricePerEntry * _numberEntries
            );
        }

        bytes32 hash = keccak256(abi.encode(msg.sender, _raffleId));
        require(
            entriesInfo[hash] + _numberEntries <= raffle.maxEntriesUser,
            "Max entries user reached."
        );

        entriesInfo[hash] += _numberEntries;
        EntriesBought memory entryBought = EntriesBought({
            player: msg.sender,
            currentEntriesLength: uint256(raffle.entriesSold + _numberEntries),
            entries: _numberEntries
        });
        entriesList[_raffleId].push(entryBought);
        raffle.entriesSold += _numberEntries;

        emit EntryBought(_raffleId, msg.sender, raffle.entriesSold, _numberEntries);
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function addorRemoveTokens(address[] memory _addresses, bool _isAdded)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            TokenAddresses[_addresses[i]] = _isAdded;
            if (_isAdded == true) {
                emit TokenAdded(_addresses[i]);
            }
        }
    }


    function ChangeCancellationFeeBase(uint256 _fee)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        CANCELATION_RAFFLE_FEE_BASE = _fee;
    }

    function ChangeSubscriptionId(uint64 _id)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        subscriptionId = _id;
    }

    function ChangecallbackGasLimit(uint32 _number)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        callbackGasLimit = _number;
    }

    function ChangeKeyHash(bytes32 _hash)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        keyHash = _hash;
    }


    function setNumberRafflesCollectionWhitelistedPerMonth(
        address[] memory _collection,
        uint256[] memory _rafflesnumber
    ) external onlyRole(OPERATOR_ROLE, msg.sender) {
        require(
            _collection.length == _rafflesnumber.length,
            "Require same length"
        );
        for (uint256 i = 0; i < _collection.length; i++) {
            numberRafflesMonthCollection[_collection[i]] = _rafflesnumber[i];
            emit CollectionWhitelisted(_collection[i], _rafflesnumber[i]);
        }
    }

    function numberRafflesRemainingPerNFT(
        address _collectionaddress,
        uint256 _tokenid
    ) public view returns (uint256) {
        uint256 numberRafflesNFT = 0;
        if (numberRafflesMonthCollection[_collectionaddress] > 0) {
            bytes32 hashNFT = keccak256(
                abi.encode(_collectionaddress, _tokenid)
            );
            numberRafflesNFT =
                numberRafflesMonthCollection[_collectionaddress] -
                raffleCreationData[hashNFT].countRaffles;
        }
        return numberRafflesNFT;
    }

    function changePlatformWalletAddress(address payable _address)
        external
        onlyOwner
    {
        platformWallet = _address;
    }

    function getEntriesBought(uint256 _raffleId)
        public
        view
        returns (EntriesBought[] memory)
    {
        return entriesList[_raffleId];
    }

    function addTokenPayments(address[] memory _address, bool _isAdded)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        for (uint256 i = 0; i < _address.length; i++) {
            TokenPaymentAddresses[_address[i]] = _isAdded;
            if (_isAdded == true) {
                emit AddedTokenPayment(_address[i]);
            }
        }
    }

    function addDiscountTokenPayment(address _address, bool _isAdded)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        DiscountTokenPayments[_address] = _isAdded;
    }

    function toggleCreateHoldersEnabled()
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        createEnabledHolders = !createEnabledHolders;
    }

    function toggleCreateSubscribersEnabled()
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        createEnabledSubscribers = !createEnabledSubscribers;
    }

    function getWinnerAddressFromRandom(
        uint256 _raffleId,
        uint256 _normalizedRandomNumber
    ) public view returns (address) {
        address winner;
        EntriesBought[] storage entries = entriesList[_raffleId];
        for (uint256 i = 0; i < entries.length; i++) {
            uint256 entriesIndex = entries[i].currentEntriesLength;
            if (entriesIndex >= _normalizedRandomNumber) {
                winner = entries[i].player;
                break;
            }
        }
        require(winner != address(0), "Winner not found");
        return winner;
    }

    function requestRandomWords(uint256 _id, uint256 _entriesSold)
        internal
        returns (uint256 requestId)
    {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        chainlinkRaffleInfo[requestId] = RaffleInfo({
            id: _id,
            size: _entriesSold
        });
        RaffleStruct storage raffle = raffles[_id];
        raffle.status = STATUS.DRAWING;

        emit RequestSent(requestId, numWords);

        return requestId;
    }

    function requestRandomWordsRetry(uint256 _id)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
        returns (uint256 requestId)
    {
        RaffleStruct storage raffle = raffles[_id];

        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        chainlinkRaffleInfo[requestId] = RaffleInfo({
            id: _id,
            size: raffle.entriesSold
        });
        raffle.status = STATUS.DRAWING;

        emit RequestSent(requestId, numWords);

        return requestId;
    }

    function transferNFTsAndFunds(
        uint256 _raffleId,
        uint256 _normalizedRandomNumber
    ) internal nonReentrant {
        RaffleStruct storage raffle = raffles[_raffleId];
        raffle.randomNumber = _normalizedRandomNumber;
        raffle.winner = (raffle.entriesSold == 0)
            ? raffle.creator
            : getWinnerAddressFromRandom(_raffleId, _normalizedRandomNumber);

        safeMultipleTransfersFrom(
            address(this),
            raffle.winner,
            raffle.collateralAddress,
            raffle.collateralAmount
        );

        uint256 amountRaised = raffle.entriesSold * raffle.pricePerEntry;
        uint256 amountForPlatform = (amountRaised * raffle.platformPercentage) /
            10000;
        uint256 amountForSeller = amountRaised - amountForPlatform;

        if (raffle.tokenPayment == address(0)) {
            (bool sent, ) = raffle.creator.call{value: amountForSeller}("");
            require(sent, "Failed to send Eth");

            (bool sent2, ) = platformWallet.call{value: amountForPlatform}("");
            require(sent2, "Failed send Eth to Platform");
        } else {
            IERC20(raffle.tokenPayment).approve(address(this), amountRaised);
            bool sent = IERC20(raffle.tokenPayment).transferFrom(
                address(this),
                raffle.creator,
                amountForSeller
            );
            require(sent, "Failed to send ERC20 Token");
            bool sent2 = IERC20(raffle.tokenPayment).transferFrom(
                address(this),
                platformWallet,
                amountForPlatform
            );
            require(sent2, "Failed to send ERC20 Token to platform");
        }
        raffle.status = STATUS.DRAWN;

        emit RaffleDrawn(
            _raffleId,
            raffle.winner,
            amountRaised,
            raffle.randomNumber
        );
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 normalizedRandomNumber = (_randomWords[0] %
            chainlinkRaffleInfo[_requestId].size) + 1;
        RaffleStruct storage raffle = raffles[
            chainlinkRaffleInfo[_requestId].id
        ];

        raffle.randomNumber = normalizedRandomNumber;

        RandomResult memory result = RandomResult({
            randomNumber: _randomWords[0],
            nomalizedRandomNumber: normalizedRandomNumber
        });

        requests[chainlinkRaffleInfo[_requestId].id] = result;

        emit RequestFulfilled(
            _requestId,
            normalizedRandomNumber,
            chainlinkRaffleInfo[_requestId].id
        );
        transferNFTsAndFunds(
            chainlinkRaffleInfo[_requestId].id,
            normalizedRandomNumber
        );
    }

    function setWinnerRaffle(uint256 _raffleId) external nonReentrant {
        RaffleStruct storage raffle = raffles[_raffleId];
        require(
            raffle.creator == msg.sender || hasRole(OPERATOR_ROLE, msg.sender),
            "Not raffle creator or operator."
        );
        if (
            hasRole(OPERATOR_ROLE, msg.sender) && raffle.creator != msg.sender
        ) {
            require(
                raffle.entriesSold == raffle.entriesSupply ||
                    raffle.endTime <= getCurrentTime(),
                "Raffle still opened or not sold out"
            );
        }
        require(raffle.status == STATUS.CREATED, "Raffle in wrong status");
        raffle.status = STATUS.PENDING_DRAW;
        uint256 entriesSold = raffle.entriesSold;
        uint256 amountRaised = entriesSold * raffle.pricePerEntry;
        if (entriesSold == 0) {
            raffle.status = STATUS.DRAWING;
            transferNFTsAndFunds(_raffleId, raffle.randomNumber);
        } else {
            requestRandomWords(_raffleId, entriesSold);
        }
        emit SetWinnerTriggered(_raffleId, amountRaised);
    }

    function setWinnerRaffleEmergency(uint256 _raffleId)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        //function in case that chainlink vrf2 doesnt work
        RaffleStruct storage raffle = raffles[_raffleId];

        if (
            raffle.creator != msg.sender
        ) {
            require(
                raffle.entriesSold == raffle.entriesSupply ||
                    raffle.endTime <= getCurrentTime(),
                "Raffle still opened or not sold out"
            );
        }

        uint256 entriesSold = raffle.entriesSold;

        bytes32 baseHash = keccak256(
            abi.encodePacked(
                block.number,
                block.timestamp,
                block.gaslimit,
                block.coinbase
            )
        );
        uint256 normalizedRandomNumber = (uint256(baseHash) % entriesSold) + 1;

        raffle.randomNumber = normalizedRandomNumber;
        transferNFTsAndFunds(_raffleId, normalizedRandomNumber);
    }

    function cancelRaffle(uint256 _raffleId) external payable nonReentrant {
        RaffleStruct storage raffle = raffles[_raffleId];
        require(
            raffle.creator == msg.sender || hasRole(OPERATOR_ROLE, msg.sender),
            "Not raffle creator or Operator."
        );
        require(
            raffle.endTime > getCurrentTime(),
            "End time can't be < as current time."
        );
        require(raffle.status == STATUS.CREATED, "Wrong status");

        if (!hasRole(OPERATOR_ROLE, msg.sender)) {
            require(raffle.canCancel, "User Can't cancel");
            if (raffle.entriesSold == 0) {
                require(msg.value == 0, "Not cancelation fee value.");
            } else {
                require(
                    msg.value >= CANCELATION_RAFFLE_FEE_BASE,
                    "Not cancelation fee value."
                );
                platformWallet.transfer(CANCELATION_RAFFLE_FEE_BASE);
            }
        }

        uint256 txLength = entriesList[_raffleId].length;
        require(
            txLength <= 200,
            "Not cancelation available when it's more than 200 txs."
        );

        uint256 amountRaised = raffle.entriesSold * raffle.pricePerEntry;

        if (raffle.tokenPayment == address(0)) {
            for (uint256 i = 0; i < txLength; i++) {
                address user = entriesList[_raffleId][i].player;
                if (user != address(0)) {
                    uint256 amountToSend = raffle.pricePerEntry *
                        entriesList[_raffleId][i].entries;
                    payable(user).transfer(amountToSend);
                }
            }
        } else {
            IERC20(raffle.tokenPayment).approve(address(this), amountRaised);
            for (uint256 i = 0; i < txLength; i++) {
                address user = entriesList[_raffleId][i].player;
                if (user != address(0)) {
                    uint256 amountToSend = raffle.pricePerEntry *
                        entriesList[_raffleId][i].entries;
                    IERC20(raffle.tokenPayment).transferFrom(
                        address(this),
                        user,
                        amountToSend
                    );
                }
            }
        }

        safeMultipleTransfersFrom(
            address(this),
            raffle.creator,
            raffle.collateralAddress,
            raffle.collateralAmount
        );

        raffle.status = STATUS.CANCELLED;
        emit RaffleCancelled(_raffleId, amountRaised);
    }

    function safeMultipleTransfersFrom(
        address from,
        address to,
        address[] memory tokenAddresses,
        uint256[] memory tokenAmounts
    ) internal virtual {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            safeTransferFrom(from, to, tokenAddresses[i], tokenAmounts[i]);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        address tokenAddress,
        uint256 tokenAmount
    ) internal virtual {
        if (tokenAddress == address(0)) {
            payable(to).transfer(tokenAmount);
        } else {
            if (from == address(this)) {
                IERC20(tokenAddress).approve(address(this), tokenAmount);
            }
            IERC20(tokenAddress).transferFrom(from, to, tokenAmount);
        }
    }

    function setRaffleToNotCancel(uint256 _raffleId) external nonReentrant {
        RaffleStruct storage raffle = raffles[_raffleId];
        require(raffle.creator == msg.sender, "Not raffle creator.");
        if (raffle.canCancel == true) {
            raffle.canCancel = false;
            emit RaffleSetNotToCancel(_raffleId, msg.sender);
        }
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        returns (bool)
    {
        return _roles[role].members[account];
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function grantRole(bytes32 role, address account)
        public
        virtual
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        _revokeRole(role, account);
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
        }
    }

    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
        }
    }

    function isValid(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) public view virtual returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function changeRootRaffle(uint256 _raffleId, bytes32 _root)
        external
        nonReentrant
    {
        RaffleStruct storage raffle = raffles[_raffleId];
        require(raffle.creator == msg.sender, "Not raffle creator.");
        raffle.root = _root;
        emit RaffleRootChanged(_raffleId, _root);
    }
}