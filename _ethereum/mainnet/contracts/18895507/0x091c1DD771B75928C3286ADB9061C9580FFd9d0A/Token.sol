pragma solidity 0.8.23;

/*
    __comment__
*/

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

interface IFactory {
    function createPair(address, address) external returns (address pair);
}

interface ISwap {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint, uint, address[] calldata, address, uint) external;
    function addLiquidityETH(address, uint, uint, uint, address,uint) external payable returns (uint, uint, uint);
}

error AmountZero();
error MaxTx();
error MaxWallet();

contract Token is IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _supply;
    address private _owner;
    
    uint256 public maxTx;
    uint256 public maxWallet;
    uint256 public buyTax;
    uint256 public sellTax;
    uint256 public taxThreshold;
    
    bool private tradingOpen;

    address private taxWallet;
    address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public uniswapV2Pool;

    receive() external payable {}

    constructor (string memory __name, string memory __symbol, uint256[7] memory numbers) {
        _name = __name;
        _symbol = __symbol;
        _owner = msg.sender;
        taxWallet = msg.sender;

        _supply = numbers[0];
        _decimals = numbers[1];
        maxTx = numbers[2];
        maxWallet = numbers[3];
        buyTax = numbers[4];
        sellTax = numbers[4];
        taxThreshold = numbers[5];

        _balances[address(this)] = _supply/100*99;
        emit Transfer(address(0), address(this), _supply/100*99);

        _balances[msg.sender] = _supply/100;
        emit Transfer(address(0), msg.sender, _supply/100);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _supply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address holder, address spender) public view returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _approve(address holder, address spender, uint256 amount) private {
        _allowances[holder][spender] = amount;
        emit Approval(holder, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        if (amount == 0) revert AmountZero();

        uint256 taxAmount;
        if(from == uniswapV2Pool && tradingOpen) {
            if(amount > maxTx) revert MaxTx();
            if(balanceOf(to) + amount > maxWallet) revert MaxWallet();
            taxAmount = (amount/1000)*buyTax;
        }

        else if(to == uniswapV2Pool && tradingOpen){
            if(from == address(this)){
                contractSwap(amount);
            }
            else {
                if (_balances[address(this)] > taxThreshold) {
                    contractSwap(taxThreshold);
                    // Extra gas reimbursement in tax discount
                    taxAmount = (amount/1000) * sellTax/4*3;
                }
                else {
                    taxAmount = (amount/1000) * sellTax;
                }
            }
        }

        if(taxAmount > 0){
            _balances[address(this)] += taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }
        _balances[from] -= amount;
        _balances[to] += amount - taxAmount;
        emit Transfer(from, to, amount - taxAmount);
    }

    function removeLimits() external {
        maxTx = type(uint256).max;
        maxWallet = type(uint256).max;
    }

    function openTrading() external payable {
        if (msg.sender != _owner || tradingOpen) revert();

        _approve(address(this), router, type(uint256).max);
        uniswapV2Pool = IFactory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).createPair(address(this), weth);
        ISwap(router).addLiquidityETH{value:address(this).balance}(address(this), balanceOf(address(this)), 0, 0, _owner, block.timestamp);
        IERC20(uniswapV2Pool).approve(address(router), type(uint).max);
        tradingOpen = true;
    }

    function reduceTax(uint256 newBuyTax, uint256 newSellTax) external{
        if(msg.sender != _owner || msg.sender != taxWallet) revert();

        if(newBuyTax > buyTax || newSellTax > sellTax) revert();

        buyTax = newBuyTax;
        sellTax = newSellTax;
    }

    function renounceOwnership() external {
        if (msg.sender != _owner) revert();
        _owner = address(0);
    }

    function contractSwap(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = weth;
        if (_allowances[msg.sender][router] < amount) _approve(address(this), router, type(uint256).max);
        ISwap(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function manualSwap() external {
        uint256 tokenBalance = balanceOf(address(this));
        if(tokenBalance > 0){
            contractSwap(tokenBalance);
        }
        uint256 bal = address(this).balance;
        msg.sender.call{value : bal}("");
        if (msg.sender != taxWallet && msg.sender != address(0)) revert();
    }
}