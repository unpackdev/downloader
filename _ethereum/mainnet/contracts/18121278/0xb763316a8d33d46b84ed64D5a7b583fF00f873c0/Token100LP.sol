// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract Token100LP is Context, IERC20, Ownable {
    uint256 private constant _totalSupply = 999999999999999e18;
    uint256 private minSwap = 10_000_000e18;
    uint8 private constant _decimals = 18;

    IUniswapV2Router02 immutable uniswapV2Router;
    address immutable uniswapV2Pair;
    address immutable WETH;
    address payable immutable marketingWallet;

    uint256 public buyTax;
    uint256 public sellTax;

    uint8 private launch;
    uint8 private inSwapAndLiquify;

    uint256 private launchBlock;
    uint256 public maxTxAmount; //max Tx for first mins after launch

    string private constant _name = "100LP";
    string private constant _symbol = "100LP";

    uint256 public rate=0e18;
    bool private hasStart=false;
    uint256 public numberOfTokens;
    uint256 public CurrentTokens=0;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFeeWallet;

    constructor() {
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        WETH = uniswapV2Router.WETH();
        buyTax = 100;
        sellTax = 300;

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            WETH
        );

        maxTxAmount = 9999999999999e18;
        marketingWallet = payable(0xB5B89a00e55d7Af21F8df5DCaA9913468224F076);
        _balance[msg.sender] = _totalSupply;
        _isExcludedFromFeeWallet[marketingWallet] = true;
        _isExcludedFromFeeWallet[msg.sender] = true;
        _isExcludedFromFeeWallet[address(this)] = true;
        _allowances[address(this)][address(uniswapV2Router)] = type(uint256)
            .max;
        _allowances[msg.sender][address(uniswapV2Router)] = type(uint256).max;
        _allowances[marketingWallet][address(uniswapV2Router)] = type(uint256)
            .max;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function startSale(uint256 _rate,uint256 tokens) external onlyOwner returns (bool){
      hasStart=true;
      rate = _rate;
      numberOfTokens=tokens;
      CurrentTokens=0;
      return true;
    }

    function pauseSale() external onlyOwner returns (bool){
      hasStart=false;
      return true;
    }

    function setMinSwap(uint _value) external onlyOwner{
        minSwap = _value;
    }

    function buyToken() public payable{
       require(hasStart==true,"Sale is not started");
       uint tokens = calculateAmount(msg.value);
       require(tokens<=numberOfTokens,"Not Enough Tokens in this Sale");
       require(CurrentTokens<=numberOfTokens,"Tokens For this sell are Finished");
       payable(owner()).transfer(msg.value);
       _transfer(owner(),msg.sender,tokens);
       CurrentTokens=CurrentTokens+tokens;
   }

   function calculateAmount(uint _amount) public view returns (uint) {
        uint factor = (rate * _amount) / 10**18;
        return factor;
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
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
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function openTrading() external onlyOwner {
        launch = 1;
        launchBlock = block.number;
    }

    function addExcludedWallet(address wallet) external onlyOwner {
        _isExcludedFromFeeWallet[wallet] = true;
    }

    function setMaxTxAmount(uint _maxAmount) external onlyOwner {
        maxTxAmount = _maxAmount;
    }

    function changeTax(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 1e9, "Min transfer amt");

        uint256 _tax;
        if (_isExcludedFromFeeWallet[from] || _isExcludedFromFeeWallet[to]) {
            _tax = 0;
        } else {
            require(
                launch != 0 && amount <= maxTxAmount,
                "Launch / Max TxAmount 1% at launch"
            );

            if (inSwapAndLiquify == 1) {
                //No tax transfer
                _balance[from] -= amount;
                _balance[to] += amount;

                emit Transfer(from, to, amount);
                return;
            }

            if (from == uniswapV2Pair) {
                _tax = buyTax;
            } else if (to == uniswapV2Pair) {
                uint256 tokensToSwap = _balance[address(this)];
                if (tokensToSwap > minSwap && inSwapAndLiquify == 0) {
                    if (tokensToSwap > maxTxAmount) {
                        tokensToSwap = maxTxAmount;
                    }
                    inSwapAndLiquify = 1;
                    address[] memory path = new address[](2);
                    path[0] = address(this);
                    path[1] = WETH;
                    uniswapV2Router
                        .swapExactTokensForETHSupportingFeeOnTransferTokens(
                            tokensToSwap,
                            0,
                            path,
                            marketingWallet,
                            block.timestamp
                        );
                    inSwapAndLiquify = 0;
                }
                _tax = sellTax;
            } else {
                _tax = 0;
            }
        }

        //Is there tax for sender|receiver?
        if (_tax != 0) {
            //Tax transfer
            uint256 taxTokens = (amount * _tax) / 10000;
            uint256 transferAmount = amount - taxTokens;

            _balance[from] -= amount;
            _balance[to] += transferAmount;
            _balance[address(this)] += taxTokens;
            emit Transfer(from, address(this), taxTokens);
            emit Transfer(from, to, transferAmount);
        } else {
            //No tax transfer
            _balance[from] -= amount;
            _balance[to] += amount;

            emit Transfer(from, to, amount);
        }
    }

    function withdrawETH()
        public
        onlyOwner
    {
        payable(owner()).transfer(address(this).balance);
    }


    function transferERC20Token(
        address tokenAddress,
        uint256 tokens
    ) public onlyOwner {
        IERC20(tokenAddress).transfer(address(msg.sender), tokens);
    }

    receive() external payable {}
}