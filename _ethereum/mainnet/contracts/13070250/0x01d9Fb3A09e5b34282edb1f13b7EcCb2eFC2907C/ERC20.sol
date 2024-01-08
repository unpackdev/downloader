// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * ----------------------------------------------------------------------------
 * 
 * Deployed to : 0x217373AB5e0082B2Ce622169672ECa6F4462319C
 * Symbol : PDOG
 * Name : Polkadog
 * Total supply: 100,000,000
 * Decimals : 18
 * 
 * Deployed by Polkadog.io Ecosystem
 * 
 * ----------------------------------------------------------------------------
 */

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract Polkadog_V1_5_ERC20 is Context, IERC20, IERC20Metadata, Ownable, Pausable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private pausedAddress;
    mapping (address => bool) private _isIncludedInFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    address[] public marketing_address;
    address private SUPPLY_HOLDER;
    
    address UNISWAPV2ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "Polkadog-V1.5";
    string private constant _symbol = "PDOG-V1.5";
    uint8 private constant _decimals = 18;
    
    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _lowerTaxFee = _taxFee;

    
    uint256 public _liquidityFee = 2;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 private _lowerLiquidityFee = _liquidityFee;
    
    uint256 public _transactionBurn = 2;
    uint256 private _previousTransactionBurn = _transactionBurn;
    uint256 private _lowerTransactionBurn = _transactionBurn;
    

    uint256 public _marketingFee = 2;
    uint256 private _previousMarketingFee = _marketingFee;
    uint256 private _lowerMarketingFee = _marketingFee;
    

    uint256 public _afterLimitTaxFee = 5;
    uint256 public _afterLimitLiquidityFee = 15;
    uint256 public _afterLimitTransactionBurn = 5;
    uint256 public _afterLimitMarketingFee = 5;

    uint256 private _perDayTimeBound = 86400;
    bool _takeBothTax = false;
    
    mapping (address => uint256) private _totalTransactions; 
    mapping (address => bool) private _taxIncreased;
    mapping (address => uint256) private _transactionTime;
    mapping (address => uint256) private _transactionAmount;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public _enableFee = true;
    
    uint256 private constant numTokensSellToAddToLiquidity = 10000 * 10**18;
    uint256 private constant maxTokensToSell = 8000 * 10**18;
    uint256 public transactionLimit = 50000 * 10**18;
    uint256 public rewardLimit = 1111 * 10**18;
    uint256 public _marketingFeeBalance;
    uint8 public marketing_address_index = 0;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    uint256 private _amount_burnt = 0;

    address public bridge_admin;
    address public migrator_admin;

    struct Amount {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tBurn;
        uint256 tMarketingFee;
        uint256 rAmount;
        uint256 rFee;
        uint256 rTransferAmount;
    }
    
    constructor (address supply_holder, address[] memory marketing_address_) {
        SUPPLY_HOLDER = supply_holder;
        _rOwned[SUPPLY_HOLDER] = _rTotal;
        excludeFromReward(SUPPLY_HOLDER);
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(UNISWAPV2ROUTER);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        emit Transfer(address(0), SUPPLY_HOLDER, _tTotal);

        setMarketingAddress(marketing_address_);
        bridge_admin = msg.sender;
        migrator_admin = msg.sender;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _tTotal - _amount_burnt;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transferToDistributors(address recipient, uint256 amount) external virtual onlyOwner () {
        _beforeTokenTransfer(_msgSender(), recipient, amount);
        
        uint256 senderBalance = balanceOf(_msgSender());
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _tokenTransfer(_msgSender(), recipient, amount, false);
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function updateMigratorAdmin(address newMigrator) external {
        require(msg.sender == migrator_admin, 'only migrator admin');
        require(newMigrator != address(0), "Address cant be zero address");
        migrator_admin = newMigrator;
    }

    function updateBridgeAdmin(address newAdmin) external {
        require(msg.sender == bridge_admin, 'only bridge admin');
        require(newAdmin != address(0), "Address cant be zero address");
        bridge_admin = newAdmin;
    }

    function migrateMint(address to, uint amount) external virtual override returns (bool) {
        require(msg.sender == migrator_admin, 'only migrator admin');
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _tokenTransfer(SUPPLY_HOLDER, to, amount, false);
        return true;
    }

    function bridgeMint(address to, uint amount) external virtual returns (bool) {
        require(msg.sender == bridge_admin, 'only bridge admin');
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _tokenTransfer(SUPPLY_HOLDER, to, amount, false);
        return true;
    }

    function bridgeBurn(address from, uint amount) external virtual returns (bool) {
        require(msg.sender == bridge_admin, 'only bridge admin');
        require(from != address(0), "Address cant be zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_rOwned[from] >= amount, "ERC20: burn amount exceeds balance");

        uint256 rAmount = amount.mul(_getRate());
        _rOwned[from] = _rOwned[from] - rAmount;
        if(_isExcluded[from])
            _tOwned[from] = _tOwned[from].sub(amount);
        _amount_burnt += amount;

        emit Transfer(from, address(0), amount);
    
        return true;
    }
    
    /**
     * @dev Pause `contract` - pause events.
     *
     * See {ERC20Pausable-_pause}.
     */
    function pauseContract() external virtual onlyOwner {
        _pause();
    }
    
    /**
     * @dev Pause `contract` - pause events.
     *
     * See {ERC20Pausable-_pause}.
     */
    function unPauseContract() external virtual onlyOwner {
        _unpause();
    }

    /**
     * @dev Pause `contract` - pause events.
     *
     * See {ERC20Pausable-_pause}.
     */
    function pauseAddress(address account) external virtual onlyOwner {
        excludeFromReward(account);
        pausedAddress[account] = true;
    }
    
    /**
     * @dev Pause `contract` - pause events.
     *
     * See {ERC20Pausable-_pause}.
     */
    function unPauseAddress(address account) external virtual onlyOwner {
        includeInReward(account);
        pausedAddress[account] = false;
    }
    
    /**
     * @dev Returns true if the address is paused, and false otherwise.
     */
    function isAddressPaused(address account) external view virtual returns (bool) {
        return pausedAddress[account];
    }
    
    /**
     * @dev Get current date timestamp.
     */
    function _setDeployDate() internal virtual returns (uint) {
        uint date = block.timestamp;    
        return date;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) internal {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) internal {
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

    
    function excludeFromFee(address account) external onlyOwner {
        _isIncludedInFee[account] = false;
    }
    
    function includeInFee(address account) external onlyOwner {
        _isIncludedInFee[account] = true;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
        _lowerTaxFee = taxFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
        _lowerLiquidityFee = liquidityFee;
    }
    
    function setBurnPercent(uint256 burn_percentage) external onlyOwner() {
        _transactionBurn = burn_percentage;
        _lowerTransactionBurn = burn_percentage;
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner() {
        _marketingFee = marketingFee;
        _lowerMarketingFee = marketingFee;
    }
    
    function setAfterLimitTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _afterLimitTaxFee = taxFee;
    }
    
    function setAfterLimitLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _afterLimitLiquidityFee = liquidityFee;
    }
    
    function setAfterLimitBurnPercent(uint256 burn_percentage) external onlyOwner() {
        _afterLimitTransactionBurn = burn_percentage;
    }

    function setMarketingAddress(address[] memory account) public onlyOwner() {
        require(account.length > 0, "Address cant be empty");
        marketing_address = account;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function enableFee(bool enableTax) external onlyOwner() {
        _enableFee = enableTax;
    }

    function setRewardLimit(uint256 limit) external onlyOwner() {
        rewardLimit = limit;
    }

    function setTxLimitForTax(uint256 limit) external onlyOwner() {
        transactionLimit = limit;
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) internal {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getTValues(uint256 amount, address recipient) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 tAmount = amount;
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tMarketingFee = calculateMarketingFee(tAmount);
        uint256 tBurn = 0;
        if (recipient == uniswapV2Pair) tBurn = calculateTransactionBurn(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tBurn).sub(tMarketingFee);
        return (tTransferAmount, tFee, tLiquidity, tBurn, tMarketingFee);
    }

    function _getRValues(uint256 amount, uint256 tFee, uint256 tLiquidity, uint256 tBurn, uint256 tMarketingFee, address recipient) internal view returns (uint256, uint256, uint256) {
        uint256 currentRate = _getRate();
        uint256 tAmount = amount;
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rMarketingFee = tMarketingFee.mul(currentRate);
        uint256 rBurn = 0;
        if(recipient == uniswapV2Pair) rBurn = tBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rBurn).sub(rMarketingFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() internal view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() internal view returns(uint256, uint256) {
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
    
    function _takeLiquidity(uint256 tLiquidity) internal {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function _takeMarketingFee(uint256 tMarketingFee) internal {
        uint256 currentRate =  _getRate();
        uint256 rMarketingFee = tMarketingFee.mul(currentRate);
        _marketingFeeBalance += tMarketingFee;
        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketingFee);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tMarketingFee);
    }
    
    function calculateTaxFee(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }
    
    function calculateTransactionBurn(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(_transactionBurn).div(
            10**2
        );
    }

    function calculateMarketingFee(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(_marketingFee).div(
            10**2
        );
    }
    
    function removeAllFee() internal {
        if(_taxFee == 0 && _liquidityFee == 0 && _transactionBurn == 0 && _marketingFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousTransactionBurn = _transactionBurn;
        _previousMarketingFee = _marketingFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
        _transactionBurn = 0;
        _marketingFee = 0;
    }
    
    function afterLimitFee() internal {
        _taxFee = _afterLimitTaxFee;
        _liquidityFee = _afterLimitLiquidityFee;
        _transactionBurn = _afterLimitTransactionBurn;
        _marketingFee = _afterLimitMarketingFee;
    }
    

    function restoreAllFee() internal {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _transactionBurn = _previousTransactionBurn;
        _marketingFee = _previousMarketingFee;
    }
    
    function restoreAllLowerFee() internal {
        _taxFee = _lowerTaxFee;
        _liquidityFee = _lowerLiquidityFee;
        _transactionBurn = _lowerTransactionBurn;
        _marketingFee = _lowerMarketingFee;
    }

    function isIncludedInFee(address account) external view returns(bool) {
        return _isIncludedInFee[account];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        
        _beforeTokenTransfer(from, to, amount);
        
        uint256 senderBalance = balanceOf(from);
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        restoreAllLowerFee();

        // Tax over the transaction amount gets decided in this block
        uint256 currentTime = block.timestamp;
        checkTimeBound(from, currentTime);
        if(amount >= transactionLimit && from != uniswapV2Pair){
            _taxIncreased[from] = true;
            afterLimitFee();
        } else{
            uint256 pastAmount = _transactionAmount[from];
            if(pastAmount >= transactionLimit) {
                afterLimitFee();
                _taxIncreased[from] = true;
            } else if((pastAmount + amount) >= transactionLimit) {
                _taxIncreased[from] = true;
                _takeBothTax = true;
            }
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee;
        
        //if any account belongs to _isIncludedInFee account then take fee
        //else remove fee
        if(_enableFee && (_isIncludedInFee[from] || _isIncludedInFee[to])){
            takeFee = true;
            _swapAndLiquify(from);
        } else {
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);

        // Tax parameter updates
        if(from != uniswapV2Pair) {
            _transactionAmount[from] = _transactionAmount[from].add(amount); 
        }
        if(_taxIncreased[from]){
            // restore the previous tax values
            restoreAllLowerFee();
        }
        _taxIncreased[from] = false;
        _takeBothTax = false;
       
        // check reward
        updateReward(from);
        updateReward(to);
    }

    function updateReward(address account) internal {
        if(balanceOf(account) >= rewardLimit) {
            if(_isExcluded[account]) includeInReward(account);
        } else {
            if(!_isExcluded[account]) excludeFromReward(account);
        }
    }

    function checkTimeBound(address from, uint256 currentTime) internal {      
        if((currentTime - _transactionTime[from]) > _perDayTimeBound ){
            _transactionTime[from] = currentTime;
            _transactionAmount[from] = 0;
        }
    }

    function swapAndLiquify(uint256 contractTokenBalance, address account) internal lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half, address(this)); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance, account);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount, address swapAddress) internal {
        bool initialFeeState = _enableFee;
        // remove fee if initialFeeState was true
        if(initialFeeState) _enableFee = false;

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            swapAddress,
            block.timestamp
        );

        // enable fee if initialFeeState was true
        if(initialFeeState) _enableFee = true;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount, address account) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            account,
            block.timestamp
        );
    }

    function transferToFeeWallet(address account, uint256 amount) internal {
        _marketingFeeBalance = 0;
        swapTokensForEth(amount, account);
        if(marketing_address_index == marketing_address.length - 1) {
            marketing_address_index = 0;
        } else {
            marketing_address_index += 1;
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) internal {
        if(!takeFee || (sender != uniswapV2Pair && recipient != uniswapV2Pair))
            removeAllFee();
        
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
    
    function _swapAndLiquify(address from) internal {
        if(_marketingFeeBalance >= maxTokensToSell && from != uniswapV2Pair) {
            transferToFeeWallet(marketing_address[marketing_address_index], _marketingFeeBalance);
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance, owner());
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) internal {

        Amount memory _tAmount;

        if(_takeBothTax) {
            uint256 pastAmount = _transactionAmount[sender];
            uint256 remainingTxLimit = transactionLimit.sub(pastAmount);
            uint256 remainingtAmount = tAmount.sub(remainingTxLimit);

            // take min fee
            address receiver = recipient;
            (_tAmount.tTransferAmount, _tAmount.tFee, _tAmount.tLiquidity, _tAmount.tBurn, _tAmount.tMarketingFee) = _getTValues(remainingTxLimit, receiver);
            (_tAmount.rAmount, _tAmount.rTransferAmount, _tAmount.rFee) = _getRValues(remainingTxLimit, _tAmount.tFee, _tAmount.tLiquidity, _tAmount.tBurn, _tAmount.tMarketingFee, receiver);

            // take high fee
            afterLimitFee();
            address receiv = recipient;
            (uint256 h_tTransferAmount, uint256 h_tFee, uint256 h_tLiquidity, uint256 h_tBurn, uint256 h_tMarketingFee) = _getTValues(remainingtAmount, receiv);
            (uint256 h_rAmount, uint256 h_rTransferAmount, uint256 h_rFee) = _getRValues(remainingtAmount, h_tFee, h_tLiquidity, h_tBurn, h_tMarketingFee, receiv);

            _tAmount.tTransferAmount += h_tTransferAmount;
            _tAmount.tFee += h_tFee;
            _tAmount.tLiquidity += h_tLiquidity;
            _tAmount.tBurn += h_tBurn;
            _tAmount.tMarketingFee += h_tMarketingFee;
            _tAmount.rAmount += h_rAmount;
            _tAmount.rTransferAmount += h_rTransferAmount;
            _tAmount.rFee += h_rFee;
        } else {
            address receiver = recipient;
            (_tAmount.tTransferAmount, _tAmount.tFee, _tAmount.tLiquidity, _tAmount.tBurn, _tAmount.tMarketingFee) = _getTValues(tAmount, receiver);
            (_tAmount.rAmount, _tAmount.rTransferAmount, _tAmount.rFee) = _getRValues(tAmount, _tAmount.tFee, _tAmount.tLiquidity, _tAmount.tBurn, _tAmount.tMarketingFee, receiver);
        }

        _rOwned[sender] = _rOwned[sender].sub(_tAmount.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(_tAmount.rTransferAmount);
        _takeLiquidity(_tAmount.tLiquidity);
        _reflectFee(_tAmount.rFee, _tAmount.tFee);
        _takeMarketingFee(_tAmount.tMarketingFee);
        if(_tAmount.tBurn > 0) {
            _amount_burnt += _tAmount.tBurn;
            emit Transfer(sender, address(0), _tAmount.tBurn);
        }
        emit Transfer(sender, recipient, _tAmount.tTransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) internal {
        Amount memory _tAmount;

        if(_takeBothTax) {
            uint256 pastAmount = _transactionAmount[sender];
            uint256 remainingTxLimit = transactionLimit.sub(pastAmount);
            uint256 remainingtAmount = tAmount.sub(remainingTxLimit);

            // take min fee
            address receiver = recipient;
            (_tAmount.tTransferAmount, _tAmount.tFee, _tAmount.tLiquidity, _tAmount.tBurn, _tAmount.tMarketingFee) = _getTValues(remainingTxLimit, receiver);
            (_tAmount.rAmount, _tAmount.rTransferAmount, _tAmount.rFee) = _getRValues(remainingTxLimit, _tAmount.tFee, _tAmount.tLiquidity, _tAmount.tBurn, _tAmount.tMarketingFee, receiver);

            // take high fee
            afterLimitFee();
            address receiv = recipient;
            (uint256 h_tTransferAmount, uint256 h_tFee, uint256 h_tLiquidity, uint256 h_tBurn, uint256 h_tMarketingFee) = _getTValues(remainingtAmount, receiv);
            (uint256 h_rAmount, uint256 h_rTransferAmount, uint256 h_rFee) = _getRValues(remainingtAmount, h_tFee, h_tLiquidity, h_tBurn, h_tMarketingFee, receiv);

            _tAmount.tTransferAmount += h_tTransferAmount;
            _tAmount.tFee += h_tFee;
            _tAmount.tLiquidity += h_tLiquidity;
            _tAmount.tBurn += h_tBurn;
            _tAmount.tMarketingFee += h_tMarketingFee;
            _tAmount.rAmount += h_rAmount;
            _tAmount.rTransferAmount += h_rTransferAmount;
            _tAmount.rFee += h_rFee;
        } else {
            address receiver = recipient;
            (_tAmount.tTransferAmount, _tAmount.tFee, _tAmount.tLiquidity, _tAmount.tBurn, _tAmount.tMarketingFee) = _getTValues(tAmount, receiver);
            (_tAmount.rAmount, _tAmount.rTransferAmount, _tAmount.rFee) = _getRValues(tAmount, _tAmount.tFee, _tAmount.tLiquidity, _tAmount.tBurn, _tAmount.tMarketingFee, receiver);
        }

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(_tAmount.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(_tAmount.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(_tAmount.rTransferAmount);        
        _takeLiquidity(_tAmount.tLiquidity);
        _reflectFee(_tAmount.rFee, _tAmount.tFee);
        _takeMarketingFee(_tAmount.tMarketingFee);
        if(_tAmount.tBurn > 0) {
            _amount_burnt += _tAmount.tBurn;
            emit Transfer(sender, address(0), _tAmount.tBurn);
        }
        emit Transfer(sender, recipient, _tAmount.tTransferAmount);
    }
    
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) internal {
        Amount memory _tAmount;

        if(_takeBothTax) {
            uint256 pastAmount = _transactionAmount[sender];
            uint256 remainingTxLimit = transactionLimit.sub(pastAmount);
            uint256 remainingtAmount = tAmount.sub(remainingTxLimit);

            // take min fee
            address receiver = recipient;
            (_tAmount.tTransferAmount, _tAmount.tFee, _tAmount.tLiquidity, _tAmount.tBurn, _tAmount.tMarketingFee) = _getTValues(remainingTxLimit, receiver);
            (_tAmount.rAmount, _tAmount.rTransferAmount, _tAmount.rFee) = _getRValues(remainingTxLimit, _tAmount.tFee, _tAmount.tLiquidity, _tAmount.tBurn, _tAmount.tMarketingFee, receiver);

            // take high fee
            afterLimitFee();
            address receiv = recipient;
            (uint256 h_tTransferAmount, uint256 h_tFee, uint256 h_tLiquidity, uint256 h_tBurn, uint256 h_tMarketingFee) = _getTValues(remainingtAmount, receiv);
            (uint256 h_rAmount, uint256 h_rTransferAmount, uint256 h_rFee) = _getRValues(remainingtAmount, h_tFee, h_tLiquidity, h_tBurn, h_tMarketingFee, receiv);

            _tAmount.tTransferAmount += h_tTransferAmount;
            _tAmount.tFee += h_tFee;
            _tAmount.tLiquidity += h_tLiquidity;
            _tAmount.tBurn += h_tBurn;
            _tAmount.tMarketingFee += h_tMarketingFee;
            _tAmount.rAmount += h_rAmount;
            _tAmount.rTransferAmount += h_rTransferAmount;
            _tAmount.rFee += h_rFee;
        } else {
            address receiver = recipient;
            (_tAmount.tTransferAmount, _tAmount.tFee, _tAmount.tLiquidity, _tAmount.tBurn, _tAmount.tMarketingFee) = _getTValues(tAmount, receiver);
            (_tAmount.rAmount, _tAmount.rTransferAmount, _tAmount.rFee) = _getRValues(tAmount, _tAmount.tFee, _tAmount.tLiquidity, _tAmount.tBurn, _tAmount.tMarketingFee, receiver);
        }

        _rOwned[sender] = _rOwned[sender].sub(_tAmount.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(_tAmount.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(_tAmount.rTransferAmount);           
        _takeLiquidity(_tAmount.tLiquidity);
        _reflectFee(_tAmount.rFee, _tAmount.tFee);
        _takeMarketingFee(_tAmount.tMarketingFee);
        if(_tAmount.tBurn > 0) {
            _amount_burnt += _tAmount.tBurn;
            emit Transfer(sender, address(0), _tAmount.tBurn);
        }
        emit Transfer(sender, recipient, _tAmount.tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) internal {
        Amount memory _tAmount;

        if(_takeBothTax) {
            uint256 pastAmount = _transactionAmount[sender];
            uint256 remainingTxLimit = transactionLimit.sub(pastAmount);
            uint256 remainingtAmount = tAmount.sub(remainingTxLimit);

            // take min fee
            address receiver = recipient;
            (_tAmount.tTransferAmount, _tAmount.tFee, _tAmount.tLiquidity, _tAmount.tBurn, _tAmount.tMarketingFee) = _getTValues(remainingTxLimit, receiver);
            (_tAmount.rAmount, _tAmount.rTransferAmount, _tAmount.rFee) = _getRValues(remainingTxLimit, _tAmount.tFee, _tAmount.tLiquidity, _tAmount.tBurn, _tAmount.tMarketingFee, receiver);

            // take high fee
            afterLimitFee();
            address receiv = recipient;
            (uint256 h_tTransferAmount, uint256 h_tFee, uint256 h_tLiquidity, uint256 h_tBurn, uint256 h_tMarketingFee) = _getTValues(remainingtAmount, receiv);
            (uint256 h_rAmount, uint256 h_rTransferAmount, uint256 h_rFee) = _getRValues(remainingtAmount, h_tFee, h_tLiquidity, h_tBurn, h_tMarketingFee, receiv);

            _tAmount.tTransferAmount += h_tTransferAmount;
            _tAmount.tFee += h_tFee;
            _tAmount.tLiquidity += h_tLiquidity;
            _tAmount.tBurn += h_tBurn;
            _tAmount.tMarketingFee += h_tMarketingFee;
            _tAmount.rAmount += h_rAmount;
            _tAmount.rTransferAmount += h_rTransferAmount;
            _tAmount.rFee += h_rFee;
        } else {
            address receiver = recipient;
            (_tAmount.tTransferAmount, _tAmount.tFee, _tAmount.tLiquidity, _tAmount.tBurn, _tAmount.tMarketingFee) = _getTValues(tAmount, receiver);
            (_tAmount.rAmount, _tAmount.rTransferAmount, _tAmount.rFee) = _getRValues(tAmount, _tAmount.tFee, _tAmount.tLiquidity, _tAmount.tBurn, _tAmount.tMarketingFee, receiver);
        }

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(_tAmount.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(_tAmount.rTransferAmount);   
        _takeLiquidity(_tAmount.tLiquidity);
        _reflectFee(_tAmount.rFee, _tAmount.tFee);
        _takeMarketingFee(_tAmount.tMarketingFee);
        if(_tAmount.tBurn > 0) {
            _amount_burnt += _tAmount.tBurn;
            emit Transfer(sender, address(0), _tAmount.tBurn);
        }
        emit Transfer(sender, recipient, _tAmount.tTransferAmount);
    }
    
    
    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        require(from != SUPPLY_HOLDER, "ERC20: transfer from the supply address");
        require(to != SUPPLY_HOLDER, "ERC20: transfer to the supply address");

        require(!paused(), "ERC20Pausable: token transfer while contract paused");
        require(!pausedAddress[from], "ERC20Pausable: token transfer while from-address paused");
        require(!pausedAddress[to], "ERC20Pausable: token transfer while to-address paused");
    }

    function addLiquidityFromPlatform(uint256 tokenAmount) external virtual {
        require(tokenAmount > 0, "Amount must be greater than zero");
        bool initialFeeState = _enableFee;
        // remove fee if initialFeeState was true
        if(initialFeeState) _enableFee = false;

        // transfer to contract address
        _approve(msg.sender, address(this), tokenAmount);
        _transfer(msg.sender, address(this), tokenAmount);

        // add liquidity to uniswap
        swapAndLiquify(tokenAmount, msg.sender);

        // enable fee if initialFeeState was true
        if(initialFeeState) _enableFee = true;
    }

    function removeLiquidityFromPlatform(uint256 liquidity) external virtual {
        require(liquidity > 0, "Amount must be greater than zero");
        bool initialFeeState = _enableFee;
        // remove fee if initialFeeState was true
        if(initialFeeState) _enableFee = false;

        // transferfrom sender to contract address
        bool isTransfered = IUniswapV2Pair(uniswapV2Pair).transferFrom(msg.sender, address(this), liquidity);
        require(isTransfered == true, "UniswapPair: transferFrom failed");

        // approve router address
        bool isApproved = IUniswapV2Pair(uniswapV2Pair).approve(UNISWAPV2ROUTER, liquidity);
        require(isApproved == true, "UniswapPair: approve failed");

        // remove the liquidity
        uniswapV2Router.removeLiquidity(
            address(this),
            uniswapV2Router.WETH(),
            liquidity,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );

        // enable fee if initialFeeState was true
        if(initialFeeState) _enableFee = true;
    }
}