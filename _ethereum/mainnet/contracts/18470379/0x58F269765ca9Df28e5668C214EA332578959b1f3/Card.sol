//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract SmartCard is OwnableUpgradeable {
    using SafeERC20 for IERC20;
    IERC20 public feeToken;
    address public adminWallet;

    enum CardType {
        Black,
        Diamond,
        Gold
    }

    mapping(uint256 => bool) public cardNumberExists;
    mapping(CardType => uint256) public cardTypeToFees;
    mapping(uint256 => address) public cardNumberToUser;

    error AddressZero();
    error WrongCardType();
    error CardAlreadyAdded();
    error InsufficientFunds(uint256 required, uint256 available);
    error UpdatedAddressSame(address inputAddress, address exisitingAddress);

    event Initialized();
    event FeeTokenAdded(address indexed feeToken);
    event FeesUpdated(CardType _cardType, uint128 newFees);
    event AdminAddressChanged(address indexed newAdminAddress);
    event CardPurchased(
        address indexed user,
        uint128 cardId,
        uint128 fees,
        uint256 blockTimestamp
    );

    event newCardUpdated(uint8 _newCard, uint128 _newFees);

    mapping(uint8 => uint128) public newCardTypeToFees;
    mapping(uint8 => string) public cardName;
    mapping(uint8 => bool) public checkCard;

    uint8 public newCard;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _adminWallet,
        IERC20 _tokenAddr,
        uint128 _feesBlack,
        uint128 _feesDiamond,
        uint128 _feesGold
    ) external initializer {
        if (_adminWallet == address(0) || address(_tokenAddr) == address(0))
            revert AddressZero();

        adminWallet = _adminWallet;

        __Ownable_init();

        cardTypeToFees[CardType.Black] = _feesBlack;
        cardTypeToFees[CardType.Diamond] = _feesDiamond;
        cardTypeToFees[CardType.Gold] = _feesGold;

        feeToken = _tokenAddr;

        emit Initialized();
    }

    function purchaseCard(
        address _user,
        uint8 _cardType,
        uint128 _cardNumber
    ) external {
        if (_cardType <= 2) {
            if (cardNumberExists[_cardNumber] == true)
                revert CardAlreadyAdded();

            IERC20 _token = feeToken;
            uint256 _fees = cardTypeToFees[CardType(_cardType)];

            if (_token.balanceOf(_user) < _fees)
                revert InsufficientFunds(_fees, _token.balanceOf(_user));
            SafeERC20.safeTransferFrom(_token, _user, adminWallet, _fees);

            emit CardPurchased(_user, _cardNumber, uint128(_fees), block.timestamp);
        } else {
            if (cardNumberExists[_cardNumber] == true)
                revert CardAlreadyAdded();

            if (checkCard[_cardType] == false) revert WrongCardType();

            IERC20 _token = feeToken;
            uint128 _fees = newCardTypeToFees[_cardType];

            if (_token.balanceOf(_user) < _fees)
                revert InsufficientFunds(_fees, _token.balanceOf(_user));
            SafeERC20.safeTransferFrom(_token, _user, adminWallet, _fees);

            emit CardPurchased(_user, _cardNumber, _fees, block.timestamp);
        }
        cardNumberExists[_cardNumber] = true;
        cardNumberToUser[_cardNumber] = _user;
    }

    function changeFees(uint128 _newFees, uint8 _cardType) external onlyOwner {
        if (_cardType <= 2) {
            cardTypeToFees[CardType(_cardType)] = _newFees;
            emit FeesUpdated(CardType(_cardType), _newFees);
        } else {
            if (checkCard[_cardType] == false) revert WrongCardType();
            newCardTypeToFees[_cardType] = _newFees;
            emit newCardUpdated(_cardType, _newFees);
        }
    }

    function changeAdminAddr(address _newAddress) external onlyOwner {
        if (_newAddress == address(0)) revert AddressZero();

        if (_newAddress == adminWallet)
            revert UpdatedAddressSame(_newAddress, adminWallet);

        adminWallet = _newAddress;

        emit AdminAddressChanged(_newAddress);
    }

    function setNewCard(
        uint128 _newFees,
        string memory _name
    ) external onlyOwner {
        newCardTypeToFees[newCard] = _newFees;
        cardName[newCard] = _name;
        checkCard[newCard] = true;
        newCard++;
        emit newCardUpdated(newCard, _newFees);
    }

    function setCards() external onlyOwner {
        newCard = 3;
        cardName[0] = "Black";
        cardName[1] = "Diamond";
        cardName[2] = "Gold";
    }
}
