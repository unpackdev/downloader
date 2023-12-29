//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

interface IOwnable {
    function owner() external view returns (address);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address _owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IBurnable {
    function burn(uint256 value) external;
    function burnFrom(address account, uint256 value) external;
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function depositNative() external payable;
    function depositToken(address from, uint256 amount) external;
    function process(uint256 gas) external;
    function inSwap() external view returns (bool);
}

interface ITaxDistributorLight {
    receive() external payable;
    function lastSwapTime() external view returns (uint256);
    function inSwap() external view returns (bool);
    function createWalletTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) external;
    function distribute() external payable;
    function getSellTax() external view returns (uint256);
    function getBuyTax() external view returns (uint256);
    function getTaxWallet(string memory taxName) external view returns(address);
    function setTaxWallet(string memory taxName, address wallet) external;
    function setSellTax(string memory taxName, uint256 taxPercentage) external;
    function setBuyTax(string memory taxName, uint256 taxPercentage) external;
    function takeSellTax(uint256 value) external returns (uint256);
    function takeBuyTax(uint256 value) external returns (uint256);
}

interface ITaxDistributor is ITaxDistributorLight {
    function createDistributorTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) external;
    function createDividendTax(string memory name, uint256 buyTax, uint256 sellTax, address dividendDistributor, bool convertToNative) external;
    function createBurnTax(string memory name, uint256 buyTax, uint256 sellTax) external;
    function createLiquidityTax(string memory name, uint256 buyTax, uint256 sellTax, address holder) external; 
}


interface IWalletDistributor {
    function receiveToken(address token, address from, uint256 amount) external;
}

interface IRewards {
    function sendFeeToHolders(uint256 feeEpoch) external payable;
    function setNewBalance(address a1, uint256 a1Balance, address a2, uint256 a2balance) external;
}

interface IRewardsTaxDistributor {
    receive() external payable;
    function lastSwapTime() external view returns (uint256);
    function inSwap() external view returns (bool);
    function distribute() external payable;
    function getSellTax() external view returns (uint256);
    function getBuyTax() external view returns (uint256);
    function getTaxWallet() external view returns(address);
    function setTaxWallet(address wallet) external;
    function setSellTax(uint256 taxPercentage) external;
    function setBuyTax(uint256 taxPercentage) external;
    function setRewardPercentage(uint256 amount) external;
    function setRewardContract(address who) external;
    function takeSellTax(uint256 value) external returns (uint256);
    function takeBuyTax(uint256 value) external returns (uint256);
}



/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

