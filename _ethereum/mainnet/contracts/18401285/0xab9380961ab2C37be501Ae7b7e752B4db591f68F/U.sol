// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * Website: https://anonzk.io/
 * VCC: https://vcc.anonzk.io/
 * Twitter: https://twitter.com/AnonAZK
 * Telegram: https://t.me/AnonZKPortal
 * Docs: https://anonzk-documents.gitbook.io/anonzk/
 *
 *    ▄████████ ███▄▄▄▄    ▄██████▄  ███▄▄▄▄    ▄███████▄     ▄█   ▄█▄
 *   ███    ███ ███▀▀▀██▄ ███    ███ ███▀▀▀██▄ ██▀     ▄██   ███ ▄███▀
 *   ███    ███ ███   ███ ███    ███ ███   ███       ▄███▀   ███▐██▀
 *   ███    ███ ███   ███ ███    ███ ███   ███  ▀█▀▄███▀▄▄  ▄█████▀
 * ▀███████████ ███   ███ ███    ███ ███   ███   ▄███▀   ▀ ▀▀█████▄
 *   ███    ███ ███   ███ ███    ███ ███   ███ ▄███▀         ███▐██▄
 *   ███    ███ ███   ███ ███    ███ ███   ███ ███▄     ▄█   ███ ▀███▄
 *   ███    █▀   ▀█   █▀   ▀██████▀   ▀█   █▀   ▀████████▀   ███   ▀█▀
 *                                                           ▀
 */

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract AnonZK is ERC20, Ownable {
    // errors
    error ErrAlreadySetup();
    error ErrAlreadyLaunched();
    error ErrMaxBalance();
    error ErrMaxTx();
    error ErrInvalidFees();
    error ErrInvalidSwapThreshold();
    error ErrAddressZero();
    error ErrZeroValue();
    error ErrZeroToken();
    error ErrTradingNotStarted();

    // states
    address constant FEE_RECEIVER = 0xC8aFc08747213Da2Ab68373E5B261dd304390270;
    uint256 public constant MAX_SUPPLY = 10 * 1e6 ether;
    IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 private constant INITIAL_MAX_TRANSACTION_AMOUNT = 3 * 1e5 ether; // 3% from total supply maxTransactionAmountTxn
    uint256 private constant INITIAL_MAX_WALLET = 3 * 1e5 ether; // 3% from total supply maxWallet

    uint256 private constant INITIAL_BUY_FEE = 5;
    uint256 private constant INITIAL_SELL_FEE = 30;

    address public uniswapPair;
    mapping(address => bool) private _limitExempted;
    mapping(address => bool) private _feeExempted;

    uint256 public maxWallet;
    uint256 public maxTx;

    address public feeReceiver;
    uint256 public buyFee;
    uint256 public sellFee;
    uint256 private _swapThreshold;

    bool private _isSwapping;
    bool public tradingStarted;

    constructor() ERC20("AnonZK", unicode"AZK") {
        // set states
        _limitExempted[tx.origin] = true;
        _limitExempted[address(0)] = true;
        _limitExempted[address(0xdead)] = true;
        _limitExempted[address(this)] = true;
        _limitExempted[address(UNISWAP_V2_ROUTER)] = true;

        _feeExempted[address(this)] = true;
        _feeExempted[tx.origin] = true;

        maxWallet = INITIAL_MAX_WALLET;
        maxTx = INITIAL_MAX_TRANSACTION_AMOUNT;

        buyFee = INITIAL_BUY_FEE;
        sellFee = INITIAL_SELL_FEE;
        feeReceiver = FEE_RECEIVER;
        _swapThreshold = MAX_SUPPLY / 100;

        // mint
        _mint(tx.origin, MAX_SUPPLY);
    }

    receive() external payable {}

    fallback() external payable {}

    // erc20
    function _beforeTokenTransfer(address from_, address to_, uint256 amount_) internal view override {
        // check limits max wallet
        if (!_limitExempted[to_]) {
            if (balanceOf(to_) + amount_ > maxWallet) {
                revert ErrMaxBalance();
            }
        }

        // check max tx
        if (!_limitExempted[from_]) {
            if (amount_ > maxTx) {
                revert ErrMaxTx();
            }
        }

        // check trading started
        if (!tradingStarted) {
            if (!_feeExempted[from_] && !_feeExempted[to_]) {
                revert ErrTradingNotStarted();
            }
        }
    }

    function _transfer(address from_, address to_, uint256 amount_) internal override {
        // check
        if (to_ == address(0)) revert ErrAddressZero();

        // zero amount
        if (amount_ == 0) {
            super._transfer(from_, to_, 0);
            return;
        }

        // swap
        if (
            !_isSwapping && balanceOf(address(this)) >= _swapThreshold && from_ != uniswapPair && !_feeExempted[from_]
                && !_feeExempted[to_]
        ) {
            _isSwapping = true;
            _swap();
            _isSwapping = false;
        }

        // fees
        uint256 fees = 0;
        if (!_isSwapping && !_feeExempted[from_] && !_feeExempted[to_]) {
            uint256 _sellTax = sellFee;
            uint256 _buyTax = buyFee;

            // on sell
            if (to_ == uniswapPair && _sellTax > 0) {
                fees = (amount_ * _sellTax) / 100;
                super._transfer(from_, address(this), fees);
            }
            // on buy
            else if (from_ == uniswapPair && _buyTax > 0) {
                fees = (amount_ * _buyTax) / 100;
                super._transfer(from_, address(this), fees);
            }
        }
        super._transfer(from_, to_, amount_ - fees);
    }

    // owners
    function launch(uint256 tokenAmount_) external payable onlyOwner {
        // check if already launched
        if (uniswapPair != address(0)) revert ErrAlreadyLaunched();

        // check token & value
        if (msg.value == 0) revert ErrZeroValue();
        if (tokenAmount_ == 0) revert ErrZeroToken();

        // transfer token
        _transfer(msg.sender, address(this), tokenAmount_);

        // create pair
        IUniswapV2Router02 __router = UNISWAP_V2_ROUTER;
        address __uniswapPair = IUniswapV2Factory(__router.factory()).createPair(address(this), __router.WETH());

        // update state
        _limitExempted[__uniswapPair] = true;

        // approve tokens
        _approve(address(this), address(__router), type(uint256).max);
        _approve(address(this), address(__uniswapPair), type(uint256).max);
        IERC20(__uniswapPair).approve(address(__router), type(uint256).max);

        // add liq
        __router.addLiquidityETH{value: address(this).balance}(
            address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp
        );

        uniswapPair = __uniswapPair;
    }

    function clearStuck() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function clearStuckToken() external onlyOwner {
        _transfer(address(this), msg.sender, balanceOf(address(this)));
    }

    function setLimitExempted(address addr_, bool exempted_) external onlyOwner {
        _limitExempted[addr_] = exempted_;
    }

    function setFeeExempted(address addr_, bool exempted_) external onlyOwner {
        _feeExempted[addr_] = exempted_;
    }

    function setMaxWallet(uint256 maxWallet_) external onlyOwner {
        maxWallet = maxWallet_;
    }

    function setMaxTx(uint256 maxTx_) external onlyOwner {
        maxTx = maxTx_;
    }

    function setFeeReceiver(address addr_) external onlyOwner {
        feeReceiver = addr_;
    }

    function setFees(uint256 buyFee_, uint256 sellFee_) external onlyOwner {
        if (buyFee_ > 100 || sellFee_ > 100) {
            revert ErrInvalidFees();
        }

        sellFee = sellFee_;
        buyFee = buyFee_;
    }

    function setSwapThreshold(uint256 swapThreshold_) external onlyOwner {
        uint256 __totalSupply = MAX_SUPPLY;
        if (swapThreshold_ < __totalSupply / 1000 || swapThreshold_ > __totalSupply / 20) {
            revert ErrInvalidSwapThreshold();
        }
        _swapThreshold = swapThreshold_;
    }

    function enableTrading() external onlyOwner {
        tradingStarted = true;
    }

    // internal
    function _swapTokensForEth(uint256 tokenAmount) private {
        IUniswapV2Router02 __swapRouter = UNISWAP_V2_ROUTER;

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = __swapRouter.WETH();

        _approve(address(this), address(__swapRouter), tokenAmount);

        // make the swap
        __swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    function _swap() private {
        uint256 __contractBalance = balanceOf(address(this));
        uint256 __swapThreshold = _swapThreshold;

        // nothing to swap
        if (__contractBalance == 0) {
            return;
        }

        // swap amount
        uint256 __swapAmount = __contractBalance;
        if (__swapAmount > __swapThreshold * 20) {
            __swapAmount = __swapThreshold * 20;
        }

        // swap to ETH
        _swapTokensForEth(__swapAmount);

        // send
        uint256 __balance = address(this).balance;
        (bool success,) = payable(address(feeReceiver)).call{value: __balance}("");
    }
}
