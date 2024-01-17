//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155HolderUpgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ContextUpgradeable.sol";

error Market__GivenAmountIsZeroOrBelow(uint256);
error Market__TradeIsAlreadyOpen(address, uint256, address);
error Market__TradeCanNotBeExecutedBySeller();
error Market__AskedAmountIsBiggerThanTradeAmount(uint256, uint256);
error Market__IncorrectSentEtherValue(uint256, uint256);
error Market__WrongReceiver(address);
error Market__GivenTradeIsNotOpen();
error Market__ServiceFeeCanNotBeHigherThan10kPoints(uint256);
error Market__GiftViaVaultFailed(bytes);

contract CruzoMarket is
    Initializable,
    ContextUpgradeable,
    UUPSUpgradeable,
    ERC1155HolderUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    modifier isAmountCorrect(uint256 _amount) {
        if (_amount == 0) {
            revert Market__GivenAmountIsZeroOrBelow(_amount);
        }
        _;
    }

    modifier isNotTradeOpened(address _tokenAddress, uint256 _tokenId) {
        if (trades[_tokenAddress][_tokenId][_msgSender()].amount != 0) {
            revert Market__TradeIsAlreadyOpen(
                _tokenAddress,
                _tokenId,
                _msgSender()
            );
        }
        _;
    }

    modifier isBuyerNotASeller(address _seller) {
        if (_msgSender() == _seller) {
            revert Market__TradeCanNotBeExecutedBySeller();
        }
        _;
    }

    modifier isEnoughItemsInTrade(
        address _tokenAddress,
        uint256 _tokenId,
        address _seller,
        uint256 _givenAmount
    ) {
        uint256 tradeAmount = trades[_tokenAddress][_tokenId][_seller].amount;
        if (_givenAmount > tradeAmount) {
            revert Market__AskedAmountIsBiggerThanTradeAmount(
                tradeAmount,
                _givenAmount
            );
        }
        _;
    }

    modifier isEtherValueCorrect(
        uint256 _value,
        address _tokenAddress,
        uint256 _tokenId,
        address _seller,
        uint256 _amount
    ) {
        uint256 tradePrice = trades[_tokenAddress][_tokenId][_seller].price;

        if (_seller != _msgSender() && _value != tradePrice * _amount) {
            revert Market__IncorrectSentEtherValue(
                _value,
                tradePrice * _amount
            );
        }
        _;
    }

    modifier isReceiverCorrect(address _receiver) {
        if (
            _receiver == address(0) ||
            _receiver == address(this) ||
            _receiver == _msgSender()
        ) {
            revert Market__WrongReceiver(_receiver);
        }
        _;
    }

    modifier isTradeOpened(address _tokenAddress, uint256 _tokenId) {
        if (trades[_tokenAddress][_tokenId][_msgSender()].amount == 0) {
            revert Market__GivenTradeIsNotOpen();
        }
        _;
    }

    modifier isServiceFeeCorrect(uint256 _newFee) {
        if (_newFee > 10000) {
            revert Market__ServiceFeeCanNotBeHigherThan10kPoints(_newFee);
        }
        _;
    }

    event TradeOpened(
        address tokenAddress,
        uint256 tokenId,
        address seller,
        uint256 amount,
        uint256 price
    );

    event TradeExecuted(
        address tokenAddress,
        uint256 tokenId,
        address seller,
        address buyer,
        uint256 amount,
        address addressee
    );

    event TradeClosed(address tokenAddress, uint256 tokenId, address seller);

    event TradeGiftedViaVault(
        address tokenAddress,
        uint256 tokenId,
        address seller,
        address sender,
        uint256 amount
    );

    event TradePriceChanged(
        address tokenAddress,
        uint256 tokenId,
        address seller,
        uint256 price
    );

    event WithdrawalCompleted(address beneficiaryAddress, uint256 _amount);

    struct Trade {
        uint256 amount;
        uint256 price;
    }

    // tokenAddress => tokenId => seller => trade
    mapping(address => mapping(uint256 => mapping(address => Trade)))
        public trades;

    // Service fee percentage in basis point (100bp = 1%)
    uint16 public serviceFee;

    string private rawVaultFuncSignature;

    address public vaultAddress;

    constructor() {}

    function initialize(
        uint16 _serviceFee,
        string calldata _initialRawVaultFuncSignature
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __Context_init();
        __ReentrancyGuard_init();
        setServiceFee(_serviceFee);
        rawVaultFuncSignature = _initialRawVaultFuncSignature;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function openTrade(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price
    )
        external
        nonReentrant
        isAmountCorrect(_amount)
        isNotTradeOpened(_tokenAddress, _tokenId)
    {
        IERC1155Upgradeable(_tokenAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            _tokenId,
            _amount,
            ""
        );
        trades[_tokenAddress][_tokenId][_msgSender()] = Trade({
            amount: _amount,
            price: _price
        });
        emit TradeOpened(
            _tokenAddress,
            _tokenId,
            _msgSender(),
            _amount,
            _price
        );
    }

    function _executeTrade(
        address _tokenAddress,
        uint256 _tokenId,
        address _seller,
        uint256 _amount,
        address _to,
        uint256 _value
    )
        internal
        nonReentrant
        isEnoughItemsInTrade(_tokenAddress, _tokenId, _seller, _amount)
        isEtherValueCorrect(_value, _tokenAddress, _tokenId, _seller, _amount)
        isAmountCorrect(_amount)
    {
        IERC1155Upgradeable(_tokenAddress).safeTransferFrom(
            address(this),
            _to,
            _tokenId,
            _amount,
            ""
        );
        if (_seller != _msgSender()) {
            _paymentProcessing(_tokenAddress, _seller, _tokenId, _value);
        }
        trades[_tokenAddress][_tokenId][_seller].amount -= _amount;
        emit TradeExecuted(
            _tokenAddress,
            _tokenId,
            _seller,
            _msgSender(),
            _amount,
            _to
        );
    }

    function buyItem(
        address _tokenAddress,
        uint256 _tokenId,
        address _seller,
        uint256 _amount
    ) external payable isBuyerNotASeller(_seller) {
        _executeTrade(
            _tokenAddress,
            _tokenId,
            _seller,
            _amount,
            _msgSender(),
            msg.value
        );
    }

    function giftItem(
        address _tokenAddress,
        uint256 _tokenId,
        address _seller,
        uint256 _amount,
        address _to
    ) external payable isReceiverCorrect(_to) {
        _executeTrade(
            _tokenAddress,
            _tokenId,
            _seller,
            _amount,
            _to,
            msg.value
        );
    }

    function giftItemViaVault(
        address _tokenAddress,
        uint256 _tokenId,
        address _seller,
        uint256 _amount,
        bytes32 _hash
    ) external payable {
        _executeTrade(
            _tokenAddress,
            _tokenId,
            _seller,
            _amount,
            vaultAddress,
            msg.value
        );
        (bool success, bytes memory data) = address(vaultAddress).call(
            abi.encodeWithSelector(
                bytes4(keccak256(bytes(rawVaultFuncSignature))),
                _hash,
                _tokenAddress,
                _tokenId,
                _amount
            )
        );
        if (!success) {
            revert Market__GiftViaVaultFailed(data);
        }
        emit TradeGiftedViaVault(
            _tokenAddress,
            _tokenId,
            _seller,
            _msgSender(),
            _amount
        );
    }

    function closeTrade(address _tokenAddress, uint256 _tokenId)
        external
        nonReentrant
        isTradeOpened(_tokenAddress, _tokenId)
    {
        Trade memory trade = trades[_tokenAddress][_tokenId][_msgSender()];
        IERC1155Upgradeable(_tokenAddress).safeTransferFrom(
            address(this),
            _msgSender(),
            _tokenId,
            trade.amount,
            ""
        );
        delete trades[_tokenAddress][_tokenId][_msgSender()];
        emit TradeClosed(_tokenAddress, _tokenId, _msgSender());
    }

    function setServiceFee(uint16 _serviceFee)
        public
        onlyOwner
        isServiceFeeCorrect(_serviceFee)
    {
        serviceFee = _serviceFee;
    }

    function withdraw(address _beneficiaryAddress, uint256 _amount)
        public
        onlyOwner
    {
        AddressUpgradeable.sendValue(payable(_beneficiaryAddress), _amount);
        emit WithdrawalCompleted(_beneficiaryAddress, _amount);
    }

    function changePrice(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _newPrice
    ) external nonReentrant isTradeOpened(_tokenAddress, _tokenId) {
        Trade storage trade = trades[_tokenAddress][_tokenId][_msgSender()];
        trade.price = _newPrice;
        emit TradePriceChanged(
            _tokenAddress,
            _tokenId,
            _msgSender(),
            _newPrice
        );
    }

    function setVaultFuncSignature(string calldata _signature)
        external
        onlyOwner
    {
        rawVaultFuncSignature = _signature;
    }

    function setVaultAddress(address _newVaultAddress) external onlyOwner {
        vaultAddress = _newVaultAddress;
    }

    function _paymentProcessing(
        address _tokenAddress,
        address _seller,
        uint256 _tokenId,
        uint256 _value
    ) internal {
        uint256 valueWithoutMarketplaceCommission = (_value *
            (10000 - uint256(serviceFee))) / 10000;
        (address royaltyReciever, uint256 royaltyAmount) = IERC2981Upgradeable(
            _tokenAddress
        ).royaltyInfo(_tokenId, valueWithoutMarketplaceCommission);
        AddressUpgradeable.sendValue(payable(royaltyReciever), royaltyAmount);
        AddressUpgradeable.sendValue(
            payable(_seller),
            valueWithoutMarketplaceCommission - royaltyAmount
        );
    }
}
