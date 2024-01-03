// File: contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <0.8.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner. (This is a BEP-20 token specific.)
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/interfaces/IBurnableToken.sol

pragma solidity >=0.6.0 <0.8.0;


interface IBurnableToken is IERC20 {
    function mint(address target, uint256 amount) external returns (bool);

    function burn(uint256 amount) external returns (bool);

    function mintable() external returns (bool);
}

// File: contracts/interfaces/ISwapContract.sol

pragma solidity >=0.6.0 <0.8.0;

interface ISwapContract {
    function singleTransferERC20(
        address _destToken,
        address _to,
        uint256 _amount,
        uint256 _totalSwapped,
        uint256 _rewardsAmount,
        bytes32[] memory _redeemedFloatTxIds
    ) external returns (bool);

    function multiTransferERC20TightlyPacked(
        address _destToken,
        bytes32[] memory _addressesAndAmounts,
        uint256 _totalSwapped,
        uint256 _rewardsAmount,
        bytes32[] memory _redeemedFloatTxIds
    ) external returns (bool);

    function collectSwapFeesForBTC(
        address _destToken,
        uint256 _incomingAmount,
        uint256 _rewardsAmount
    ) external returns (bool);

    function recordIncomingFloat(
        address _token,
        bytes32 _addressesAndAmountOfFloat,
        bool _zerofee,
        bytes32 _txid
    ) external returns (bool);

    // function issueLPTokensForFloat(bytes32 _txid) external returns (bool);

    function recordOutcomingFloat(
        address _token,
        bytes32 _addressesAndAmountOfLPtoken,
        uint256 _minerFee,
        bytes32 _txid
    ) external returns (bool);

    // function burnLPTokensForFloat(bytes32 _txid) external returns (bool);

    function distributeNodeRewards() external returns (bool);

    function churn(
        address _newOwner,
        bytes32[] memory _rewardAddressAndAmounts,
        bool[] memory _isRemoved,
        uint8 _churnedInCount,
        uint8 _tssThreshold,
        uint8 _nodeRewardsRatio,
        uint8 _withdrawalFeeBPS
    ) external returns (bool);

    function isTxUsed(bytes32 _txid) external view returns (bool);

    function getCurrentPriceLP() external view returns (uint256);

    function getDepositFeeRate(address _token, uint256 _amountOfFloat)
        external
        view
        returns (uint256);

    function getFloatReserve(address _tokenA, address _tokenB)
        external
        returns (uint256 reserveA, uint256 reserveB);

    function getActiveNodes() external returns (bytes32[] memory);

    function getMinimumAmountOfLPTokens(uint256 _minerFees)
        external
        view
        returns (uint256, uint256);
}

// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/SwapContract.sol

pragma solidity >=0.6.0 <0.8.0;

