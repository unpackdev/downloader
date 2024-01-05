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
    address payable private _salesperson;
    address private _originCreator;
    uint256 public _limitPerWallet;
    bool public _saleStarted = false;

    struct Card {
        uint256 cardId;
        uint256 tokenId;
        uint256 totalAmount;
        uint256 currentAmount;
        uint256 basePrice;
        address contractAddress;
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
    mapping(address => bool) internal _blacklist;
    mapping(address => bool) internal _whitelist;
    mapping(address => History) internal _history;

    constructor() {
        _salesperson = msg.sender;
        _limitPerWallet = 1;
        _originCreator = msg.sender;
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
        if (_whitelist[msg.sender] == false) return 0;

        if (_saleStarted == false) return 0;

        Card memory _currentCard = _cards[_cardId];
        History storage _currentHistory =
            _history[_currentCard.contractAddress];
        uint256 _currentBoughtAmount =
            _currentHistory.purchasedHistories[_currentCard.tokenId][
                msg.sender
            ];

        if (_currentBoughtAmount >= _limitPerWallet) return 0;

        return _limitPerWallet.sub(_currentBoughtAmount);
    }

    function purchaseNFT(uint256 _cardId, uint256 _amount) external payable {
        require(_blacklist[msg.sender] == false, "you are blocked");
        require(_whitelist[msg.sender], "you are not whitelisted");

        require(_saleStarted == true, "Sale stopped");

        Card memory _currentCard = _cards[_cardId];
        require(_currentCard.isFinished == false, "Card is finished");

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

        require(msg.value >= _price, "Not enough funds to purchase");
        uint256 overPrice = msg.value - _price;
        _salesperson.transfer(_price);

        if (overPrice > 0) msg.sender.transfer(overPrice);

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

    function addWhiteListAddress(address addr) external onlyOwner {
        _whitelist[addr] = true;
    }

    function batchAddWhiteListAddress(address[] calldata addr)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addr.length; i++) {
            _whitelist[addr[i]] = true;
        }
    }

    function removeWhiteListAddress(address addr) external onlyOwner {
        _whitelist[addr] = false;
    }

    function batchRemoveWhiteListAddress(address[] calldata addr)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addr.length; i++) {
            _whitelist[addr[i]] = false;
        }
    }

    function isCardCompleted(uint256 _cardId) public view returns (bool) {
        return _cards[_cardId].isFinished;
    }

    function isCardFree(uint256 _cardId) public view returns (bool) {
        if (_cards[_cardId].basePrice == 0) return true;

        return false;
    }

    function getCardContract(uint256 _cardId) public view returns (address) {
        return _cards[_cardId].contractAddress;
    }

    function getCardTokenId(uint256 _cardId) public view returns (uint256) {
        return _cards[_cardId].tokenId;
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

    function getCardURL(uint256 _cardId) public view returns (string memory) {
        return
            IERC1155MetadataURI(_cards[_cardId].contractAddress).uri(
                _cards[_cardId].tokenId
            );
    }

    function collect(address _token) external {
        require(msg.sender == _originCreator, "you are not admin");

        if (_token == address(0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            uint256 amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(msg.sender, amount);
        }
    }
}