abstract contract BaseErc20 is IERC20, Ownable {
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    uint256 internal _totalSupply;
    
    string public symbol;
    string public name;
    uint8 public decimals;
    
    bool public launched;
    uint256 public launchBlock;
    
    mapping (address => bool) internal exchanges;

    modifier isLaunched() {
        require(launched, "can only be called once token is launched");
        _;
    }

    // @dev Trading is allowed before launch if the sender is the owner, we are transferring from the owner, or in canAlwaysTrade list
    modifier tradingEnabled(address from) virtual {
        require(launched || from == owner(), "trading not enabled");
        _;
    }
    
    constructor(address _owner) Ownable(_owner) {

    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) external override view returns (uint256) {
        return _balances[_owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address spender) external override view returns (uint256) {
        return _allowed[_owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) external override tradingEnabled(msg.sender) returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external override tradingEnabled(msg.sender) returns (bool) {
        require(spender != address(0), "cannot approve the 0 address");

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) external override tradingEnabled(from) returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender] - value;
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    // Virtual methods
    function launch() virtual external onlyOwner {
        require(launched == false, "contract already launched");
        launched = true;
        launchBlock = block.number;
    }

    function calculateTransferAmount(address from, address to, uint256 value) virtual internal returns (uint256) {
        require(from != to, "you cannot transfer to yourself");
        return value;
    }
    
    function preTransfer(address from, address to, uint256 value) virtual internal { }

    function postTransfer(address from, uint256 fromBalance, address to, uint256 toBalance) virtual internal { }

    // Admin methods

    function setExchange(address who, bool on) external onlyOwner {
        require(exchanges[who] != on, "already set");
        exchanges[who] = on;
    }

    // Private methods

    function getRouterAddress() internal view returns (address routerAddress) {
        if (block.chainid == 1 || block.chainid == 3 || block.chainid == 4  || block.chainid == 5) {
            routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ; // ETHEREUM
        } else if (block.chainid == 11155111) {
             routerAddress = 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008; // SEPOLIA
        } else if (block.chainid == 56) {
            routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC MAINNET
         } else if (block.chainid == 8453) {
            routerAddress = 0xfCD3842f85ed87ba2889b4D35893403796e67FF1; // BASE
        } else {
            revert("Unknown Chain ID");
        }
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) private {
        require(to != address(0), "cannot be zero address");

        preTransfer(from, to, value);

        uint256 modifiedAmount = calculateTransferAmount(from, to, value);
        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + modifiedAmount;

        postTransfer(from, _balances[from], to, _balances[to]);

        emit Transfer(from, to, modifiedAmount);
    }
}

abstract contract Taxable is BaseErc20 {
    
    IRewardsTaxDistributor internal taxDistributor;
    IRewards internal rewardContract;

    bool internal autoSwapTax;
    uint256 internal deadBlocks = 3;
    uint256 internal minimumTimeBetweenSwaps;
    uint256 internal minimumTokensBeforeSwap;
    mapping (address => bool) internal excludedFromTax;
    uint256 private swapStartTime;
    
    // Overrides
    constructor (address owner, address rewards) BaseErc20(owner) {
        rewardContract = IRewards(rewards);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) internal virtual override returns (uint256) {
        
        uint256 amountAfterTax = value;

        if (excludedFromTax[from] == false && excludedFromTax[to] == false && launched) {
            if (exchanges[from]) {
                // we are BUYING
                amountAfterTax = taxDistributor.takeBuyTax(value);
            } else if (exchanges[to]) {
                // we are SELLING
                amountAfterTax = taxDistributor.takeSellTax(value);
            }
        }

        uint256 taxAmount = value - amountAfterTax;
        if (taxAmount > 0) {
            _balances[address(taxDistributor)] = _balances[address(taxDistributor)] + taxAmount;
        }

        return super.calculateTransferAmount(from, to, amountAfterTax);
    }


    function preTransfer(address from, address to, uint256 value) override virtual internal {
        uint256 timeSinceLastSwap = block.timestamp - taxDistributor.lastSwapTime();
        if (
            launched && 
            autoSwapTax && 
            exchanges[to] && 
            swapStartTime + 60 <= block.timestamp &&
            timeSinceLastSwap >= minimumTimeBetweenSwaps &&
            _balances[address(taxDistributor)] >= minimumTokensBeforeSwap &&
            taxDistributor.inSwap() == false
        ) {
            swapStartTime = block.timestamp;
            try taxDistributor.distribute() {} catch {}
        }
        super.preTransfer(from, to, value);
    }

    function postTransfer(address from, uint256 fromBalance, address to, uint256 toBalance) override virtual internal { 
        rewardContract.setNewBalance(from, fromBalance, to, toBalance);
        super.postTransfer(from, fromBalance, to, toBalance);
    }
    
    
    // Public methods
    
    /**
     * @dev Return the current total sell tax from the tax distributor
     */
    function sellTax() external view returns (uint256) {
        return taxDistributor.getSellTax();
    }

    /**
     * @dev Return the current total sell tax from the tax distributor
     */
    function buyTax() external view returns (uint256) {
        return taxDistributor.getBuyTax();
    }

    /**
     * @dev Return the address of the tax distributor contract
     */
    function taxDistributorAddress() external view returns (address) {
        return address(taxDistributor);
    }    
    
    
    // Admin methods

    function setAutoSwaptax(bool enabled) external onlyOwner {
        autoSwapTax = enabled;
    }

    function setExcludedFromTax(address who, bool enabled) external onlyOwner {
        require(exchanges[who] == false || enabled == false, "Cannot exclude an exchange from tax");
        excludedFromTax[who] = enabled;
    }

    function setTaxDistributionThresholds(uint256 minAmount, uint256 minTime) external onlyOwner {
        minimumTokensBeforeSwap = minAmount;
        minimumTimeBetweenSwaps = minTime;
    }
    
    function setSellTax(uint256 taxAmount) external onlyOwner {
        taxDistributor.setSellTax(taxAmount);
    }

    function setBuyTax(uint256 taxAmount) external onlyOwner {
        taxDistributor.setBuyTax(taxAmount);
    }
    
    function setTaxWallet(address who) external onlyOwner {
        taxDistributor.setTaxWallet(who);
    }

    function setRewardPercentage(uint256 amount) external onlyOwner {
        taxDistributor.setRewardPercentage(amount);
    }

    function setRewardContract(address who) external onlyOwner {
        taxDistributor.setRewardContract(who);
        rewardContract = IRewards(who);
    }

    function runSwapManually() external isLaunched {
        taxDistributor.distribute();
    }
}

contract RewardTaxDistributor is IRewardsTaxDistributor {
    using Address for address;

    address immutable private tokenPair;
    address immutable private routerAddress;
    address immutable private _token;
    address immutable private _wbnb;

    IDEXRouter private _router;

    bool public override inSwap;
    uint256 public override lastSwapTime;

    uint256 immutable private maxSellTax;
    uint256 immutable private maxBuyTax;

    uint256 buyTaxPercentage;
    uint256 sellTaxPercentage;
    address location;

    uint256 rewardShare;
    IRewards rewardContract;

    event TaxesDistributed(uint256 tokensSwapped, uint256 ethReceived);
    event DistributionError(string text);

    modifier onlyToken() {
        require(msg.sender == _token, "no permissions");
        _;
    }

    modifier swapLock() {
        require(inSwap == false, "already swapping");
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (address router, address pair, address wbnb, uint256 _maxSellTax, uint256 _maxBuyTax, address rewards) {
        require(wbnb != address(0), "pairedToken cannot be 0 address");
        require(pair != address(0), "pair cannot be 0 address");
        require(router != address(0), "router cannot be 0 address");
        _token = msg.sender;
        _wbnb = wbnb;
        _router = IDEXRouter(router);
        maxSellTax = _maxSellTax;
        maxBuyTax = _maxBuyTax;
        tokenPair = pair;
        routerAddress = router;
        rewardContract = IRewards(rewards);
    }

    receive() external override payable {}

    function currentEpoch() private view returns(uint256) {
        return block.timestamp / 3 hours;
    }

    function distribute() external payable override onlyToken swapLock {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = _wbnb;
        IERC20 token = IERC20(_token);

        uint256 totalTokens;
        totalTokens = token.balanceOf(address(this));

        uint256[] memory amts = _router.swapExactTokensForETH(
            totalTokens,
            0,
            path,
            address(this),
            block.timestamp + 300
        );

        uint256 balance = address(this).balance;

        uint256 ownerShare = balance * (100_00 - rewardShare) / 100_00;
        uint256 holderShare = balance - ownerShare;
        payable(location).transfer(ownerShare);
        if (holderShare > 0) {
            rewardContract.sendFeeToHolders{ value: holderShare }(currentEpoch() - 1);
        }

        emit TaxesDistributed(totalTokens, amts[1]);

        lastSwapTime = block.timestamp;
    }

    function getSellTax() public override onlyToken view returns (uint256) {
        return sellTaxPercentage;
    }

    function getBuyTax() public override onlyToken view returns (uint256) {
        return buyTaxPercentage;
    }

    function getTaxWallet()external override view onlyToken returns (address)  {
        return location;
    }
    
    function setTaxWallet(address wallet) external override onlyToken {
        location = wallet;
    }

    function setSellTax(uint256 taxPercentage) external override onlyToken {
        sellTaxPercentage = taxPercentage;
        require(getSellTax() <= maxSellTax, "tax cannot be set this high");
    }

    function setBuyTax(uint256 taxPercentage) external override onlyToken {
        buyTaxPercentage = taxPercentage;
        require(getBuyTax() <= maxBuyTax, "tax cannot be set this high");
    }

    function setRewardPercentage(uint256 taxPercentage) external override onlyToken {
        rewardShare = taxPercentage;
        require(taxPercentage <= 100_00, "Cannot be higher than 100%");
    }

    function setRewardContract(address who) external override onlyToken {
        rewardContract = IRewards(who);
    }

    function takeSellTax(uint256 value) external view override onlyToken returns (uint256) {
        if (sellTaxPercentage > 0) {
            uint256 taxAmount = (value * sellTaxPercentage) / 10000;
            value = value - taxAmount;
        }
        return value;
    }

    function takeBuyTax(uint256 value) view external override onlyToken returns (uint256) {
        if (buyTaxPercentage > 0) {
            uint256 taxAmount = (value * buyTaxPercentage) / 10000;
            value = value - taxAmount;
        }
        return value;
    }
}

contract Unodex is BaseErc20, Taxable {

    uint256 immutable public mhAmount;

    constructor () Taxable(msg.sender, 0x0130D3A9E98812159EdFa037F4Ad1Cf0E46645E7) {
        symbol = "UNDX";
        name = "UNODEX";
        decimals = 18;

        // Swap
        address routerAddress = getRouterAddress();
        IDEXRouter router = IDEXRouter(routerAddress);
        address native = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(native, address(this));
        exchanges[pair] = true;
        taxDistributor = new RewardTaxDistributor(routerAddress, pair, native, 30_00, 30_00, 0x0130D3A9E98812159EdFa037F4Ad1Cf0E46645E7);

        // Tax
        minimumTimeBetweenSwaps = 30 seconds;
        minimumTokensBeforeSwap = 160_000 * 10 ** decimals;
        excludedFromTax[address(taxDistributor)] = true;
        excludedFromTax[owner()] = true;
        taxDistributor.setBuyTax(30_00);
        taxDistributor.setSellTax(30_00);
        taxDistributor.setRewardPercentage(0);
        taxDistributor.setTaxWallet(0x9EA06865fd1b1808660cCfdd9224e017742dEcE8);
        autoSwapTax = true;
   
        // Max Hold
        mhAmount = 1_000_005  * 10 ** decimals;

        // Finalise
        _allowed[address(taxDistributor)][routerAddress] = 2**256 - 1;
        _totalSupply = _totalSupply + (100_000_000 * 10 ** decimals);
        _balances[owner()] = _balances[owner()] + _totalSupply;
        emit Transfer(address(0), owner(), _totalSupply); 
    }

    // Overrides
   
    function preTransfer(address from, address to, uint256 value) override(Taxable, BaseErc20) internal {      
        if (launched && 
            from != owner() && to != owner() && 
            exchanges[to] == false && 
            to != getRouterAddress() &&
            to != address(taxDistributor) &&
            from != address(taxDistributor)
        ) {
            require (_balances[to] + value <= mhAmount, "this is over the max hold amount");
        }
        
        super.preTransfer(from, to, value);
    }
    
    function postTransfer(address from, uint256 fromBalance, address to, uint256 toBalance) override(Taxable, BaseErc20) internal { 
        return super.postTransfer(from, fromBalance, to, toBalance);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) override(Taxable, BaseErc20) internal returns (uint256) {
        return super.calculateTransferAmount(from, to, value);
    }

    function setTax(uint256 taxAmount) external onlyOwner {
        taxDistributor.setSellTax(taxAmount);
        taxDistributor.setBuyTax(taxAmount);
    }
}