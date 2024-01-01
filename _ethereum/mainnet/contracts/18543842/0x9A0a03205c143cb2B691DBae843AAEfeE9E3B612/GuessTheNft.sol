// SPDX-License-Identifier: Unlicensed
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @chainlink/contracts/src/v0.8/VRFRequestIDBase.sol


pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// File: @chainlink/contracts/src/v0.8/VRFConsumerBase.sol


pragma solidity ^0.8.0;



/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/prod/Base.sol


pragma solidity ^0.8.0;






abstract contract BaseContract is Ownable {

  using SafeMath for uint256;

  struct BubuAccounting{
    uint256 affiliates;
    uint256 team;
    uint256 staking;
  }

  struct DuduAccounting{
    uint256 affiliates;
    uint256 team;
    uint256 staking;
    uint256 burn;
  }

  struct EthAccounting{
    uint256 affiliates;
    uint256 team;
    uint256 staking;
  }

  // ACCOUNTING
  BubuAccounting public bubuAccounting;

  DuduAccounting public duduAccounting;

  EthAccounting public ethAccounting;

  // CHAINLINK CONSTANTS
  address public constant CHAINLINK_AGGREGATOR_USD_ETH = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
  address public constant CHAINLINK_AGGREGATOR_LINK_ETH = 0xDC530D9457755926550b59e8ECcdaE7624181557;

  // SWAP CONSTANTS
  address public constant UNISWAPV2_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  uint256 public ENTRY_PRICE_USDT = 88.88 * 10**6; // 88.88 usdt
  uint256 public ETH_ENTRY_PRICE_INCREASE_PERCENTAGE = 20; // 20%
  uint256 public UINT32_MAX = 2**32-1;

  // CONSTRUCTOR ARGS
  AggregatorV3Interface public immutable linkToEthDataFeed;
  AggregatorV3Interface public immutable usdToEthDataFeed;
  IUniswapV2Router02 public immutable uniswapV2Router;
  IERC20 public immutable bubuToken;
  IERC20 public immutable duduToken;
  address payable public teamFeeReceiver;
  address payable public stakingFeeReceiver;

  // ACCOUNTING + SETTINGS
  uint16 public maxEntriesPerTx = 100; // owner can update
  uint256 public tip = 0.0025 ether;                      // owner can update
  bool public lockBurnEntries = true;                            // owner can update
  bool public lockInitiateDrawing;                        // owner can update
  bool public includeFreeEntriesWithMaxEntries = false;   // owner can update
  bool internal includeFreeEntries = false;
  uint32 public drawingIndex;           // internal
  uint16 public numPayoutAttempts = 5;  // owner can update

  // STATE
  mapping(address => bool) private approvedOwners;
  mapping(address => bool) public isBlacklistedFromPrizes;
  mapping(address => uint256) public amountBurned;

  // EVENTS
  event OwnerApproved(address indexed approvedOwner);
  event OwnerRevoked(address indexed revokedOwner);
  event DrawingInitiated();
  event NoEntries();
  event BurnedEntries(address sender, uint256 numEntries);
  event Received(uint256 amount);

  constructor(
    address _bubuToken,
    address _duduToken,
    address _teamFeeReceiver,
    address _stakingFeeReceiver
  ) {

    linkToEthDataFeed = AggregatorV3Interface(CHAINLINK_AGGREGATOR_LINK_ETH);
    usdToEthDataFeed = AggregatorV3Interface(CHAINLINK_AGGREGATOR_USD_ETH);
    uniswapV2Router = IUniswapV2Router02(UNISWAPV2_ROUTER_ADDRESS);

    bubuToken = IERC20(_bubuToken);
    duduToken = IERC20(_duduToken);

    teamFeeReceiver = payable(_teamFeeReceiver);
    stakingFeeReceiver = payable(_stakingFeeReceiver);
  }

  receive() external payable {
    emit Received(msg.value);
  }

  modifier refundGas {
    uint256 initialGas = gasleft();
    _;
    uint256 gasConsumed = initialGas - gasleft() + 30000;
    (bool success,) = msg.sender.call{value: gasConsumed * block.basefee + tip}("");
    require(success, "refund");
  }

  // ACCESS CONTROL--------------------------------------------------------------
  modifier onlyApprovedOwner() {
      require(msg.sender == owner() || isApprovedOwner(msg.sender), "Not an approved owner");
      _;
  }

  function approveOwner(address _approvedOwner) external onlyApprovedOwner {
    approvedOwners[_approvedOwner] = true;
    emit OwnerApproved(_approvedOwner);
  }

  function revokeOwner(address _revokedOwner) external onlyApprovedOwner {
    approvedOwners[_revokedOwner] = false;
    emit OwnerRevoked(_revokedOwner);
  }

  function isApprovedOwner(address _address) public view returns(bool) {
    return approvedOwners[_address];
  }

  // OWNER ONLY --------------------------------------------------------------
  function setTip(uint256 _tip) public onlyApprovedOwner {
    tip = _tip;
  }

  function setLockInitiateDrawing(bool _lockInitiateDrawing) public onlyApprovedOwner {
    lockInitiateDrawing = _lockInitiateDrawing;
  }

  function setIncludeFreeEntriesWithMaxEntries(bool _includeFreeEntriesWithMaxEntries) public onlyApprovedOwner {
    includeFreeEntriesWithMaxEntries = _includeFreeEntriesWithMaxEntries;
  }

  function setLockBurnEntries(bool _lockBurnEntries) public onlyApprovedOwner {
    lockBurnEntries = _lockBurnEntries;
  }

  function setmaxEntriesPerTx(uint16 _maxEntriesPerTx) public onlyApprovedOwner {
    maxEntriesPerTx = _maxEntriesPerTx;
  }

  function setNumPayoutAttempts(uint16 _numPayoutAttempts) public onlyApprovedOwner {
    require(_numPayoutAttempts > 0, 'must be a value higher than 0');
    numPayoutAttempts = _numPayoutAttempts;
  }

  function setBlacklistedFromPrizes(address _user, bool isBlacklisted) public onlyApprovedOwner {
    // only to be used if someone tries to exploit our on-chain token price lookup.
    isBlacklistedFromPrizes[_user] = isBlacklisted;
  }

  function setTeamFeeReciever(address payable _teamFeeReceiver) public onlyApprovedOwner {
    teamFeeReceiver = _teamFeeReceiver;
  }

  function setStakingFeeReceiver(address payable _stakingFeeReceiver) public onlyApprovedOwner {
    stakingFeeReceiver = _stakingFeeReceiver;
  }

  function setEntryPriceUSDT(uint16 _entryPriceUSDT) public onlyApprovedOwner {
    require(_entryPriceUSDT > 0, 'must be a value higher than 0');
    ENTRY_PRICE_USDT = _entryPriceUSDT * 10**6;
  }

  function setEthEntryPriceIncreasePercentage(uint16 _ethEntryPriceIncreasePercentage) public onlyApprovedOwner {
    require(_ethEntryPriceIncreasePercentage > 0, 'must be a value higher than 0');
    ETH_ENTRY_PRICE_INCREASE_PERCENTAGE = _ethEntryPriceIncreasePercentage;
  }

  // RESCUE ------------------------------------------------------------------
  /**
   * @dev rescues eth from contract
   */
  function rescueEth() public onlyApprovedOwner {
    (bool success,) = owner().call{value: address(this).balance}("");
    require(success);
  }

  /**
   * @dev rescues erc20 tokens sent directly to vault
   */
  function rescueERC20(address token, uint256 amount) public onlyApprovedOwner {
    IERC20(token).transfer(owner(), amount);
  }

  function ethRequiredForUSD(uint256 _numEntries) public view returns (uint256) {
    (,int price,,,) = usdToEthDataFeed.latestRoundData();
    require(price > 0, "Invalid ETH price");
    uint256 ENTRY_ETH_PRICE_USDT = ENTRY_PRICE_USDT * (100 + ETH_ENTRY_PRICE_INCREASE_PERCENTAGE) / 100;
    uint256 usdAmount = ENTRY_ETH_PRICE_USDT * _numEntries;
    return usdAmount.mul(1e18).div(uint256(price));
  }

  /**
   * @dev calculates how many tokens are needed for _numEntries
   */
  function getEntryPrice(uint256 _numEntries, address tokenAddress) public view returns (uint256) {
    address[] memory tokenWethUsdtPath = new address[](3);
    tokenWethUsdtPath[0] = tokenAddress;
    tokenWethUsdtPath[1] = WETH_ADDRESS;
    tokenWethUsdtPath[2] = USDT_ADDRESS;

    return uniswapV2Router.getAmountsIn(ENTRY_PRICE_USDT * _numEntries, tokenWethUsdtPath)[0];
  }

  function burnEntriesCheck(uint16 _numEntries) internal view returns (uint256){
    address sender = msg.sender;

    entryCondition();

    require(tx.origin == sender, "no contracts"); // prevent bots
    require(!lockBurnEntries, "no burn");
    require(!lockInitiateDrawing, "in progress");
    require(!isBlacklistedFromPrizes[sender], "shoo");

    uint256 _allEntries;

    if(includeFreeEntries){
      uint256 _freeEntries = _numEntries / 5;
      _allEntries = _numEntries + _freeEntries;
    } else {
      _allEntries = _numEntries;
    }

    if(!includeFreeEntriesWithMaxEntries)
      require(_numEntries <= maxEntriesPerTx, "tx limit");
    else
      require(_allEntries <= maxEntriesPerTx, "tx limit");
    return _allEntries;
  }

  function afterBurnAddEntries(uint256 amountInMin, uint256 _allEntries) internal {
    address sender = msg.sender;
    amountBurned[sender] += amountInMin;
    uint i;
    for (;i < _allEntries;) {
        addEntry(sender);
        unchecked {++i;}
    }
    emit BurnedEntries(sender, _allEntries);
  }

  function entryCondition() internal view virtual {}

  function addEntry(address sender) internal virtual {}

  function getRandomEntryIndex(uint256 randomness, uint32 i, uint256 total) internal pure returns (uint256) {
    require(total > 0, "No entries available");

    uint256 simulatedRandomness = uint256(keccak256(abi.encode(randomness, i)));
    uint256 index = simulatedRandomness % total;

    return index;
  }


  /**
   * @dev returns max tokens _user can burn at once
   */
  function getMaxBurnableEntries(address _user, address burnTokenAddress) public view returns (uint16) {
    if (isBlacklistedFromPrizes[_user]) {
      return 0;
    }
    address[] memory tokenWethUsdtPath = new address[](3);
    IERC20 burnToken = IERC20(burnTokenAddress);
    tokenWethUsdtPath[0] = burnTokenAddress;
    tokenWethUsdtPath[1] = WETH_ADDRESS;
    tokenWethUsdtPath[2] = USDT_ADDRESS;
    uint256 tokenHoldings = burnToken.balanceOf(_user);
    uint256 usdtOut = uniswapV2Router.getAmountsOut(tokenHoldings, tokenWethUsdtPath)[2];
    uint16 numEntries = uint16(usdtOut / ENTRY_PRICE_USDT);
    if (numEntries > maxEntriesPerTx) {
        numEntries = maxEntriesPerTx;
    }
    return numEntries;
  }

  function enterWithBUBU(uint16 _numEntries, address _affiliates) public {
    address sender = msg.sender;
    uint256 _allEntries = burnEntriesCheck(_numEntries);

    // transfer entry amount
    uint256 amountInMin = getEntryPrice(_numEntries, address(bubuToken));

    if (_affiliates != address(0) && _affiliates != sender) {
      bubuAccounting.affiliates > 0 && bubuToken.transferFrom(sender, _affiliates, amountInMin * bubuAccounting.affiliates/100);
      bubuAccounting.staking > 0 && bubuToken.transferFrom(sender, stakingFeeReceiver, amountInMin * bubuAccounting.staking/100);
      bubuAccounting.team > 0 && bubuToken.transferFrom(sender, teamFeeReceiver, amountInMin * bubuAccounting.team/100);
    } else {
      (bubuAccounting.affiliates > 0 || bubuAccounting.team > 0) && bubuToken.transferFrom(sender, teamFeeReceiver, amountInMin * (bubuAccounting.affiliates + bubuAccounting.team)/100);
      bubuAccounting.staking > 0 && bubuToken.transferFrom(sender, stakingFeeReceiver, amountInMin * bubuAccounting.staking/100);
    }

    uint256 remainder = 100 - (bubuAccounting.affiliates + bubuAccounting.staking + bubuAccounting.team);

    if(remainder > 0){
      bubuToken.transferFrom(sender, address(this), amountInMin * remainder/100);
    }

    afterBurnAddEntries(amountInMin, _allEntries);
  }

  function enterWithDUDU(uint16 _numEntries, address _affiliates) public {
    address sender = msg.sender;
    uint256 _allEntries = burnEntriesCheck(_numEntries);

    // transfer entry amount
    uint256 amountInMin = getEntryPrice(_numEntries, address(duduToken));
    duduAccounting.burn > 0 && duduToken.transferFrom(sender, DEAD_ADDRESS, amountInMin * duduAccounting.burn/100);

    if (_affiliates != address(0) && _affiliates != sender) {
      duduAccounting.affiliates > 0 && duduToken.transferFrom(sender, _affiliates, amountInMin * duduAccounting.affiliates/100);
      duduAccounting.staking > 0 && duduToken.transferFrom(sender, stakingFeeReceiver, amountInMin * duduAccounting.staking/100);
      duduAccounting.team > 0 && duduToken.transferFrom(sender, teamFeeReceiver, amountInMin * duduAccounting.team/100);
    } else {
      (duduAccounting.affiliates > 0 || duduAccounting.team > 0) && duduToken.transferFrom(sender, teamFeeReceiver, amountInMin * (duduAccounting.affiliates + duduAccounting.team)/100);
      duduAccounting.staking > 0 && duduToken.transferFrom(sender, stakingFeeReceiver, amountInMin * duduAccounting.staking/100);
    }

     uint256 remainder = 100 - (duduAccounting.affiliates + duduAccounting.staking + duduAccounting.team + duduAccounting.burn);

    if(remainder > 0){
      duduToken.transferFrom(sender, address(this), amountInMin * remainder/100);
    }

    afterBurnAddEntries(amountInMin, _allEntries);
  }

  function enterWithEth(uint16 _numEntries, address payable _affiliates) public payable {
    address sender = msg.sender;
    uint256 _allEntries = burnEntriesCheck(_numEntries);
    uint256 amountInMin = ethRequiredForUSD(_numEntries);

    require(msg.value >= amountInMin, "Incorrect Ether sent!");

    if (_affiliates != address(0) && _affiliates != sender) {
      if(ethAccounting.affiliates > 0) _affiliates.transfer(msg.value * ethAccounting.affiliates/100);
      if(ethAccounting.team > 0) teamFeeReceiver.transfer(msg.value * ethAccounting.team/100);
    } else {
      if(ethAccounting.team > 0 || ethAccounting.affiliates > 0) teamFeeReceiver.transfer(msg.value * (ethAccounting.team + ethAccounting.affiliates)/100);
    }

    if(ethAccounting.staking > 0) stakingFeeReceiver.transfer(msg.value * ethAccounting.staking/100);
    afterBurnAddEntries(msg.value, _allEntries);
  }

    function setBubuAccounting(uint256 affiliates, uint256 team, uint256 staking) public onlyApprovedOwner {
    bubuAccounting = BubuAccounting({
      affiliates: affiliates,
      team: team,
      staking: staking
    });
  }

  function setDuduAccounting(uint256 affiliates, uint256 team, uint256 staking, uint256 burn) public onlyApprovedOwner {
    duduAccounting = DuduAccounting({
      affiliates: affiliates,
      team: team,
      staking: staking,
      burn: burn
    });
  }

  function setEthAccounting(uint256 affiliates, uint256 team, uint256 staking) public onlyApprovedOwner {
    ethAccounting = EthAccounting({
      team: team,
      staking: staking,
      affiliates: affiliates
    });
  }

}

