// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./OwnableUpgradeable.sol";
import "./IUnikuraMarket.sol";
import "./IUnikuraCollectibles.sol";
import "./UnikuraErrors.sol";

/**
 * @author The Unikura Team
 * @title {UnikuraMarket} is for managing orders, minting, and handling payments for {UnikuraCollectibles}.
 */
contract UnikuraMarket is IUnikuraMarket, OwnableUpgradeable {
    address public feeRecipient;
    uint256 public feePercentage; // 10000 BPS
    IUnikuraCollectibles public collection;

    mapping(uint256 => mapping(address => OrderInfo)) public orderInfo;
    mapping(uint256 => bool) public tokenMinted;
    mapping(address => bool) public admins;

    /**
     * @dev Restricts function access to addresses designated as admins.
     */
    modifier onlyAdmin() {
        if (!admins[msg.sender]) {
            revert UnikuraErrors.NotAdmin(msg.sender);
        }
        _;
    }

    /**
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev initializer for deployment when using the upgradeability pattern.
     */
    function initialize() external initializer {
        __Ownable_init();
    }

    /**
     * @notice Sets or unsets an address as an admin of the contract.
     * @param account The address to update the admin role.
     * @param status True to set as admin, false to remove admin role.
     */
    function setAdmin(address account, bool status) external override onlyOwner {
        if (account == address(0)) {
            revert UnikuraErrors.ZeroAddress();
        }
        admins[account] = status;
        emit LogUpdateAdmin(account, status);
    }

    /**
     * @notice Sets the recipient address for fees collected by the contract.
     * @param account The address to receive collected fees.
     */
    function setFeeRecipient(address account) external override onlyOwner {
        if (account == address(0)) {
            revert UnikuraErrors.ZeroAddress();
        }
        emit FeeRecipientChanged(feeRecipient, account);
        feeRecipient = account;
    }

    /**
     * @notice Sets the percentage of fees to be collected on each order.
     * @param percent The fee percentage (in basis points).
     */
    function setFeePercentage(uint256 percent) external override onlyOwner {
        if (percent > 10000) {
            revert UnikuraErrors.WrongPercentage(percent);
        }
        emit FeePercentageChanged(feePercentage, percent);
        feePercentage = percent;
    }

    /**
     * @notice Sets the address of the UnikuraCollectibles contract.
     * @param token The address of the UnikuraCollectibles contract.
     */
    function setCollection(address token) external override onlyOwner {
        if (token == address(0)) {
            revert UnikuraErrors.ZeroAddress();
        }
        emit CollectionChanged(address(collection), token);
        collection = IUnikuraCollectibles(token);
    }

    /**
     * @notice Places an order for minting a specific tokenId at a given price.
     * @param tokenId The identifier of the NFT to be minted.
     * @param mintPrice The price to mint the NFT.
     */
    function order(uint256 tokenId, uint256 mintPrice) external payable override {
        if (msg.value == 0) {
            revert UnikuraErrors.ZeroAmount();
        }
        uint256 totalAmount = mintPrice + (mintPrice * feePercentage) / 10000;
        if (msg.value != totalAmount) {
            revert UnikuraErrors.WrongAmount(msg.value);
        }
        if (tokenMinted[tokenId]) {
            revert UnikuraErrors.TokenMinted(tokenId);
        }
        if (orderInfo[tokenId][msg.sender].status != OrderStatus.NONE) {
            revert UnikuraErrors.OrderPlaced(tokenId, msg.sender);
        }

        orderInfo[tokenId][msg.sender] = OrderInfo({
            tokenId: tokenId,
            mintPrice: mintPrice,
            serviceFee: feePercentage,
            sender: msg.sender,
            salesAddress: address(0),
            status: OrderStatus.PLACED
        });

        emit Order(tokenId, msg.sender, mintPrice, feePercentage);
    }

    /**
     * @notice Completes an order for a specific tokenId, minting the NFT and transferring funds.
     * @param tokenId The identifier of the NFT to be minted.
     * @param account The address that placed the order.
     * @param salesAddress The address to receive the mint price.
     */
    function complete(uint256 tokenId, address account, address salesAddress) external override onlyAdmin {
        if (tokenMinted[tokenId]) {
            revert UnikuraErrors.TokenMinted(tokenId);
        }

        OrderInfo storage info = orderInfo[tokenId][account];
        if (info.status != OrderStatus.PLACED) {
            revert UnikuraErrors.NoOrder(tokenId, account);
        }

        info.status = OrderStatus.COMPLETED;
        info.salesAddress = salesAddress;
        tokenMinted[tokenId] = true;

        uint256 feeAmount = (info.mintPrice * info.serviceFee) / 10000;
        _safeTransferETH(feeRecipient, feeAmount);
        _safeTransferETH(salesAddress, info.mintPrice);

        collection.mint(account, info.tokenId);

        emit Complete(tokenId, account, salesAddress, info.mintPrice, info.serviceFee);
    }

    /**
     * @notice Rejects an order for a specific tokenId, refunding the funds.
     * @param tokenId The identifier of the NFT for which the order was placed.
     * @param account The address that placed the order.
     */
    function reject(uint256 tokenId, address account) external override onlyAdmin {
        OrderInfo storage info = orderInfo[tokenId][account];
        if (info.status != OrderStatus.PLACED) {
            revert UnikuraErrors.NoOrder(tokenId, account);
        }

        info.status = OrderStatus.NONE;

        uint256 amount = info.mintPrice + (info.mintPrice * info.serviceFee) / 10000;
        _safeTransferETH(account, amount);

        emit Reject(tokenId, account, info.mintPrice, info.serviceFee);
    }

    /**
     * @notice Cancels an order placed by the sender for a specific tokenId.
     * @param tokenId The identifier of the NFT for which the order was placed.
     */
    function cancel(uint256 tokenId) external override {
        if (!tokenMinted[tokenId]) {
            revert UnikuraErrors.TokenNotMinted(tokenId);
        }

        OrderInfo storage info = orderInfo[tokenId][msg.sender];
        if (info.status != OrderStatus.PLACED) {
            revert UnikuraErrors.NoOrder(tokenId, msg.sender);
        }

        info.status = OrderStatus.NONE;

        uint256 amount = info.mintPrice + (info.mintPrice * info.serviceFee) / 10000;
        _safeTransferETH(msg.sender, amount);

        emit Cancel(tokenId, msg.sender, info.mintPrice, info.serviceFee);
    }

    /**
     * @notice Safely transfers ETH to a specified address.
     * @param to The address to transfer ETH to.
     * @param value The amount of ETH to transfer.
     */
    function _safeTransferETH(address to, uint256 value) private {
        if (value > 0) {
            (bool success, ) = to.call{value: value}("");
            require(success, "ETH send failed");
        }
    }

    /**
     * @notice Prevents renouncing ownership of the contract.
     * @dev Overrides the original renounceOwnership function to ensure that ownership cannot be renounced.
     */
    function renounceOwnership() public view override onlyOwner {
        revert UnikuraErrors.CannotRenounceOwnership();
    }
}
