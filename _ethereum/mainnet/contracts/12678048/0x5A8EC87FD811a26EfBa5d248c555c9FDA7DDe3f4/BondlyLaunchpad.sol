// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.3;

/////////////////////////////////////////////////
//  ____                        _   _          //
// | __ )    ___    _ __     __| | | |  _   _  //
// |  _ \   / _ \  | '_ \   / _` | | | | | | | //
// | |_) | | (_) | | | | | | (_| | | | | |_| | //
// |____/   \___/  |_| |_|  \__,_| |_|  \__, | //
//                                      |___/  //
/////////////////////////////////////////////////

import "./Ownable.sol";
import "./Strings.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";

contract BondlyLaunchPad is Ownable {
    using Strings for string;
    using SafeMath for uint256;
    using Address for address;

    uint256 public _currentCardId = 0;
    address payable public _salesperson;
    uint256 public _limitPerWallet;
    bool public _saleStarted = false;

    struct Card {
        uint256 cardId;
        uint256 tokenId;
        uint256 totalAmount;
        uint256 currentAmount;
        uint256 basePrice;
        uint256[] times;
        uint8[] tiers;
        address contractAddress;
        address paymentToken;
        bool isFinished;
    }

    struct History {
        mapping(uint256 => mapping(address => uint8)) purchasedHistories; // tokenId -> wallet -> amount
    }

    // Events
    event CreateCard(
        address indexed _from,
        uint256 _cardId,
        address indexed _contractAddress,
        uint256 _tokenId,
        uint256 _totalAmount,
        uint256 _basePrice
    );

    event PurchaseCard(address indexed _from, uint256 _cardId, uint256 _amount);
    event CardChanged(uint256 _cardId);

    bool public isPublicSale;
    address public limitTokenForPublicSale;
    uint256 public limitTokenAmountForPublicSale;

    mapping(uint256 => Card) public _cards;
    mapping(address => bool) public _blacklist;
    mapping(uint256 => mapping(address => uint8)) public _whitelist; // tokenId -> wallet -> whitelistLevel

    // whitelist level      | Priority
    // 0: Not available     |    /\
    // 1: selected winners  |    ||
    // 2: bronze            |    ||
    // 3: silver            |    ||
    // 4: gold              |    ||
    // 5: platinum          |    ||

    mapping(address => History) private _history;

    constructor() {
        _salesperson = msg.sender;
        _limitPerWallet = 1;
        isPublicSale = false;
        limitTokenForPublicSale = 0xD2dDa223b2617cB616c1580db421e4cFAe6a8a85;
        limitTokenAmountForPublicSale = 10000 * 10**18;
    }

    function setLimitForPublicSale(uint256 limitAmount, address limitToken)
        external
        onlyOwner
    {
        limitTokenForPublicSale = limitToken;
        limitTokenAmountForPublicSale = limitAmount;
    }

    function setLimitPerWallet(uint256 limit) external onlyOwner {
        _limitPerWallet = limit;
    }

    function setSalesPerson(address payable newSalesPerson) external onlyOwner {
        _salesperson = newSalesPerson;
    }

    function startSale() external onlyOwner {
        _saleStarted = true;
    }

    function stopSale() external onlyOwner {
        _saleStarted = false;
    }

    function createCard(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _totalAmount,
        address _paymentTokenAddress,
        uint256 _basePrice
    ) external onlyOwner {
        IERC1155 _contract = IERC1155(_contractAddress);
        require(
            _contract.balanceOf(_salesperson, _tokenId) >= _totalAmount,
            "Initial supply cannot be more than available supply"
        );
        require(
            _contract.isApprovedForAll(_salesperson, address(this)) == true,
            "Contract must be whitelisted by owner"
        );
        uint256 _id = _getNextCardID();
        _incrementCardId();
        Card memory _newCard;
        _newCard.cardId = _id;
        _newCard.contractAddress = _contractAddress;
        _newCard.tokenId = _tokenId;
        _newCard.totalAmount = _totalAmount;
        _newCard.currentAmount = _totalAmount;
        _newCard.basePrice = _basePrice;
        _newCard.paymentToken = _paymentTokenAddress;
        _newCard.isFinished = false;

        _cards[_id] = _newCard;
        emit CreateCard(
            msg.sender,
            _id,
            _contractAddress,
            _tokenId,
            _totalAmount,
            _basePrice
        );
    }

    function isEligbleToBuy(uint256 _cardId) public view returns (uint256) {
        if (_blacklist[msg.sender] == true) return 0;

        if (_saleStarted == false) return 0;

        Card memory _currentCard = _cards[_cardId];

        if (isPublicSale) {
            if (
                IERC20(limitTokenForPublicSale).allowance(
                    msg.sender,
                    address(this)
                ) < limitTokenAmountForPublicSale
            ) return 0;

            History storage _currentHistory =
                _history[_currentCard.contractAddress];
            uint256 _currentBoughtAmount =
                _currentHistory.purchasedHistories[_currentCard.tokenId][
                    msg.sender
                ];

            if (_currentBoughtAmount >= _limitPerWallet) return 0;

            if (
                _currentCard.currentAmount <=
                _limitPerWallet.sub(_currentBoughtAmount)
            ) return _currentCard.currentAmount;

            return _limitPerWallet.sub(_currentBoughtAmount);
        }

        if (_currentCard.times.length == 0) return 0;

        for (uint256 i = 0; i < _currentCard.times.length; i++) {
            if (
                block.timestamp >= _currentCard.times[i] &&
                _whitelist[_cardId][msg.sender] == _currentCard.tiers[i]
            ) {
                History storage _currentHistory =
                    _history[_currentCard.contractAddress];
                uint256 _currentBoughtAmount =
                    _currentHistory.purchasedHistories[_currentCard.tokenId][
                        msg.sender
                    ];

                if (_currentBoughtAmount >= _limitPerWallet) return 0;

                if (
                    _currentCard.currentAmount <=
                    _limitPerWallet.sub(_currentBoughtAmount)
                ) return _currentCard.currentAmount;

                return _limitPerWallet.sub(_currentBoughtAmount);
            }
        }

        return 0;
    }

    function purchaseNFT(uint256 _cardId, uint256 _amount) external payable {
        require(_blacklist[msg.sender] == false, "you are blocked");

        require(_saleStarted == true, "Sale stopped");

        Card memory _currentCard = _cards[_cardId];
        require(_currentCard.isFinished == false, "Card is finished");

        if (!isPublicSale) {
            uint8 currentTier = _whitelist[_cardId][msg.sender];
            require(currentTier != 0, "you are not whitelisted");

            uint256 startTime;
            for (uint256 i = 0; i < _currentCard.tiers.length; i++) {
                if (_currentCard.tiers[i] == currentTier) {
                    startTime = _currentCard.times[i];
                }
            }

            require(
                startTime != 0 && startTime <= block.timestamp,
                "wait for sale start"
            );
        }

        IERC1155 _nftContract = IERC1155(_currentCard.contractAddress);
        require(
            _currentCard.currentAmount >= _amount,
            "Order exceeds the max number of available NFTs"
        );

        History storage _currentHistory =
            _history[_currentCard.contractAddress];
        uint256 _currentBoughtAmount =
            _currentHistory.purchasedHistories[_currentCard.tokenId][
                msg.sender
            ];

        require(
            _currentBoughtAmount < _limitPerWallet,
            "Order exceeds the max limit of NFTs per wallet"
        );

        uint256 availableAmount = _limitPerWallet.sub(_currentBoughtAmount);
        if (availableAmount > _amount) {
            availableAmount = _amount;
        }

        uint256 _price = _currentCard.basePrice.mul(availableAmount);

        require(
            _currentCard.paymentToken == address(0) ||
                IERC20(_currentCard.paymentToken).allowance(
                    msg.sender,
                    address(this)
                ) >=
                _price,
            "Need to Approve payment"
        );

        if (_currentCard.paymentToken == address(0)) {
            require(msg.value >= _price, "Not enough funds to purchase");
            uint256 overPrice = msg.value - _price;
            _salesperson.transfer(_price);

            if (overPrice > 0) msg.sender.transfer(overPrice);
        } else {
            require(
                IERC20(_currentCard.paymentToken).allowance(
                    msg.sender,
                    address(this)
                ) >= _price,
                "Need to approve first"
            );
            IERC20(_currentCard.paymentToken).transferFrom(
                msg.sender,
                _salesperson,
                _price
            );
        }

        _nftContract.safeTransferFrom(
            _salesperson,
            msg.sender,
            _currentCard.tokenId,
            availableAmount,
            ""
        );
        _cards[_cardId].currentAmount = _cards[_cardId].currentAmount.sub(
            availableAmount
        );

        _currentHistory.purchasedHistories[_currentCard.tokenId][
            msg.sender
        ] = uint8(_currentBoughtAmount.add(availableAmount));

        emit PurchaseCard(msg.sender, _cardId, availableAmount);
    }

    function _getNextCardID() private view returns (uint256) {
        return _currentCardId.add(1);
    }

    function _incrementCardId() private {
        _currentCardId++;
    }

    function cancelCard(uint256 _cardId) external onlyOwner {
        _cards[_cardId].isFinished = true;

        emit CardChanged(_cardId);
    }

    function openPublicSale(bool _isOpen) external onlyOwner {
        isPublicSale = _isOpen;
    }

    function setTimes(
        uint256 _cardId,
        uint8 _tier,
        uint256 _finalTime
    ) external onlyOwner {
        Card storage _currentCard = _cards[_cardId];

        for (uint256 i = 0; i < _currentCard.tiers.length; i++) {
            if (_currentCard.tiers[i] == _tier) {
                _currentCard.times[i] = _finalTime;
                emit CardChanged(_cardId);
                return;
            }
        }

        _currentCard.tiers.push(_tier);
        _currentCard.times.push(_finalTime);
        emit CardChanged(_cardId);
    }

    function resumeCard(uint256 _cardId) external onlyOwner {
        _cards[_cardId].isFinished = false;

        emit CardChanged(_cardId);
    }

    function setCardPrice(uint256 _cardId, uint256 _newPrice)
        external
        onlyOwner
        returns (bool)
    {
        _cards[_cardId].basePrice = _newPrice;

        emit CardChanged(_cardId);
        return true;
    }

    function addBlackListAddress(address addr) external onlyOwner {
        _blacklist[addr] = true;
    }

    function batchAddBlackListAddress(address[] calldata addr)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addr.length; i++) {
            _blacklist[addr[i]] = true;
        }
    }

    function removeBlackListAddress(address addr) external onlyOwner {
        _blacklist[addr] = false;
    }

    function batchRemoveBlackListAddress(address[] calldata addr)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addr.length; i++) {
            _blacklist[addr[i]] = false;
        }
    }

    function addWhiteListAddress(
        uint256 _cardId,
        address _addr,
        uint8 _tier
    ) external onlyOwner {
        _whitelist[_cardId][_addr] = _tier;
    }

    function batchAddWhiteListAddress(
        uint256 _cardId,
        address[] calldata _addr,
        uint8 _tier
    ) external onlyOwner {
        for (uint256 i = 0; i < _addr.length; i++) {
            _whitelist[_cardId][_addr[i]] = _tier;
        }
    }

    function isPublicSaleOpened() public view returns (bool) {
        return isPublicSale;
    }

    function isCardCompleted(uint256 _cardId) public view returns (bool) {
        return _cards[_cardId].isFinished;
    }

    function isCardFree(uint256 _cardId) public view returns (bool) {
        return _cards[_cardId].basePrice == 0;
    }

    function getCardContract(uint256 _cardId) public view returns (address) {
        return _cards[_cardId].contractAddress;
    }

    function getCardTokenId(uint256 _cardId) public view returns (uint256) {
        return _cards[_cardId].tokenId;
    }

    function getCardTime(uint256 _cardId)
        public
        view
        returns (uint256[] memory)
    {
        return _cards[_cardId].times;
    }

    function getCardTotalAmount(uint256 _cardId) public view returns (uint256) {
        return _cards[_cardId].totalAmount;
    }

    function getCardCurrentAmount(uint256 _cardId)
        public
        view
        returns (uint256)
    {
        return _cards[_cardId].currentAmount;
    }

    function getAllCardsPerContract(address _contractAddr)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256 count;
        for (uint256 i = 1; i <= _currentCardId; i++) {
            if (_cards[i].contractAddress == _contractAddr) {
                count++;
            }
        }

        uint256[] memory cardIds = new uint256[](count);
        uint256[] memory tokenIds = new uint256[](count);
        count = 0;

        for (uint256 i = 1; i <= _currentCardId; i++) {
            if (_cards[i].contractAddress == _contractAddr) {
                cardIds[count] = i;
                tokenIds[count] = _cards[i].tokenId;
                count++;
            }
        }

        return (cardIds, tokenIds);
    }

    function getActiveCardsPerContract(address _contractAddr)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256 count;
        for (uint256 i = 1; i <= _currentCardId; i++) {
            if (
                _cards[i].contractAddress == _contractAddr &&
                _cards[i].isFinished == false
            ) {
                count++;
            }
        }

        uint256[] memory cardIds = new uint256[](count);
        uint256[] memory tokenIds = new uint256[](count);
        count = 0;

        for (uint256 i = 1; i <= _currentCardId; i++) {
            if (
                _cards[i].contractAddress == _contractAddr &&
                _cards[i].isFinished == false
            ) {
                cardIds[count] = i;
                tokenIds[count] = _cards[i].tokenId;
                count++;
            }
        }

        return (cardIds, tokenIds);
    }

    function getClosedCardsPerContract(address _contractAddr)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256 count;
        for (uint256 i = 1; i <= _currentCardId; i++) {
            if (
                _cards[i].contractAddress == _contractAddr &&
                _cards[i].isFinished
            ) {
                count++;
            }
        }

        uint256[] memory cardIds = new uint256[](count);
        uint256[] memory tokenIds = new uint256[](count);
        count = 0;

        for (uint256 i = 1; i <= _currentCardId; i++) {
            if (
                _cards[i].contractAddress == _contractAddr &&
                _cards[i].isFinished
            ) {
                cardIds[count] = i;
                tokenIds[count] = _cards[i].tokenId;
                count++;
            }
        }

        return (cardIds, tokenIds);
    }

    function getCardBasePrice(uint256 _cardId) public view returns (uint256) {
        return _cards[_cardId].basePrice;
    }

    function getCardURL(uint256 _cardId) public view returns (string memory) {
        return
            IERC1155MetadataURI(_cards[_cardId].contractAddress).uri(
                _cards[_cardId].tokenId
            );
    }

    function collect(address _token) external onlyOwner {
        if (_token == address(0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            uint256 amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(msg.sender, amount);
        }
    }
}
