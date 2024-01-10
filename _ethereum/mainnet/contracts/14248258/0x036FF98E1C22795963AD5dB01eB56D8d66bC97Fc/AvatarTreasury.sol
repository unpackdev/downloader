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
    uint256 public _ITEM_PRICE_IN_USDC;
    uint256 public _ITEM_PRICE_IN_USDT;
    uint256 public _ITEM_PRICE_IN_WETH;

    uint256 public _MAX_NUM_ITEMS;

    IERC20 public TOKEN_USDC;
    IERC20 public TOKEN_USDT;
    IERC20 public TOKEN_WETH;

    bool public _PUBLIC_SALE_ENABLED;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct TokenInfo {
        string name;
        IERC20 tokenAddress;
        uint256 balance;
    }

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

        _ITEM_PRICE_IN_ETH = 777E14; // 0.077700000000000000 ETH with 18 decimal points on mainnet
        _ITEM_PRICE_IN_USDC = 213E6; // 213.000000 USDC with 6 decimal points on mainnet
        _ITEM_PRICE_IN_USDT = 213E6; // 213.000000 USDT with 6 decimal points on mainnet
        _ITEM_PRICE_IN_WETH = 777E14;// 0.077700000000000000 WETH with 18 decimal points on mainnet

        TOKEN_USDC = IERC20(0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b);
        TOKEN_USDT = IERC20(0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02);
        TOKEN_WETH = IERC20(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    }

    /**
     * @dev purchase avatar minting right by public users via ETH.
     */
    function purchaseMintingRight() external payable saleConditions {
        require(
            msg.value >= _ITEM_PRICE_IN_ETH,
            "Value is not sufficient for purchase"
        );

        incrementSalesCount(IERC20(0x0000000000000000000000000000000000000000), msg.value);
    }

    /**
     * @dev purchase avatar minting right by public users via Token.
     */
    function purchaseMintingRightByToken(IERC20 tokenAddress, uint256 amount)
        external
        saleConditions
    {
        require(tokenAddress == TOKEN_USDC || tokenAddress == TOKEN_USDT || tokenAddress == TOKEN_WETH, "Token not supported");

        if (tokenAddress == TOKEN_USDC) {
            require(amount >= _ITEM_PRICE_IN_USDC, "Amount is not sufficient for purchase by USDC token");
        } else if (tokenAddress == TOKEN_USDT) {
            require(amount >= _ITEM_PRICE_IN_USDT, "Amount is not sufficient for purchase by USDT token");
        } else if (tokenAddress == TOKEN_WETH) {
            require(amount >= _ITEM_PRICE_IN_WETH, "Amount is not sufficient for purchase by WETH token");
        }

        bool success = IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed.");

        incrementSalesCount(tokenAddress, amount);
    }

    /**
     * @notice Allows an admin to enable/disable public sale.
     */
    function adminUpdatePublicSale(bool enabled)
        external
        onlyRole(ADMIN_ROLE)
    {
        _PUBLIC_SALE_ENABLED = enabled;
    }

    /**
     * @notice Allows an admin to update sale parameters.
     */
    function adminUpdateSaleLimits(uint256 maxNumItems)
        external
        onlyRole(ADMIN_ROLE)
    {
        _MAX_NUM_ITEMS = maxNumItems;
    }

    /**
     * @notice Allows an admin to update token price.
     */
    function adminUpdateTokenPrice(IERC20 tokenAddress, uint256 amount)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(amount > 0, "Token price cannot be zero");

        if (tokenAddress == TOKEN_USDC) {
            _ITEM_PRICE_IN_USDC = amount;
        } else if (tokenAddress == TOKEN_USDT) {
            _ITEM_PRICE_IN_USDT = amount;
        } else if (tokenAddress == TOKEN_WETH) {
            _ITEM_PRICE_IN_WETH = amount;
        } else if (tokenAddress == IERC20(0x0000000000000000000000000000000000000000)) {
            _ITEM_PRICE_IN_ETH = amount;
        }
    }

    /**
     * @notice Allows an admin to update token addresses.
     */
    function adminUpdateTokenAddress(IERC20 usdcAddress, IERC20 usdtAddress, IERC20 wethAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        if (usdcAddress != IERC20(0x0000000000000000000000000000000000000000)) {
            TOKEN_USDC = usdcAddress;
        }

        if (usdtAddress != IERC20(0x0000000000000000000000000000000000000000)) {
            TOKEN_USDT = usdtAddress;
        }

        if (wethAddress != IERC20(0x0000000000000000000000000000000000000000)) {
            TOKEN_WETH = wethAddress;
        }
    }

    /**
     * @notice Allows an admin to withdraw all the funds from this smart-contract.
     */
    function adminWithdrawAll() external onlyRole(ADMIN_ROLE) nonReentrant {
        uint256 ethBalance = address(this).balance;
        uint256 usdcBalance = getTokenBalance(TOKEN_USDC);
        uint256 usdtBalance = getTokenBalance(TOKEN_USDT);
        uint256 wethBalance = getTokenBalance(TOKEN_WETH);

        require(
            ethBalance > 0 ||
                usdcBalance > 0 ||
                usdtBalance > 0 ||
                wethBalance > 0,
            "No funds left"
        );

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
        require(
            token == TOKEN_WETH || token == TOKEN_USDT || token == TOKEN_USDC,
            "Token not supported"
        );

        return IERC20(token).balanceOf(address(this));
    }

    function getAllTokenBalances() external view returns (TokenInfo[] memory) {
        TokenInfo[] memory tokenInfo = new TokenInfo[](3);
        tokenInfo[0] = TokenInfo(
            "USDT",
            TOKEN_USDT,
            getTokenBalance(TOKEN_USDT)
        );
        tokenInfo[1] = TokenInfo(
            "USDC",
            TOKEN_USDC,
            getTokenBalance(TOKEN_USDC)
        );
        tokenInfo[2] = TokenInfo(
            "WETH",
            TOKEN_WETH,
            getTokenBalance(TOKEN_WETH)
        );
        return tokenInfo;
    }

    function incrementSalesCount(IERC20 tokenAddress, uint256 amount) internal {
        _soldItemIdCounter.increment();

        emit PaymentReceived(
            _soldItemIdCounter.current(),
            address(msg.sender),
            amount,
            tokenAddress
        );
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}
