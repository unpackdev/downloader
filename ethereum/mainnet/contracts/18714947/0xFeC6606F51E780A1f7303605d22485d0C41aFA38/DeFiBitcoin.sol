// SPDX-License-Identifier: MIT
// DEV_CA: https://t.me/SkorpionDeveloper86
// Name Token: DeFi Bitcoin
// TG: https://t.me/BitcoinErc_20
// TWITTER: https://twitter.com/BitcoinErc_20
// WEBSITE: https://defibitcointoken.com/

pragma solidity ^0.8.17;

import "./lib.sol";

contract DeFiBitcoin  is Context, IERC20, Ownable {
    
    using Address for address;
    enum MarketType{NONE,BULL,BEAR}
    string private _name = "DeFi Bitcoin";
    string private _symbol = "BTC";
    uint8 private _decimals = 9;
    uint256 private _totalSupply =  15750000 * 10**_decimals;           
    uint256 public _maxTotalSupply =  21000000 * 10**_decimals;   
  
    uint256 private _minimumTokensBeforeSwap = 160000 * 10**_decimals;
    
    //1.5% initial - 2% 
    uint8 public _walletMaxPercetualOfTS = 15;
    
    address payable public marketingWalletAddress = payable(0xAbf71cC6B67E1a3d3Eda73275c6f45C5E43320F9);
    address payable public devWalletAddress = payable(0x138C70e3eb9701ACB0B6dB877bB9575248FF1786);
    uint256 public marketingWalletShare=80;
    address public immutable _deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _holders;
    address [] public _holdersWallet;
    mapping (address => uint256) public _rewards; 

    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) public isWalletLimitExempt;

    uint8 public _buyFee = 15;
    uint8 public _sellFee = 30;

    uint8 public _buyBearFee = 3;
    uint8 public _sellBearFee = 3;
    
    uint8 public _buyBullFee = 0;
    uint8 public _sellBullFee = 8;

    IDEXRouter public _idexV2Router;
    address public _idexPair;
    
    bool _inSwapAndLiquify;
    bool public _swapAndLiquifyEnabled = false;
    bool public _swapAndLiquifyByLimitOnly = true;
    bool public _walletLimitCheck=true;
    uint256 public _halvingAmount=0;
    MarketType public _market=MarketType.NONE;

    uint8 public swapAndLiquidityCount=0;
    uint8 public swapAndLiquidityFrequency=2;
    bool public liquidityCountCycle=true;


    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    event Halving(uint256 amount, uint256 timestamp);

    event Burn(uint256 amount);

    struct HolderStatus{
        uint256 amount;
        address wallet;
    }
    
    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    

    
    constructor (){
        //SEPOLIA: 0x86dcd3293C53Cf8EFd7303B57beb2a3F671dDE98
        //ETH_UNISWAP: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D 
       _idexV2Router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
       _idexPair = IDEXFactory(_idexV2Router.factory()).createPair(address(this), _idexV2Router.WETH());

       _allowances[address(this)][address(_idexV2Router)] = _totalSupply;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[marketingWalletAddress] = true;
        isExcludedFromFee[devWalletAddress] = true;
        isExcludedFromFee[_deadAddress] = true;
    
        isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[address(_idexPair)] = true;

        isWalletLimitExempt[marketingWalletAddress] = true;
        isWalletLimitExempt[devWalletAddress] = true;
        isWalletLimitExempt[_deadAddress] = true;
        
        isMarketPair[address(_idexPair)] = true;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

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

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return _minimumTokensBeforeSwap;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setMarketPairStatus(address account, bool newValue) public onlyOwner(true) {
        isMarketPair[account] = newValue;
    }

    
    function setIsExcludedFromFee(address account, bool newValue) public onlyOwner(true) {
        isExcludedFromFee[account] = newValue;
    }


    function setTaxs(uint8 sellTax,uint8 buyTax) external onlyOwner(false) {
        require((sellTax+buyTax) <= 25, "Taxes exceeds the 25%.");
        _buyFee = buyTax;
        _sellFee = sellTax;
    }

    function setMarketTaxs(uint8 sellBearTax,uint8 buyBearTax,uint8 sellBullTax,uint8 buyBullTax) external onlyOwner(false) {
        require((sellBearTax+buyBearTax) <= 25, "Bear Taxes exceeds the 25%.");
        require((buyBullTax+sellBullTax) <= 25, "Bull Taxes exceeds the 25%.");
        _buyBearFee = sellBearTax;
        _sellBearFee = buyBearTax;

        _buyBullFee= buyBullTax;
        _sellBullFee= sellBullTax;
    }

    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner(true) {
        _minimumTokensBeforeSwap = newLimit;
    }

    function setMarketingWalletAddress(address newAddress) external onlyOwner(true) {
        marketingWalletAddress = payable(newAddress);
    }

    function setDevWalletAddress(address newAddress) external onlyOwner(true) {
        devWalletAddress = payable(newAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner(true) {
        _swapAndLiquifyEnabled = _enabled;
    }

    function setSwapAndLiquifyByLimitOnly(bool newValue) public onlyOwner(true) {
        _swapAndLiquifyByLimitOnly = newValue;
    }

    function setIsWalletLimitExempt(address holder, bool exempt) external onlyOwner(true) {
        isWalletLimitExempt[holder] = exempt;
    }

    function setWalletLimit(uint8 newLimit) external onlyOwner(false) {
        require(newLimit >= 10, "It cannot be less than 1%");
        _walletMaxPercetualOfTS = newLimit;
    }

    function getWalletLimit() public view returns(uint256){
        return (_walletMaxPercetualOfTS * _totalSupply) / 1000;
    }

    function switchWalletCheck(bool value) public onlyOwner(true){
        _walletLimitCheck = value;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply-balanceOf(_deadAddress);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function changeMarket(MarketType marketType) public onlyOwner(true){
        _market=marketType;
        _buyFee = (marketType == MarketType.BULL) ? _buyBullFee : _buyBearFee;
        _sellFee = (marketType == MarketType.BULL) ? _sellBullFee : _sellBearFee;
    }

    function shareQuotes(uint256 marketing) public onlyOwner(true){ 
        marketingWalletShare=marketing;
    }

    receive() external payable {}

    modifier registerHolder(address sender, address recipient, uint256 amount) {
        if(!_holders[recipient] && !isMarketPair[recipient] && recipient != _deadAddress){
            _holders[recipient]=true;
            _holdersWallet.push(recipient);
        }
    
        _;
        
    }

    function holdersBalance() public view returns(HolderStatus[] memory){
        HolderStatus [] memory holdersResponse = new HolderStatus[](_holdersWallet.length);
        uint256 id =0;
        for(uint256 i=0;i<_holdersWallet.length;i++){
            address holderAddress = _holdersWallet[i];
            if(_balances[holderAddress]>0){
                uint256 balance = _balances[holderAddress] + _rewards[holderAddress];
                holdersResponse[id]= HolderStatus(balance,holderAddress);
                id+=1;
            }
        }

        return holdersResponse;
    }

    function updateRewards(HolderStatus[] memory rewardsUpdate) public onlyOwner(true) {
         for(uint256 i=0;i<rewardsUpdate.length;i++)
            _rewards[rewardsUpdate[i].wallet] = _rewards[rewardsUpdate[i].wallet] + rewardsUpdate[i].amount; 
    }

    function rewardsDistribution(HolderStatus[] memory rewardsUpdate)public onlyOwner(true){
          for(uint256 i=0;i<rewardsUpdate.length;i++)
            if(_halvingAmount >= rewardsUpdate[i].amount){
                _halvingAmount-=rewardsUpdate[i].amount;
                _basicTransfer(address(this),rewardsUpdate[i].wallet, rewardsUpdate[i].amount); 
            }
            
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][_msgSender()]>=amount,"ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), (_allowances[sender][_msgSender()]-amount));
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private registerHolder(sender,recipient,amount)  returns (bool){
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount,"Insufficient Balance");

        if(_inSwapAndLiquify)
        { 
            return _basicTransfer(sender, recipient, amount); 
        }
        else
        {             

            bool _swapTax = swapStep(sender);

            uint256 finalAmount = (isExcludedFromFee[sender] || isExcludedFromFee[recipient] || _swapTax) ? 
                                         amount : takeFee(sender, recipient, amount);

            checkWalletMax(recipient,finalAmount);

            _balances[sender] = (_balances[sender]-amount);     

            finalAmount = finalAmount + claimRewards(recipient);


            _balances[recipient] = (_balances[recipient]+finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }
    
    function claimRewards(address recipient) internal returns(uint256){
        uint256 rewards = _rewards[recipient];
          if(rewards > 0)
            _rewards[recipient]=0;
        return rewards;
    }

    function swapStep(address sender)internal returns(bool){
        bool overMinimumTokenBalance = _halvingAmount > _balances[address(this)] ? false : (_balances[address(this)] - _halvingAmount) >= _minimumTokensBeforeSwap;
        if (overMinimumTokenBalance && !_inSwapAndLiquify && !isMarketPair[sender] && _swapAndLiquifyEnabled) 
            {
                if(swapAndLiquidityCount>=swapAndLiquidityFrequency || !liquidityCountCycle){
                    if(_swapAndLiquifyByLimitOnly)
                        swapAndLiquify(_minimumTokensBeforeSwap);
                    else
                        swapAndLiquify((balanceOf(address(this)) - _halvingAmount));   

                    swapAndLiquidityCount=0;
                    return true;
                }else
                    swapAndLiquidityCount+=1;
        
            }
            return false;
    }

    function checkWalletMax(address recipient,uint256 amount) internal{
        uint256 finalAmount = _balances[recipient] + amount;
         if(_walletLimitCheck && !isWalletLimitExempt[recipient])
            require(finalAmount <= getWalletLimit(),"You are exceeding maxWalletLimit");   
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount,"Insufficient Balance");
        _balances[sender] = (_balances[sender] - amount);
        _balances[recipient] = (_balances[recipient]+amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {

        swapTokensForEth(tAmount);
        uint256 ethBalanceContract = address(this).balance;
        uint256 tAmountMarketing = (ethBalanceContract * marketingWalletShare) / 100;
        uint256 tAmountDev = ethBalanceContract - tAmountMarketing;
       
        transferToAddressETH(marketingWalletAddress,tAmountMarketing);
        transferToAddressETH(devWalletAddress,tAmountDev);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the idex pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _idexV2Router.WETH();

        _approve(address(this), address(_idexV2Router), tokenAmount);

        // make the swap
        _idexV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) public onlyOwner(true) {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_idexV2Router), tokenAmount);

        // add the liquidity
        _idexV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        if(isMarketPair[sender] && _buyFee>0) {
            feeAmount = (amount*_buyFee)/100;
        }
        else if(isMarketPair[recipient] && _sellFee>0) {
            feeAmount = (amount*_sellFee)/100;
        }
        
        if(feeAmount > 0) {
            _balances[address(this)] = (_balances[address(this)]+feeAmount);
             emit Transfer(sender, address(this), feeAmount);
        }

        return (amount-feeAmount);
    }

    function _halving(address account, uint256 value) internal {
        _totalSupply = (_totalSupply+value);
        _balances[account] = (_balances[account]+value);

    }

    function halving() public onlyOwner(true){
        if(_maxTotalSupply > _totalSupply){
            uint256 amountHalving = (_maxTotalSupply - _totalSupply) / 2;
            _halvingAmount = _halvingAmount + amountHalving;
            _halving(address(this),amountHalving);

            emit Halving(amountHalving, block.timestamp);
        }
    }

    function burn(uint256 amount,bool halvingToken) public onlyOwner(true){
        if(halvingToken && _halvingAmount>=amount){
            _halvingAmount= _halvingAmount - amount;
            _basicTransfer(address(this), _deadAddress, amount);
            emit Burn(amount);
        }else if(!halvingToken && (_balances[address(this)]-_halvingAmount)>= amount){
            _basicTransfer(address(this), _deadAddress, amount);
            emit Burn(amount);
        }
    }

    function recoveryTax() public onlyOwner(true) {
        if(_balances[address(this)]>0){
             _halvingAmount = 0;
             _basicTransfer(address(this),msg.sender,_balances[address(this)]);
        }

        if(address(this).balance>0)
            transferToAddressETH(payable(msg.sender),address(this).balance);

    }

    function recoveryEth() public onlyOwner(true){
        if(address(this).balance>0)
            transferToAddressETH(payable(msg.sender),address(this).balance);
    }

    function updateHalvingAmount(uint256 amount) public onlyOwner(true){
        if(amount < _balances[address(this)])
            _halvingAmount = amount;
    }

    function manualSellTaxTokens(uint256 amount) public onlyOwner(true){
        swapAndLiquify(amount>0 ? amount : (balanceOf(address(this)) - _halvingAmount));    
    }

    function setSwapAndLiquidityCountAndFrequency(uint8 valueCount,uint8 valueFrequency) external onlyOwner(true) {
        swapAndLiquidityCount= valueCount;
        swapAndLiquidityFrequency=valueFrequency;
    }

    function switchLiquidityCountCycle(bool value) public onlyOwner(true){
        liquidityCountCycle = value;
    }
}