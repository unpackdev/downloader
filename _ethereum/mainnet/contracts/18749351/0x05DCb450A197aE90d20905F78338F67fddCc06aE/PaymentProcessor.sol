interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
contract PaymentProcessor {
    // Event to be emitted after a payment is processed
    event PaymentProcessed(uint256 indexed orderId, bytes32 hash);

    // Mapping to store the hash of amounts and recipients for each Order ID
    mapping(uint256 => bytes32) private orderHashes;

    // Address of the PYUSD token
    address private PYUSD_ADDRESS;

    // Constructor to set the PYUSD token address
    constructor(address _pyusdAddress) {
        PYUSD_ADDRESS = _pyusdAddress;
    }

    // Function to process a payment
    function processPayment(
        uint256 orderId,
        uint256[] memory amounts,
        address[] memory recipients
    ) external {
        require(
            amounts.length == recipients.length,
            "Amounts and recipients length mismatch"
        );
        require(
            orderHashes[orderId] == bytes32(0),
            "Order ID already used"
        );
        bytes32 hash = keccak256(
            abi.encodePacked(orderId, amounts, recipients)
        );
        orderHashes[orderId] = hash;
        IERC20 pyusd = IERC20(PYUSD_ADDRESS);

        for (uint256 i = 0; i < amounts.length; i++) {
            // Ensure that the token transfer is successful
            require(
                pyusd.transferFrom(msg.sender, recipients[i], amounts[i]),
                "Transfer failed"
            );
        }

        emit PaymentProcessed(orderId, hash);
    }

    // Function to get the hash of amounts and recipients for a given Order ID
    function getOrderHash(uint256 orderId) external view returns (bytes32) {
        return orderHashes[orderId];
    }
}