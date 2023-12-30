pragma solidity 0.5.16;


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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

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

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract ERC20Detailed is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor (string memory _name, string memory _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}

interface EarningPoolInterface {
    function deposit(address _beneficiary, uint256 _amount) external;
    function withdraw(address _beneficiary, uint256 _amount) external returns (uint256);
    function dispenseEarning() external returns (uint);
    function dispenseReward() external returns (uint);
    function underlyingToken() external view returns (address);
    function rewardToken() external view returns (address);
    function calcPoolValueInUnderlying() external view returns (uint);
    function calcUndispensedEarningInUnderlying() external view returns(uint256);
    function calcUndispensedProviderReward() external view returns(uint256);
}

interface ManagedRewardPoolInterface {
    function claim(address _account) external;
    function mintShares(address _account, uint256 _amount) external;
    function burnShares(address _account, uint256 _amount) external;
}

/**
 * @title nToken
 * @dev nToken are collateralized assets pegged to a specific value.
 *      Collaterals are EarningPool shares
 */
contract nToken is ERC20, ERC20Detailed, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => address) public underlyingToEarningPoolMap;
    address[] public supportedUnderlyings;

    ManagedRewardPoolInterface public managedRewardPool;

    // mapping between underlying token and its paused state
    // pause is used for mint and swap
    mapping(address => bool) public paused;

    event Minted(address indexed beneficiary, address indexed underlying, uint256 amount, address payer);
    event Redeemed(address indexed beneficiary, address indexed underlying, uint256 amount, address payer);
    event Swapped(address indexed beneficiary, address indexed underlyingFrom, uint256 amountFrom, address indexed underlyingTo, uint256 amountTo, address payer);
    event EarningPoolAdded(address indexed earningPool, address indexed underlying);
    event Pause(address indexed underlying);
    event Unpause(address indexed underlying);

    /**
     * @dev nToken constructor
     * @param _name Name of nToken
     * @param _symbol Symbol of nToken
     * @param _decimals Decimal place of nToken
     * @param _earningPools List of earning pools to supply underlying token to
     */
    constructor (
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address[] memory _earningPools,
        address _managedRewardPool
    )
        ERC20Detailed(_name, _symbol, _decimals)
        public
    {
        require(_managedRewardPool != address(0), "NTOKEN: reward pool address cannot be zero");
        managedRewardPool = ManagedRewardPoolInterface(_managedRewardPool);

        for (uint i=0; i<_earningPools.length; i++) {
            _addEarningPool(_earningPools[i]);
        }
    }

    /**
     * @dev Modifier to make a function callable only when the underlying is not paused.
     */
    modifier whenNotPaused(address _underlying) {
      require(!paused[_underlying], "NTOKEN: underlying is paused");
      _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused(address _underlying) {
      require(paused[_underlying], "NTOKEN: underlying is not paused");
      _;
    }

    /*** PUBLIC ***/

    /**
     * @dev Mint nToken using underlying
     * @param _beneficiary Address of beneficiary
     * @param _underlying Token supplied for minting
     * @param _underlyingAmount Amount of _underlying
     */
    function mint(
        address _beneficiary,
        address _underlying,
        uint _underlyingAmount
    )
        external
        nonReentrant
        whenNotPaused(_underlying)
    {
        _mintInternal(_beneficiary, _underlying, _underlyingAmount);
    }

    /**
     * @dev Redeem nToken to underlying
     * @param _beneficiary Address of beneficiary
     * @param _underlying Token withdrawn for redeeming
     * @param _underlyingAmount Amount of _underlying
     */
    function redeem(
        address _beneficiary,
        address _underlying,
        uint _underlyingAmount
    )
        external
        nonReentrant
    {
        _redeemInternal(_beneficiary, _underlying, _underlyingAmount);
    }

    /**
     * @dev Swap from one underlying to another
     * @param _beneficiary Address of beneficiary
     * @param _underlyingFrom Token to swap from
     * @param _amountFrom Amount of _underlyingFrom
     * @param _underlyingTo Token to swap to
     */
    function swap(
        address _beneficiary,
        address _underlyingFrom,
        uint _amountFrom,
        address _underlyingTo
    )
        external
        nonReentrant
        whenNotPaused(_underlyingFrom)
    {
        require(_amountFrom > 0, "NTOKEN: swap amountFrom must be greater than 0");
        require(isUnderlyingSupported(_underlyingFrom), "NTOKEN: swap underlyingFrom is not supported");
        require(isUnderlyingSupported(_underlyingTo), "NTOKEN: swap underlyingTo is not supported");

        // check if there is sufficient underlyingTo to swap
        // currently there are no exchange rate between underlyings as only stable coins are supported
        EarningPoolInterface underlyingToPool = EarningPoolInterface(underlyingToEarningPoolMap[_underlyingTo]);
        uint amountTo = _scaleTokenAmount(_underlyingFrom, _amountFrom, _underlyingTo);
        require(underlyingToPool.calcPoolValueInUnderlying() >= amountTo, "NTOKEN: insufficient underlyingTo for swap");

        // transfer underlyingFrom from msg.sender and deposit into earnin pool
        EarningPoolInterface underlyingFromPool = EarningPoolInterface(underlyingToEarningPoolMap[_underlyingFrom]);
        IERC20(_underlyingFrom).safeTransferFrom(msg.sender, address(this), _amountFrom);
        underlyingFromPool.deposit(address(this), _amountFrom);

        // withdraw underlyingTo from earning pool to _beneficiary
        uint256 actualAmountTo = underlyingToPool.withdraw(address(this), amountTo);
        IERC20(_underlyingTo).safeTransfer(_beneficiary, actualAmountTo);

        emit Swapped(_beneficiary, _underlyingFrom, _amountFrom, _underlyingTo, actualAmountTo, msg.sender);
    }

    /*** VIEW ***/

    /**
     * @dev Check if an underlying is supported
     * @param _underlying Address of underlying token
     */
    function isUnderlyingSupported(address _underlying) public view returns (bool) {
        return underlyingToEarningPoolMap[_underlying] != address(0);
    }

    /**
     * @dev Get corresponding earning pool address of underlying
     * @param _underlying Address of underlying token
     */
    function getUnderlyingEarningPool(address _underlying) public view returns (address) {
        return underlyingToEarningPoolMap[_underlying];
    }

    /**
     * @dev Get all supported underlyings
     * @return address[] List of address of supported underlying token
     */
    function getAllSupportedUnderlyings() public view returns (address[] memory) {
        return supportedUnderlyings;
    }

    /*** ADMIN ***/

    /**
     * @dev Add earning pool to nToken
     * @param _earningPool Address of earning pool
     */
    function addEarningPool(address _earningPool)
        external
        onlyOwner
    {
        _addEarningPool(_earningPool);
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause(address _underlying)
        public
        onlyOwner
        whenNotPaused(_underlying)
    {
        paused[_underlying] = true;
        emit Pause(_underlying);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause(address _underlying)
        public
        onlyOwner
        whenPaused(_underlying)
    {
        paused[_underlying] = false;
        emit Unpause(_underlying);
    }

    /**
     * @dev Set the name of token
     * @param _name Name of token
     */
    function setName(string calldata _name)
        external
        onlyOwner
    {
        name = _name;
    }

    /**
     * @dev Set the symbol of token
     * @param _symbol Symbol of token
     */
    function setSymbol(string calldata _symbol)
        external
        onlyOwner
    {
        symbol = _symbol;
    }

    /*** INTERNAL ***/

    function _mintInternal(address _beneficiary, address _underlying, uint _underlyingAmount) internal {
        require(_underlyingAmount > 0, "NTOKEN: mint must be greater than 0");
        require(isUnderlyingSupported(_underlying), "NTOKEN: mint underlying is not supported");

        // transfer underlying from msg.sender into nToken and deposit into earning pool
        EarningPoolInterface pool = EarningPoolInterface(underlyingToEarningPoolMap[_underlying]);
        IERC20(_underlying).safeTransferFrom(msg.sender, address(this), _underlyingAmount);
        pool.deposit(address(this), _underlyingAmount);

        // mint nToken for _beneficiary
        uint nTokenAmount = _scaleTokenAmount(_underlying, _underlyingAmount, address(this));
        _mint(_beneficiary, nTokenAmount);

        // mint shares in managedRewardPool for _beneficiary
        managedRewardPool.mintShares(_beneficiary, nTokenAmount);

        emit Minted(_beneficiary, _underlying, _underlyingAmount, msg.sender);
    }

    function _redeemInternal(address _beneficiary, address _underlying, uint _underlyingAmount) internal {
        require(_underlyingAmount > 0, "NTOKEN: redeem must be greater than 0");
        require(isUnderlyingSupported(_underlying), "NTOKEN: redeem underlying is not supported");

        // burn msg.sender nToken
        uint nTokenAmount = _scaleTokenAmount(_underlying, _underlyingAmount, address(this));
        _burn(msg.sender, nTokenAmount);

        // burn msg.sender shares from managedRewardPool
        managedRewardPool.burnShares(msg.sender, nTokenAmount);

        // withdraw underlying from earning pool and transfer to _beneficiary
        EarningPoolInterface pool = EarningPoolInterface(underlyingToEarningPoolMap[_underlying]);
        uint256 actualWithdrawnAmount = pool.withdraw(address(this), _underlyingAmount);
        IERC20(_underlying).safeTransfer(_beneficiary, actualWithdrawnAmount);

        emit Redeemed(_beneficiary, _underlying, actualWithdrawnAmount, msg.sender);
    }

    /**
     * @dev Approve underlyings to earning pool
     * @param _underlying Address of underlying token
     * @param _pool Address of earning pool
     */
    function _approveUnderlyingToEarningPool(address _underlying, address _pool) internal {
        IERC20(_underlying).safeApprove(_pool, uint(-1));
    }

    /**
     * @dev Scale token amount from one decimal precision to another
     * @param _from Address of token to convert from
     * @param _fromAmount Amount of _from token
     * @param _to Address of token to convert to
     */
    function _scaleTokenAmount(address _from, uint _fromAmount, address _to) internal view returns (uint) {
        uint fromTokenDecimalPlace = uint(ERC20Detailed(_from).decimals());
        uint toTokenDecimalPlace = uint(ERC20Detailed(_to).decimals());
        uint toTokenAmount;
        uint scaleFactor;
        if (fromTokenDecimalPlace > toTokenDecimalPlace) {
            scaleFactor = fromTokenDecimalPlace.sub(toTokenDecimalPlace);
            toTokenAmount = _fromAmount.div(uint(10**scaleFactor)); // expect precision loss
        } else if (toTokenDecimalPlace > fromTokenDecimalPlace) {
            scaleFactor = toTokenDecimalPlace.sub(fromTokenDecimalPlace);
            toTokenAmount = _fromAmount.mul(uint(10**(scaleFactor)));
        } else {
            toTokenAmount = _fromAmount;
        }
        return toTokenAmount;
    }

    /**
     * @dev Add earning pool to nToken
     * @param _earningPool Address of earning pool
     */
    function _addEarningPool(address _earningPool)
        internal
    {
        EarningPoolInterface pool = EarningPoolInterface(_earningPool);

        underlyingToEarningPoolMap[pool.underlyingToken()] = _earningPool;
        supportedUnderlyings.push(pool.underlyingToken());
        _approveUnderlyingToEarningPool(pool.underlyingToken(), _earningPool);

        emit EarningPoolAdded(_earningPool, pool.underlyingToken());
    }

    /**
     * @dev Overrides parent ERC20 _transfer function to update reward for sender and recipient
     * @param _sender Sender of transfer
     * @param _recipient Address to recieve transfer
     * @param _amount Amount to transfer
     * @return bool Is transfer successful
     */
    function _transfer(address _sender, address _recipient, uint256 _amount)
        internal
    {
        managedRewardPool.burnShares(_sender, _amount);
        managedRewardPool.mintShares(_recipient, _amount);
        super._transfer(_sender, _recipient, _amount);
    }
}

/**
 * @title nUSD
 * @dev nToken pegged to USD
 */
contract nUSD is nToken {
    constructor (
        address[] memory _initialEarningPools,
        address _rewardPool
    )
        nToken (
            "Bretton USD",
            "nUSD",
            18,
            _initialEarningPools,
            _rewardPool
        )
        public
    {
    }
}