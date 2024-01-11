// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Context.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./Arrays.sol";
import "./Counters.sol";
import "./ERC20.sol";
import "./IWETH.sol";
import "./IPYESwapFactory.sol";
import "./IPYESwapPair.sol";
import "./IPYESwapRouter.sol";
import "./BEP20.sol";


contract APPLE is Context, Ownable, AccessControl, ERC20 {
    using SafeMath for uint256;
    using Address for address;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    // staked struct	
    struct Staked {	
        uint256 amount;	
    }	
    address[] holders;	
    mapping (address => uint256) holderIndexes;	
    uint256 public totalStaked;

    // Fees
    // Add and remove fee types and destinations here as needed
    struct Fees {
        uint256 developmentFee;
        uint256 buybackFee;
        uint256 burnFee;
        address developmentAddress;
    }

    // Transaction fee values
    // Add and remove fee value types here as needed
    struct FeeValues {
        uint256 transferAmount;
        uint256 development;
        uint256 buyback;
        uint256 burn;
    }

    // Token details
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => Staked) public staked;

    // blacklist and staking contract mappings	
    mapping (address => bool) isBlacklisted; 	
    mapping (address => bool) isStakingContract; 


    // Set total supply here
    uint256 private _tTotal;

    // auto set buyback to false. additional buyback params. blockPeriod acts as a time delay in the shouldAutoBuyback(). Last uint represents last block for buyback occurance.
    struct Settings {
        bool autoBuybackEnabled;
        uint256 autoBuybackCap;
        uint256 autoBuybackAccumulator;
        uint256 autoBuybackAmount;
        uint256 autoBuybackBlockPeriod;
        uint256 autoBuybackBlockLast;
        uint256 minimumBuyBackThreshold;
    }

    // Users states
    mapping (address => bool) private _isExcludedFromFee;

    // Outside Swap Pairs
    mapping (address => bool) private _includeSwapFee;


    // Pair Details
    mapping (uint256 => address) private pairs;
    mapping (uint256 => address) private tokens;
    uint256 private pairsLength;
    mapping (address => bool) public _isPairAddress;


    // Set the name, symbol, and decimals here
    string constant _name = "ApplePYE";
    string constant _symbol = "APPLEPYE";
    uint8 constant _decimals = 18;

    Fees public _defaultFees;
    Fees public _defaultSellFees;
    Fees private _previousFees;
    Fees private _emptyFees;
    Fees private _sellFees;
    Fees private _outsideBuyFees;
    Fees private _outsideSellFees;

    Settings public _buyback;

    IPYESwapRouter public pyeSwapRouter;
    address public pyeSwapPair;
    address public WETH;
    address public constant _burnAddress = 0x000000000000000000000000000000000000dEaD;

    bool public swapEnabled = true;
    bool inSwap;

    modifier swapping() { inSwap = true; _; inSwap = false; }
    modifier onlyExchange() {
        bool isPair = false;
        for(uint i = 0; i < pairsLength; i++) {
            if(pairs[i] == msg.sender) isPair = true;
        }
        require(
            msg.sender == address(pyeSwapRouter)
            || isPair
            , "PYE: NOT_ALLOWED"
        );
        _;
    }

    /// @dev A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    // Edit the constructor in order to declare default fees on deployment
    constructor (address _router, address _development, uint256 _developmentFee, uint256 _buybackFee, uint256 _burnFee) ERC20("","") {
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _setupRole(FEE_SETTER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        pyeSwapRouter = IPYESwapRouter(_router);
        WETH = pyeSwapRouter.WETH();
        pyeSwapPair = IPYESwapFactory(pyeSwapRouter.factory())
        .createPair(address(this), WETH, true);

        tokens[pairsLength] = WETH;
        pairs[pairsLength] = pyeSwapPair;
        pairsLength += 1;
        _isPairAddress[pyeSwapPair] = true;

        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[pyeSwapPair] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_burnAddress] = true;

        // This should match the struct Fee
        _defaultFees = Fees(
            _developmentFee,
            _buybackFee,
            0,
            _development
        );

        _defaultSellFees = Fees(
            _developmentFee,
            _buybackFee,
            _burnFee,
            _development
        );

        _sellFees = Fees(
            0,
            0,
            _burnFee,
            _development
        );

        _outsideBuyFees = Fees(
            _developmentFee.add(_buybackFee),
            0,
            0,
            _development
        );

        _outsideSellFees = Fees(
            _developmentFee.add(_buybackFee),
            0,
            _burnFee,
            _development
        );

        IPYESwapPair(pyeSwapPair).updateTotalFee(400);
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function excludeFromFee(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        _isExcludedFromFee[account] = false;
    }

    function addOutsideSwapPair(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        _includeSwapFee[account] = true;
    }

    function removeOutsideSwapPair(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        _includeSwapFee[account] = false;
    }

    function _updatePairsFee() internal {
        for (uint j = 0; j < pairsLength; j++) {
            IPYESwapPair(pairs[j]).updateTotalFee(getTotalFee());
        }
    }


    // Functions to update fees and addresses 

    function setBuybackPercent(uint256 _buybackFee) external {
        require(hasRole(FEE_SETTER_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        require(_defaultSellFees.developmentFee.add(_defaultSellFees.burnFee).add(_buybackFee) <= 2500, "Fees exceed max limit.");
        _defaultFees.buybackFee = _buybackFee;
        _defaultSellFees.buybackFee = _buybackFee;
        _outsideBuyFees.developmentFee = _outsideBuyFees.developmentFee.add(_buybackFee);
        _outsideSellFees.developmentFee = _outsideSellFees.developmentFee.add(_buybackFee);
        _updatePairsFee();
    }

    function setDevelopmentPercent(uint256 _developmentFee) external {
        require(hasRole(FEE_SETTER_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        require(_defaultSellFees.buybackFee.add(_defaultSellFees.burnFee).add(_developmentFee) <= 2500, "Fees exceed max limit.");
        _defaultFees.developmentFee = _developmentFee;
        _defaultSellFees.developmentFee = _developmentFee;
        _outsideBuyFees.developmentFee = _outsideBuyFees.buybackFee.add(_developmentFee);
        _outsideSellFees.developmentFee = _outsideSellFees.buybackFee.add(_developmentFee);
        _updatePairsFee();
    }

    function setdevelopmentAddress(address _development) external {
        require(hasRole(FEE_SETTER_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        require(_development != address(0), "PYE: Address Zero is not allowed");
        _defaultFees.developmentAddress = _development;
        _defaultSellFees.developmentAddress = _development;
        _outsideBuyFees.developmentAddress = _development;
        _outsideSellFees.developmentAddress = _development;
    }

    function setSellBurnFee(uint256 _burnFee) external {
        require(hasRole(FEE_SETTER_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        require(_defaultSellFees.buybackFee.add(_defaultSellFees.developmentFee).add(_burnFee) <= 2500, "Fees exceed max limit.");
        _sellFees.burnFee = _burnFee;
        _defaultSellFees.burnFee = _burnFee;
        _outsideSellFees.burnFee = _burnFee;
    }



    function updateRouterAndPair(address _router, address _pair) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        _isExcludedFromFee[pyeSwapPair] = false;
        pyeSwapRouter = IPYESwapRouter(_router);
        pyeSwapPair = _pair;
        WETH = pyeSwapRouter.WETH();

        _isPairAddress[pyeSwapPair] = true;
        _isExcludedFromFee[pyeSwapPair] = true;

        pairs[0] = pyeSwapPair;
        tokens[0] = WETH;

        IPYESwapPair(pyeSwapPair).updateTotalFee(getTotalFee());
    }

    //to receive ETH from pyeRouter when swapping
    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (FeeValues memory) {
        FeeValues memory values = FeeValues(
            0,
            calculateFee(tAmount, _defaultFees.developmentFee),
            calculateFee(tAmount, _defaultFees.buybackFee),
            calculateFee(tAmount, _defaultFees.burnFee)
        );

        values.transferAmount = tAmount.sub(values.development).sub(values.buyback).sub(values.burn);
        return values;
    }

    function calculateFee(uint256 _amount, uint256 _fee) private pure returns (uint256) {
        if(_fee == 0) return 0;
        return _amount.mul(_fee).div(
            10**4
        );
    }

    function removeAllFee() private {
        _previousFees = _defaultFees;
        _defaultFees = _emptyFees;
    }

    function setSellFee() private {
        _previousFees = _defaultFees;
        _defaultFees = _sellFees;
    }

    function setOutsideBuyFee() private {
        _previousFees = _defaultFees;
        _defaultFees = _outsideBuyFees;
    }

    function setOutsideSellFee() private {
        _previousFees = _defaultFees;
        _defaultFees = _outsideSellFees;
    }

    function restoreAllFee() private {
        _defaultFees = _previousFees;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function getBalance(address keeper) public view returns (uint256){
        return _balances[keeper];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBlacklisted[to]);
        _beforeTokenTransfer(from, to, amount);

        if(shouldAutoBuyback(amount)){ triggerAutoBuyback(); }

        if(isStakingContract[to]) { 	
            uint256 newAmountAdd = staked[from].amount.add(amount);	
            setStaked(from, newAmountAdd);	
        }	
        if(isStakingContract[from]) {	
            uint256 newAmountSub = staked[to].amount.sub(amount);	
            setStaked(to, newAmountSub);	
        }

        //indicates if fee should be deducted from transfer of tokens
        uint8 takeFee = 0;
        if(_isPairAddress[to] && from != address(pyeSwapRouter) && !isExcludedFromFee(from)) {
            takeFee = 1;
        } else if(_includeSwapFee[from]) {
            takeFee = 2;
        } else if(_includeSwapFee[to]) {
            takeFee = 3;
        }

        //transfer amount, it will take tax
        _tokenTransfer(from, to, amount, takeFee);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _tTotal.sub(balanceOf(_burnAddress)).sub(balanceOf(address(0)));
    }

    function getTotalFee() public view returns (uint256) {
        return _defaultFees.developmentFee
            .add(_defaultFees.buybackFee)
            .add(_defaultFees.burnFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, uint8 takeFee) private {
        if(takeFee == 0) {
            removeAllFee();
        } else if(takeFee == 1) {
            setSellFee();
        } else if(takeFee == 2) {
            setOutsideBuyFee();
        } else if(takeFee == 3) {
            setOutsideSellFee();
        }

        FeeValues memory _values = _getValues(amount);
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(_values.transferAmount);
        _takeFees(_values);

        emit Transfer(sender, recipient, _values.transferAmount);

        if(delegates[sender] == address(0)) {
            delegates[sender] = sender;
        }

        if(delegates[recipient] == address(0)) {
            delegates[recipient] = recipient;
        }

        if(amount == _values.transferAmount) {	
            _moveDelegates(delegates[sender], delegates[recipient], amount);	
        } else {	
            _moveDelegates(delegates[sender], delegates[recipient], _values.transferAmount);	
            _moveDelegates(delegates[sender], delegates[_defaultFees.developmentAddress], _values.development);	
            _moveDelegates(delegates[sender], address(0), _values.burn);	
        }

        if(takeFee == 0 || takeFee == 1) {
            restoreAllFee();
        } else if(takeFee == 2 || takeFee == 3) {
            restoreAllFee();
            emit Transfer(sender, _defaultFees.developmentAddress, _values.development);
        }
    }

    function _takeFees(FeeValues memory values) private {
        _takeFee(values.development, _defaultFees.developmentAddress);
        _takeBurnFee(values.burn);
    }

    function _takeFee(uint256 tAmount, address recipient) private {
        if(recipient == address(0)) return;
        if(tAmount == 0) return;

        _balances[recipient] = _balances[recipient].add(tAmount);
    }

    function _takeBurnFee(uint256 amount) private {
        if(amount == 0) return;

        _balances[address(this)] = _balances[address(this)].add(amount);
        _burn(address(this), amount);
    }

    // This function transfers the fees to the correct addresses. 
    function depositLPFee(uint256 amount, address token) public onlyExchange {
        uint256 tokenIndex = _getTokenIndex(token);
        if(tokenIndex < pairsLength) {
            uint256 allowanceT = IERC20(token).allowance(msg.sender, address(this));
            if(allowanceT >= amount) {
                IERC20(token).transferFrom(msg.sender, address(this), amount);

                if(token != WETH) {
                    uint256 balanceBefore = IERC20(address(WETH)).balanceOf(address(this));
                    swapToWETH(amount, token);
                    uint256 fAmount = IERC20(address(WETH)).balanceOf(address(this)).sub(balanceBefore);
                    
                    // All fees to be declared here in order to be calculated and sent
                    uint256 totalFee = getTotalFee();
                    uint256 developmentFeeAmount = fAmount.mul(_defaultFees.developmentFee).div(totalFee);

                    IERC20(WETH).transfer(_defaultFees.developmentAddress, developmentFeeAmount);
                } else {
                    // All fees to be declared here in order to be calculated and sent
                    uint256 totalFee = getTotalFee();
                    uint256 developmentFeeAmount = amount.mul(_defaultFees.developmentFee).div(totalFee);

                    IERC20(token).transfer(_defaultFees.developmentAddress, developmentFeeAmount);
                }
            }
        }
    }

    function swapToWETH(uint256 amount, address token) internal {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WETH;

        IERC20(token).approve(address(pyeSwapRouter), amount);
        pyeSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    // runs check to see if autobuyback should trigger
    function shouldAutoBuyback(uint256 amount) internal view returns (bool) {
        return msg.sender != pyeSwapPair
        && !inSwap
        && _buyback.autoBuybackEnabled
        && _buyback.autoBuybackBlockLast + _buyback.autoBuybackBlockPeriod <= block.number // After N blocks from last buyback
        && IERC20(address(WETH)).balanceOf(address(this)) >= _buyback.autoBuybackAmount
        && amount >= _buyback.minimumBuyBackThreshold;
    }

    // triggers auto buyback
    function triggerAutoBuyback() internal {
        buyTokens(_buyback.autoBuybackAmount, _burnAddress);
        _buyback.autoBuybackBlockLast = block.number;
        _buyback.autoBuybackAccumulator = _buyback.autoBuybackAccumulator.add(_buyback.autoBuybackAmount);
        if(_buyback.autoBuybackAccumulator > _buyback.autoBuybackCap){ _buyback.autoBuybackEnabled = false; }
    }

    // logic to purchase moonforce tokens
    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        IERC20(WETH).approve(address(pyeSwapRouter), amount);
        pyeSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    // manually adjust the buyback settings to suit your needs
    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period, uint256 _minimumThreshold) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        _buyback.autoBuybackEnabled = _enabled;
        _buyback.autoBuybackCap = _cap;
        _buyback.autoBuybackAccumulator = 0;
        _buyback.autoBuybackAmount = _amount;
        _buyback.autoBuybackBlockPeriod = _period;
        _buyback.autoBuybackBlockLast = block.number;
        _buyback.minimumBuyBackThreshold = _minimumThreshold;
    }

    function _getTokenIndex(address _token) internal view returns (uint256) {
        uint256 index = pairsLength + 1;
        for(uint256 i = 0; i < pairsLength; i++) {
            if(tokens[i] == _token) index = i;
        }

        return index;
    }

    function addPair(address _pair, address _token) public {
        address factory = pyeSwapRouter.factory();
        require(
            msg.sender == factory
            || msg.sender == address(pyeSwapRouter)
            || msg.sender == address(this)
        , "PYE: NOT_ALLOWED"
        );

        if(!_checkPairRegistered(_pair)) {
            _isExcludedFromFee[_pair] = true;
            _isPairAddress[_pair] = true;

            pairs[pairsLength] = _pair;
            tokens[pairsLength] = _token;

            pairsLength += 1;

            IPYESwapPair(_pair).updateTotalFee(getTotalFee());
        }
    }

    function _checkPairRegistered(address _pair) internal view returns (bool) {
        bool isPair = false;
        for(uint i = 0; i < pairsLength; i++) {
            if(pairs[i] == _pair) isPair = true;
        }

        return isPair;
    }

    // Rescue eth that is sent here by mistake
    function rescueETH(uint256 amount, address to) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        payable(to).transfer(amount);
      }

    // Rescue tokens that are sent here by mistake
    function rescueToken(IERC20 token, uint256 amount, address to) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        if( token.balanceOf(address(this)) < amount ) {
            amount = token.balanceOf(address(this));
        }
        token.transfer(to, amount);
    }

    /**	
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.	
     *	
     * Does not update the allowance amount in case of infinite allowance.	
     * Revert if not enough allowance is available.	
     *	
     * Might emit an {Approval} event.	
     */	
    function _spendAllowance(	
        address owner,	
        address spender,	
        uint256 amount	
    ) internal override virtual {	
        uint256 currentAllowance = allowance(owner, spender);	
        if (currentAllowance != type(uint256).max) {	
            require(currentAllowance >= amount, "ERC20: insufficient allowance");	
            unchecked {	
                _approve(owner, spender, currentAllowance - amount);	
            }	
        }	
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) override internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _tTotal = _tTotal.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) override internal {	
        require(account != address(0), 'BEP20: burn from the zero address');	
        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');	
        _tTotal = _tTotal.sub(amount);	
        emit Transfer(account, address(0), amount);	
    }

    
    function burnFrom(address _from, uint256 _amount) public {	
        require(hasRole(BURNER_ROLE, msg.sender), "APPLE: NOT_ALLOWED");	
        _spendAllowance(_from, msg.sender, _amount);
        _beforeTokenTransfer(_from, address(0), _amount);		
        _burn(_from, _amount);	
        if(delegates[_from] == address(0)) {	
            delegates[_from] = _from;	
        }	
        _moveDelegates(delegates[_from], address(0), _amount);	
    }	


    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        _beforeTokenTransfer(address(0), _to, _amount);
        _mint(_to, _amount);
        
        if(delegates[_to] == address(0)) {
            delegates[_to] = _to;
        }
        _moveDelegates(address(0), delegates[_to], _amount);
    }

    function burn(uint256 _amount) public {
        require(hasRole(BURNER_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        _beforeTokenTransfer(msg.sender, address(0), _amount);
        _burn(msg.sender, _amount);

        if(delegates[msg.sender] == address(0)) {
            delegates[msg.sender] = msg.sender;
        }
        _moveDelegates(delegates[msg.sender], address(0), _amount);
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "APPLE::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "APPLE::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "APPLE::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
    external
    view
    returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
    external
    view
    returns (uint256)
    {
        require(blockNumber < block.number, "APPLE::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
    internal
    {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying APPLE (not scaled);
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
    internal
    {
        uint32 blockNumber = safe32(block.number, "APPLE::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    //-------------------- BEGIN STAKED FXNS ------------------------------	
    function getOwnedBalance(address account) external view returns (uint256){	
        return staked[account].amount.add(_balances[account]);	
    }	
    function setStaked(address holder, uint256 amount) internal  {	
        if(amount > 0 && staked[holder].amount == 0){	
            addHolder(holder);	
        }else if(amount == 0 && staked[holder].amount > 0){	
            removeHolder(holder);	
        }	
        totalStaked = totalStaked.sub(staked[holder].amount).add(amount);	
        staked[holder].amount = amount;	
    }	
    function addHolder(address holder) internal {	
        holderIndexes[holder] = holders.length;	
        holders.push(holder);	
    }	
    function removeHolder(address holder) internal {	
        holders[holderIndexes[holder]] = holders[holders.length-1];	
        holderIndexes[holders[holders.length-1]] = holderIndexes[holder];	
        holders.pop();	
    }	
    // set an address as a staking contract	
    function setIsStakingContract(address account, bool set) external {	
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "FUEL: NOT_ALLOWED");	
        isStakingContract[account] = set;	
    }	
    //--------------------------------------BEGIN BLACKLIST FUNCTIONS---------|	
    // enter an address to blacklist it. This blocks transfers TO that address. Balcklisted members can still sell.	
    function blacklistAddress(address addressToBlacklist) external {	
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "FUEL: NOT_ALLOWED");	
        require(!isBlacklisted[addressToBlacklist] , "Address is already blacklisted!");	
        isBlacklisted[addressToBlacklist] = true;	
    }	
    // enter a currently blacklisted address to un-blacklist it.	
    function removeFromBlacklist(address addressToRemove) external {	
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "FUEL: NOT_ALLOWED");	
        require(isBlacklisted[addressToRemove] , "Address has not been blacklisted! Enter an address that is on the blacklist.");	
        isBlacklisted[addressToRemove] = false;	
    }

    // -------------------------------------BEGIN MODIFIED SNAPSHOT FUNCTIONS--------------------|

    //@ dev a direct, modified implementation of ERC20 snapshot designed to track totalOwnedBalance (the sum of balanceOf(acct) and staked.amount of that acct), as opposed
    // to just balanceOf(acct). totalSupply is tracked normally via _tTotal in the totalSupply() function.

    using Arrays for uint256[];
    using Counters for Counters.Counter;
    Counters.Counter private _currentSnapshotId;

    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;
    event Snapshot(uint256 id);

    // owner can manually call a snapshot.
    function snapshot() public onlyOwner {
        _snapshot();
    }

    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    function getCurrentSnapshotID() public view onlyOwner returns (uint256) {
        return _getCurrentSnapshotId();
    }

    // modified to also read users staked balance. 
    function totalBalanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : (balanceOf(account).add(staked[account].amount));
    }

    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    // modified to also add staked[acct].amount
    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], (balanceOf(account).add(staked[account].amount)));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

}
