// Ryuki
pragma solidity 0.8.23;
// SPDX-License-Identifier: MIT
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Ryuki is Context, IERC20, Ownable{
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    
    mapping (address => bool) public _isBlackListedBot;
    address[] private _blackListedBots;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    string private constant _name = "Ryuki";
    string private constant _symbol = "RYU";
    uint8 private constant _decimals = 18;
    
    struct AddressFee {
        bool enable;
        uint256 _taxFee;
        uint256 _buyTaxFee;
        uint256 _sellTaxFee;
    }

    // sell data max allowance
    bool private _isSelling = false;
    bool private _isBuying = false;
    ////mapping(address => SellDataHeader) private _sellDataHeader;

    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _buyTaxFee = 2;
    
    uint256 public _sellTaxFee = 2;

	// wallet addresses
	address public marketingWallet = 0xa45bEEf5AA1dB5902b563Fd58f00A4b8f1f74e60;
    address public presaleWallet;
	
	// false = only enabled can trade or owner (add LP)
	// true = all can trade
	bool tradingEnabled = false;

    address public uniswapRouter;
    address public uniswapPair;
    
    // Fee per address
    mapping (address => AddressFee) public addressFees;

    uint256 public _maxTxAmount = 10000000 * 10**18;
    
    uint256 private liquidityActiveBlock = 3; //  Auto Liquidify Snipers

    enum AddressFeeType{ TRANSF, BUY, SELL }
    enum WalletType{ MARKETING, PRESALE, SWAP, PAIR }

    // Events
    
    event ExclusionOfRewardsChanged(address account, bool excluded);
    event ExclusionOfFeesChanged(address account, bool excluded);

    //event TaxFeePercentChanged(uint256 fee);
    //event LiquidityFeePercentChanged(uint256 fee);
    event MaxTxPercentChanged(uint256 percent);
    
    event FeesChanged(uint256 taxFee);
    event BuyFeesChanged(uint256 buyTaxFee);
    event SellFeesChanged(uint256 sellTaxFee);
    
    event AddressFeesChanged(address account, bool enabled, AddressFeeType feeType, uint256 taxFee);

    event taxWalletChanged(address marketing);
    event presaleWalletChanged(address marketing);
    
    event TradingEnabled(bool enabled);

    event UpdateUniswapV2Router( address indexed newAddress, address indexed oldAddress );

    event ExclusionOfCreditsChanged(address account, bool excluded);
    event ExclusionFromCreditsRemovalChanged(address account, bool excluded); 
    event ExclusionToCreditsRemovalChanged(address account, bool excluded); 

    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
        //IUniswapV2Router02 _uniswapV2Router =0x1F98431c8aD98523631AE4a59f267346ea31F984); // mainnet
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // testnet
        // Create a uniswap pair for this new token
        //uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        //    .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapRouter = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        //_isExcludedFromFee[presaleWallet] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[address(this)] = true;
        

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string  memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function isBlacklisted(address account) external view returns (bool) {
        return _isBlackListedBot[account];
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        //require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function setExclusionFromRewards(address account, bool enabled) external onlyOwner(){
        if(enabled){
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            _excluded.push(account);
        }else{
            for (uint256 i = 0; i < _excluded.length; i++) {
                if (_excluded[i] == account) {
                    _excluded[i] = _excluded[_excluded.length - 1];
                    _tOwned[account] = 0;
                    _isExcluded[account] = false;
                    _excluded.pop();
                    break;
                }
            }
        }
        emit ExclusionOfRewardsChanged(account, enabled);
    }
    function setExclusionFromFees(address account, bool enable) external onlyOwner(){
        _isExcludedFromFee[account] = enable;
        emit ExclusionOfFeesChanged(account, enable);
    }
   
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent >  1, "Max transaction percentage has to be higher 1%");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
        
        emit MaxTxPercentChanged(maxTxPercent);
    }

    function removeBlacklist(address account) external onlyOwner() {
        for (uint256 i = 0; i < _blackListedBots.length; i++) {
            if (_blackListedBots[i] == account) {
                _blackListedBots[i] = _blackListedBots[_blackListedBots.length - 1];
                _isBlackListedBot[account] = false;
                _blackListedBots.pop();
                break;
            }
        }

    }

    // if feeType = 0 = Transfer
    // if feeType = 1 = Buy
    // if feeType = 2 = Sell
    function setFees(AddressFeeType feeType, uint256 taxFee) external onlyOwner {
        if(feeType == AddressFeeType.TRANSF){
            require(taxFee<5, "Taxes/fees higher 5 is not allowed");
            _taxFee = taxFee;

            emit FeesChanged(taxFee);
        }else if(feeType == AddressFeeType.BUY){
            require(taxFee<5, "Taxes/fees higher 5 is not allowed");
            _buyTaxFee = taxFee;

            emit BuyFeesChanged(taxFee);
        }else if(feeType == AddressFeeType.SELL){ // if type SELL it uses the sellExtra* Parameters otherwise not
            require(taxFee<5, "Taxes/fees higher 5 is not allowed");
            _sellTaxFee = taxFee;
        
            emit SellFeesChanged(taxFee);
        }
    }
    // if feeType = 0 = Transfer
    // if feeType = 1 = Buy
    // if feeType = 2 = Sell
    function setAddressFee(address _address, bool _enable, AddressFeeType feeType, uint256 _addressTaxFee) external onlyOwner {
        addressFees[_address].enable = _enable;
        if(feeType == AddressFeeType.TRANSF){
            addressFees[_address]._taxFee = _addressTaxFee;
        }else if(feeType == AddressFeeType.BUY){
            addressFees[_address]._buyTaxFee = _addressTaxFee;
        }else if(feeType == AddressFeeType.SELL){
            addressFees[_address]._sellTaxFee = _addressTaxFee;
        }
        
        emit AddressFeesChanged(_address, _enable, feeType, _addressTaxFee);
    }
    
    function setAddress(WalletType walletType, address newAddr) external onlyOwner {
        if(walletType == WalletType.MARKETING){
            _isExcludedFromFee[marketingWallet] = false;
            marketingWallet = newAddr;
            _isExcludedFromFee[newAddr] = false;
            emit taxWalletChanged(newAddr);
        }
        else if(walletType == WalletType.PRESALE){
            _isExcludedFromFee[presaleWallet] = false;
            presaleWallet = newAddr;
            _isExcludedFromFee[newAddr] = true;
            emit presaleWalletChanged(newAddr);
        }
        else if(walletType == WalletType.SWAP){
            uniswapRouter = newAddr;
        }
        else if(walletType == WalletType.PAIR){
            uniswapPair = newAddr;
        }
    }
    
    function enableTrading() external onlyOwner{
        tradingEnabled = true;
        liquidityActiveBlock = block.number; // when trading enabled for bot protection
        
        emit TradingEnabled(true);
    }    
    
     //to allow ETH on contract but should not be the case 
    receive() external payable {}

    function _sendTax(uint256 rFee, uint256 tFee) private{
        
        // no tax no needs
        if(rFee == 0 && tFee == 0)
            return;
        _rOwned[marketingWallet] = _rOwned[marketingWallet].add(rFee);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[marketingWallet].add(tFee);
    }
    
    // reflection ----------------------------------------------------- //
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee) private view returns (uint256, uint256, uint256) {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        if(_taxFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _taxFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
    }
    
    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        //require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0) && owner != address(0), "ERC20: approve from/to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0) && to != address(0) && amount > 0, "ERC20: transfer from/to the zero address && transfer amount must be greater than zero");
        require(( tradingEnabled &&  ( !_isBlackListedBot[from] && !_isBlackListedBot[to] && !_isBlackListedBot[tx.origin] )) || from == presaleWallet || to == presaleWallet || tx.origin == presaleWallet || from == owner() || to == owner() || tx.origin == owner(), "Trading is not enabled or account is blacklisted");
        
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        if (
            tradingEnabled &&
            block.number < liquidityActiveBlock + 3 && // 3 blocks against the snipers/bots
            from == uniswapPair
        ) {
            _isBlackListedBot[to] = true;
        }

        if (!tradingEnabled) {
            require(
                from == owner() || from == address(uniswapRouter) || from == presaleWallet,
                "Trading is not active."
            );
        }
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        _isSelling = false;
        _isBuying = false;
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }else{
            // Buy
            if(from == uniswapPair){
                removeAllFee();
                _isBuying = true;
                _taxFee = _buyTaxFee;
            }
            // Sell
            if(to == uniswapPair){
                removeAllFee();
                _isSelling = true;
                _taxFee = _sellTaxFee;
            }
            
            // If send account has a special fee 
            if(addressFees[from].enable){
                removeAllFee();
                _taxFee = addressFees[from]._taxFee;
                
                // Sell
                if(to == uniswapPair){
                    removeAllFee();
                    _taxFee = addressFees[from]._sellTaxFee;
                }
            }else{
                // If buy account has a special fee
                if(addressFees[to].enable){
                    //buy
                    removeAllFee();
                    if(from == uniswapPair){
                        _taxFee = addressFees[to]._buyTaxFee;
                    }
                }
            }
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _sendTax(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _sendTax(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _sendTax(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _sendTax(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function withdrawETH(uint256 _amount) external onlyOwner {
        (bool sucess,) = address(msg.sender).call{
            value: _amount
        }("");
        
    }
    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }

}