// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;
pragma abicoder v2;

import "Ownable.sol";
import "SafeERC20.sol";
import "ReentrancyGuard.sol";
import "IERC20.sol";
import "IERC721Receiver.sol";
import "ERC1155Receiver.sol";

import "IMintywayRoyalty.sol";
import "TokenLibrary.sol";

contract MintywayTrading is Ownable, IERC721Receiver, ERC1155Receiver, ReentrancyGuard  {

    using SafeERC20 for IERC20;
    using TokenLibrary for TokenLibrary.TokenValue;

    enum DepositStatus {
        FOR_SALE,
        CANCELED,
        SOLD
    }

    struct Deposit {
        address buyer;
        address owner;
        TokenLibrary.TokenValue token;
        IERC20 paymentContract;
        uint256 price;
        DepositStatus status;
        address creator;
        uint256 royalty;
    }

    mapping(uint256 => Deposit) private _deposits;
    uint256 private nextDepositId;
    mapping(address => mapping(IERC20 => uint256)) public collectedRoyalties;
    mapping(IERC20 => uint256) public collectedFees;
    uint256 internal _feeDenominator = 100;

    mapping(address => bool) private _supportsRoyalties;

    event DepositCreated(uint256 depositId);
    event SaleCanceled(uint256 depositId);
    event DepositBought(uint256 depositId);

    constructor(address erc721Contract, address erc1155Contract) {
        _supportsRoyalties[erc721Contract] = true;
        _supportsRoyalties[erc1155Contract] = true;
    }

    function setContractWithRoyalties(address ercContract) external onlyOwner {
        _supportsRoyalties[ercContract] = true;
    }

    function isSupportRoyalties(address ercContract) external view returns(bool) {
        return _supportsRoyalties[ercContract];
    }
    
    function deleteContractWithRoyalties(address ercContract) external onlyOwner {
        _supportsRoyalties[ercContract] = false;
    }

    function getDeposit(uint256 depositId) external view returns(Deposit memory) {
        return _deposits[depositId];
    }

    function feeDenominator() external view returns(uint256) {
        return _feeDenominator;
    }

    function setFeeDenominator(uint256 feeDenominator_) external onlyOwner {
        _feeDenominator = feeDenominator_;
    }

    function placeTokens(TokenLibrary.TokenValue calldata token, uint256 price, IERC20 paymentContract) public {
        address sender = msg.sender;
        require(price > 0, "MintywayTrading: price must be not 0");

        address creator;
        uint256 royalty;

        if (_supportsRoyalties[token.token]) {
            royalty = IMintywayRoyalty(token.token).royaltyOf(token.tokenId);
            creator = IMintywayRoyalty(token.token).creatorOf(token.tokenId);
        } 

        _deposits[nextDepositId] = Deposit ({
            owner: sender,
            creator: creator,
            token: token,
            buyer: address(0),
            paymentContract: paymentContract,
            price: price,
            status: DepositStatus.FOR_SALE,
            royalty: royalty
        });

        _deposits[nextDepositId].token.transferFrom(sender, address(this));

        emit DepositCreated(nextDepositId);
        nextDepositId++;
    }

    function cancelSale(uint256 depositId) public nonReentrant {
        Deposit storage deposit = _deposits[depositId];
        address sender = msg.sender;
        require(deposit.owner == sender, "MintywayTrading: You do not have permission to cancelSale");
        require(
            deposit.status == DepositStatus.FOR_SALE,
            "MintywayTrading: You can't cancel this sale"
        );

        deposit.token.transferFrom(address(this), sender);

        deposit.status = DepositStatus.CANCELED;
        emit SaleCanceled(depositId);
    }

    function buyDeposit(uint256 depositId) public nonReentrant {
        address sender = msg.sender;
        Deposit storage deposit = _deposits[depositId];

        require(
            deposit.status == DepositStatus.FOR_SALE,
            "MintywayTrading: You can't buy this deposit"
        );

        deposit.paymentContract.safeTransferFrom(
            sender,
            address(this),
            deposit.price
        );

        uint256 fee = deposit.price / _feeDenominator;
        uint256 royalty = 0;

        if (deposit.royalty != 0) {
            royalty = deposit.price * deposit.royalty / 100;
            collectedRoyalties[deposit.creator][deposit.paymentContract] += royalty;

            deposit.paymentContract.safeTransfer(
                deposit.creator,
                royalty
            );
        }
    
        deposit.paymentContract.safeTransfer(
            deposit.owner,
            deposit.price - fee - royalty
        );

        deposit.token.transferFrom(address(this), sender);

        collectedFees[deposit.paymentContract] += fee;

        deposit.status = DepositStatus.SOLD;
        deposit.buyer = sender;

        emit DepositBought(depositId);
    }

    function withdrawFees(IERC20 contractAddress) external onlyOwner {
        contractAddress.safeTransfer(owner(), collectedFees[contractAddress]);
        collectedFees[contractAddress] = 0;
    }

    function onERC721Received(address /* operator */, address /* from */, uint256 /* tokenId */, bytes calldata /* data */) override public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address /* operator */, address /* from */, uint256 /* id */, uint256 /* value */, bytes calldata /* data */) override public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address /* operator */, address /* from */, uint256[] calldata /* ids */, uint256[] calldata /* values */, bytes calldata /* data */) override public pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}