/**

Website: https://fumblers.co
Twitter:  https://twitter.com/fumblers_club
Fumblers:  https://t.me/fumblers_club

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

contract FUMBLE is Context, IERC20, Ownable {

    string private constant _name = "Fumblers Club";
    string private constant _symbol = "FUMBLE";

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    address[] private _excluded;
    
    bool public tradingEnabled;
    bool public swapEnabled;
    bool private swapping;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) public _isExcludedFromMaxTx;

    modifier activeTrading(address account){
        require(tradingEnabled || _isExcludedFromMaxTx[account], "Trading not enabled yet");
        _;
    }

    IRouter public router;
    address public pair;

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = 1e30;

    uint256 private constant _tTotal = 1_000_000_000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 public swapTokensAtAmount = _tTotal * 1 / 10000;
    uint256 public buyLimitAmount = _tTotal * 25 / 1000;
    uint256 public sellLimitAmount = _tTotal * 25 / 1000;
    uint256 public walletLimitAmount = _tTotal * 25 / 1000;

    uint256 public genesis_block;
    Taxes public taxes = Taxes(0, 1, 0, 0);
    Taxes public sellTaxes = Taxes(0, 1, 0, 0);

    struct Taxes {
        uint256 rfi;
        uint256 marketing;
        uint256 liquidity; 
        uint256 donation;
    }

    struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 marketing;
        uint256 liquidity; 
        uint256 donation;
    }

    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues{
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rRfi;
        uint256 rMarketing;
        uint256 rLiquidity;
        uint256 rDonation;
        uint256 tTransferAmount;
        uint256 tRfi;
        uint256 tMarketing;
        uint256 tLiquidity;
        uint256 tDonation;
    }

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    address public marketingWallet = 0x9200096c4CB53406406d8f96cDb12B42C767E2ad;
    address public donationWallet = 0xb7Af26bf70A986007aF616cfa39C9164b0B59759;

    constructor () {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        router = _router;

        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[donationWallet] = true;
        
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[marketingWallet] = true;
        _isExcludedFromMaxTx[donationWallet] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    //std ERC20:
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    //override ERC20:
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public  override activeTrading(msg.sender) returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override activeTrading(sender) returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public  activeTrading(msg.sender) returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public  activeTrading(msg.sender) returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) public override activeTrading(msg.sender) returns (bool)
    { 
      _transfer(msg.sender, recipient, amount);
      return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, true, false, false);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true, false, false);
            return s.rTransferAmount;
        }
    }

    function launch() external onlyOwner{
        tradingEnabled = true;
        swapEnabled = true;
        genesis_block = block.number;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -=rRfi;
        totFeesPaid.rfi +=tRfi;
    }

    function addLiquidity() external payable onlyOwner {
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
        _isExcluded[pair] = true;
        _excluded.push(pair);
        _isExcludedFromMaxTx[pair] = true;
        _approve(address(this), address(router), type(uint256).max);
        router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            0, 
            0, 
            owner(),
            block.timestamp
        );
    }

    function _takeLiquidity(uint256 rLiquidity, uint256 tLiquidity) private {
        totFeesPaid.liquidity +=tLiquidity;

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tLiquidity;
        }
        _rOwned[address(this)] +=rLiquidity;
    }

    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private {
        totFeesPaid.marketing +=tMarketing;

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tMarketing;
        }
        _rOwned[address(this)] +=rMarketing;
    }
    
    function _takeDonation(uint256 rDonation, uint256 tDonation) private {
        totFeesPaid.donation +=tDonation;

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tDonation;
        }
        _rOwned[address(this)] +=rDonation;
    }
    
    function _getValues(uint256 tAmount, bool takeFee, bool isSell, bool isTransfer) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee, isSell);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi, to_return.rMarketing, to_return.rLiquidity) = _getRValues1(to_return, tAmount, takeFee, _getRate(), isSell && isTransfer);
        (to_return.rDonation) = _getRValues2(to_return, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee, bool isSell) private view returns (valuesFromGetValues memory s) {

        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }
        Taxes memory temp;
        if(isSell) temp = sellTaxes;
        else temp = taxes;
        
        s.tRfi = tAmount*temp.rfi/100;
        s.tMarketing = tAmount*temp.marketing/100;
        s.tLiquidity = tAmount*temp.liquidity/100;
        s.tDonation = tAmount*temp.donation/100;
        s.tTransferAmount = tAmount-s.tRfi-s.tMarketing-s.tLiquidity-s.tDonation;
        return s;
    }

    function _getRValues1(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate, bool isSell) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi,uint256 rMarketing, uint256 rLiquidity){
        rAmount = tAmount*currentRate;

        if(!takeFee) {
          return(isSell?0:rAmount, rAmount, 0,0,0);
        }

        rRfi = s.tRfi*currentRate;
        rMarketing = s.tMarketing*currentRate;
        rLiquidity = s.tLiquidity*currentRate;
        uint256 rDonation = s.tDonation*currentRate;
        rTransferAmount =  rAmount-rRfi-rMarketing-rLiquidity-rDonation;
        return (rAmount, rTransferAmount, rRfi,rMarketing,rLiquidity);
    }
    
    function _getRValues2(valuesFromGetValues memory s, bool takeFee, uint256 currentRate) private pure returns (uint256 rDonation) {

        if(!takeFee) {
          return(0);
        }

        rDonation = s.tDonation*currentRate;
        return (rDonation);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-_rOwned[_excluded[i]];
            tSupply = tSupply-_tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            require(tradingEnabled, "Trading not active");
        }
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && block.number <= genesis_block) {
            require(to != pair, "Sells not allowed for dead blocks");
        }
        
        if(from == pair && !_isExcludedFromFee[to] && !swapping){
            require(amount <= buyLimitAmount, "You are exceeding buyLimitAmount");
            require(balanceOf(to) + amount <= walletLimitAmount, "You are exceeding walletLimitAmount");
        }
        
        if(from != pair && !_isExcludedFromFee[to] && !_isExcludedFromFee[from] && !swapping){
            require(amount <= sellLimitAmount, "You are exceeding sellLimitAmount");
            if(to != pair){
                require(balanceOf(to) + amount <= walletLimitAmount, "You are exceeding walletLimitAmount");
            }
        }
       
        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount && amount >= swapTokensAtAmount;
        if(!swapping && swapEnabled && canSwap && to == pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            swapAndLiquify(swapTokensAtAmount, sellTaxes);
        }
        bool takeFee = true;
        bool isSell = false;
        if(swapping || _isExcludedFromFee[from] || _isExcludedFromFee[to]) takeFee = false;
        if(to == pair) isSell = true;

        _tokenTransfer(from, to, amount, takeFee, isSell);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee, bool isSell) private {

        valuesFromGetValues memory s = _getValues(tAmount, takeFee, isSell, sender == donationWallet);

        if (_isExcluded[sender] ) {  //from excluded
                _tOwned[sender] = _tOwned[sender]-tAmount;
        }
        if (_isExcluded[recipient]) { //to excluded
                _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
        
        if(s.rRfi > 0 || s.tRfi > 0) _reflectRfi(s.rRfi, s.tRfi);
        if(s.rLiquidity > 0 || s.tLiquidity > 0) {
            _takeLiquidity(s.rLiquidity,s.tLiquidity);
            emit Transfer(sender, address(this), s.tLiquidity + s.tMarketing + s.tDonation);
        }
        if(s.rMarketing > 0 || s.tMarketing > 0) _takeMarketing(s.rMarketing, s.tMarketing);
        if(s.rDonation > 0 || s.tDonation > 0) _takeDonation(s.rDonation, s.tDonation);
        emit Transfer(sender, recipient, s.tTransferAmount);
        
    }

    function swapAndLiquify(uint256 contractBalance, Taxes memory temp) private lockTheSwap {
        uint256 denominator = (temp.liquidity + temp.marketing + temp.donation) * 2;
        uint256 tokensToAddLiquidityWith = contractBalance * temp.liquidity / denominator;
        uint256 toSwap = contractBalance - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance= deltaBalance / (denominator - temp.liquidity);
        uint256 ethToAddLiquidityWith = unitBalance * temp.liquidity;

        if(ethToAddLiquidityWith > 0){
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
        }

        payable(marketingWallet).transfer(address(this).balance);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    receive() external payable{}

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function removeLimits() external onlyOwner {
        buyLimitAmount = _tTotal;
        sellLimitAmount = _tTotal;
        walletLimitAmount = _tTotal;
    }
    
    //Use this in case ETH are sent to the contract by mistake
    function rescueETH(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "insufficient ETH balance");
        payable(msg.sender).transfer(weiAmount);
    }

    function rescueAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }
}