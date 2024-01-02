// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IERC20
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
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
}

contract Ownable
{
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipRenounced();

    constructor()
    {
        address msgSender = _msgSender();
        owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function _msgSender() internal view virtual returns (address payable)
    {
        return payable(msg.sender);
    }

    function isOwner(address who) public view returns (bool)
    {
        return owner == who;
    }

    modifier onlyOwner()
    {
        require(isOwner(_msgSender()), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address _newOwner) external virtual onlyOwner
    {
        require(_newOwner != owner, "Ownable: new owner is already the owner");
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }

    function remounceOwnership() external virtual onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        emit OwnershipRenounced();
    }

    function getTime() public view returns (uint256)
    {
        return block.timestamp;
    }
}

contract Allowable is Ownable
{
    uint256 private allowedCount;

    mapping(uint256 => address) private allowedByID;
    mapping(address => bool) private allowedContract;
    mapping(address => uint256) private allowedindex;

    constructor() payable {}

    // Use this to prevent those not on the list from accessing controlled functions on the token contract
    modifier onlyAllowedContract()
    {
        _onlyAllowedContract();
        _;
    }

    function _onlyAllowedContract() internal view
    {
        require(isOwner(_msgSender()) || allowedContract[_msgSender()], "caller is not an allowed contract or the owner");
    }

    function GetAllowedID(address _wallet) view external returns(uint256 allowedID)
    {
        return allowedindex[_wallet];
    }

    function SetupAllowedContract(address _contractAddress, bool _allowOrNot) external onlyAllowedContract
    {
        allowedContract[_contractAddress] = _allowOrNot;

        if(allowedindex[_contractAddress] != 0) return;

        allowedCount++;
        allowedByID[allowedCount] = _contractAddress;
        allowedindex[_contractAddress] = allowedCount;
    }

    function SetupAllowedContracts(address [] calldata _contractAddresses, bool _allowOrNot) external onlyAllowedContract
    {
        uint256 count = _contractAddresses.length;

        for(uint256 i = 0; i < count; i++)
        {
          address _contractAddress = _contractAddresses[i];

          allowedContract[_contractAddress] = _allowOrNot;

          if(allowedindex[_contractAddress] == 0)
          {
            allowedCount++;
            allowedByID[allowedCount] = _contractAddress;
            allowedindex[_contractAddress] = allowedCount;
          }
        }
    }

    function IsAllowed(address _wallet) view public returns(bool addressAllowed)
    {
        return (isOwner(_wallet) || allowedContract[_wallet]);
    }

    struct Allowed
    {
        address account;
        bool stillAllowed;
    }

    function GetAllAllowedAddresses() view external onlyAllowedContract returns (Allowed [] memory allowanceDetails)
    {
        allowanceDetails = new Allowed[](allowedCount);
        uint256 elem = 0;
        uint256 entries = allowedCount;
        for(uint256 i = 1; i <= entries; i++)
        {
            allowanceDetails[elem].account = allowedByID[i];
            allowanceDetails[elem].stillAllowed = allowedContract[allowedByID[i]];
            elem++;
        }
        return allowanceDetails;
    }

    // SECTION: Token and BNB Transfers...

    // Used to get random tokens sent to this address out to a wallet...
    function TransferForeignTokens(address _token, address _to) external onlyAllowedContract returns (bool _sent)
    {
        // See what is available...
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));

        return TransferForeignAmount(_token, _to, _contractBalance);
    }

    // Used to get an amount of random tokens sent to this address out to a wallet...
    function TransferForeignAmount(address _token, address _to, uint256 _maxAmount) public onlyAllowedContract returns (bool _sent)
    {
        // See what we have available...
        uint256 amount = IERC20(_token).balanceOf(address(this));

        // Cap it at the max requested...
        if(amount > _maxAmount) amount = _maxAmount;

        // Perform the send...
        if(amount != 0) _sent = IERC20(_token).transfer(_to, amount);
        else _sent = false;
    }

    // Used to get BNB from the contract...
    function TransferBNBToAddress(address payable recipient, uint256 amount) external onlyAllowedContract
    {
        if(address(this).balance < amount) revert("Balance Low");
        if(amount != 0) recipient.transfer(amount);
    }

    // Used to get BNB from the contract...
    function TransferAllBNBToAddress(address payable recipient) external onlyAllowedContract
    {
        uint256 amount = address(this).balance;
        if(amount != 0) recipient.transfer(amount);
    }
}