// File: contracts/prod/Games.sol


pragma solidity ^0.8.9;








contract GuessTheNft is BaseContract {
    using SafeMath for uint256;

    struct GameToken {
        uint256 tokenId;
        address owner;
    }

    // Token counter to assign unique IDs
    uint256 private tokenCounter = 0;

    // Mapping from token ID to the GameToken data
    mapping(uint256 => GameToken) public tokens;

    // Mapping from user's address to a list of their token IDs
    mapping(address => uint256[]) public userTokenIds;

    // Events
    event TokenPurchased(address indexed user, uint256 tokenId);

    // Setting the contract deployer as the owner
    constructor(
        address _bubuToken,
        address _duduToken,
        address _teamFeeReceiver,
        address _stakingFeeReceiver
    ) BaseContract(_bubuToken, _duduToken, _teamFeeReceiver, _stakingFeeReceiver) {

        // Entry price for supported tokens and eth (also has setter functions)
        ENTRY_PRICE_USDT = 20 * 10**6; // 20 usdt;
        ETH_ENTRY_PRICE_INCREASE_PERCENTAGE = 20; // 20%

        bubuAccounting = BubuAccounting({
            affiliates: 10,
            team: 10,
            staking: 0
        });

        duduAccounting = DuduAccounting({
            affiliates: 10,
            team: 10,
            staking: 0,
            burn: 0
        });

        ethAccounting = EthAccounting({
            team: 10,
            staking: 0,
            affiliates: 10
        });
    }

    /**
     * @dev Award winners - contract balance of ETH,DUDU and BUBU splits up to X equal portions and gets sent out to the addresses provided.
     */
    function awardWinners(address[] memory recipients) external onlyApprovedOwner {
        require(recipients.length > 0, "Recipients array is empty");

        uint256 ethBalance = address(this).balance;
        uint256 bubuBalance = bubuToken.balanceOf(address(this));
        uint256 duduBalance = duduToken.balanceOf(address(this));

        uint256 ethPortion = ethBalance / recipients.length;
        uint256 bubuPortion = bubuBalance / recipients.length;
        uint256 duduPortion = duduBalance / recipients.length;

        for (uint i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(ethPortion);
            require(
                bubuToken.transfer(recipients[i], bubuPortion),
                "BUBU transfer failed"
            );
            require(
                duduToken.transfer(recipients[i], duduPortion),
                "DUDU transfer failed"
            );
        }
    }

    function addEntry(address sender) internal override {
        uint256 newTokenId = generateUniqueTokenId();
        GameToken memory newToken = GameToken(newTokenId, sender);
        tokens[newTokenId] = newToken;
        userTokenIds[sender].push(newTokenId);

        emit TokenPurchased(sender, newTokenId);
    }

    /**
     * @dev  Generate a unique ID based on block timestamp and the current address
     */
    function generateUniqueTokenId() private returns (uint256) {
        uint256 uniqueId = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, address(this), tokenCounter)
            )
        );
        tokenCounter++; // Increment the counter
        return uniqueId;
    }

    /**
     * @dev returns all game tokens owned by the address passed in
     */
    function getTokensOfUser(
        address userAddress
    ) public view returns (GameToken[] memory) {
        uint256[] memory tokenIds = userTokenIds[userAddress];
        GameToken[] memory userTokens = new GameToken[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            userTokens[i] = tokens[tokenIds[i]];
        }

        return userTokens;
    }

    /**
     * @dev returns the prize pool of the contracts current holdings in ETH, DUDU and BUBU
     */
    function getPrizePool() public view returns (uint256[3] memory) {
        uint256 ethBalance = address(this).balance;
        uint256 duduBalance = duduToken.balanceOf(address(this));
        uint256 bubuBalance = bubuToken.balanceOf(address(this));

        return [ethBalance, duduBalance, bubuBalance];
    }
}