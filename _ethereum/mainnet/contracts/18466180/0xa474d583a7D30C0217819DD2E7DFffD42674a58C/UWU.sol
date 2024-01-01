// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./IERC20.sol";
import "./Ownable.sol";
import "./IUniswap.sol";

/**
 * ⠀⠀⠀⠀⠀⠀⢀⡤⣢⠟⢁⣴⣾⡿⠋⢉⠱⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠑⠒⠦⢄⣀⣴⠟⢡⣠⣼⣿⡿⢳⣄⡀⠀⠀
 * ⠀⠀⠀⠀⠀⢀⣾⡿⠃⣠⣿⣿⠿⠂⠀⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢲⡿⠋⢰⣾⣿⣿⡟⠀⠀⠈⠙⢆⠀
 * ⠀⠀⠀⠀⠀⡜⠻⣷⣾⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣁⣰⢸⣿⢻⠟⢀⠀⠀⠀⠀⠀⠁
 * ⠀⠀⠀⠀⠰⠀⠀⢙⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿⣿⣯⡀⠀⢃⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⢠⠎⠀⠀⠀⠀⠀⠀⣼⠀⢀⠀⠀⠀⠀⠀⢠⣷⡀⠀⠀⠀⠀⡀⠄⠀⠀⠀⠀⢻⣿⣿⣿⣧⠑⠀⣢⡄⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⡰⠃⢀⠄⠀⠀⠀⠀⣼⡿⡆⢸⠀⠀⠀⠀⠀⠈⣿⢷⡄⠀⠀⠀⠱⡀⠰⡀⠀⠀⠈⢿⣿⣿⣿⣧⠀⢸⣧⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠡⢢⠋⠀⠀⠀⠀⣼⡟⠀⣇⢸⡆⠀⠀⠀⡄⠀⢿⠀⢳⡄⠀⠀⠀⢳⠀⢳⠀⠀⠀⠈⣿⣿⣿⣿⣷⣘⡟⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⢀⠇⠀⠀⠀⠀⣸⡿⢤⠤⠸⡸⣷⠀⠀⠀⢱⠀⣾⡤⠤⢿⡤⢀⡀⠀⢧⠘⡆⠀⠀⠀⢸⡟⠻⢿⠟⣿⣷⡄⠀⠀⠀
 * ⠀⠀⠀⠀⠀⡞⠀⠀⠀⠀⢰⡿⢠⠇⠀⠀⢳⣿⢇⠀⠀⠈⡇⣿⡇⠀⠀⠻⣄⠀⠀⠘⡆⡇⠀⠀⠀⠀⣇⢀⡏⠀⣿⡿⣄⠀⠀⠀
 * ⠀⠀⠀⠀⢰⠁⠀⠀⠀⠀⣿⠁⣄⣀⣀⡀⠈⢿⡜⡄⠀⠀⢹⣿⡇⠐⢄⣀⠘⢧⡀⠀⠹⣿⠀⠀⠀⠀⢸⣿⣷⣶⣿⡇⢹⡇⠀⠀
 * ⠀⠀⠀⠀⠾⠀⠀⠀⠀⢸⣧⣾⠟⢉⣽⣿⣦⠈⢷⡘⣆⠀⠸⡟⣷⣶⠟⠛⢻⣷⣦⣀⠀⢻⠀⠀⠀⠀⢸⣏⣩⣼⣿⡇⠈⣷⠀⠀
 * ⠀⠀⠀⠃⠀⠀⠀⠀⠀⣿⡿⠁⠀⣠⣾⣿⣿⠀⠈⢿⠺⡆⠀⣧⢸⠀⠀⢀⣹⣿⣿⣿⣷⣼⣤⠀⠀⠀⢸⣿⣿⣿⣿⠀⠀⣿⠀⠀
 * ⠀⠀⣠⠄⣀⠀⠀⠀⢠⣿⡇⠀⠀⢻⢻⣟⢿⠀⠀⠈⠣⠈⠓⠾⠀⠀⠀⣿⣿⢿⣿⣿⠘⡇⡞⠀⠀⢠⣾⣿⣿⣿⡏⠀⠀⢹⠀⠀
 * ⠀⠀⠛⠀⣿⠀⠀⠀⢸⣿⣿⡀⠀⠈⠃⠐⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣄⣐⣠⠏⢠⣿⠁⠀⠀⢸⣿⣿⣿⣿⠀⠀⠀⢸⠀⠀
 * ⠀⠀⠀⠀⢹⡆⠰⡀⢸⡟⠩⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠃⠀⠀⠀⢸⣿⣿⣿⠟⠀⠀⠀⠘⠀⠀
 * ⠀⠀⠀⠀⢎⣿⡀⢱⢞⣁⣀⡿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠞⡏⡼⠀⠀⠀⣾⣿⠋⠁⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠈⠿⠻⡇⠀⠀⠒⠢⢵⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣽⠁⠀⠀⢠⡿⢹⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⡀⠀⠀⠀⠀⠀⠀⡟⣦⡀⠀⠀⠀⠈⠓⢄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⢿⡇⠀⠀⡄⣸⣇⣼⣀⣀⣀⠀⠀⠀⠀⠀⠀
 * ⡀⠀⠀⠀⠀⠀⢰⠇⣿⢸⣦⡀⠀⠀⠀⠀⠈⠲⣄⡀⠀⠀⠀⠀⠀⣀⡤⠒⢉⡴⠃⣸⠀⠀⢰⣿⣿⣿⠃⡤⠊⠁⠉⠑⢄⠀⠀⠀
 * ⡇⠀⠀⠀⠀⠀⢸⠀⣿⣾⣿⢿⠲⣄⠀⠀⠀⠀⠘⠟⣦⣤⣴⡒⠉⢀⡠⠖⠉⠀⣠⠃⠀⣠⣿⣿⡿⠁⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⢸⠀⣿⠛⢿⠈⢢⠏⠀⠀⠀⠀⠀⣰⣏⣀⣿⠗⠊⠁⠀⠀⣠⣾⠃⢀⡴⠿⠛⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⢸⢀⠇⠀⠈⢠⠃⠀⠀⠀⠀⠀⢰⠟⠁⠀⢹⢇⠀⣀⠴⠊⡱⠥⠔⠋⠀⠀⢰⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⢸⡟⠀⢀⡴⠁⠀⠀⠀⠀⠀⢠⡟⠀⠀⣰⢿⡘⣾⡅⠀⠀⠀⠀⢀⠄⠀⢠⠏⢀⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⢸⠀⣰⣿⠀⠀⠀⠀⠀⠀⢠⣿⠃⢀⡾⡇⠘⠻⡿⢷⡀⠀⠀⠒⠁⠀⢠⠏⢀⠏⣸⠃⢻⠏⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⣧⣾⣹⣿⠀⠀⠀⠀⠀⢠⠏⢉⠀⡞⣰⡇⠀⣴⣥⠞⢷⠀⠀⠀⠀⣠⠎⠀⠸⣶⠋⣠⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀
 */
