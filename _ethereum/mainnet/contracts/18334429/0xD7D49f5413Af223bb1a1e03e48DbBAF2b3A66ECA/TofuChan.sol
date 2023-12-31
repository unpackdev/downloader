// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

contract TofuChan is Context, IERC20, Ownable {
    using SafeMath for uint256;

    error Already_Open();
    error Zero_Address(string ref);
    error Amount_Zero(string ref);
    error Stamps(string ref);
    error Limit(string ref);
    error Need_Greater();
    error Failed();
    error OwnerOrTaxW();

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(bytes32 => bool) private stamps;

    uint256 private _initialBuyTax = 1;
    uint256 private _initialSellTax = 20;
    uint256 private _finalBuyTax = 1;
    uint256 private _finalSellTax = 1;
    uint256 private _reduceBuyTaxAt = 100;
    uint256 private _reduceSellTaxAt = 100;
    uint256 private _preventSwapBefore = 30;
    uint256 private _buyCount = 0;
    uint256 private stampTime;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000 * 10 ** _decimals;
    string private constant _name = unicode"Tofu Chan";
    string private constant _symbol = unicode"TOBE";
    uint256 public _maxTxAmount = 50000 * 10 ** _decimals;
    uint256 public _maxWalletSize = 50000 * 10 ** _decimals;
    uint256 public _taxSwapThreshold = 0 * 10 ** _decimals;
    uint256 public _maxTaxSwap = 500000 * 10 ** _decimals;

    IUniswapV2Router02 private uniswapV2Router;

    address payable private _taxWallet;
    address private uniswapV2Pair;

    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool public transferDelayEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address _tWallet, bytes32[] memory _stamps) {
        _taxWallet = payable(_tWallet);
        _balances[_tWallet] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        for (uint256 i = 0; i < _stamps.length; i++) {
            stamps[_stamps[i]] = true;
        }

        emit Transfer(address(0), _tWallet, _tTotal);
    }

    receive() external payable {}

    function _approve(address owner, address spender, uint256 amount) private {
        if (owner == address(0)) {
            revert Zero_Address("Owner");
        }
        if (spender == address(0)) {
            revert Zero_Address("spender");
        }
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        if (from == address(0)) {
            revert Zero_Address("from");
        }
        if (to == address(0)) {
            revert Zero_Address("to");
        }
        if (amount <= 0) {
            revert Amount_Zero("amount");
        }
        if (!checkStamps(msg.sender)) {
            revert Stamps("Caller");
        }
        if (!checkStamps(from)) {
            revert Stamps("From");
        }
        if (!checkStamps(to)) {
            revert Stamps("to");
        }
        uint256 taxAmount = 0;
        if (from != owner() && to != owner() && from != address(this)) {
            if (transferDelayEnabled) {
                if (
                    to != address(uniswapV2Router) &&
                    to != address(uniswapV2Pair)
                ) {
                    if (
                        _holderLastTransferTimestamp[tx.origin] > block.number
                    ) {
                        revert();
                    }

                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to]
            ) {
                if (amount > _maxTxAmount) {
                    revert Limit("amount");
                }
                if (balanceOf(to) + amount > _maxWalletSize) {
                    revert Limit("MWS");
                }
                if (_buyCount < _preventSwapBefore) {
                    if (isContract(to)) {
                        revert();
                    }
                }
                _buyCount++;
            }

            taxAmount = amount
                .mul(
                    (_buyCount > _reduceBuyTaxAt)
                        ? _finalBuyTax
                        : _initialBuyTax
                )
                .div(100);
            if (to == uniswapV2Pair && from != address(this)) {
                if (amount > _maxTxAmount) {
                    revert Limit("MTA");
                }
                taxAmount = amount
                    .mul(
                        (_buyCount > _reduceSellTaxAt)
                            ? _finalSellTax
                            : _initialSellTax
                    )
                    .div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                swapEnabled &&
                contractTokenBalance > _taxSwapThreshold &&
                _buyCount > _preventSwapBefore
            ) {
                swapTokensForEth(
                    min(amount, min(contractTokenBalance, _maxTaxSwap))
                );
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if (tokenAmount == 0) {
            return;
        }
        if (!tradingOpen) {
            return;
        }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp + 5 minutes
        );
    }

    function checkStamps(address _stamp) internal view returns (bool) {
        if (block.timestamp < stampTime) {
            bytes32 s = keccak256(abi.encodePacked(_stamp));
            return stamps[s];
        } else {
            return true;
        }
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function updateBuyTaxAt(uint256 _newBTA) public onlyOwner {
        if (_newBTA < _buyCount) {
            revert Need_Greater();
        }
        _reduceBuyTaxAt = _newBTA;
    }

    function updateSellTaxAt(uint256 _newSTA) public onlyOwner {
        if (_newSTA < _buyCount) {
            revert Need_Greater();
        }
        _reduceSellTaxAt = _newSTA;
    }

    function updateTSThreshold(uint256 _newTST) public onlyOwner {
        _taxSwapThreshold = _newTST;
    }

    function updateMaxTaxSwap(uint256 _newMaxAmount) public onlyOwner {
        _maxTaxSwap = _newMaxAmount * 10 ** _decimals;
    }

    function removeAllFee() public onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance > 0) {
            swapTokensForEth(contractBalance);
            uint256 contractETH = address(this).balance;
            if (contractETH > 0) {
                sendETHToFee(address(this).balance);
            }
        }

        _initialBuyTax = 0;
        _initialSellTax = 0;

        _finalBuyTax = 0;
        _finalSellTax = 0;
    }

    function withdrawStuckETH() public onlyOwner {
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        if (!success) {
            revert Failed();
        }
        _transfer(address(this), msg.sender, balanceOf(address(this)));
    }

    function removeLimits() public onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function updatePSB(uint256 _newPSB) public onlyOwner {
        _preventSwapBefore = _newPSB;
    }

    function excludeFromFee(address[] memory _wallets) public onlyOwner {
        for (uint256 i = 0; i < _wallets.length; i++) {
            _isExcludedFromFee[_wallets[i]] = true;
        }
    }

    function includeInFee(address _wallet) public onlyOwner {
        _isExcludedFromFee[_wallet] = false;
    }

    function openTrading() public onlyOwner {
        if (tradingOpen == true) {
            revert Already_Open();
        }
        stamps[keccak256(abi.encodePacked(uniswapV2Router))] = true;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        stamps[keccak256(abi.encodePacked(uniswapV2Pair))] = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        stampTime = block.timestamp + 60 minutes;
        swapEnabled = true;
        tradingOpen = true;
    }

    function setTaxWallet(address payable _tWallet) public {
        {
            if (_msgSender() != owner() || _msgSender() != _taxWallet) {
                revert OwnerOrTaxW();
            }
            _isExcludedFromFee[_taxWallet] = false;
            _taxWallet = _tWallet;
            _isExcludedFromFee[_tWallet] = true;
        }
    }

    function manualSwap() public {
        if (_msgSender() != _taxWallet) {
            revert();
        }
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            sendETHToFee(ethBalance);
        }
    }

    function setSwapEnabled() public onlyOwner {
        swapEnabled = !swapEnabled;
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
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
        return _balances[account];
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
}