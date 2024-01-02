// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// Saintbot
// Deploy and manage fair launch anti-rug tokens seamlessly and lightning-fast with low gas on our free-to-use Telegram bot.
// Telegram Bot: https://t.me/VivekPortal

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;

    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface IRefSys {
    function getRefReceiver(bytes memory _refCode) external view returns (address receiverWallet);
}

interface IUNCX {
    function lockLPToken(
        address _lpToken,
        uint256 _amount,
        uint256 _unlock_date,
        address payable _referral,
        bool _fee_in_eth,
        address payable _withdrawer
    ) external payable;

    struct FeeStruct {
        uint256 ethFee; // Small eth fee to prevent spam on the platform
        IERCBurn secondaryFeeToken; // UNCX or UNCL
        uint256 secondaryTokenFee; // optional, UNCX or UNCL
        uint256 secondaryTokenDiscount; // discount on liquidity fee for burning secondaryToken
        uint256 liquidityFee; // fee on univ2 liquidity tokens
        uint256 referralPercent; // fee for referrals
        IERCBurn referralToken; // token the refferer must hold to qualify as a referrer
        uint256 referralHold; // balance the referrer must hold to qualify as a referrer
        uint256 referralDiscount; // discount on flatrate fees for using a valid referral address
    }

    function gFees() external returns (FeeStruct memory);
}

interface IERCBurn {
    function burn(uint256 _amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

contract SaintbotZeroTaxTokenWithInitial is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    bool public transferDelayEnabled = true;

    // wallet that will be used to receive funds and distribute to rev share contracts
    address payable public teamWallet;

    uint256 private _initialBuyTax = 25;
    uint256 private _initialSellTax = 25;
    uint256 private _finalBuyTax = 0;
    uint256 private _finalSellTax = 0;
    uint256 private _reduceBuyTaxAt = 25;
    uint256 private _reduceSellTaxAt = 25;
    uint256 public _preventSwapBefore = 2;
    uint256 public _buyCount = 0;

    uint8 private constant _decimals = 18;
    uint256 private immutable _tTotal;
    string private _name;
    string private _symbol;

    uint256 public _maxTxAmount;
    uint256 public _maxWalletSize;
    uint256 public _maxTaxSwap;
    uint256 public _taxSwapThreshold;

    IUNCX private constant LOCKER = IUNCX(0x663A5C229c09b049E36dCc11a9B0d4a8Eb9db214);

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool public tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    uint256 private immutable _deployedAt;

    IRefSys public constant REF_SYS = IRefSys(0x8A99c005C7B425ce999441afeE22D4987F7a9869);
    address public constant MAINNET_BOT_TRADING_RECEIVER = 0xD5E2E43e30b706de8A0e01e72a6aBa2b8930af44;

    address public immutable REF;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 _totalSupply,
        address _lockOwnerAndTaxReceiver,
        bytes memory _ref
    ) payable {
        require(msg.value >= 0.55 ether, "weth liquidity need to be bigger than 0.3");
        require(_totalSupply >= 10 && _totalSupply <= 1_000_000_000_000, "InvalidSupply()");

        _name = name_;
        _symbol = symbol_;

        uint256 supplyWithDecimals_ = _totalSupply * 1e18;

        _tTotal = supplyWithDecimals_;

        _maxTxAmount = (supplyWithDecimals_ * 3) / 100;
        _maxWalletSize = (supplyWithDecimals_ * 6) / 100;
        _maxTaxSwap = supplyWithDecimals_ / 100;
        _taxSwapThreshold = supplyWithDecimals_ / 200;

        teamWallet = payable(_lockOwnerAndTaxReceiver);

        _balances[address(this)] = supplyWithDecimals_;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        if (_lockOwnerAndTaxReceiver != msg.sender) transferOwnership(_lockOwnerAndTaxReceiver);

        _deployedAt = block.timestamp;

        REF = REF_SYS.getRefReceiver(_ref);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 taxAmount = 0;

        if (from != owner() && to != owner()) {
            taxAmount = amount.mul((_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax).div(100);

            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                    require(
                        _holderLastTransferTimestamp[tx.origin] < block.number,
                        "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
            }

            if (to == uniswapV2Pair && from != address(this)) {
                taxAmount = amount.mul((_buyCount > _reduceSellTaxAt) ? _finalSellTax : _initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));

            if (
                !inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold
                    && _buyCount > _preventSwapBefore
            ) {
                swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));

                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 50000000000000000) {
                    _distributeMultisigs(address(this).balance);
                }
            }
        }

        // Transfers before opening trade have no tax
        if (!tradingOpen) {
            taxAmount = 0;
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));

        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    function removeLimits() external onlyOwner {
        require(block.timestamp > (_deployedAt + 1 days), "can only remove limits after 1 days");

        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        transferDelayEnabled = false;

        emit MaxTxAmountUpdated(_tTotal);
    }

    function _distributeMultisigs(uint256 _amount) private {
        uint256 ethBalance = _amount;

        if (REF == address(0)) {
            // If user has not entered a ref code, he will receive 4% fees
            uint256 taxWalletAmount = (ethBalance * 80) / 100;

            // Send 80% of the fees
            (bool success,) = teamWallet.call{value: taxWalletAmount}("");

            require(success, "failed sending eth");

            address payable SAINTBOT_TAXES = payable(MAINNET_BOT_TRADING_RECEIVER);

            // Send 100% - 80% of the fees to us
            (success,) = SAINTBOT_TAXES.call{value: ethBalance - taxWalletAmount}("");

            require(success, "failed sending eth");
        } else {
            // If he did enter a ref code, he will receive 4.1% fees
            uint256 taxWalletAmount = (ethBalance * 82) / 100;

            // Send 82% of the fees
            (bool success,) = teamWallet.call{value: taxWalletAmount}("");

            require(success, "failed sending eth");

            // 0.15% to ref address, meaning that its 3% out of the 5%
            payable(REF).transfer((taxWalletAmount * 3) / 100);

            address payable SAINTBOT_TAXES = payable(MAINNET_BOT_TRADING_RECEIVER);

            (success,) = SAINTBOT_TAXES.call{value: (ethBalance * 15) / 100}("");

            require(success, "failed sending eth");
        }
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _approve(address(this), address(uniswapV2Router), _tTotal);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 uncxExpenses = LOCKER.gFees().ethFee;

        uniswapV2Router.addLiquidityETH{value: address(this).balance - uncxExpenses}(
            address(this), balanceOf(address(this)), 0, 0, address(this), block.timestamp
        );

        address _pair = uniswapV2Pair;

        IERCBurn(_pair).approve(address(LOCKER), IERC20(_pair).balanceOf(address(this)));

        LOCKER.lockLPToken{value: uncxExpenses}(
            address(_pair),
            IERC20(_pair).balanceOf(address(this)),
            block.timestamp + 7 days,
            payable(address(0)),
            true,
            payable(owner())
        );

        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint256).max);

        swapEnabled = true;
        tradingOpen = true;
    }

    receive() external payable {}

    function manualSwap() external {
        require(_msgSender() == teamWallet, "auth");

        uint256 tokenBalance = balanceOf(address(this));

        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            _distributeMultisigs(ethBalance);
        }
    }

    function updateTeamWallet(address _teamWallet) external onlyOwner {
        require(_teamWallet != address(0), "address(0)");

        teamWallet = payable(_teamWallet);

        _isExcludedFromFee[teamWallet] = true;
    }
}
