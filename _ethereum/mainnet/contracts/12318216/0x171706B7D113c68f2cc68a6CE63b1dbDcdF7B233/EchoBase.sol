// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// Requires openzeppelin contracts 4.0.0, uniswap v2 core and v2 periphery (node modules)
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./VolumeLimiter.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";


contract EchoBase is AccessControl, IERC20, VolumeLimiter {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    // Supply Initialization
    uint256 private constant MAX = ~uint256(0);
    uint256 public _tTotal = 100 * 10**9 * 10**18;
    uint256 public constant _tMin = 10 * 10**9 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 public _tFeeTotal;
    uint256 public _tBurnTotal;
    uint256 public _tDonationTotal;

    string private _name = 'Echo Token';
    string private _symbol = 'ECHO';
    uint8 private _decimals = 18;

    // Reidstribution, burn, and donation percentage initialization

    // // minimum time interval between fee adjustments by community
    uint256 private percentChangeTimespan = 60 * 60 * 24 * 7 * 4 * 3; // 3 months in seconds

    // will be 3% donation ,2% reflect, 1% burn initially
    uint256 public _redistFee = 2;
    uint256 private _redistFeeModCounter = 0;
    uint256 private _redistFeeLastChangeDate = block.timestamp;
    uint256 private _previousRedistFee = _redistFee;
    
    uint256 public _burnFee = 1;
    uint256 private _burnFeeModCounter = 0;
    uint256 private _burnFeeLastChangeDate = block.timestamp;
    uint256 private _previousBurnFee = _burnFee;
    
    uint256 public _donationFee = 3;
    uint256 private _donationFeeModCounter = 0;
    uint256 private _donationFeeLastChangeDate = block.timestamp;
    uint256 private _previousDonationFee = _donationFee;

    bytes32 public constant COMMUNITY_DECISION_ROLE = keccak256("COMMUNITY_DECISION_ROLE");

    // Charity Address (can be any valid address - decided upon by community multisig)
    address payable public charityAddress;
    address payable public constant multisigAddress = payable(0x32cD2c588D61410bAABB55b005f2C0ae520f8Aa5);

    IUniswapV2Router02 public immutable uniswapRouter;
    address public immutable uniswapPool;

    bool public swapEnabled = true;
    bool public limitationCheckEnabled = true;

    // Set the maximum amount that can be exchanged in a single transfer => 1.2B
    uint256 public _maxTxAmount = 12 * 10**8 * 10**18;

    // Set the maximum amount that can be liquidated from the contract in the uniswap pool in a single transfer => 120M
    uint256 public _maxTxLiquidationAmount = _maxTxAmount.div(10);

    // Set the minimum amount of tokens that can be liquidated in the 
    // uniswap pool in a single call to transfer => 12M
    uint256 public _minTokenExchangeBalance = 12 * 10**6 * 10**18;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapEnabledUpdated(bool enabled);

    // ############### REENTRANCY ##################
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status = _NOT_ENTERED;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED); //, "[1]"); // ReentrancyGuard: reentrant call

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    // #############################################

    /**
    @dev Echo Token constructor
    @param launchStartTime - unix timestamp of launch (enable limited trading)
    @param launchVolumeLimitDuration - duration in seconds of limited trading period
    @param _charityAddress - the address of the charity that will be donated to
     */
    constructor (
        uint256 launchStartTime,
        uint256 launchVolumeLimitDuration,
        address payable _charityAddress
    ) VolumeLimiter (
        launchStartTime,
        launchVolumeLimitDuration
    ) {
        _rOwned[_msgSender()] = _rTotal;

        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;

        IUniswapV2Router02 _uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // UniswapV2 for Ethereum network
        // Create a uniswap pair for this new token
        uniswapPool = IUniswapV2Factory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());

        // set the rest of the contract variabless
        uniswapRouter = _uniswapRouter;

        // set the initial charity address
        charityAddress = _charityAddress;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(COMMUNITY_DECISION_ROLE, _msgSender());
        _setupRole(COMMUNITY_DECISION_ROLE, multisigAddress);

        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }
    
    function totalDonation() public view returns (uint256) {
        return _tDonationTotal;
    }

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not admin");
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not admin");
        require(_isExcluded[account], "Account is already excluded");
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
    @dev This function:
    1. Transfers any token balance of this contract to the charity address
    2. Calls a modified version of RFI's _transfer function (_tokenTransfer)
    */
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!hasRole(COMMUNITY_DECISION_ROLE, sender) && !hasRole(COMMUNITY_DECISION_ROLE, recipient))
            require(amount <= _maxTxAmount);

        // Logic for transferring the token contract's balance to the charity address
        uint256 contractTokenBalance = balanceOf(address(this));

        // Price impact consideration if too much internal token accumulation due to a single 
        // large transaction - or due to needing to stop the swap while taking liquidity
        if(contractTokenBalance >= _maxTxLiquidationAmount) {
            contractTokenBalance = _maxTxLiquidationAmount;
        }
        

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap?
        // also, don't get caught in a circular charity (liquidity) event.
        // also, don't swap if sender is uniswap pair.

        bool overMinTokenBalance = contractTokenBalance >= _minTokenExchangeBalance;
        if (_status == _NOT_ENTERED && swapEnabled && overMinTokenBalance && sender != uniswapPool) {
            // We need to swap the current tokens to ETH and send to the charity wallet
            swapTokensForEth(contractTokenBalance);
            
            uint256 contractETHBalance = address(this).balance;
            if(contractETHBalance > 0) {
                sendETHToCharity(address(this).balance);
            }
        }

        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            takeFee = false;
        }
        
        _tokenTransfer(sender,recipient,amount,takeFee);

    }

    // to recieve ETH from uniswapRouter when swapping
    receive() external payable {}

    function swapTokensForEth(uint256 tokenAmount) private nonReentrant {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /**
    @dev Send eth to charity - charity wallet must be an EOA or a contract
    with a payable function to receive ETH --> send all available gas by using call
     */
    function sendETHToCharity(uint256 amount) private {
        // charityAddress.transfer(amount);
        (bool success, ) = charityAddress.call{value: amount}("");
        require(success, 'Tx Failed');
    }

    /**
    @dev Check for trading volume limitations between launch and launch + volume limit duration
     */
    function preValidateTransaction(address sender, address recipient, address _uniswapPool, uint256 amount) internal override {
        super.preValidateTransaction(sender, recipient, _uniswapPool, amount);
    }

    /**
    @dev No need to call preValidateTransaction once the initial trading restrictions are lifted
    if these need to be re-enabled by changing 'launchStartTime' then this should also be set
    back to true
     */
    function setlimitationCheckEnabled(bool enabled) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        limitationCheckEnabled = enabled;
    }

    /**
    @dev RFI's token transfer function - with an addtional takeFee parameter based on if called from
    account exempt from fees. NB: 'excluded' means EXEMPT from being subject to fees
    (useful for administrative adresses in the token ecosystem)
     */
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {

        if(!takeFee)
            removeAllFee();

        if(takeFee && limitationCheckEnabled) {
            preValidateTransaction(sender, recipient, uniswapPool, amount);
        }
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 rBurn, uint256 tFee, uint256 tBurn) private {
        _rTotal = _rTotal.sub(rFee).sub(rBurn);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _tBurnTotal = _tBurnTotal.add(tBurn);
        // With a burnable token, the total supply initialized above cannot be a constant variable
        _tTotal = _tTotal.sub(tBurn);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tBurn, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateRedistFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tBurn).sub(tLiquidity);
        return (tTransferAmount, tFee, tBurn, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn).sub(rLiquidity);
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

    /**
    @dev Add the liquidity (donation fee) from each transaction to the contract's balance itself
    to then be sent to the charity address upon next transfer and emit a transfer event
    */
    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);

        emit Transfer(sender, address(this), tLiquidity);
    }

    function calculateRedistFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_redistFee).div(
            10**2
        );
    }
    
    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(
            10**2
        );
    }
    
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_donationFee).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        if(_redistFee == 0 && _burnFee == 0 && _donationFee == 0) return;
        
        _previousRedistFee = _redistFee;
        _previousBurnFee = _burnFee;
        _previousDonationFee = _donationFee;
        
        _redistFee = 0;
        _burnFee = 0;
        _donationFee = 0;
    }
    
    function restoreAllFee() private {
        _redistFee = _previousRedistFee;
        _burnFee = _previousBurnFee;
        _donationFee = _previousDonationFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function excludeFromFee(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender())); // Caller is not admin
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender())); // Caller is not admin
        _isExcludedFromFee[account] = false;
    }

    /**
    * @dev enable or disable the charity swap (use in case of liqudity issues) - token contact
    * will accumulate balance regardless if donation fee is not set to 0
    * @param enabled - enabled or not
    */
    function setSwapEnabled(bool enabled) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender())); // , "Caller is not admin");
        swapEnabled = enabled;
    }

    /**
    * @dev manually swap contract token balance for eth using router
    */
    function manualSwap() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        uint256 contractTokenBalance = balanceOf(address(this));
        // Price impact consideration if too much internal token accumulation due to a single large transaction
        if(contractTokenBalance >= _maxTxLiquidationAmount) {
            contractTokenBalance = _maxTxLiquidationAmount;
        }
        swapTokensForEth(contractTokenBalance);
    }

    /**
    * @dev manually send contract eth balance to charity address
    */
    function manualSend() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        uint256 contractETHBalance = address(this).balance;
        sendETHToCharity(contractETHBalance);
    }

    /**
    * @dev change the reflection fee percentage - max 5 times
    * @param redistFee - percentage - between 0 and 5, lower than donation fee
    */
    function setRedistFeePercent(uint256 redistFee) external {
        require(hasRole(COMMUNITY_DECISION_ROLE, _msgSender())); // Caller is not decision maker

        uint256 newChangeDate = _redistFeeLastChangeDate.add(percentChangeTimespan);
        require(block.timestamp >= newChangeDate); // Attempting to change value before enough time elapsed
        require(redistFee <= 5 && redistFee >= 0); // percentage outside bounds
        require(redistFee < _donationFee); // Cannot redistribute more than is donated
        require(_redistFeeModCounter <= 5); // can no longer change the percentage

        _redistFeeModCounter += 1;
        _redistFeeLastChangeDate = newChangeDate;
        _redistFee = redistFee;
    }

    /**
    * @dev change the burn fee percentage - max 5 times
    * @param burnFee - percentage - between 0 and 3, lower than donation fee
    */
    function setBurnFeePercent(uint256 burnFee) external {
        require(hasRole(COMMUNITY_DECISION_ROLE, _msgSender())); // Caller is not decision maker

        uint256 newChangeDate = _burnFeeLastChangeDate.add(percentChangeTimespan);
        require(block.timestamp >= newChangeDate); // Attempting to change value before enough time elapsed
        require(burnFee <= 3 && burnFee >= 0); // percentage outside bounds
        require(burnFee < _donationFee); // Cannot burn more than is donated
        require(_burnFeeModCounter <= 5); // can no longer change the percentage

        _burnFeeModCounter += 1;
        _burnFeeLastChangeDate = newChangeDate;
        _burnFee = burnFee;
    }

    /**
    * @dev disable token burn permanently if below minimum token balance
    */
    function stopTokenBurn() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender())); // Caller is not admin
        // If total is below minimum supply - stop token burn forever
        if (this._tTotal() < this._tMin()) {
            _burnFeeModCounter = 6;
            _burnFee = 0;
        }
    }

    /**
    * @dev change the donation fee percentage - max 5 times
    * @param donationFee - percentage - between 0 and 25
    */
    function setDonationFeePercent(uint256 donationFee) external {
        require(hasRole(COMMUNITY_DECISION_ROLE, _msgSender())); // "Caller is not decision maker"

        uint256 newChangeDate = _donationFeeLastChangeDate.add(percentChangeTimespan);
        require(block.timestamp >= newChangeDate); // Attempting to change value before enough time elapsed
        require(donationFee <= 25 && donationFee >= 0);// percentage outside bounds
        require(_donationFeeModCounter <= 5);// can no longer change the percentage

        _donationFeeModCounter += 1;
        _donationFeeLastChangeDate = newChangeDate;
        _donationFee = donationFee;
    }
    /**
    * @dev change the charity wallet address - can be called from multisig
    * @param _charityAddress - the address of the charity wallet
    */
    function changeCharityWalletAddress(address _charityAddress) external {
        require(hasRole(COMMUNITY_DECISION_ROLE, _msgSender()));// Caller is not decision maker
        charityAddress = payable(_charityAddress);
    }

    /**
    * @dev update the minimum amount of tokens that the token contract must have
    * for the uniswap router to swap its balance for eth and send to the
    * charity address
    * @param _newMinTokenBalance - the new min token balance
    */
    function changeMinTokenBalance(uint256 _newMinTokenBalance) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        require(_newMinTokenBalance > 0);
        _minTokenExchangeBalance = _newMinTokenBalance;
    }

    /** 
    * @dev update the maximum amount of tokens that the token contract can swap
    * with the uniswap router in a single transaction
    * @param _newMaxTxAmount - the new min token balance
    */
    function changeMaxTxAmount(uint256 _newMaxTxAmount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        require(_newMaxTxAmount > _minTokenExchangeBalance);
        _maxTxAmount = _newMaxTxAmount;
        _maxTxLiquidationAmount = _newMaxTxAmount.div(10);
    }
    
}