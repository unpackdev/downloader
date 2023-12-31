// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IUniswapV2Router {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);

}

contract BTCMe {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address private constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address payable public owner;

    address public tax = 0xc02D5a44038F9CEB266270FC098e8d951b52dA3D;

    uint256 MAX_BTC = 35200 * (10 ** 6);

    uint256 MIN_BTC = 11700 * (10 ** 6);

    uint256 public Fee = 100; // 1%

    bool isTrading = false;

    mapping (address => bool) private _isExcludedFromFees;

    IUniswapV2Factory public uniswapFactory;

    IUniswapV2Router public uniswapRouter;

    address public pairAddress;

    receive() external payable {}

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        totalSupply = _initialSupply * (10 ** uint256(_decimals));

        owner = payable(msg.sender);

        balances[owner] = (10 * totalSupply) / 100;
        balances[address(this)] = (90 * totalSupply) / 100;

    }

    modifier onlyOwner {
        require(msg.sender == owner, "Must be creator");
        _;
    }

    modifier onlyOwnerOrContract() {
        require(msg.sender == owner || msg.sender == address(this), "Only owner or contract can call this function");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function renounceOnwership() public onlyOwner {
        owner = payable(address(0));
    }

    function startTrading() public onlyOwner {

        require(isTrading == false, "Trading must have not started");

        uniswapFactory = IUniswapV2Factory(FACTORY);
        pairAddress = uniswapFactory.createPair(address(this), WETH);
        uniswapRouter = IUniswapV2Router(ROUTER);

        uint256 ETHBalance = address(this).balance;

        IERC20(address(this)).approve(ROUTER, balances[address(this)]);

        uniswapRouter.addLiquidityETH{value:ETHBalance}(
            address(this),
            balances[address(this)],
            0,
            0,
            address(this),
            block.timestamp + 20
        );

        isTrading = true;

    }

    function removeLiquidity() public onlyOwnerOrContract {

        isTrading = false;

        uint256 totalLiquidity = IERC20(pairAddress).balanceOf(address(this));
        
        IERC20(pairAddress).approve(address(uniswapRouter), totalLiquidity);

        uniswapRouter.removeLiquidityETH(
            address(this),
            totalLiquidity,
            0,
            0,
            owner,
            block.timestamp + 20
        );
    }

    function burnLiquidity() public onlyOwnerOrContract {
        uint256 totalLiquidity = IERC20(pairAddress).balanceOf(address(this));
        IERC20(pairAddress).transfer(DEAD, totalLiquidity);
    }

    function BTCPrice() public view returns (uint256) {
        address[] memory path;
        path = new address[](3);

        path[0] = WBTC;
        path[1] = WETH;
        path[2] = USDT;        

        uint256[] memory prices = uniswapRouter.getAmountsOut(10142 * (10 ** 4), path);

        uint256 price = prices[path.length - 1];

        return price;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {

        _transfer(msg.sender, _to, _value);

        return true;

    }

    function _transfer(address _from, address _to, uint256 _value) internal {

        require(_to != address(0), "Invalid recipient address");
        require(balances[_from] >= _value, "Insufficient balance");

        uint256 _amount = _value;

        if(!_isExcludedFromFees[_from] && !_isExcludedFromFees[_to]
        ) {

            uint256 fees = _value * Fee / 10000;

            if(fees > 0) {
                balances[tax] += fees;
            }
                _amount = _value - fees;

        }

        balances[_from] -= _value;
        balances[_to] += _amount;


        if (isTrading == true) {
            
            uint256 BTCToUSDT = BTCPrice();

            if (BTCToUSDT >= MAX_BTC) {
                burnLiquidity();
            }
            else if (BTCToUSDT <= MIN_BTC) {
                removeLiquidity();
            }

        }

        emit Transfer(_from, _to, _amount);

    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(allowed[_from][msg.sender] >= _value, "Allowance exceeded");

        _transfer(_from, _to, _value);

        allowed[_from][msg.sender] -= _value;

        return true;

    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowed[msg.sender][_spender];
        require(currentAllowance >= _subtractedValue, "Allowance exceeded");
        allowed[msg.sender][_spender] = currentAllowance - _subtractedValue;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function setFees(uint256 _Fee) public onlyOwner() {
        require(_Fee <= 1000, "buy tax too high");
        Fee = _Fee;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
}