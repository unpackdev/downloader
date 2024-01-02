// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

error INVALID_FEE();
error PAUSED();

contract HigherProtocol is ERC20, AccessControl {
    using SafeERC20 for IERC20;

    /// @dev name
    string private constant NAME = "Higher Protocol";

    /// @dev symbol
    string private constant SYMBOL = "HIGHER";

    /// @dev initial supply
    uint256 private constant INITIAL_SUPPLY = 10000000 ether;

    /// @notice percent multiplier (100%)
    uint256 public constant MULTIPLIER = 10000;

    /// @notice Uniswap Router
    IUniswapV2Router02 public ROUTER;

    /// @notice tax info
    struct TaxInfo {
        uint256 buyFee;
        uint256 sellFee;
    }
    TaxInfo public taxInfo;
    uint256 private pendingTax;
    uint256 public maxWallet;

    /// @notice whether a wallet excludes fees
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isDexAddress;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    /// @notice swap enabled
    bool public swapEnabled = true;

    /* ======== INITIALIZATION ======== */

    constructor(IUniswapV2Router02 router) ERC20(NAME, SYMBOL) {
        _mint(_msgSender(), INITIAL_SUPPLY);
        ROUTER = router;
        _approve(address(this), address(ROUTER), type(uint256).max);
        isExcludedFromFee[address(this)] = true;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    receive() external payable {}

    /* ======== MODIFIERS ======== */

    modifier onlyOwner() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    /* ======== POLICY FUNCTIONS ======== */

    function setTaxFee(uint256 buyFee, uint256 sellFee) external onlyOwner {
        taxInfo.buyFee = buyFee;
        taxInfo.sellFee = sellFee;
    }

    function excludeFromFee(address account, bool isEx) external onlyOwner {
        isExcludedFromFee[account] = isEx;
    }

    function excludeFromMaxTransaction(
        address account,
        bool isEx
    ) external onlyOwner {
        require(account != address(0), "zero address");
        _isExcludedMaxTransactionAmount[account] = isEx;
    }

    function includeFromDexAddresss(
        address updAds,
        bool isEx
    ) external onlyOwner {
        require(updAds != address(0), "zero address");
        isDexAddress[updAds] = isEx;
    }

    function setSwapTaxSettings(bool _swapEnabled) external onlyOwner {
        swapEnabled = _swapEnabled;
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner {
        maxWallet = _maxWallet;
    }

    function recoverERC20(IERC20 token) external onlyOwner {
        token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
    }

    function recoverETH() external onlyOwner {
        uint256 balance = address(this).balance;

        if (balance > 0) {
            (bool success, ) = payable(msg.sender).call{value: balance}("");
            require(success);
        }
    }

    /* ======== PUBLIC FUNCTIONS ======== */

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        address owner = _msgSender();
        _transferWithTax(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transferWithTax(from, to, amount);
        return true;
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _transferWithTax(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (!swapEnabled) revert PAUSED();
        if (amount == 0) return;

        if (maxWallet != 0) {
            if (!_isExcludedMaxTransactionAmount[to]) {
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Max wallet exceeded"
                );
            }
        }

        if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
            _transfer(from, to, amount);
            return;
        }

        if (isDexAddress[from]) {
            uint256 buyTax = (amount * taxInfo.buyFee) / MULTIPLIER;
            unchecked {
                amount -= buyTax;
                pendingTax += buyTax;
            }

            if (buyTax > 0) {
                require(
                    pendingTax + amount <= balanceOf(from),
                    "Exceeded the balance"
                );
                _transfer(from, address(this), buyTax);
                _burn(address(this), buyTax);
            }
        } else if (isDexAddress[to]) {
            uint256 sellTax = (amount * taxInfo.sellFee) / MULTIPLIER;
            unchecked {
                amount -= sellTax;
            }
            if (sellTax > 0) {
                _transfer(from, address(this), sellTax);
                _burn(address(this), sellTax);
                _burn(to, sellTax);
            }
            if (pendingTax > 0) {
                _burn(to, pendingTax);
                pendingTax = 0;
            }
            IUniswapV2Pair pair = IUniswapV2Pair(to);
            pair.sync();
        }
        _transfer(from, to, amount);
    }
}