contract SwapContract is Ownable, ISwapContract {
    using SafeMath for uint256;

    address public WBTC_ADDR;
    address public lpToken;

    uint8 public churnedInCount;
    uint8 public tssThreshold;
    uint8 public nodeRewardsRatio;
    uint8 public depositFeesBPS;
    uint8 public withdrawalFeeBPS;

    uint256 public activeWBTCBalances;
    uint256 public lockedLPTokensForNode;

    uint256 private priceDecimals;
    uint256 private currentExchangeRate;
    uint256 private lpDecimals;
    // Support tokens
    mapping(address => bool) public whitelist;

    // Nodes
    mapping(address => bytes32) private nodes;
    mapping(address => bool) private isInList;
    address[] private nodeAddrs;
    // Token address -> amount
    mapping(address => uint256) private totalRewards;
    mapping(address => uint256) private floatAmountOf;
    mapping(bytes32 => bool) private used;

    /**
     * Events
     */

    event RecordIncomingFloat(
        address token,
        bytes32 addressesAndAmountOfFloat,
        bytes32 txid
    );

    event IssueLPTokensForFloat(address to, uint256 amountOfLP, bytes32 txid);

    event RecordOutcomingFloat(
        address token,
        bytes32 addressesAndAmountOfLPtoken,
        bytes32 txid
    );

    event BurnLPTokensForFloat(
        address token,
        uint256 amountOfFloat,
        bytes32 txid
    );

    modifier priceCheck() {
        uint256 beforePrice = getCurrentPriceLP();
        _;
        require(getCurrentPriceLP() >= beforePrice, "Invalid  LP price change");
    }

    constructor(
        address _lpToken,
        address _wbtc,
        uint256 _existingBTCFloat
    ) public {
        // burner = new Burner();
        lpToken = _lpToken;
        // Set initial price of LP token per BTC/WBTC.
        lpDecimals = 10**IERC20(lpToken).decimals();
        // Set WBTC address
        WBTC_ADDR = _wbtc;
        // Set nodeRewardsRatio
        nodeRewardsRatio = 66;
        // Set depositFeesBPS
        depositFeesBPS = 50;
        // Set withdrawalFeeBPS
        withdrawalFeeBPS = 20;
        // Set priceDecimals
        priceDecimals = 10**8;
        // Set currentExchangeRate
        currentExchangeRate = priceDecimals;
        // Set lockedLPTokensForNode
        lockedLPTokensForNode = 0;
        // SEt whitelist
        whitelist[WBTC_ADDR] = true;
        whitelist[lpToken] = true;
        whitelist[address(0)] = true;
        floatAmountOf[address(0)] = _existingBTCFloat;
    }

    /**
     * Transfer part
     */

    /// @dev singleTransferERC20 function sends tokens from contract.
    /// @param _destToken Address of token.
    /// @param _to Recevier address.
    /// @param _amount The amount of tokens.
    /// @param _totalSwapped the amount of swapped amount which is for send.
    /// @param _rewardsAmount Value that should be paid as fees.
    /// @param _redeemedFloatTxIds the txs which is for records txids.
    function singleTransferERC20(
        address _destToken,
        address _to,
        uint256 _amount,
        uint256 _totalSwapped,
        uint256 _rewardsAmount,
        bytes32[] memory _redeemedFloatTxIds
    ) external override onlyOwner returns (bool) {
        require(whitelist[_destToken], "_destToken is not whitelisted");
        require(
            _destToken != address(0),
            "_destToken should not be address(0)"
        );
        if (_destToken == WBTC_ADDR && _totalSwapped > 0) {
            activeWBTCBalances = activeWBTCBalances.sub(
                _totalSwapped,
                "activeWBTCBalances insufficient"
            );
        }
        _rewardsCollection(_destToken, _rewardsAmount);
        _addTxidUsed(_redeemedFloatTxIds);
        require(IERC20(_destToken).transfer(_to, _amount));
        return true;
    }

    /// @dev multiTransferERC20TightlyPacked function sends tokens from contract.
    /// @param _destToken Address of token.
    /// @param _addressesAndAmounts Recevier address and amounts.
    /// @param _totalSwapped the amount of swapped amount which is for send.
    /// @param _rewardsAmount Value that should be paid as fees.
    /// @param _redeemedFloatTxIds the txs which is for records txids.
    function multiTransferERC20TightlyPacked(
        address _destToken,
        bytes32[] memory _addressesAndAmounts,
        uint256 _totalSwapped,
        uint256 _rewardsAmount,
        bytes32[] memory _redeemedFloatTxIds
    ) external override onlyOwner returns (bool) {
        require(whitelist[_destToken], "_destToken is not whitelisted");
        require(
            _destToken != address(0),
            "_destToken should not be address(0)"
        );
        if (_destToken == WBTC_ADDR && _totalSwapped > 0) {
            activeWBTCBalances = activeWBTCBalances.sub(
                _totalSwapped,
                "activeWBTCBalances insufficient"
            );
        }
        _rewardsCollection(_destToken, _rewardsAmount);
        _addTxidUsed(_redeemedFloatTxIds);
        for (uint256 i = 0; i < _addressesAndAmounts.length; i++) {
            require(
                IERC20(_destToken).transfer(
                    address(uint160(uint256(_addressesAndAmounts[i]))),
                    uint256(uint96(bytes12(_addressesAndAmounts[i])))
                ),
                "Batch transfer error"
            );
        }
        return true;
    }

    /// @dev collectSwapFeesForBTC function collectes fees on BTC.
    /// @param _destToken Address of token.
    /// @param _incomingAmount spent amount of BTC.
    /// @param _rewardsAmount Value that should be paid as fees.
    function collectSwapFeesForBTC(
        address _destToken,
        uint256 _incomingAmount,
        uint256 _rewardsAmount
    ) external override onlyOwner returns (bool) {
        require(_destToken == address(0), "_destToken should be address(0)");
        activeWBTCBalances = activeWBTCBalances.add(_incomingAmount);
        _rewardsCollection(_destToken, _rewardsAmount);
        return true;
    }

    /**
     * Float part
     */

    /// @dev recordIncomingFloat function mint LP token.
    /// @param _token Address of target token.
    /// @param _addressesAndAmountOfFloat Recevier address and amounts.
    /// @param _zerofee The flag of accept.
    /// @param _txid the txs which is for records txids.
    function recordIncomingFloat(
        address _token,
        bytes32 _addressesAndAmountOfFloat,
        bool _zerofee,
        bytes32 _txid
    ) external override onlyOwner priceCheck returns (bool) {
        require(whitelist[_token], "_token is invalid");
        require(
            _issueLPTokensForFloat(
                _token,
                _addressesAndAmountOfFloat,
                _zerofee,
                _txid
            )
        );
        return true;
    }

    /// @dev recordOutcomingFloat function burn LP token.
    /// @param _token Address of target token.
    /// @param _addressesAndAmountOfLPtoken Sender address and amounts.
    /// @param _txid the txs which is for records txids.
    function recordOutcomingFloat(
        address _token,
        bytes32 _addressesAndAmountOfLPtoken,
        uint256 _minerFee,
        bytes32 _txid
    ) external override onlyOwner priceCheck returns (bool) {
        require(whitelist[_token], "_token is invalid");
        require(
            _burnLPTokensForFloat(
                _token,
                _addressesAndAmountOfLPtoken,
                withdrawalFeeBPS,
                _minerFee,
                _txid
            )
        );
        return true;
    }

    /// @dev distributeNodeRewards function sends rewards for Nodes.
    function distributeNodeRewards() external override returns (bool) {
        // Reduce Gas
        uint256 rewardLPsForNodes = lockedLPTokensForNode;
        require(rewardLPsForNodes > 0, "totalRewardLPsForNode is not positive");
        bytes32[] memory nodeList = getActiveNodes();
        uint256 totalStaked = 0;
        for (uint256 i = 0; i < nodeList.length; i++) {
            totalStaked = totalStaked.add(
                uint256(uint96(bytes12(nodeList[i])))
            );
        }
        for (uint256 i = 0; i < nodeList.length; i++) {
            IBurnableToken(lpToken).mint(
                address(uint160(uint256(nodeList[i]))),
                rewardLPsForNodes
                    .mul(uint256(uint96(bytes12(nodeList[i]))))
                    .div(totalStaked)
            );
        }
        lockedLPTokensForNode = 0;
        return true;
    }

    /// @dev churn function transfer contract ownership and set variables.
    /// @param _newOwner Address of new Owner.
    /// @param _rewardAddressAndAmounts Staker addresses and amounts.
    /// @param _isRemoved The flags for remove node.
    /// @param _churnedInCount The number of next N count.
    /// @param _tssThreshold The number of next T.
    /// @param _nodeRewardsRatio The number of next node rewards ratio.
    /// @param _withdrawalFeeBPS The amount of wthdrawal fees.
    function churn(
        address _newOwner,
        bytes32[] memory _rewardAddressAndAmounts,
        bool[] memory _isRemoved,
        uint8 _churnedInCount,
        uint8 _tssThreshold,
        uint8 _nodeRewardsRatio,
        uint8 _withdrawalFeeBPS
    ) external override onlyOwner returns (bool) {
        require(
            _tssThreshold >= tssThreshold && _tssThreshold <= 2**8 - 1,
            "_tssThreshold should be >= tssThreshold"
        );
        require(
            _churnedInCount >= _tssThreshold + uint8(1),
            "n should be >= t+1"
        );
        require(
            _nodeRewardsRatio >= 0 && _nodeRewardsRatio <= 100,
            "_nodeRewardsRatio is not valid"
        );
        require(
            _withdrawalFeeBPS >= 0 && _withdrawalFeeBPS <= 100,
            "_withdrawalFeeBPS is invalid"
        );
        require(
            _rewardAddressAndAmounts.length == _isRemoved.length,
            "_rewardAddressAndAmounts and _isRemoved length is not match"
        );
        transferOwnership(_newOwner);
        // Update active node list
        for (uint256 i = 0; i < _rewardAddressAndAmounts.length; i++) {
            (address newNode, ) = _splitToValues(_rewardAddressAndAmounts[i]);
            _addNode(newNode, _rewardAddressAndAmounts[i], _isRemoved[i]);
        }
        bytes32[] memory nodeList = getActiveNodes();
        if (nodeList.length > 100) {
            revert("node size should be <= 100");
        }
        churnedInCount = _churnedInCount;
        tssThreshold = _tssThreshold;
        nodeRewardsRatio = _nodeRewardsRatio;
        withdrawalFeeBPS = _withdrawalFeeBPS;
        return true;
    }

    /// @dev isTxUsed function sends rewards for Nodes.
    /// @param _txid txid of incoming tx.
    function isTxUsed(bytes32 _txid) public override view returns (bool) {
        return used[_txid];
    }

    /// @dev getCurrentPriceLP function returns exchange rate of LP token.
    function getCurrentPriceLP() public override view returns (uint256) {
        return currentExchangeRate;
    }

    /// @dev getDepositFeeRate function returns deposit fees rate
    /// @param _token The address of target token.
    /// @param _amountOfFloat The amount of float.
    function getDepositFeeRate(address _token, uint256 _amountOfFloat)
        public
        override
        view
        returns (uint256 depositFeeRate)
    {
        uint8 isFlip = _checkFlips(_token, _amountOfFloat);
        if (isFlip == 1) {
            depositFeeRate = _token == WBTC_ADDR ? depositFeesBPS : 0;
        } else if (isFlip == 2) {
            depositFeeRate = _token == address(0) ? depositFeesBPS : 0;
        }
    }

    /// @dev getMinimumAmountOfLPTokens function returns the minimum amount of LP Token.
    /// @param _minerFees The amount of miner Fees (BTC).
    function getMinimumAmountOfLPTokens(uint256 _minerFees)
        public
        override
        view
        returns (uint256, uint256)
    {
        (uint256 reserveA, uint256 reserveB) = getFloatReserve(
            address(0),
            WBTC_ADDR
        );
        uint256 totalLPs = IBurnableToken(lpToken).totalSupply();
        // decimals of totalReserved == 8, lpDecimals == 8, decimals of rate == 8
        uint256 nowPrice = totalLPs == 0
            ? currentExchangeRate
            : (reserveA.add(reserveB)).mul(lpDecimals).div(
                totalLPs.add(lockedLPTokensForNode)
            );
        uint256 requiredFloat = _minerFees.mul(10000).div(withdrawalFeeBPS);
        uint256 amountOfLPTokens = requiredFloat.add(10).mul(priceDecimals).div(
            nowPrice
        );
        return (amountOfLPTokens, nowPrice);
    }

    /// @dev getFloatReserve function returns float reserves not current balances.
    function getFloatReserve(address _tokenA, address _tokenB)
        public
        override
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (reserveA, reserveB) = (
            floatAmountOf[_tokenA].add(totalRewards[_tokenA]),
            floatAmountOf[_tokenB].add(totalRewards[_tokenB])
        );
    }

    /// @dev getActiveNodes function returns active nodes list (stakes and amount)
    function getActiveNodes() public override view returns (bytes32[] memory) {
        uint256 nodeCount = 0;
        uint256 count = 0;
        // Seek all nodes
        for (uint256 i = 0; i < nodeAddrs.length; i++) {
            if (nodes[nodeAddrs[i]] != 0x0) {
                nodeCount = nodeCount.add(1);
            }
        }
        bytes32[] memory _nodes = new bytes32[](nodeCount);
        for (uint256 i = 0; i < nodeAddrs.length; i++) {
            if (nodes[nodeAddrs[i]] != 0x0) {
                _nodes[count] = nodes[nodeAddrs[i]];
                count = count.add(1);
            }
        }
        return _nodes;
    }

    /// @dev _issueLPTokensForFloat
    /// @param _token Address of target token.
    /// @param _transaction Recevier address and amounts.
    /// @param _zerofee The flag of accept.
    /// @param _txid the txs which is for records txids.
    function _issueLPTokensForFloat(
        address _token,
        bytes32 _transaction,
        bool _zerofee,
        bytes32 _txid
    ) internal returns (bool) {
        require(!isTxUsed(_txid), "The txid is already used");
        // (address token, bytes32 transaction) = _loadTx(_txid);
        require(_transaction != 0x0, "The transaction is not found");
        // Define target address which is recorded bottom 20bytes on tx data
        // Define amountLP which is recorded top 12bytes on tx data
        (address to, uint256 amountOfFloat) = _splitToValues(_transaction);
        // LP token price per BTC/WBTC changed
        uint256 nowPrice = _updateFloatPool(address(0), WBTC_ADDR);
        // Calculate amount of LP token
        uint256 amountOfLP = amountOfFloat.mul(priceDecimals).div(nowPrice);
        uint256 depositFeeRate = getDepositFeeRate(_token, amountOfFloat);
        uint256 depositFees = depositFeeRate != 0
            ? amountOfLP.mul(depositFeeRate).div(10000)
            : 0;

        if (_zerofee && depositFees != 0) {
            revert();
        }
        //Send LP tokens to LP
        IBurnableToken(lpToken).mint(to, amountOfLP.sub(depositFees));
        // Add deposit fees
        lockedLPTokensForNode = lockedLPTokensForNode.add(depositFees);
        // Add float amount
        _addFloat(_token, amountOfFloat);
        used[_txid] = true;
        emit IssueLPTokensForFloat(to, amountOfLP, _txid);
        return true;
    }

    /// @dev _burnLPTokensForFloat
    /// @param _token Address of target token.
    /// @param _transaction Sender address and amounts.
    /// @param _withdrawalFeeBPS The amount of withdrawal fees.
    /// @param _txid the txs which is for records txids.
    function _burnLPTokensForFloat(
        address _token,
        bytes32 _transaction,
        uint256 _withdrawalFeeBPS,
        uint256 _minerFee,
        bytes32 _txid
    ) internal returns (bool) {
        require(!isTxUsed(_txid), "The txid is already used");
        // _token should be address(0) or WBTC_ADDR
        // (address token, bytes32 transaction) = _loadTx(_txid);
        require(_transaction != 0x0, "The transaction is not found");
        // Define target address which is recorded bottom 20bytes on tx data
        // Define amountLP which is recorded top 12bytes on tx data
        (address to, uint256 amountOfLP) = _splitToValues(_transaction);
        // Calculate amountOfLP
        uint256 nowPrice = _updateFloatPool(address(0), WBTC_ADDR);
        // Calculate amountOfFloat
        uint256 amountOfFloat = amountOfLP.mul(nowPrice).div(priceDecimals);
        uint256 amountOfFees = amountOfFloat.mul(_withdrawalFeeBPS).div(10000);
        require(
            floatAmountOf[_token] >= amountOfFloat,
            "Pool balance insufficient."
        );
        require(
            _minerFee <= amountOfFees,
            "amountOfFees.sub(_minerFee) is negative"
        );
        // Burn LP tokens
        require(IBurnableToken(lpToken).burn(amountOfLP));
        // Remove float amount
        _removeFloat(_token, amountOfFloat);
        // Collect fees
        _rewardsCollection(_token, amountOfFees.sub(_minerFee));
        used[_txid] = true;
        // WBTC transfer if token address is WBTC_ADDR
        if (_token == WBTC_ADDR) {
            require(
                IERC20(_token).transfer(
                    to,
                    amountOfFloat.sub(amountOfFees).sub(_minerFee)
                ),
                "WBTC balance insufficient"
            );
        }
        emit BurnLPTokensForFloat(to, amountOfFloat, _txid);
        return true;
    }

    /// @dev _checkFlips
    /// @param _token Address of target token.
    /// @param _amountOfFloat The amount of float.
    function _checkFlips(address _token, uint256 _amountOfFloat)
        internal
        view
        returns (uint8)
    {
        (uint256 reserveA, uint256 reserveB) = getFloatReserve(
            address(0),
            WBTC_ADDR
        );
        if (activeWBTCBalances > reserveA.add(reserveB)) {
            return 0;
        }
        // BTC balance == balance of BTC float + balance of WBTC float - balance of WBTC
        uint256 balBTC = reserveA.add(reserveB).sub(activeWBTCBalances);
        uint256 threshold = reserveA
            .add(reserveB)
            .add(_amountOfFloat)
            .mul(2)
            .div(3);
        if (_token == WBTC_ADDR) {
            if (activeWBTCBalances.add(_amountOfFloat) >= threshold) {
                return 1; // BTC float insufficient
            }
        } else if (_token == address(0)) {
            if (balBTC.add(_amountOfFloat) >= threshold) {
                return 2; // WBTC float insufficient
            }
        }
        return 0;
    }

    /// @dev _updateFloatPool updates float balances.
    /// @param _tokenA Address of target tokenA.
    /// @param _tokenB Address of target tokenB.
    function _updateFloatPool(address _tokenA, address _tokenB)
        internal
        returns (uint256)
    {
        // Reduce gas cost.
        (uint256 reserveA, uint256 reserveB) = getFloatReserve(
            _tokenA,
            _tokenB
        );
        uint256 totalLPs = IBurnableToken(lpToken).totalSupply();
        // decimals of totalReserved == 8, lpDecimals == 8, decimals of rate == 8
        currentExchangeRate = totalLPs == 0
            ? currentExchangeRate
            : (reserveA.add(reserveB)).mul(lpDecimals).div(
                totalLPs.add(lockedLPTokensForNode)
            );
        return currentExchangeRate;
    }

    /// @dev _addFloat updates Float.
    /// @param _token The address of target token.
    /// @param _amount The amount of float.
    function _addFloat(address _token, uint256 _amount) internal {
        floatAmountOf[_token] = floatAmountOf[_token].add(_amount);
        if (_token == WBTC_ADDR) {
            activeWBTCBalances = activeWBTCBalances.add(_amount);
        }
    }

    /// @dev _removeFloat remove Float.
    /// @param _token The address of target token.
    /// @param _amount The amount of float.
    function _removeFloat(address _token, uint256 _amount) internal {
        floatAmountOf[_token] = floatAmountOf[_token].sub(
            _amount,
            "float amount insufficient"
        );
        if (_token == WBTC_ADDR) {
            activeWBTCBalances = activeWBTCBalances.sub(
                _amount,
                "activeWBTCBalances insufficient"
            );
        }
    }

    /// @dev _rewardsCollection collects rewards.
    /// @param _destToken The address of target token.
    /// @param _rewardsAmount The amount of rewards.
    function _rewardsCollection(address _destToken, uint256 _rewardsAmount)
        internal
    {
        if (_destToken == lpToken) return;
        if (_rewardsAmount == 0) return;
        // The fee is always collected in the source token (it's left in the float on the origin chain).
        address _feesToken = _destToken == WBTC_ADDR ? address(0) : WBTC_ADDR;
        // Add all fees into pool
        totalRewards[_feesToken] = totalRewards[_feesToken].add(_rewardsAmount);
        uint256 amountForNodes = _rewardsAmount.mul(nodeRewardsRatio).div(100);
        // Alloc LP tokens for nodes as fees
        uint256 amountLPForNode = amountForNodes.mul(priceDecimals).div(
            getCurrentPriceLP()
        );
        // Add minted LP tokens for Nodes
        lockedLPTokensForNode = lockedLPTokensForNode.add(amountLPForNode);
    }

    /// @dev _addTxidUsed updates a spent txhash.
    /// @param _txs The array of txid.
    function _addTxidUsed(bytes32[] memory _txs) internal {
        for (uint256 i = 0; i < _txs.length; i++) {
            used[_txs[i]] = true;
        }
    }

    /// @dev _addNode updates a Staker.
    /// @param _addr The address of staker.
    /// @param _data The data of staker.
    /// @param _remove The flag for remove.
    function _addNode(
        address _addr,
        bytes32 _data,
        bool _remove
    ) internal returns (bool) {
        if (_remove) {
            delete nodes[_addr];
            return true;
        }
        if (!isInList[_addr]) {
            nodeAddrs.push(_addr);
            isInList[_addr] = true;
        }
        if (nodes[_addr] == 0x0) {
            nodes[_addr] = _data;
        }
        return true;
    }

    /// @dev _splitToValues returns address and amount of stakes
    /// @param _data The data of staker.
    function _splitToValues(bytes32 _data)
        internal
        pure
        returns (address, uint256)
    {
        return (
            address(uint160(uint256(_data))),
            uint256(uint96(bytes12(_data)))
        );
    }

    /// @dev The contract doesn't allow receiving Ether.
    fallback() external {
        revert();
    }
}