contract UWU is IERC20, Ownable {
    string private constant _name = "MENTALLYSANE";
    string private constant _symbol = "UWU";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1_000_000_000 * 10 ** _decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _redisFeeOnBuy = 0;
    uint256 private _taxFeeOnBuy = 25;
    uint256 private _redisFeeOnSell = 0;
    uint256 private _taxFeeOnSell = 30;

    uint256 private _redisFee = _redisFeeOnSell;
    uint256 private _taxFee = _taxFeeOnSell;

    uint256 private _previousredisFee = _redisFee;
    uint256 private _previoustaxFee = _taxFee;

    mapping(address => bool) public bots;
    mapping(address => uint256) public _buyMap;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private swapEnabled = true;

    uint256 public _maxTxAmount = 10_000_000 * 10 ** _decimals;
    uint256 public _maxWalletSize = 10_000_000 * 10 ** _decimals;
    uint256 public _swapTokensAtAmount = 10_000 * 10 ** _decimals;

    uint256 public deployBlock;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Ownable(msg.sender) {
        _rOwned[msg.sender] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        deployBlock = block.number;

        emit Transfer(address(0), msg.sender, _tTotal);
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(
            amount <= _allowances[sender][msg.sender],
            "ERC20: transfer amount exceeds allowance"
        );
        _allowances[sender][msg.sender] -= amount;
        _approve(sender, msg.sender, _allowances[sender][msg.sender]);
        _transfer(sender, recipient, amount);
        return true;
    }

    function tokenFromReflection(
        uint256 rAmount
    ) private view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function removeAllFee() private {
        if (_redisFee == 0 && _taxFee == 0) return;

        _previousredisFee = _redisFee;
        _previoustaxFee = _taxFee;

        _redisFee = 0;
        _taxFee = 0;
    }

    function restoreAllFee() private {
        _redisFee = _previousredisFee;
        _taxFee = _previoustaxFee;
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

        if (from != owner() && to != owner()) {
            //Trade start check
            if (!tradingOpen) {
                require(
                    from == owner(),
                    "TOKEN: This account cannot send tokens until trading is enabled"
                );
            }

            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
            require(
                !bots[from] && !bots[to],
                "TOKEN: Your account is blacklisted!"
            );

            if (to != uniswapV2Pair) {
                require(
                    balanceOf(to) + amount < _maxWalletSize,
                    "TOKEN: Balance exceeds wallet size!"
                );
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

            if (contractTokenBalance >= _maxTxAmount) {
                contractTokenBalance = _maxTxAmount;
            }

            if (
                canSwap &&
                !inSwap &&
                from != uniswapV2Pair &&
                swapEnabled &&
                !_isExcludedFromFee[from] &&
                !_isExcludedFromFee[to]
            ) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    _sendETHToFee(address(this).balance);
                }
            }
        }

        bool takeFee = true;

        //Transfer Tokens
        if (
            (_isExcludedFromFee[from] || _isExcludedFromFee[to]) ||
            (from != uniswapV2Pair && to != uniswapV2Pair)
        ) {
            takeFee = false;
        } else {
            //Set Fee for Buys
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnBuy;
                _taxFee = _taxFeeOnBuy;
            }

            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnSell;
                _taxFee = _taxFeeOnSell;
            }
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _sendETHToFee(uint256 amount) private {
        payable(owner()).transfer(amount);
    }

    function kawaii(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }

    function manualswap() public onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }
        if (contractTokenBalance > 0) {
            swapTokensForEth(contractTokenBalance);
        }
    }

    function manualsend() public onlyOwner {
        _sendETHToFee(address(this).balance);
    }

    function blockBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function unblockBot(address notbot) public onlyOwner {
        bots[notbot] = false;
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
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rTeam;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    receive() external payable {}

    function _getValues(
        uint256 tAmount
    )
        private
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(
            tAmount,
            _redisFee,
            _taxFee
        );
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tTeam,
            currentRate
        );
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 redisFee,
        uint256 taxFee
    ) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = (tAmount * redisFee) / 100;
        uint256 tTeam = (tAmount * taxFee) / 100;
        uint256 tTransferAmount = tAmount - tFee - tTeam;
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    ) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rTeam = tTeam * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rTeam;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function setFee(
        uint256 redisFeeOnBuy,
        uint256 redisFeeOnSell,
        uint256 taxFeeOnBuy,
        uint256 taxFeeOnSell
    ) public onlyOwner {
        _redisFeeOnBuy = redisFeeOnBuy;
        _redisFeeOnSell = redisFeeOnSell;
        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
    }

    function setMinSwapTokensThreshold(
        uint256 swapTokensAtAmount
    ) public onlyOwner {
        _swapTokensAtAmount = swapTokensAtAmount;
    }

    function toggleSwap(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }

    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }

    function removeTaxes() public onlyOwner {
        require(block.number >= deployBlock + 10, "Not elapsed");
        setFee(0, 0, 0, 0);
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }
}
