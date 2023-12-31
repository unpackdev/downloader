//SPDX-License-Identifier: Unlicensed
// Twitter: https://twitter.com/WeAreLuffyErc
// Telegram: https://t.me/WeAreLuffyErc
// Website: https://WeAreLuffy.com
pragma solidity >=0.7.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Luffy is Context, IERC20 {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public _balances;
    mapping(address => bool) feeExcluded;
    mapping(address => bool) maxTransactionExcluded;
    mapping(address => bool) pairs;

    string private _name;
    string private _symbol;

    uint256 supply;
    uint256 maxTransactionAmount;
    uint256 swapAmount;
    uint256 taxAmount;
    uint16 tax;
    uint16 public sellTax;
    uint16 public buyTax;
    uint16 public transferTax;
    uint16 taxDivisor = 1000;

    bool swapEnabled;
    bool taxEnabled;
    bool _inSwap;
    bool limits;

    IRouter router;
    address ownerWallet;
    address public taxWallet;
    address public pair;

    modifier onlyOwner() {
        require(_msgSender() == ownerWallet);
        _;
    }

    constructor(string memory name_, string memory symbol_, uint256 startingSupply, address _taxWallet) {
        ownerWallet = _msgSender();
        taxWallet = _taxWallet;
        _name = name_;
        _symbol = symbol_;
        _mint(_msgSender(), startingSupply * (10**9));

        maxTransactionAmount = (supply * 2) / 100;

        setSwap(true, 10);
        buyTax = 100;
        sellTax = 200;
        taxEnabled = true;

        router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IFactory(router.factory()).createPair(router.WETH(), address(this));
        pairs[pair] = true;

        _approve(address(this), address(router), type(uint256).max);
        _approve(_msgSender(), address(router), type(uint256).max);

        maxTransactionExcluded[_msgSender()] = true;
        maxTransactionExcluded[address(this)] = true;
        maxTransactionExcluded[pair] = true;
        feeExcluded[address(this)] = true;
        feeExcluded[_msgSender()] = true;
        feeExcluded[address(router)] = true;
    }

    receive() external payable {}

    function owner() public view returns (address) {
        return ownerWallet;
    }

    function name() public view override returns (string memory) {
        return _name;
    }
 
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function totalSupply() public view override returns (uint256) {
        return supply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address _owner = _msgSender();
        _transfer(_owner, to, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        address _owner = _msgSender();
        _approve(_owner, spender, amount);
        return true;
    }
     
    function renounceOwnership() external onlyOwner {
        ownerWallet = address(0);
        maxTransactionAmount = supply;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address, use renounceOwnership Function");

        if(balanceOf(ownerWallet) > 0) _transfer(ownerWallet, newOwner, balanceOf(ownerWallet));

        ownerWallet = newOwner;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");


        supply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            supply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _spendAllowance(address _owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(_owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(_owner, spender, currentAllowance - amount);
            }
        }
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address _owner = _msgSender();
        _approve(_owner, spender, allowance(_owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address _owner = _msgSender();
        uint256 currentAllowance = allowance(_owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");

        if (limits) {
            if (!maxTransactionExcluded[to]) {
                require(
                    amount <= maxTransactionAmount,
                    "TOKEN: Amount exceeds Transaction size"
                );
            } else if (pairs[to] && !maxTransactionExcluded[from]) {
                require(
                    amount <= maxTransactionAmount,
                    "TOKEN: Amount exceeds Transaction size"
                );
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) internal {
        _beforeTokenTransfer(from, to, amount);


        if( from != pair
        && swapEnabled 
        && _balances[address(this)] >= swapAmount) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = router.WETH();

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                swapAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
    
            uint256 balance = address(this).balance;
            payable(taxWallet).transfer(balance);
        
        }

        uint256 amountReceived = taxEnabled && !feeExcluded[from] ? takeFee(from, to, amount) : amount;

        uint256 fromBalance = _balances[from];
        unchecked {
            _balances[from] = fromBalance - amountReceived;
            _balances[to] += amountReceived;
        }
        emit Transfer(from, to, amountReceived);
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        if (feeExcluded[receiver]) {
            return amount;
        }
        if(pairs[receiver]) {   
            tax = sellTax;         
        } else if(pairs[sender]){
            tax = buyTax;    
        } else {
            tax = transferTax;
        }

        if(tax == 0) {return amount;}
        taxAmount = (amount * tax) / taxDivisor;
        uint256 senderBalance = _balances[sender];
        unchecked {
            _balances[sender] = senderBalance - taxAmount;
            _balances[address(this)] += taxAmount;
        }

        emit Transfer(sender, address(this), taxAmount);

        return amount - taxAmount;
    }

    function clearStuckBalance(uint256 percent) external onlyOwner {
        require(percent <= 100);
        uint256 amountEth = (address(this).balance * percent) / 100;
        payable(taxWallet).transfer(amountEth);
    }

    function clearStuckTokens(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0) && _token != address(this));
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    function setFeeExclusion(address holder, bool fee) external onlyOwner(){
        feeExcluded[holder] = fee;
    }

    function setPair(address pairing, bool lpPair) external onlyOwner {
        pairs[pairing] = lpPair;
    }

    function setTransactionAmount(uint256 amount) external onlyOwner {
        require(amount <= supply / 100 );
        maxTransactionAmount = amount;
    }

    function setTax(uint16 _buyTax, uint16 _sellTax, uint16 _transferTax, bool _taxEnabled) external onlyOwner {
        require(_buyTax + _sellTax + transferTax <= 200);
        buyTax = _buyTax;
        sellTax = _sellTax;
        transferTax = _transferTax;
        taxEnabled = _taxEnabled;
    }

    function setTaxWallet(address _taxWallet) external onlyOwner {
        taxWallet = _taxWallet;
    }
    
    function setSwap(bool _enabled, uint256 _amount) public onlyOwner{
        swapEnabled = _enabled;
        swapAmount = _amount * (10**9);
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
}