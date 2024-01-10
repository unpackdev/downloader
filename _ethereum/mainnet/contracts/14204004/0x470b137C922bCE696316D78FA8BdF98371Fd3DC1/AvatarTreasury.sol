// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "./AccessControl.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract AvatarTreasury is AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _soldItemIdCounter;

    uint256 public _ITEM_PRICE_IN_ETH;
    uint256 public _ITEM_PRICE_IN_USD;

    uint256 public _MAX_NUM_ITEMS;

    IERC20 public TOKEN_USDT;
    IERC20 public TOKEN_USDC;
    IERC20 public TOKEN_WETH;

    bool public _PUBLIC_SALE_ENABLED;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event PaymentReceived(
        uint256 indexed soldItemId,
        address indexed buyerAddress,
        uint256 purchaseAmount,
        IERC20 tokenAddress
    );

    modifier saleConditions() {
        require(_PUBLIC_SALE_ENABLED == true, "Sale is not started yet!");
        require(remainingItemsForSale() >= 1, "Max limit reached");
        _;
    }

    /**
     * @notice Called once to configure the contract after the initial deployment.
     * @dev This farms the initialize call out to inherited contracts as needed.
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        _MAX_NUM_ITEMS = 7000;

        _ITEM_PRICE_IN_ETH = 777E11;
        //_ITEM_PRICE_IN_ETH = 777E14;
        _ITEM_PRICE_IN_USD = 0.223E6;
        //_ITEM_PRICE_IN_USD = 223;

        TOKEN_USDT = IERC20(0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02);
        TOKEN_USDC = IERC20(0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b);
        TOKEN_WETH = IERC20(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    }

    /**
     * @dev purchase avatar minting right by public users via ETH.
     */
    function purchaseMintingRight() external payable saleConditions {
        require(msg.value >= _ITEM_PRICE_IN_ETH, "Value is not sufficient for purchase");

        incrementSalesCount(msg.value, IERC20(0x0000000000000000000000000000000000000000));
    }

    /**
     * @dev purchase avatar minting right by public users via Token.
     */
    function purchaseMintingRightByToken(IERC20 token, uint256 amount) external saleConditions
    {
        require(token == TOKEN_WETH || token == TOKEN_USDT || token == TOKEN_USDC, "Token not supported");

        if (token == TOKEN_WETH) {
            require(amount >= _ITEM_PRICE_IN_ETH, "Amount is not sufficient for purchase by token");
        } else if (token == TOKEN_USDT || token == TOKEN_USDC) {
            require(amount >= _ITEM_PRICE_IN_USD, "Amount is not sufficient for purchase by token");
        }

        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed.");

        incrementSalesCount(amount, token);
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
    function adminUpdateTokenPrice(uint256 tokenPriceETH, uint256 tokenPriceUSD) external onlyRole(ADMIN_ROLE)
    {
        _ITEM_PRICE_IN_ETH = tokenPriceETH;
        _ITEM_PRICE_IN_USD = tokenPriceUSD;
    }

    /**
     * @notice Allows an admin to withdraw all the funds from this smart-contract.
     */
    function adminWithdrawAll() external onlyRole(ADMIN_ROLE) nonReentrant {
        uint256 ethBalance = address(this).balance;
        uint256 usdcBalance = getTokenBalance(TOKEN_USDC);
        uint256 usdtBalance = getTokenBalance(TOKEN_USDT);
        uint256 wethBalance = getTokenBalance(TOKEN_WETH);

        require(ethBalance > 0 || usdcBalance > 0 || usdtBalance > 0 || wethBalance > 0, "No funds left");

        if (ethBalance > 0) {
            _withdraw(address(msg.sender), ethBalance);
        }

        if (usdtBalance > 0) {
            TOKEN_USDT.transfer(address(msg.sender), usdtBalance);
        }

        if (usdcBalance > 0) {
            TOKEN_USDC.transfer(address(msg.sender), usdcBalance);
        }

        if (wethBalance > 0) {
            TOKEN_WETH.transfer(address(msg.sender), wethBalance);
        }
    }

    function remainingItemsForSale() public view returns (uint256) {
        return _MAX_NUM_ITEMS.sub(_soldItemIdCounter.current());
    }

    function getTokenBalance(IERC20 token) public view returns (uint256) {
        require(token == TOKEN_WETH || token == TOKEN_USDT || token == TOKEN_USDC, "Token not supported");

        return IERC20(token).balanceOf(address(this));
    }

    function incrementSalesCount(uint256 amount, IERC20 token) internal {
        _soldItemIdCounter.increment();

        emit PaymentReceived(_soldItemIdCounter.current(), address(msg.sender), amount, token);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}
