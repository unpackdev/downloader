// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IUnikuraMarket {
    enum OrderStatus {
        NONE,
        PLACED,
        COMPLETED
    }

    struct OrderInfo {
        uint256 tokenId;
        uint256 mintPrice;
        uint256 serviceFee;
        address sender;
        address salesAddress;
        OrderStatus status;
    }

    event LogUpdateAdmin(address account, bool status);

    event FeeRecipientChanged(address indexed oldAccount, address indexed account);

    event FeePercentageChanged(uint256 oldPercent, uint256 percent);

    event CollectionChanged(address indexed oldToken, address indexed token);

    event Order(uint256 indexed tokenId, address indexed sender, uint256 mintPrice, uint256 serviceFee);

    event Complete(
        uint256 indexed tokenId,
        address indexed sender,
        address indexed salesAddress,
        uint256 mintPrice,
        uint256 serviceFee
    );

    event Reject(uint256 indexed tokenId, address indexed sender, uint256 mintPrice, uint256 serviceFee);

    event Cancel(uint256 indexed tokenId, address indexed sender, uint256 mintPrice, uint256 serviceFee);

    /// @notice OnlyOwner
    function setAdmin(address account, bool status) external;

    /// @notice OnlyOwner
    function setFeeRecipient(address feeRecipient_) external;

    /// @notice OnlyOwner
    function setFeePercentage(uint256 feePercentage_) external;

    /// @notice OnlyOwner
    function setCollection(address token) external;

    function order(uint256 tokenId, uint256 mintPrice) external payable;

    /// @notice OnlyAdmin
    function complete(uint256 tokenId, address account, address salesAddress) external;

    /// @notice OnlyAdmin
    function reject(uint256 tokenId, address account) external;

    function cancel(uint256 tokenId) external;
}
