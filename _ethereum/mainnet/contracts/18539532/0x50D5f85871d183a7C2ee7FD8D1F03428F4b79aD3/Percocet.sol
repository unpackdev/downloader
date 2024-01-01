/**
    Website: percocetpepe.vip
    Twitter: twitter.com/PercocetPepe
    Telegram: https://t.me/PercocetPepe
    KYC: https://pinksale.notion.site/Percocetpepe-KYC-Verification-4c3969edd0fe42629c3477e79c66a9b2
**/
// SPDX-License-Identifier:MIT
pragma solidity ^0.8.21;

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


interface IDexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}


interface IUniswapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        _owner = payable(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Percocet is Context, IERC20, Ownable {
    string private _name = "Percocet Pepe";
    string private _symbol = "PERC";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 420690000000000 * 1e18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isExcludedFromFee;
   

    uint256 public swapLimit = (_totalSupply * 5) / (10000);
    
    uint256 public divided = 100;
  

    bool public swapEnabled = false; 
    bool public feeStatus = false; 
    bool public tradeOpen = false; 

    IUniswapRouter public uniswapRouter; 

    address public routerPair; 
    address public marketingWallet; 
    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);

    uint256 public buyMarketingFee = 5;

    uint256 public sellMarketingFee = 5;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor() {
        _balances[owner()] = _totalSupply;
        marketingWallet = 0xBF605bc90AD61323e25688939e59D4255B99B844;

        uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        isExcludedFromFee[address(uniswapRouter)] = true;
     
        routerPair = IDexFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );
      
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + (addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    function includeOrExcludeFromFee(
        address account,
        bool value
    ) external onlyOwner {
        isExcludedFromFee[account] = value;
    }


    function setswapLimit(uint256 newLimit) external onlyOwner {
        swapLimit = newLimit * (10**18);
    }


    function setBuyTax(uint256 _buyFee) external onlyOwner {
        buyMarketingFee = _buyFee;
    }

    function setSellTax(uint256 _sellFee) external onlyOwner {
        sellMarketingFee = _sellFee;
    }

    function setswapEnabled(bool _value) public onlyOwner {
        swapEnabled = _value;
    }

    function setFeesStatus(bool _value) external onlyOwner {
        feeStatus = _value;
    }

    function updateAddresses(address _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function TradeOpen() external onlyOwner {
        require(!tradeOpen, "already enabled");
        tradeOpen = true;
        feeStatus = true;
        swapEnabled = true;
        
    }

    function removeStuckETH(address _receiver) public onlyOwner {
        payable(_receiver).transfer(address(this).balance);
    }



    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), " approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(amount > 0, "Amount must be greater than zero");
       
if (!isExcludedFromFee[from] && !isExcludedFromFee[to]) {
     if (!tradeOpen) {
                require(
                    routerPair != from && routerPair != to,
                    "trading is not yet enabled"
                );
            }

}
           

        taxSwap(from, to);
        bool takeFee = true;
        if (isExcludedFromFee[from] || isExcludedFromFee[to] || !feeStatus) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (routerPair == sender && takeFee) {
            uint256 feeAmount=(amount * buyMarketingFee) / (divided);
            uint256 tTransferAmount;
            
            tTransferAmount = amount - feeAmount;

            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + tTransferAmount;
            emit Transfer(sender, recipient, tTransferAmount);

            takeTokenFee(sender, feeAmount);
        } else if (routerPair == recipient && takeFee) {
            uint256 feeAmount = (amount * sellMarketingFee) / (divided);
            uint256 tTransferAmount = amount - feeAmount;
            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + tTransferAmount;
            emit Transfer(sender, recipient, tTransferAmount);

            takeTokenFee(sender, feeAmount);
        } else {
            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + (amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function takeTokenFee(address sender, uint256 amount) private {
        _balances[address(this)] = _balances[address(this)] + (amount);

        emit Transfer(sender, address(this), amount);
    }

    function withdrawETH(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Invalid Amount");
        payable(msg.sender).transfer(_amount);
    }

    function withdrawToken(IERC20 _token, uint256 _amount) external onlyOwner {
        require(_token.balanceOf(address(this)) >= _amount, "Invalid Amount");
        _token.transfer(msg.sender, _amount);
    }

    function taxSwap(address from, address to) private {
        uint256 contractTokenBalance = balanceOf(address(this));

        bool shouldSell = contractTokenBalance >= swapLimit;

        if (
            shouldSell &&
            from != routerPair &&
            swapEnabled &&
            !(from == address(this) && to == routerPair)
        ) {
            _approve(address(this), address(uniswapRouter), contractTokenBalance);

            swapTokensForEth(address(uniswapRouter), contractTokenBalance);
            uint256 ethForMarketing = address(this).balance;

            if (ethForMarketing > 0)
                payable(marketingWallet).transfer(ethForMarketing);
        }
    }
        function swapTokensForEth(
        address routerAddress,
        uint256 tokenAmount
    ) internal {
        IUniswapRouter dexRouter = IUniswapRouter(routerAddress);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp + 300
        );
    }
}