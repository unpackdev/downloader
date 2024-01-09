// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "./AccessControl.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract AvatarTreasury is AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _soldItemIdCounter;

    uint256 public _ITEM_PRICE;
    uint256 public _MAX_NUM_ITEMS;

    bool public _PUBLIC_SALE_ENABLED;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event PaymentReceived(
        uint256 indexed soldItemId,
        address indexed buyerAddress,
        uint256 purchaseAmount
    );

    /**
     * @notice Called once to configure the contract after the initial deployment.
     * @dev This farms the initialize call out to inherited contracts as needed.
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        _MAX_NUM_ITEMS = 10500; // %70 * 15K avatars
        _ITEM_PRICE = 5E16; // 0.05 ETH
        _PUBLIC_SALE_ENABLED = false;
    }

    /**
     * @dev purchase avatar minting right by public users.
     */
    function purchaseMintingRight() external payable
    {
        require(_PUBLIC_SALE_ENABLED == true, "Sale is not started yet!");
        require(remainingItemsForSale() >= 1, "Max limit reached");
        require(msg.value >= _ITEM_PRICE, "Value is not sufficient for purchase");

        _soldItemIdCounter.increment();

        emit PaymentReceived(_soldItemIdCounter.current(), msg.sender, msg.value);
    }

    /**
     * @notice Allows an admin to enable/disable public sale.
     */
    function adminUpdatePublicSale(bool enabled) external onlyRole(ADMIN_ROLE) {
        _PUBLIC_SALE_ENABLED = enabled;
    }

    /**
     * @notice Allows an admin to update sale parameters.
     */
    function adminUpdateSaleLimits(uint256 maxNumItems) external onlyRole(ADMIN_ROLE)
    {
        _MAX_NUM_ITEMS = maxNumItems;
    }

    /**
     * @notice Allows an admin to update token price.
     */
    function adminUpdateTokenPrice(uint256 tokenPrice) external onlyRole(ADMIN_ROLE)
    {
        _ITEM_PRICE = tokenPrice;
    }

    /**
     * @notice Allows an admin to withdraw all the funds from this smart-contract.
     */
    function adminWithdrawAll() external onlyRole(ADMIN_ROLE) {
        require(address(this).balance > 0, "No funds left");
        _withdraw(address(msg.sender), address(this).balance);
    }

    function remainingItemsForSale() public view returns (uint256) {
        return _MAX_NUM_ITEMS.sub(_soldItemIdCounter.current());
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}
