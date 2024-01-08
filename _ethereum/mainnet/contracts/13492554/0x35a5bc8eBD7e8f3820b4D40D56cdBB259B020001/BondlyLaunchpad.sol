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
import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./MerkleProof.sol";

contract BondlyLaunchPad is Ownable {
    using Strings for string;
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for ERC20;
    using MerkleProof for bytes32[];

    uint256 public _currentCardId = 0;
    address payable public _salesperson;
    bool public _saleStarted = false;
    uint256[] times;
    uint256[] limitsPerWallet;
    uint256[] tiers;

    struct Card {
        uint256 cardId;
        uint256 tokenId;
        uint256 totalAmount;
        uint256 currentAmount;
        uint256 basePrice;
        address contractAddress;
        address paymentToken;
        bool isFinished;
    }

    struct History {
        mapping(uint256 => mapping(address => uint256)) purchasedHistories; // tokenId -> wallet -> amount
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

    mapping(uint256 => Card) public _cards;
    mapping(address => bool) public _blacklist;
    bytes32 public _whitelistRoot;
    

    // whitelist level      | Priority
    // 0: public sale       |    /\
    // 1: selected winners  |    ||
    // 2: bronze            |    ||
    // 3: silver            |    ||
    // 4: gold              |    ||
    // 5: platinum          |    ||

    mapping(address => History) private _history;

    constructor() {
        _salesperson = msg.sender;
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

    function isEligbleToBuy(uint256 _cardId, uint256 tier, bytes32[] calldata whitelistProof) public view returns (uint256) {
        if (_blacklist[msg.sender] == true) return 0;

        if (_saleStarted == false) return 0;

        if(tier != 0){
            if(! verifyWhitelist(msg.sender,tier,whitelistProof)){
                return 0;
            }
        }

        Card memory _currentCard = _cards[_cardId];

        if (times.length == 0) return 0;

        for (uint256 i = 0; i < times.length; i++) {
            if (
                block.timestamp >= times[i] &&
                tier == tiers[i]
            ) {

                History storage _currentHistory =
                    _history[_currentCard.contractAddress];
                uint256 _currentBoughtAmount =
                    _currentHistory.purchasedHistories[_currentCard.tokenId][
                        msg.sender
                    ];

                uint256 _limitPerWallet = limitsPerWallet[i];

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

    function purchaseNFT(uint256 _cardId, uint256 _amount, uint256 tier, bytes32[] calldata whitelistProof) external payable {
        require(_blacklist[msg.sender] == false, "you are blocked");

        require(_saleStarted == true, "Sale stopped");

        Card memory _currentCard = _cards[_cardId];
        require(_currentCard.isFinished == false, "Card is finished");

        if(tier != 0){
            require(verifyWhitelist(msg.sender,tier,whitelistProof),"Invalid proof for whitelist");
        }

        uint256 startTime;
        uint256 _limitPerWallet;
        for (uint256 i = 0; i < tiers.length; i++) {
            if (tiers[i] == tier) {
                startTime = times[i];
                _limitPerWallet = limitsPerWallet[i];
            }
        }

        require(
            startTime != 0 && startTime <= block.timestamp,
            "wait for sale start"
        );

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

        IERC1155(_currentCard.contractAddress).safeTransferFrom(
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
        ] = _currentBoughtAmount.add(availableAmount);

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
        uint256 _tier,
        uint256 _startTime,
        uint256 _limitPerWallet
    ) private {

        for (uint256 i = 0; i < tiers.length; i++) {
            if (tiers[i] == _tier) {
                times[i] = _startTime;
                limitsPerWallet[i] = _limitPerWallet;
                return;
            }
        }

        tiers.push(_tier);
        times.push(_startTime);
        limitsPerWallet.push(_limitPerWallet);
    }

    function setTier(
        uint256 _tier,
        uint256 _startTime,
        uint256 _limitPerWallet
    ) external onlyOwner {
        _setTier(_tier, _startTime, _limitPerWallet);
    }

    function setTiers(
        uint256[] calldata _tiers,
        uint256[] calldata _startTimes,
        uint256[] calldata _limitsPerWallet
    ) external onlyOwner{
        require(_tiers.length == _startTimes.length && 
                _tiers.length == _limitsPerWallet.length, 
                "Input array lengths mismatch");
        for(uint256 i = 0; i < _tiers.length; i++){
            _setTier(_tiers[i], _startTimes[i], _limitsPerWallet[i]);
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

    function setWhitelistRoot(bytes32 merkleRoot) external onlyOwner{
        _whitelistRoot = merkleRoot;
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

    function getCardPaymentContract(uint256 _cardId)
        public
        view
        returns (address)
    {
        return _cards[_cardId].paymentToken;
    }

    function getCardTokenId(uint256 _cardId) public view returns (uint256) {
        return _cards[_cardId].tokenId;
    }

    function getTierTimes()
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        return (tiers, times);
    }

    function getTierTime(uint256 _tier)
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

    function getTierLimitsPerWallet()
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        return (tiers, times);   
    }

    function getTierLimitPerWallet(uint256 _tier)
        public 
        view
        returns (uint256)
    {
        for(uint256 i = 0; i < tiers.length; i++)
        {
            if(tiers[i] == _tier){
                return limitsPerWallet[i];
            }
        }
        return 0;
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
            uint256 amount = ERC20(_token).balanceOf(address(this));
            ERC20(_token).transfer(msg.sender, amount);
        }
    }

    function verifyWhitelist(address user, uint256 tier, bytes32[] calldata whitelistProof) public view returns (bool){
        bytes32 leaf = keccak256(abi.encodePacked(user,tier));
        return whitelistProof.verify(_whitelistRoot, leaf);
    }
}
