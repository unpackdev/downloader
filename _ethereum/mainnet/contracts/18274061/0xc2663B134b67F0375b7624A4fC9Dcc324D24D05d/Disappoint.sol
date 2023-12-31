// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    // function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    //     external
    //     payable
    //     returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract Disappoint is Context, IERC20, Ownable {
    using SafeMath for uint256;



    // Add function to change fee and remove final tax, buy count and parts in _transfer function.
    // Add function to change fee and remove final tax, buy count and parts in _transfer function.
    // Add function to change fee and remove final tax, buy count and parts in _transfer function.
    // Add function to change fee and remove final tax, buy count and parts in _transfer function.

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    
    // add mapping for blacklisting
    mapping(address => bool) private _blacklist;

    bool public transferDelayEnabled = false;

    // wallet that will be used to receive funds and distribute to rev share contracts
    address payable public teamWallet;

    address public immutable WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 private _initialBuyTax = 50;
    uint256 private _initialSellTax = 50;
    uint256 public _preventSwapBefore = 2;
    uint256 public _buyCount = 0;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 85_000_000 * 10 ** _decimals;
    string private constant _name = "Disappoint";
    string private constant _symbol = "$DSPNT";

    // maxTxAmount and maxWalletSize = 3%
    uint256 public _maxTxAmount = 2_070_000 * 10 ** _decimals;
    uint256 public _maxWalletSize = 2_070_000 * 10 ** _decimals;
    uint256 public _maxTaxSwap = 15_000 * 10 ** _decimals;
    uint256 public _taxSwapThreshold = 15_001 * 10 ** _decimals;

    IUniswapV2Router02 public uniswapV2Router;
    address public pair;

    bool public tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event BlacklistUpdate(address indexed _address, bool _blacklisted);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    constructor() {
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
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
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
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

        // Blacklisting functionality
        require(_blacklist[to] != true && _blacklist[from] != true, "Cannot transfer to/from a blacklisted address");

        uint256 taxAmount = 0;

        // Only apply tax if not owner()
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul(_initialBuyTax).div(100);

            // Transfer delay. limits one buy/sell per block
            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(pair)) {
                    require(
                        _holderLastTransferTimestamp[tx.origin] < block.number,
                        "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            // Check if tx amount is over the max and if the receiving wallet will exceed the max
            if (from == pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
            }

            // Apply sell tax if applicable
            if (to == pair && from != address(this)) {
                taxAmount = amount.mul(_initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));

            
            if (
                !inSwap && to == pair && swapEnabled && contractTokenBalance > _taxSwapThreshold
                    && _buyCount > _preventSwapBefore
            ) {
                swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));

                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 50000000000000000) {
                    _distributeMultisigs(address(this).balance);
                }
            }
        }

        // Transfers before opening trade have no tax
        if (!tradingOpen) {
            taxAmount = 0;
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function _distributeMultisigs(uint256 _feeAmount) private {
        teamWallet.transfer(_feeAmount);
    }

    // Initialize the LP pool/pair
    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");

        // uniswapv2 router mainnet
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _approve(address(this), address(uniswapV2Router), _tTotal);

        // create/store [eth][$dspnt] pair address
        pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp
        );
        IERC20(pair).approve(address(uniswapV2Router), type(uint256).max);

        swapEnabled = true;
        tradingOpen = true;
    }

    // function to receive ERC20 tokens
    receive() external payable {}

    function manualSwapTotal() external {
        require(_msgSender() == teamWallet, "authentication required");

        uint256 tokenBalance = balanceOf(address(this));

        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            _distributeMultisigs(ethBalance);
        }
    }

    function manualSwapPartial() external {
        require(_msgSender() == teamWallet, "authentication required");

        uint256 tokenBalance = (balanceOf(address(this)).mul(15).div(100));

        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            _distributeMultisigs(ethBalance);
        }
    }

    function updateTeamWallet(address _teamWallet) external onlyOwner {
        require(_teamWallet != address(0), "address(0)");

        teamWallet = payable(_teamWallet);

        _isExcludedFromFee[teamWallet] = true;
    }

    function blacklist(address _address) external onlyOwner {
        require(_address != address(0), "address(0)");
        require(!_blacklist[_address], "Address already blacklisted");
        _blacklist[_address] = true;
        emit BlacklistUpdate(_address, true);
    }

    function removeBlacklist(address _address) external onlyOwner {
        require(_address != address(0), "address(0)");
        require(_blacklist[_address], "User is not blacklisted");
        _blacklist[_address] = false;
        emit BlacklistUpdate(_address, false);
    }

    function toggleDelay() external onlyOwner {
        transferDelayEnabled = !transferDelayEnabled;
    }

    function excludeFee(address _user) external onlyOwner() {
        require(_user != address(0), "address(0)");
        _isExcludedFromFee[_user] = true;
    }

    function delegateFee(address _user) external onlyOwner {
        require(_user != address(0), "address(0)");
        _isExcludedFromFee[_user] = false;
    }

    function changeTax(uint256 _buyTax, uint256 _sellTax) external onlyOwner {
        // require(_msgSender() == teamWallet, "authentication required");
        _initialBuyTax = _buyTax;
        _initialSellTax = _sellTax;
    }

    function withdraw(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    // deposit function for liquidity
    function deposit() payable external onlyOwner {
        require(msg.value > 0, "Value must be greater than 0");
    }

    function withdrawToken(address _token, address _to) external onlyOwner {
        IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
    }
}