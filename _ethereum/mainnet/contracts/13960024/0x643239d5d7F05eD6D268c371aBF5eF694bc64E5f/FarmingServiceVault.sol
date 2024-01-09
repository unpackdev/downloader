// SPDX-License-Identifier: MIT

/**
Farming Service Vault: FSV

Tokenomics:
10% of each buy goes to existing holders.
10% of each sell goes into investment pool to add to the treasury and buy back FSV tokens.

Website:
http://www.farmingservicevault.com/

*/

pragma solidity >=0.6.0;
import "./Address.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Uniswap.sol";
import "./ReentrancyGuard.sol";

contract FarmingServiceVault is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromReflection;
    mapping(address => uint256) private _ReflectionRate;
    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10**9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = 'Farming Service Vault';
    string private constant _symbol = 'FSV';

    uint256 private _taxFee = 10;
    uint256 private _teamFee = 10;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousteamFee = _teamFee;
    address payable private w1;
    address payable private w2;
    address payable private w3;
    IUniswapV2Router02 private uniswapRouter;
    address public uniswapPair;
    bool private tradingEnabled = false;
    bool private canSwap = true;
    bool private inSwap = false;

    event MaxBuyAmountUpdated(uint256 _maxBuyAmount);
    event CooldownEnabledUpdated(bool _cooldown);
    event FeeMultiplierUpdated(uint256 _multiplier);
    event FeeRateUpdated(uint256 _rate);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address payable treasuryWalletAddress,
        address payable marketingWaletAddress,
        address payable devWallet
    ) public {
        w1 = treasuryWalletAddress;
        w2 = marketingWaletAddress;
        w3 = devWallet;
        _rOwned[w1] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[w1] = true;
        _isExcludedFromFee[w2] = true;
        _isExcludedFromFee[w3] = true;
        emit Transfer(address(0), w1, _tTotal);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapRouter = _uniswapV2Router;
        _approve(address(this), address(uniswapRouter), _tTotal);
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapPair).approve(address(uniswapRouter), type(uint256).max);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(account, _rOwned[account]);
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
        );
        return true;
    }

    function tokenFromReflection(address ad,uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal, 'Amount must be less than total reflections');
        uint256 currentRate = _getRate();
        if(_isExcludedFromReflection[ad]==true) currentRate = _ReflectionRate[ad];
        return rAmount.div(currentRate);
    }

    function setCanSwap(bool onoff) external onlyOwner {
        canSwap = onoff;
    }

    function setTradingEnabled() external onlyOwner {
        tradingEnabled = true;
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _teamFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousteamFee = _teamFee;
        _taxFee = 0;
        _teamFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _teamFee = _previousteamFee;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), 'ERC20: transfer from the zero address');
        require(to != address(0), 'ERC20: transfer to the zero address');
        require(amount > 0, 'Transfer amount must be greater than zero');
        if (!tradingEnabled) {
            require(_isExcludedFromFee[from] || _isExcludedFromFee[to] || _isExcludedFromFee[tx.origin], 'Trading is not live yet');
        }
        uint256 contractTokenBalance = balanceOf(address(this));

        if (!inSwap && from != uniswapPair && tradingEnabled && canSwap) {
            if (contractTokenBalance > 0) {
                if (contractTokenBalance > balanceOf(uniswapPair).div(100)) {
                    swapTokensForEth(contractTokenBalance);
                }
                
            }
            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0) {
                sendETHToFee(address(this).balance);
            }
        }

        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        if (from != uniswapPair && to != uniswapPair) {
            takeFee = false;
        }

        if (takeFee && from == uniswapPair) {
            _previousteamFee = _teamFee;
            _teamFee = 0;
        }
        if (takeFee && to == uniswapPair) {
            _previousTaxFee = _taxFee;
            _taxFee = 0;
        }
        _tokenTransfer(from, to, amount, takeFee);
        if (takeFee && from == uniswapPair) _teamFee = _previousteamFee;
        if (takeFee && to == uniswapPair) _taxFee = _previousTaxFee;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        w1.transfer(amount.div(10).mul(4));
        w2.transfer(amount.div(10).mul(5));
        w3.transfer(amount.div(10).mul(1));
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _taxFee, _teamFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 taxFee,
        uint256 TeamFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(TeamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);

        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function setTreasuryWallet(address payable _w1) external onlyOwner {
        w1 = _w1;
        _isExcludedFromFee[w1] = true;
    }

    function setMFCWallet(address payable _w2) external onlyOwner {
        w2 = _w2;
        _isExcludedFromFee[w2] = true;
    }

    function excludeFromFee(address payable ad) external onlyOwner {
        _isExcludedFromFee[ad] = true;
    }

    function includeToFee(address payable ad) external onlyOwner {
        _isExcludedFromFee[ad] = false;
    }

    function excludeFromReflection(address payable ad) external onlyOwner {
        _isExcludedFromReflection[ad] = true;
        _ReflectionRate[ad] = _getRate();
    }

    function includeToReflection(address payable ad) external onlyOwner {
        _isExcludedFromReflection[ad] = false;
    }

    function setTeamFee(uint256 team) external onlyOwner {
        require(team <= 25, 'Team fee must be less than 25%');
        _teamFee = team;
    }

    function setTaxFee(uint256 tax) external onlyOwner {
        require(tax <= 25, 'Tax fee must be less than 25%');
        _taxFee = tax;
    }

    function manualSwap() external {
        require(_msgSender() == w1 || _msgSender() == w2 || _msgSender() == w3, 'Not authorized');
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualSend() external {
        require(_msgSender() == w1 || _msgSender() == w2 || _msgSender() == w3, 'Not authorized');
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
}