// 1) Create Contract
// 2) Call setCurrentRouter
// 3) Create Liquidity or Launch on Fair/Stealth Launchpad
contract HoldTimeToken is IERC20, Allowable
{
    uint256 private constant TOTAL_SUPPLY = 111_000_000_000 * 10**18;
    uint256 public constant holdPeriod = 7 days;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public excludedFromLockPeriod;
    mapping(address => bool) public _blacklisted;
    mapping(address => bool) public uniswapPairs;

    struct KeyHolder
    {
        uint256 vaultCount;             // Count of vaults they created (0 = none yet)
        uint256 firstVault;         // Where to start looking for new ones
    }

    struct Vault
    {
        uint256 amountStored;           // Count of tokens added to the vault for safe keeping
        uint256 lockedUntil;            // Time when this vault becomes unlockable
    }

    mapping(address => KeyHolder) public _numLocks;
    mapping(address => mapping(uint256 => Vault)) public _lockAmounts;

    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public immutable totalSupply;

    address public uniswapPair;
    IUniswapV2Router02 public uniswapRouter;

    event RouterUpdated(address indexed oldRouter, address indexed newRouter, address indexed newPair);
    event ExcludedFromLockPeriod(address indexed account);
    event IncludedInTimeLock(address indexed account);
    event Blacklisted(address indexed account);
    event Unblacklisted(address indexed account);

    error InsufficientBalance(uint256 available, uint256 required);
    error InsufficientAllowance(uint256 available, uint256 required);
    error ZeroAddressNotAllowed();
    error TransferAmountIsZero();
    error ParticipantBlacklisted(address wallet);
    error BlacklistAlreadyUpdated(address wallet);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) payable
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        totalSupply = TOTAL_SUPPLY;

        _balances[owner] = TOTAL_SUPPLY;
        emit Transfer(address(0), owner, TOTAL_SUPPLY);

        excludedFromLockPeriod[owner] = true;
        emit ExcludedFromLockPeriod(owner);
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        if (amount > _allowances[sender][_msgSender()])
            revert InsufficientAllowance({
                available: _allowances[sender][_msgSender()],
                required: amount
            });

        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        if (subtractedValue <= _allowances[_msgSender()][spender])
            revert InsufficientAllowance({
                available: _allowances[_msgSender()][spender],
                required: subtractedValue
            });

        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        if (sender == address(0) || recipient == address(0)) revert ZeroAddressNotAllowed();

        if(_blacklisted[sender]) revert ParticipantBlacklisted(sender);
        if(_blacklisted[recipient]) revert ParticipantBlacklisted(recipient);

        uint256 accessible = _balances[sender];

        // Check if sender is in the time lock period
        if (!excludedFromLockPeriod[sender]) {
            _cleanVaults(sender);
            accessible -= tokensLocked(sender);
        }

        if (amount > accessible)
            revert InsufficientBalance({
                available: accessible,
                required: amount
            });

        if (amount == 0) revert TransferAmountIsZero();

        // Check if recipient is in the time lock period
        if (!excludedFromLockPeriod[recipient]) {
            _numLocks[recipient].vaultCount += 1;
            uint256 index = _numLocks[recipient].vaultCount;
            if(index == 1) _numLocks[recipient].firstVault = 1;
            _lockAmounts[recipient][index].lockedUntil = getTime() + holdPeriod;
            _lockAmounts[recipient][index].amountStored = amount;
        }

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        if (owner == address(0) || spender == address(0)) revert ZeroAddressNotAllowed();

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setCurrentRouter(
        address _newRouterAddress
    ) external onlyAllowedContract {
        if (_newRouterAddress == address(0)) revert ZeroAddressNotAllowed();

        IUniswapV2Router02 _newRouter = IUniswapV2Router02(_newRouterAddress);
        address _pair = IUniswapV2Factory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        require(_pair != address(0), "New pair not found");

        emit RouterUpdated(address(uniswapRouter), address(_newRouter), _pair);

        uniswapRouter = _newRouter;
        uniswapPair = _pair;
        uniswapPairs[_pair] = true;

        excludedFromLockPeriod[address(uniswapRouter)] = true;
        emit ExcludedFromLockPeriod(address(uniswapRouter));
        excludedFromLockPeriod[address(uniswapPair)] = true;
        emit ExcludedFromLockPeriod(address(uniswapPair));
    }

    function excludeFromLockPeriod(
        address _address
    ) external onlyAllowedContract {
        excludedFromLockPeriod[_address] = true;
        emit ExcludedFromLockPeriod(_address);
    }   

    function includeInTimeLock(
        address _address
    ) external onlyAllowedContract {
        excludedFromLockPeriod[_address] = false;
        emit IncludedInTimeLock(_address);
    }

    function blacklistAddress(
        address _address
    ) external onlyAllowedContract {
        if(_blacklisted[_address]) revert BlacklistAlreadyUpdated(_address);
        _blacklisted[_address] = true;
        emit Blacklisted(_address);
    }

    function unblacklistAddress(
        address _address
    ) external onlyAllowedContract {
        if(!_blacklisted[_address]) revert BlacklistAlreadyUpdated(_address);
        _blacklisted[_address] = false;
        emit Unblacklisted(_address);
    }

    function _cleanVaults(
        address _address
    ) internal {
        uint256 curBlock = getTime();
        uint256 index = _numLocks[_address].firstVault;
        while(index <= _numLocks[_address].vaultCount && curBlock >= _lockAmounts[_address][index].lockedUntil)
        {
            ++index;
        }
        _numLocks[_address].firstVault = index;
    }

    function tokensLocked(
        address _address
    ) public view returns(uint256 lockedAmount) {
        uint256 curBlock = getTime();
        uint256 index = _numLocks[_address].firstVault;
        while(index <= _numLocks[_address].vaultCount)
        {
            if(curBlock < _lockAmounts[_address][index].lockedUntil) lockedAmount += _lockAmounts[_address][index].amountStored;
            ++index;
        }
    }

    function tokensAvailable(
        address _address
    ) public view returns(uint256 amountAvailable) {
        amountAvailable = _balances[_address];
        if (!excludedFromLockPeriod[_address]) amountAvailable -= tokensLocked(_address);
    }

    function nextUnlock(
        address _address
    ) public view returns(uint256 unlockBlock,uint256 blocksRemaining) {
        uint256 index = _numLocks[_address].firstVault;
        unlockBlock = _lockAmounts[_address][index].lockedUntil;
        uint256 curBlock = getTime();
        if(curBlock < unlockBlock) blocksRemaining = unlockBlock - curBlock;
        else blocksRemaining = 0;
    }
}