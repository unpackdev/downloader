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
import "./ERC20.sol";
import "./SafeERC20.sol";

contract BondlyLaunchPad is Ownable {
    using Strings for string;
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for ERC20;

    uint256 public _currentCardId = 0;
    address payable public _salesperson;
    uint256 public _limitPerWallet;
    bool public _saleStarted = false;
    uint256[] private times;
    uint8[] tiers;

    struct Card {
        uint256 cardId;
        uint256 totalAmount;
        uint256 currentAmount;
        uint256 basePrice;
        address paymentToken;
        bool isFinished;
    }

    struct History {
        mapping(address => uint256) purchasedHistories; // wallet -> amount
    }

    // Events
    event CreateCard(
        address indexed _from,
        uint256 _cardId,
        uint256 _totalAmount,
        uint256 _basePrice
    );

    event PurchaseCard(address indexed _from, uint256 _cardId, uint256 _amount);
    event CardChanged(uint256 _cardId);

    address public limitTokenForPublicSale;
    uint256 public limitTokenAmountForPublicSale;

    mapping(uint256 => Card) public _cards;
    mapping(uint256 => address[]) private _purchasers;
    mapping(address => bool) public _blacklist;
    mapping(address => uint8) public _whitelist; // wallet -> whitelistLevel

    // whitelist level      | Priority
    // 0: public sale       |    /\
    // 1: bronze            |    ||
    // 2: silver            |    ||
    // 3: gold              |    ||
    // 4: platinum          |    ||
    // 5: VIP 2             |    ||
    // 6: VIP 1             |    ||

    mapping(uint256 => History) private _history;

    constructor() {
        _salesperson = msg.sender;
        _limitPerWallet = 1;
        limitTokenForPublicSale = 0x91dFbEE3965baAEE32784c2d546B7a0C62F268c9;
        limitTokenAmountForPublicSale = 10000 * 10**18;
    }

    function setLimitPerWallet(uint256 limit) external onlyOwner {
        _limitPerWallet = limit;
    }

    function setLimitForPublicSale(uint256 limitAmount, address limitToken)
        external
        onlyOwner
    {
        limitTokenForPublicSale = limitToken;
        limitTokenAmountForPublicSale = limitAmount;
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
        uint256 _totalAmount,
        address _paymentTokenAddress,
        uint256 _basePrice
    ) external onlyOwner {
        uint256 _id = _getNextCardID();
        _incrementCardId();
        Card memory _newCard;
        _newCard.cardId = _id;
        _newCard.totalAmount = _totalAmount;
        _newCard.currentAmount = _totalAmount;
        _newCard.basePrice = _basePrice;
        _newCard.paymentToken = _paymentTokenAddress;
        _newCard.isFinished = false;

        _cards[_id] = _newCard;
        emit CreateCard(
            msg.sender,
            _id,
            _totalAmount,
            _basePrice
        );
    }

    function isEligbleToBuy(uint256 _cardId) public view returns (uint256) {
        if (_blacklist[msg.sender] == true) return 0;

        if (_saleStarted == false) return 0;

        Card memory _currentCard = _cards[_cardId];

        if (times.length == 0) return 0;

        for (uint256 i = 0; i < times.length; i++) {
            uint8 currentTier = tiers[i];
            if (
                block.timestamp >= times[i] &&
                _whitelist[msg.sender] == currentTier
            ) {
                if(currentTier == 0){
                    if(ERC20(limitTokenForPublicSale).balanceOf(msg.sender) < limitTokenAmountForPublicSale){
                        return 0;
                    }                        
                }
                History storage _currentHistory =
                    _history[_currentCard.cardId];
                uint256 _currentBoughtAmount =_currentHistory.purchasedHistories[msg.sender];

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

        uint8 currentTier = _whitelist[msg.sender];

        uint256 startTime;
        for (uint256 i = 0; i < tiers.length; i++) {
            if (tiers[i] == currentTier) {
                startTime = times[i];
                break;
            }
        }

        require(
            startTime != 0 && startTime <= block.timestamp,
            "wait for sale start"
        );

        if(currentTier == 0){
            require(
                ERC20(limitTokenForPublicSale).balanceOf(msg.sender) >= limitTokenAmountForPublicSale,
                "Not enough Bondly for public sale"
            );
        }

        History storage _currentHistory = _history[_currentCard.cardId];
        uint256 _currentBoughtAmount = _currentHistory.purchasedHistories[msg.sender];

        require(
            _currentBoughtAmount < _limitPerWallet,
            "Order exceeds the max limit of NFTs per wallet"
        );

        uint256 availableAmount = _limitPerWallet.sub(_currentBoughtAmount);
        if (availableAmount > _amount) {
            availableAmount = _amount;
        }

        require(_cards[_cardId].currentAmount >= availableAmount, "Sold Out!");

        uint256 _price = _currentCard.basePrice.mul(availableAmount);

        require(
            _currentCard.paymentToken == address(0) ||
                ERC20(_currentCard.paymentToken).allowance(
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
            ERC20(_currentCard.paymentToken).transferFrom(
                msg.sender,
                _salesperson,
                _price
            );
        }

        _purchasers[_cardId].push(msg.sender);
        
        _cards[_cardId].currentAmount = _cards[_cardId].currentAmount.sub(
            availableAmount
        );

        _currentHistory.purchasedHistories[msg.sender] = uint8(_currentBoughtAmount.add(availableAmount));

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

    function _setTier(
        uint8 _tier,
        uint256 _startTime
    ) private {

        for (uint256 i = 0; i < tiers.length; i++) {
            if (tiers[i] == _tier) {
                times[i] = _startTime;
                return;
            }
        }

        tiers.push(_tier);
        times.push(_startTime);
    }

    function setTier(uint8 _tier,
        uint256 _startTime
    ) external onlyOwner {
        _setTier(_tier, _startTime);
    }

    function setTiers(
        uint8[] calldata _tiers,
        uint256[] calldata _startTimes
    ) external onlyOwner{
        require(_tiers.length == _startTimes.length, 
                "Input array lengths mismatch");
        for(uint256 i = 0; i < _tiers.length; i++){
            _setTier(_tiers[i], _startTimes[i]);
        }
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
    }

    function setCardPaymentToken(uint256 _cardId, address _newAddr)
        external
        onlyOwner
        returns (bool)
    {
        _cards[_cardId].paymentToken = _newAddr;

        emit CardChanged(_cardId);
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
        address _addr,
        uint8 _tier
    ) external onlyOwner {
        _whitelist[_addr] = _tier;
        
    }

    function batchAddWhiteListAddress(
        address[] calldata _addr,
        uint8 _tier
    ) external onlyOwner {
        for (uint256 i = 0; i < _addr.length; i++) {
            _whitelist[_addr[i]] = _tier;
        }
    }

    function isCardCompleted(uint256 _cardId) public view returns (bool) {
        return _cards[_cardId].isFinished;
    }

    function isCardFree(uint256 _cardId) public view returns (bool) {
        return _cards[_cardId].basePrice == 0;
    }

    function getCardPaymentContract(uint256 _cardId)
        public
        view
        returns (address)
    {
        return _cards[_cardId].paymentToken;
    }

    function getCardTimes(uint256 _cardId)
        public
        view
        returns (uint8[] memory, uint256[] memory)
    {
        return (tiers, times);
    }

    function getCardTime(uint256 _cardId, uint8 _tier)
        public
        view
        returns (uint256)
    {
        for(uint256 i = 0; i < tiers.length; i++){
            if(tiers[i] == _tier){
                return times[i];
            }    
        }
        return 0;
    }

    function getCardPurchasers(uint256 _cardId)
        public
        view
        returns (address[] memory)
    {
        return _purchasers[_cardId];
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

    function getCardBasePrice(uint256 _cardId) public view returns (uint256) {
        return _cards[_cardId].basePrice;
    }

    function collect(address _token) external onlyOwner {
        if (_token == address(0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            uint256 amount = ERC20(_token).balanceOf(address(this));
            ERC20(_token).transfer(msg.sender, amount);
        }
    }
}
