/*
https://www.gnomescollective.xyz/

https://t.me/HungerGameserc20

https://twitter.com/HungerGamesERC
*/
// SPDX-License-Identifier: MIT

//██╗░░██╗██╗░░░██╗███╗░░██╗░██████╗░███████╗██████╗░
//██║░░██║██║░░░██║████╗░██║██╔════╝░██╔════╝██╔══██╗
//███████║██║░░░██║██╔██╗██║██║░░██╗░█████╗░░██████╔╝
//██╔══██║██║░░░██║██║╚████║██║░░╚██╗██╔══╝░░██╔══██╗
//██║░░██║╚██████╔╝██║░╚███║╚██████╔╝███████╗██║░░██║
//╚═╝░░╚═╝░╚═════╝░╚═╝░░╚══╝░╚═════╝░╚══════╝╚═╝░░╚═╝

//░██████╗░░█████╗░███╗░░░███╗███████╗░██████╗
//██╔════╝░██╔══██╗████╗░████║██╔════╝██╔════╝
//██║░░██╗░███████║██╔████╔██║█████╗░░╚█████╗░
//██║░░╚██╗██╔══██║██║╚██╔╝██║██╔══╝░░░╚═══██╗
//╚██████╔╝██║░░██║██║░╚═╝░██║███████╗██████╔╝
//░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░


