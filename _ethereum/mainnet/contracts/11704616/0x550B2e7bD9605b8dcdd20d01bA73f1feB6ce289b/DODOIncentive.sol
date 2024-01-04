// File: contracts/lib/InitializableOwnable.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/intf/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
}

// File: contracts/lib/SafeMath.sol



/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/lib/SafeERC20.sol




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/DODOToken/DODOIncentive.sol



interface IDODOIncentive {
    function triggerIncentive(
        address fromToken,
        address toToken,
        address assetTo
    ) external;
}

/**
 * @title DODOIncentive
 * @author DODO Breeder
 *
 * @notice Trade Incentive in DODO platform
 */
contract DODOIncentive is InitializableOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ============ Storage ============
    address public immutable _DODO_TOKEN_;
    address public _DODO_PROXY_;
    uint256 public dodoPerBlock;
    uint256 public defaultRate = 10;
    mapping(address => uint256) public boosts;

    uint32 public lastRewardBlock;
    uint112 public totalReward;
    uint112 public totalDistribution;

    // ============ Events ============

    event SetBoost(address token, uint256 boostRate);
    event SetNewProxy(address dodoProxy);
    event SetPerReward(uint256 dodoPerBlock);
    event SetDefaultRate(uint256 defaultRate);
    event Incentive(address user, uint256 reward);

    constructor(address _dodoToken) public {
        _DODO_TOKEN_ = _dodoToken;
    }

    // ============ Ownable ============

    function changeBoost(address _token, uint256 _boostRate) public onlyOwner {
        require(_token != address(0));
        require(_boostRate + defaultRate <= 1000);
        boosts[_token] = _boostRate;
        emit SetBoost(_token, _boostRate);
    }

    function changePerReward(uint256 _dodoPerBlock) public onlyOwner {
        _updateTotalReward();
        dodoPerBlock = _dodoPerBlock;
        emit SetPerReward(dodoPerBlock);
    }

    function changeDefaultRate(uint256 _defaultRate) public onlyOwner {
        defaultRate = _defaultRate;
        emit SetDefaultRate(defaultRate);
    }

    function changeDODOProxy(address _dodoProxy) public onlyOwner {
        _DODO_PROXY_ = _dodoProxy;
        emit SetNewProxy(_DODO_PROXY_);
    }

    function emptyReward(address assetTo) public onlyOwner {
        uint256 balance = IERC20(_DODO_TOKEN_).balanceOf(address(this));
        IERC20(_DODO_TOKEN_).transfer(assetTo, balance);
    }

    // ============ Incentive  function ============

    function triggerIncentive(
        address fromToken,
        address toToken,
        address assetTo
    ) external {
        require(msg.sender == _DODO_PROXY_, "DODOIncentive:Access restricted");

        uint256 curTotalDistribution = totalDistribution;
        uint256 fromRate = boosts[fromToken];
        uint256 toRate = boosts[toToken];
        uint256 rate = (fromRate >= toRate ? fromRate : toRate) + defaultRate;
        require(rate <= 1000, "RATE_INVALID");
        
        uint256 _totalReward = _getTotalReward();
        uint256 reward = ((_totalReward - curTotalDistribution) * rate) / 1000;
        uint256 _totalDistribution = curTotalDistribution + reward;

        _update(_totalReward, _totalDistribution);
        if (reward != 0) {
            IERC20(_DODO_TOKEN_).transfer(assetTo, reward);
            emit Incentive(assetTo, reward);
        }
    }

    function _updateTotalReward() internal {
        uint256 _totalReward = _getTotalReward();
        require(_totalReward < uint112(-1), "OVERFLOW");
        totalReward = uint112(_totalReward);
        lastRewardBlock = uint32(block.number);
    }

    function _update(uint256 _totalReward, uint256 _totalDistribution) internal {
        require(
            _totalReward < uint112(-1) && _totalDistribution < uint112(-1) && block.number < uint32(-1),
            "OVERFLOW"
        );
        lastRewardBlock = uint32(block.number);
        totalReward = uint112(_totalReward);
        totalDistribution = uint112(_totalDistribution);
    }

    function _getTotalReward() internal view returns (uint256) {
        if (lastRewardBlock == 0) {
            return totalReward;
        } else {
            return totalReward + (block.number - lastRewardBlock) * dodoPerBlock;
        }
    }

    // ============= Helper function ===============

    function incentiveStatus(address fromToken, address toToken)
        external
        view
        returns (
            uint256 reward,
            uint256 baseRate,
            uint256 totalRate,
            uint256 curTotalReward,
            uint256 perBlockReward
        )
    {
        baseRate = defaultRate;
        uint256 fromRate = boosts[fromToken];
        uint256 toRate = boosts[toToken];
        totalRate = (fromRate >= toRate ? fromRate : toRate) + defaultRate;
        uint256 _totalReward = _getTotalReward();
        reward = ((_totalReward - totalDistribution) * totalRate) / 1000;
        curTotalReward = _totalReward - totalDistribution;
        perBlockReward = dodoPerBlock;
    }
}