pragma solidity 0.8.21;

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
    event Burn(address indexed account, uint256 amount);
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

    constructor () {
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
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract HungerGames is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    mapping (uint256 => bool)    public NFTXTRABalance;
    mapping (uint256 => bool)    public NFTVBalance;
    mapping (uint256 => bool)    public NFTBOOSTBalance;
    mapping (uint256 => bool)    public NFTSKIPBalance;

    mapping (address => uint256) private _holderLastTransferTimestamp;
    mapping (address => uint256) public hgmsShopBalances;
    mapping (address => uint256) public ethShopBalances;
    mapping (address => uint256) public XTRAShopBalances;
    mapping (address => uint256) public BOOSTShopBalances;
    mapping (address => uint256) public VShopBalances;
    mapping (address => uint256) public SKIPShopBalances;
    mapping (uint256 => uint256) public potionsUsed;

    address payable public _maintenanceWallet;
    address payable public _teamWallet;
    address payable public _devWallet;
    address payable public _marketWallet;
    uint256 private _initialBuyTax=19;
    uint256 private _initialSellTax=25;
    uint256 private _finalBuyTax=5;
    uint256 private _finalSellTax=5;
    uint256 private _reduceBuyTaxAt=19;
    uint256 private _reduceSellTaxAt=25;
    uint256 private _preventSwapBefore=25;
    uint256 private _buyCount=0;

    uint8 private constant _decimals = 9;
    string private constant _name = unicode"HungerGames";
    string private constant _symbol = unicode"HGMS";
    uint256 private _tTotal = 1000000000 * 10**_decimals;
    uint256 public _maxTxAmount = 10000000 * 10**_decimals;
    uint256 public _maxWalletSize = 20000000 * 10**_decimals;
    uint256 public _taxSwapThreshold= 1000000 * 10**_decimals;
    uint256 public _maxTaxSwap= 10000000 * 10**_decimals;

    uint256 public totalXTRA;
    uint256 public totalBOOST;
    uint256 public totalV;
    uint256 public totalSKIP;

    uint256 public XTRAPriceHGMS=25000;
    uint256 public BOOSTPriceHGMS=25000;
    uint256 public VPriceHGMS=25000;
    uint256 public SKIPPriceHGMS=25000;

    uint256 public XTRAPriceETH = 20* 10**(_decimals - 3);
    uint256 public BOOSTPriceETH= 0;
    uint256 public VPriceETH = 9* 10**(_decimals - 3);
    uint256 public SKIPPriceETH= 12* 10**(_decimals - 3);

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool public transferDelayEnabled = true;
    bool private inLiquidityAddition = false;

    event PotionsRemoved();
    event PotionPurchased(address indexed buyer, address indexed shopOwner, string potionName, uint256 ethAmount, uint256 hgmsAmount);
    event Deposit();
    event MaxTxAmountUpdated(uint _maxTxAmount);
    event PayoutWinnersExecuted(address[] indexed winners, uint256 share, uint256 nonDeads);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _devWallet = payable(_msgSender());
        _marketWallet = payable(address(0xE63129686F9AE07bf4a733C41a424cB54444aBc8));
        _teamWallet = payable(address(0xEe31A88b55Dc7f69DD3D9f5E0b77bd5cABD8a41F));
        _maintenanceWallet = payable(address(0xBeBDD8b641965E7618A39B1B2C5b1a64625Aa84c));

        _balances[address(this)] = (_tTotal);
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketWallet] = true;
        _isExcludedFromFee[_teamWallet] = true;
        _isExcludedFromFee[_maintenanceWallet] = true;

        emit Transfer(address(0), address(this),  _balances[address(this)]);
    }
    function setXTRAPrice(uint256 hgmsAmount, uint256 ethAmount) public{
        require(msg.sender == _maintenanceWallet);
        XTRAPriceHGMS = hgmsAmount;
        XTRAPriceETH = ethAmount* 10**(_decimals - 3);
    }
    function setBOOSTPrice(uint256 hgmsAmount, uint256 ethAmount) public{
        require(msg.sender == _maintenanceWallet);
        BOOSTPriceHGMS = hgmsAmount;
        BOOSTPriceETH = ethAmount* 10**(_decimals - 3);
    }
    function setVPrice(uint256 hgmsAmount, uint256 ethAmount) public{
        require(msg.sender == _maintenanceWallet);
        VPriceHGMS = hgmsAmount;
        VPriceETH = ethAmount* 10**(_decimals - 3);
    }
    function setSKIPPrice(uint256 hgmsAmount, uint256 ethAmount) public{
        require(msg.sender == _maintenanceWallet);
        SKIPPriceHGMS = hgmsAmount;
        SKIPPriceETH = ethAmount* 10**(_decimals - 3);
    }
    function emergencyTaxAt() public {
        require(msg.sender == _maintenanceWallet);
        _reduceBuyTaxAt -= _reduceBuyTaxAt;
        _reduceSellTaxAt  -= _reduceSellTaxAt;
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
    function getNFTXTRABalance(uint NFTId) external view returns(bool){
        return NFTXTRABalance[NFTId];
    }
    function getNFTBOOSTBalance(uint NFTId) external view returns(bool){
        return NFTBOOSTBalance[NFTId];
    }
    function getNFTVBalance(uint NFTId) external view returns(bool){
        return NFTVBalance[NFTId];
    }
    function getNFTSKIPBalance(uint NFTId) external view returns(bool){
        return NFTSKIPBalance[NFTId];
    }
    function totalSupply() public view override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 taxAmount=0;
        if(!inLiquidityAddition){
            require(tradingOpen, "Trading not open yet");
        }
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);

            if (transferDelayEnabled) {
                  if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                      require(
                          _holderLastTransferTimestamp[tx.origin] <
                              block.number,
                          "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                      );
                      _holderLastTransferTimestamp[tx.origin] = block.number;
                  }
              }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to   == uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwapThreshold && _buyCount>_preventSwapBefore) {
                uint256 contractETHBalance = address(this).balance;
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                uint256 deltaETH = address(this).balance.sub(contractETHBalance);
                if(deltaETH > 0) {
                    sendETHToFee(deltaETH);
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this), taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }
    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
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
    function _removeLimits() internal onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_tTotal);
    }
    function removeLimits() external onlyOwner {
        _removeLimits();
    }
    function sendETHToFee(uint256 amount) private {
        require(amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= amount, "Insufficient contract balance");

        uint256 feePerWallet = amount/5;

        _marketWallet.transfer(feePerWallet);
        _teamWallet.transfer(feePerWallet);
        _maintenanceWallet.transfer(feePerWallet);
    }
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        tradingOpen = true;
    }
    function addLiquidity() external onlyOwner() {
        inLiquidityAddition = true;
        if (address(uniswapV2Router) == address(0)) {
            uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        }
        if (uniswapV2Pair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        }
        uint256 tokenAmount = balanceOf(address(this));
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            tokenAmount,
            _tTotal,  
            0,  
            owner(),
            block.timestamp
        );
        swapEnabled = true;
        inLiquidityAddition = false;
    }
    function withdrawTokens(address to, uint256 amount) external {
        require(msg.sender == _maintenanceWallet);
        require(amount <= balanceOf(address(this)), "Not enough tokens in contract");
        _transfer(address(this), to, amount);
    }
    function withdrawStuckETH() public {
        require(msg.sender == _maintenanceWallet);
        _devWallet.transfer(address(this).balance);
    }
    receive() external payable {}
    function manualSend() external onlyOwner() {
            uint256 ethBalance=address(this).balance;
            if(ethBalance>0){
                sendETHToFee(ethBalance);
            }
    }
    function ManualSwap() external {
        require(_msgSender()== _devWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }
    function depositToShop(uint256 hgmsAmount, uint256 ethAmount) payable external {
        require(hgmsAmount > 0 || ethAmount > 0, "Amount should be greater than 0");
        require(msg.value >= ethAmount * 10**_decimals, "Incorrect ETH amount sent");
       
        if (hgmsAmount > 0) {
        require(_balances[msg.sender] >= hgmsAmount, "Not enough HGMS tokens");
        _burn(msg.sender, hgmsAmount);  
        hgmsShopBalances[msg.sender] += hgmsAmount; 
        }

        if (ethAmount > 0) {
            ethShopBalances[msg.sender] += ethAmount;  
            sendETHToFee(msg.value);  
        }

        emit Deposit();
    }
    function buyPotion(string[] memory potionNames, uint256[] memory amounts, address shopOwner, uint256 bonusLength) external {
        require(msg.sender == _maintenanceWallet, "Only maintenanceWallet can call this function");
        require(potionNames.length == amounts.length, "Mismatched potionNames and amounts arrays length");

        uint256 loopEnd = potionNames.length;

        totalXTRA = 0;
        totalBOOST = 0;
        totalV = 0;
        totalSKIP = 0;
        loopEnd -= bonusLength; 
        
        for(uint i = 0; i < loopEnd; i++) {
            processPotionCounts(potionNames[i], amounts[i]);
        }

        for(uint i = loopEnd; i < potionNames.length; i++) {
            processOrderWithoutCharges(potionNames[i], amounts[i], shopOwner);
        }

        if(totalXTRA > 0) processOrder("XTRA", totalXTRA, shopOwner);
        if(totalBOOST > 0) processOrder("BOOST", totalBOOST, shopOwner);
        if(totalV > 0) processOrder("V", totalV, shopOwner);
        if(totalSKIP > 0) processOrder("SKIP", totalSKIP, shopOwner);
    }
    function processPotionCounts(
        string memory potionName,
        uint256 amount
        ) internal {
            if(keccak256(abi.encodePacked(potionName)) == keccak256(abi.encodePacked("XTRA"))){
                totalXTRA += amount;
            }
            else if(keccak256(abi.encodePacked(potionName)) == keccak256(abi.encodePacked("BOOST"))){
                totalBOOST += amount;
            }
            else if(keccak256(abi.encodePacked(potionName)) == keccak256(abi.encodePacked("V"))){
                totalV += amount;
            }
            else if(keccak256(abi.encodePacked(potionName)) == keccak256(abi.encodePacked("SKIP"))){
                totalSKIP += amount;
            }
    }
    function processOrderWithoutCharges(string memory potionName, uint256 amount, address shopOwner) internal {
        if(keccak256(abi.encodePacked(potionName)) == keccak256(abi.encodePacked("XTRA"))){
            XTRAShopBalances[shopOwner] += amount;
        } 
        else if(keccak256(abi.encodePacked(potionName)) == keccak256(abi.encodePacked("BOOST"))){
            BOOSTShopBalances[shopOwner] += amount;
        }
        else if(keccak256(abi.encodePacked(potionName)) == keccak256(abi.encodePacked("V"))){
            VShopBalances[shopOwner] += amount;
        } 
        else if(keccak256(abi.encodePacked(potionName)) == keccak256(abi.encodePacked("SKIP"))){
            SKIPShopBalances[shopOwner] += amount;
        } 
        else {
            revert("Invalid Potion Name");
        }
        emit PotionPurchased(msg.sender, shopOwner, potionName, 0, 0);
    }
    function processOrder(string memory potionName, uint256 amount, address shopOwner) internal {
        if(amount == 0) return;
   
        uint256 hgmsAmount;
        uint256 ethAmount;

            if(keccak256(abi.encodePacked(potionName)) == keccak256(abi.encodePacked("XTRA"))){

            hgmsAmount = XTRAPriceHGMS.mul(amount); 
            ethAmount = XTRAPriceETH.mul(amount); 

            require(hgmsShopBalances[shopOwner] >= hgmsAmount, "Balance does not have enough HGMS");
            require(ethShopBalances[shopOwner] >= ethAmount, "Balance does not have enough ETH");

            hgmsShopBalances[shopOwner] -= hgmsAmount;
            ethShopBalances[shopOwner] -= ethAmount;
            XTRAShopBalances[shopOwner] += amount;

            emit PotionPurchased(msg.sender, shopOwner, potionName, ethAmount, hgmsAmount);
            } else if(keccak256(abi.encodePacked(potionName)) == keccak256(abi.encodePacked("BOOST"))){

            hgmsAmount = BOOSTPriceHGMS.mul(amount); 
            ethAmount = BOOSTPriceETH.mul(amount); 

            require(hgmsShopBalances[shopOwner] >= hgmsAmount, "Balance does not have enough HGMS");
            require(ethShopBalances[shopOwner] >= ethAmount, "Balance does not have enough ETH");

            hgmsShopBalances[shopOwner] -= hgmsAmount;
            ethShopBalances[shopOwner] -= ethAmount;
            BOOSTShopBalances[shopOwner] += amount;

            emit PotionPurchased(msg.sender, shopOwner, potionName, ethAmount, hgmsAmount);
            } else if(keccak256(abi.encodePacked(potionName)) == keccak256(abi.encodePacked("V"))){

            hgmsAmount = VPriceHGMS.mul(amount); 
            ethAmount = VPriceETH.mul(amount); 

            require(hgmsShopBalances[shopOwner] >= hgmsAmount, "Balance does not have enough HGMS");
            require(ethShopBalances[shopOwner] >= ethAmount, "Balance does not have enough ETH");

            hgmsShopBalances[shopOwner] -= hgmsAmount;
            ethShopBalances[shopOwner] -= ethAmount;
            VShopBalances[shopOwner] += amount;

            emit PotionPurchased(msg.sender, shopOwner, potionName, ethAmount, hgmsAmount);
            }else if(keccak256(abi.encodePacked(potionName)) == keccak256(abi.encodePacked("SKIP"))){

            hgmsAmount = SKIPPriceHGMS.mul(amount); 
            ethAmount = SKIPPriceETH.mul(amount); 

            require(hgmsShopBalances[shopOwner] >= hgmsAmount, "Balance does not have enough HGMS");
            require(ethShopBalances[shopOwner] >= ethAmount, "Balance does not have enough ETH");

            hgmsShopBalances[shopOwner] -= hgmsAmount;
            ethShopBalances[shopOwner] -= ethAmount;
            SKIPShopBalances[shopOwner] += amount;

            emit PotionPurchased(msg.sender, shopOwner, potionName, ethAmount, hgmsAmount);
            } else {
                revert("Invalid Potion Name");
            }
    }
    function applyPotion(address shopOwner, uint256[] memory NFTId, string memory potionName) external{
        require(msg.sender == _maintenanceWallet);
        if(keccak256(abi.encodePacked(potionName)) == keccak256(abi.encodePacked("XTRA"))){
            require(XTRAShopBalances[shopOwner] >= NFTId.length, "Balance does not have enough Potions");
            for(uint256 i=0; i<NFTId.length;i++){
                require(!NFTXTRABalance[NFTId[i]], "Already active XTRA");
                 NFTXTRABalance[NFTId[i]] = true;
                 XTRAShopBalances[shopOwner] -= 1;
                 potionsUsed[NFTId[i]] += 1;
             }
        } else if(keccak256(abi.encodePacked(potionName)) == keccak256(abi.encodePacked("BOOST"))){
            require(BOOSTShopBalances[shopOwner] >= NFTId.length, "Balance does not have enough Potions");
            for(uint256 i=0; i<NFTId.length;i++){
                require(!NFTBOOSTBalance[NFTId[i]], "Already active BOOST");
                 NFTBOOSTBalance[NFTId[i]] = true;
                 BOOSTShopBalances[shopOwner] -= 1;
                 potionsUsed[NFTId[i]] += 1;
             }
        } else if(keccak256(abi.encodePacked(potionName)) == keccak256(abi.encodePacked("V"))){
            require(VShopBalances[shopOwner] >= NFTId.length, "Balance does not have enough Potions");
            for(uint256 i=0; i<NFTId.length;i++){
                require(!NFTVBalance[NFTId[i]], "Already active V");
                 NFTVBalance[NFTId[i]] = true;
                 VShopBalances[shopOwner] -= 1;
                 potionsUsed[NFTId[i]] += 1;
             }
        } else if(keccak256(abi.encodePacked(potionName)) == keccak256(abi.encodePacked("SKIP"))){
            require(SKIPShopBalances[shopOwner] >= NFTId.length, "Balance does not have enough Potions");
            for(uint256 i=0; i<NFTId.length;i++){
                require(!NFTSKIPBalance[NFTId[i]], "Already active SKIP");
                 NFTSKIPBalance[NFTId[i]] = true;
                 SKIPShopBalances[shopOwner] -= 1;
                 potionsUsed[NFTId[i]] += 1;
             }
        } else {
            revert("Wrong Potion Name");
        }

    }
    function removePotions(uint256 mintAmount) external {
        require(msg.sender == _maintenanceWallet, "Not authorized");
        for (uint256 i = 1; i <= mintAmount; i++) {
        NFTXTRABalance[i] = false;
        NFTVBalance[i] = false;
        NFTBOOSTBalance[i] = false;
        NFTSKIPBalance[i] = false;
        }
        emit PotionsRemoved();
    }

    function payoutWinners(address[] memory winners, uint256 share, uint256 nonDeads) external {
        require(msg.sender == _maintenanceWallet, "Not authorized");
        for (uint256 i = 0; i < nonDeads; i++) {
            payable(winners[winners.length - i - 1]).transfer(share);
        }
        emit PayoutWinnersExecuted(winners, share, nonDeads);
    }


    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Cannot burn from the zero address");
        amount = amount * 10**_decimals;
        _balances[account] -= amount;
        _tTotal -= amount;
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;

        emit Burn(account, amount);
        emit Transfer(account, address(0), amount);
        emit MaxTxAmountUpdated(_tTotal);
    }
}