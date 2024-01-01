// File: interfaces/IDexRouter.sol

pragma solidity ^0.8.0;

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

// File: interfaces/IDexFactory.sol

pragma solidity ^0.8.0;

interface IDexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

// File: libraries/SafeMath.sol

pragma solidity ^0.8.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: interfaces/IERC20.sol

pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// File: interfaces/IERC20Metadata.sol

pragma solidity ^0.8.0;


interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: contracts/Context.sol

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// File: contracts/ERC20.sol

pragma solidity ^0.8.0;




contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
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
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
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
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: interfaces/IOwnable.sol


pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external returns (address);

    function transferOwnership(address recipient) external;

    function acceptOwnership() external;
}

// File: contracts/ConfirmedOwnerWithProposal.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is IOwnable {
    address private s_owner;
    address private s_pendingOwner;

    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);

    constructor(address newOwner, address pendingOwner) {
        require(newOwner != address(0), "Cannot set owner to zero");

        s_owner = newOwner;
        if (pendingOwner != address(0)) {
            _transferOwnership(pendingOwner);
        }
    }

    /**
     * @notice Allows an owner to begin transferring ownership to a new address,
     * pending.
     */
    function transferOwnership(address to) public override onlyOwner {
        _transferOwnership(to);
    }

    /**
     * @notice Allows an ownership transfer to be completed by the recipient.
     */
    function acceptOwnership() external override {
        require(msg.sender == s_pendingOwner, "Must be proposed owner");

        address oldOwner = s_owner;
        s_owner = msg.sender;
        s_pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    /**
     * @notice Get the current owner
     */
    function owner() public view override returns (address) {
        return s_owner;
    }

    /**
     * @notice validate, transfer ownership, and emit relevant events
     */
    function _transferOwnership(address to) private {
        require(to != msg.sender, "Cannot transfer to self");

        s_pendingOwner = to;

        emit OwnershipTransferRequested(s_owner, to);
    }

    /**
     * @notice validate access
     */
    function _validateOwnership() internal view {
        require(msg.sender == s_owner, "Only callable by owner");
    }

    /**
     * @notice Reverts if called by anyone other than the contract owner.
     */
    modifier onlyOwner() {
        _validateOwnership();
        _;
    }
}

// File: contracts/ConfirmedOwner.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
    constructor(
        address newOwner
    ) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// File: interfaces/VRFCoordinatorV2Interface.sol


pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
    /**
     * @notice Get configuration relevant for making requests
     * @return minimumRequestConfirmations global min for request confirmations
     * @return maxGasLimit global max for request gas limit
     * @return s_provingKeyHashes list of registered key hashes
     */
    function getRequestConfig()
        external
        view
        returns (uint16, uint32, bytes32[] memory);

    /**
     * @notice Request a set of random words.
     * @param keyHash - Corresponds to a particular oracle job which uses
     * that key for generating the VRF proof. Different keyHash's have different gas price
     * ceilings, so you can select a specific one to bound your maximum per request cost.
     * @param subId  - The ID of the VRF subscription. Must be funded
     * with the minimum subscription balance required for the selected keyHash.
     * @param minimumRequestConfirmations - How many blocks you'd like the
     * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
     * for why you may want to request more. The acceptable range is
     * [minimumRequestBlockConfirmations, 200].
     * @param callbackGasLimit - How much gas you'd like to receive in your
     * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
     * may be slightly less than this amount because of gas used calling the function
     * (argument decoding etc.), so you may need to request slightly more than you expect
     * to have inside fulfillRandomWords. The acceptable range is
     * [0, maxGasLimit]
     * @param numWords - The number of uint256 random values you'd like to receive
     * in your fulfillRandomWords callback. Note these numbers are expanded in a
     * secure way by the VRFCoordinator from a single random value supplied by the oracle.
     * @return requestId - A unique identifier of the request. Can be used to match
     * a request to a response in fulfillRandomWords.
     */
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);

    /**
     * @notice Create a VRF subscription.
     * @return subId - A unique subscription id.
     * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
     * @dev Note to fund the subscription, use transferAndCall. For example
     * @dev  LINKTOKEN.transferAndCall(
     * @dev    address(COORDINATOR),
     * @dev    amount,
     * @dev    abi.encode(subId));
     */
    function createSubscription() external returns (uint64 subId);

    /**
     * @notice Get a VRF subscription.
     * @param subId - ID of the subscription
     * @return balance - LINK balance of the subscription in juels.
     * @return reqCount - number of requests for this subscription, determines fee tier.
     * @return owner - owner of the subscription.
     * @return consumers - list of consumer address which are able to use this subscription.
     */
    function getSubscription(
        uint64 subId
    )
        external
        view
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers
        );

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @param newOwner - proposed new owner of the subscription
     */
    function requestSubscriptionOwnerTransfer(
        uint64 subId,
        address newOwner
    ) external;

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @dev will revert if original owner of subId has
     * not requested that msg.sender become the new owner.
     */
    function acceptSubscriptionOwnerTransfer(uint64 subId) external;

    /**
     * @notice Add a consumer to a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - New consumer which can use the subscription
     */
    function addConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Remove a consumer from a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - Consumer to remove from the subscription
     */
    function removeConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Cancel a subscription
     * @param subId - ID of the subscription
     * @param to - Where to send the remaining LINK to
     */
    function cancelSubscription(uint64 subId, address to) external;

    /*
     * @notice Check to see if there exists a request commitment consumers
     * for all consumers and keyhashes for a given sub.
     * @param subId - ID of the subscription
     * @return true if there exists at least one unfulfilled request for the subscription, false
     * otherwise.
     */
    function pendingRequestExists(uint64 subId) external view returns (bool);
}

// File: contracts/VRFConsumerBaseV2.sol


pragma solidity ^0.8.4;

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
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
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
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
    error OnlyCoordinatorCanFulfill(address have, address want);
    address private immutable vrfCoordinator;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     */
    constructor(address _vrfCoordinator) {
        vrfCoordinator = _vrfCoordinator;
    }

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomWords the VRF output expanded to the requested number of words
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual;

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}

// File: contracts/TreatToken.sol

/*
 Halloween coin with a lottery system and possibility of winning up to 10x your bet.


https://t.me/HalloweenCerc20

twitter.com/HalloweenCerc20

https://halloweencoinerc20.com



             .
                 //
       _.-"""""'//-'""""-._
     .', ,  , , : : ` ` `  `.
    / , , \'-._ : :_.-'/ ` ` \
   / , ,  :\(_)\  /(_)/ : ` ` \
  | , ,  ,  \__//\\__/ . . ` ` |
  | . .:_  : : '--`: : . _: ; :|
  | : : \\_  _' : _: :__// , , |
   \ ` ` \ \/ \/\/ \_/  / , , /
    \ ` ` \_/\_/\_/\_/\/ , , /
     `._ ` . :  :  :  , , _.'
        `-..............-' 

*/


pragma solidity ^0.8.0;







contract TreatToken is ERC20, VRFConsumerBaseV2, ConfirmedOwner {
    // ======================== VRF ========================
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256 randomWords);

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256 randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests;
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;

    bytes32 keyHash =
        0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805;

    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    uint32 numWords = 1;

    // ======================== GAME STRUCTURE ========================
    struct Game {
        uint256 startTime; // start of the game
        uint256 endBet; //timestamp where they can no longer bet
        uint256 claimBegin; //timestamp from which they can claim
        uint256 claimDuration; //timestamp for claim
        uint256 endClaim; //timestamp up to which they can claim
        uint256 idOfTheGame;
        bool gameHasBegun;
        uint16 numberOfDoor;
        bool doorHasBeenGenerated;
        uint256 totalBets;
        uint256 totalBetDoor1;
        uint256 totalBetDoor2;
        uint256 totalBetDoor3;
        uint256 _multiplicator;
    }

    uint16 public numberOfGame;
    mapping(uint16 => Game) public game;
    mapping(uint16 => uint256) private resultOfGame;

    event Bet(address indexed user, uint256 amount);
    event DoorGeneration(uint256 indexed requestId);
    event DoorGenerated(uint256 indexed requestId, uint256 result);

    // ======================== USER STRUCTURE ========================
    struct User {
        uint256 bet;
        uint256 totalBet;
        uint16 chosenDoor;
        bool openedDoor;
        bool win;
        uint256 earned;
        uint256 totalEarned;
    }

    mapping(address => mapping(uint16 => User)) public userInfos;

    // ======================== TAXES & LIMITS ========================

    mapping(address => bool) public exemptFromFees;
    mapping(address => bool) public exemptFromLimits;

    uint128 public transactionLimit = 26_000e18;
    uint128 public walletLimit = 26_000e18;

    uint48 buyTax = 5;
    uint48 sellTax = 5;
    uint48 earlyTax = 19;

    uint64 public constant FEE_DIVISOR = 100;
    uint256 public _buyCount;
    uint256 public swapTokensAmount = 5000e18;

    // ======================== TOKEN ========================

    uint256 maxTime = type(uint256).max / 2;
    address team;
    uint256 constant _initial_supply = 1000000 * (10 ** 18);
    bool tradingOpen;

    address public lpPair;
    IDexRouter public dexRouter;

    mapping(address => bool) public isAMMPair;

    // ======================== CONSTRUCTOR ========================
    constructor(
        uint64 subscriptionId
    )
        ERC20("Halloween Coin", "TREAT")
        VRFConsumerBaseV2(0x271682DEB8C4E0901D1a1550aD2e64D568E69909)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x271682DEB8C4E0901D1a1550aD2e64D568E69909
        );
        s_subscriptionId = subscriptionId;
        team = msg.sender;
        address _v2Router;

        // UniswapRouter
        _v2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        dexRouter = IDexRouter(_v2Router);
        lpPair = IDexFactory(dexRouter.factory()).createPair(
            address(this),
            dexRouter.WETH()
        );

        isAMMPair[lpPair] = true;

        exemptFromLimits[lpPair] = true;
        exemptFromLimits[msg.sender] = true;
        exemptFromLimits[address(this)] = true;

        exemptFromFees[msg.sender] = true;
        exemptFromFees[address(this)] = true;

        _approve(address(this), address(dexRouter), type(uint256).max);
        _approve(address(msg.sender), address(dexRouter), totalSupply());

        _mint(msg.sender, _initial_supply);
    }

    modifier onlyTeam() {
        require(msg.sender == team);
        _;
    }

    receive() external payable {}

    function setGame(
        uint256 _bettingDuration,
        uint256 _claimingDuration,
        uint16 _numberOfDoor,
        uint256 _multipe
    ) external onlyTeam {
        if (game[numberOfGame].gameHasBegun) {
            require(
                block.timestamp > game[numberOfGame].endClaim,
                "a game is in progress"
            );
            numberOfGame++;
        }
        game[numberOfGame].startTime = block.timestamp;
        game[numberOfGame].endBet = block.timestamp + _bettingDuration;
        game[numberOfGame].claimDuration = _claimingDuration;
        game[numberOfGame].gameHasBegun = true;
        game[numberOfGame].numberOfDoor = _numberOfDoor;
        game[numberOfGame].claimBegin = maxTime;
        game[numberOfGame]._multiplicator = _multipe;
    }

    function placeBet(uint256 _betAmount, uint16 _door) external {
        require(game[numberOfGame].gameHasBegun, "The game hasn't started yet");
        require(block.timestamp < game[numberOfGame].endBet);
        require(
            _door > 0 && _door <= game[numberOfGame].numberOfDoor,
            "please select a valid door"
        );
        if (_door == 1) {
            game[numberOfGame].totalBetDoor1++;
        } else if (_door == 2) {
            game[numberOfGame].totalBetDoor2++;
        } else {
            game[numberOfGame].totalBetDoor3++;
        }
        game[numberOfGame].totalBets++;
        userInfos[msg.sender][numberOfGame].bet = _betAmount;
        userInfos[msg.sender][numberOfGame].totalBet += _betAmount;
        userInfos[msg.sender][numberOfGame].chosenDoor = _door;
        _burn(msg.sender, _betAmount);
        emit Bet(msg.sender, _betAmount);
    }

    function getPercentage() public view returns (uint256, uint256, uint256) {
        require(game[numberOfGame].totalBets > 0, "there are no bets");
        uint256 total = game[numberOfGame].totalBets;
        return (
            (game[numberOfGame].totalBetDoor1 * 100) / total,
            (game[numberOfGame].totalBetDoor2 * 100) / total,
            (game[numberOfGame].totalBetDoor3 * 100) / total
        );
    }

    function generateRandomDoor()
        external
        onlyTeam
        returns (uint256 requestId)
    {
        require(game[numberOfGame].gameHasBegun, "The game hasn't started yet");
        require(
            block.timestamp > game[numberOfGame].endBet,
            "users can still place bets"
        );
        require(
            !game[numberOfGame].doorHasBeenGenerated,
            "the door has already been generated"
        );
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        game[numberOfGame].claimBegin = block.timestamp + 360; // wait 6 minutes
        game[numberOfGame].endClaim =
            game[numberOfGame].claimBegin +
            game[numberOfGame].claimDuration;
        game[numberOfGame].idOfTheGame = requestId;
        game[numberOfGame].doorHasBeenGenerated = true;
        emit DoorGeneration(requestId);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 doorValue = (randomWords[0] % game[numberOfGame].numberOfDoor) +
            1; // value in [1, ..., numberDoor]
        resultOfGame[numberOfGame] = doorValue;
        emit DoorGenerated(requestId, doorValue);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (!exemptFromFees[from] && !exemptFromFees[to]) {
            require(tradingOpen, "Trading is not open yet");
            uint128 tax = 0;
            bool sell;
            //buy
            if (isAMMPair[from]) {
                require(
                    amount <= transactionLimit &&
                        amount + balanceOf(to) <= walletLimit,
                    "amount too high"
                );
                if (_buyCount <= 20) {
                    tax = earlyTax;
                } else {
                    tax = buyTax;
                }
                _buyCount++;
            }
            // sell
            else if (isAMMPair[to]) {
                require(amount <= transactionLimit, "amount too high");
                sell = true;
                if (_buyCount <= 20) {
                    tax = earlyTax;
                } else {
                    tax = sellTax;
                }
            }
            // transfer
            else {
                require(amount + balanceOf(to) <= walletLimit, "Max Wallet");
            }
            uint256 taxAmount = (amount * tax) / FEE_DIVISOR;
            amount -= taxAmount;
            super._transfer(from, address(this), taxAmount);

            if (sell && balanceOf(address(this)) > swapTokensAmount) {
                sendTeamCall();
            }
        }

        super._transfer(from, to, amount);
    }

    function sendTeamCall() private {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(swapTokensAmount);
        uint256 newBalance = address(this).balance - initialETHBalance;
        (bool success, ) = team.call{value: newBalance}("");
    }

    // view the reward before
    function viewResult(uint16 _game) public view returns (uint256) {
        if (block.timestamp > game[_game].endClaim) {
            return resultOfGame[_game];
        } else {
            return 0;
        }
    }

    function openDoor() external {
        require(
            !userInfos[msg.sender][numberOfGame].openedDoor,
            "user has already opened the door"
        );
        require(
            block.timestamp > game[numberOfGame].claimBegin &&
                block.timestamp < game[numberOfGame].endClaim,
            "you can't claim right now"
        );
        userInfos[msg.sender][numberOfGame].openedDoor = true;
        if (
            userInfos[msg.sender][numberOfGame].chosenDoor ==
            resultOfGame[numberOfGame]
        ) {
            uint256 mutiplicator = game[numberOfGame]._multiplicator;
            userInfos[msg.sender][numberOfGame].win = true;
            uint256 _earn = mutiplicator *
                userInfos[msg.sender][numberOfGame].bet;
            userInfos[msg.sender][numberOfGame].earned = _earn;
            userInfos[msg.sender][numberOfGame].totalEarned += _earn;
            _mint(msg.sender, _earn);
        }
    }

    function getResult(
        address _address,
        uint16 _game
    ) public view returns (bool _didWin, uint256 _earned) {
        return (
            userInfos[_address][_game].win,
            userInfos[_address][_game].earned
        );
    }

    // view if a user has already claimed for a given game
    function hasAlreadyClaimed(
        address _user,
        uint16 _gameNumber
    ) public view returns (bool) {
        return userInfos[_user][_gameNumber].openedDoor;
    }

    // view for a given game the amount of a user's bet and the gate chosen
    function getBetAndDoor(
        address _user,
        uint16 _gameNumber
    ) public view returns (uint256, uint256) {
        return (
            userInfos[_user][_gameNumber].bet,
            userInfos[_user][_gameNumber].chosenDoor
        );
    }

    function getStateOfTheGame() public view returns (uint16 _state) {
        if (block.timestamp < game[numberOfGame].endBet) {
            _state = 1;
        } else if (block.timestamp < game[numberOfGame].claimBegin) {
            _state = 2;
        } else if (block.timestamp < game[numberOfGame].endClaim) {
            _state = 3;
        } else {
            _state = 0;
        }
        return _state;
    }

    function updateTaxesFees(uint48 _buy, uint48 _sell) external onlyTeam {
        buyTax = _buy;
        sellTax = _sell;
    }

    function updateSwapTokensAmount(uint256 _newAmount) external onlyTeam {
        swapTokensAmount = _newAmount;
    }

    function enableTrading() external onlyTeam {
        tradingOpen = true;
    }

    function updateLimits(uint128 _tx, uint128 _wallet) external onlyTeam {
        transactionLimit = _tx;
        walletLimit = _wallet;
    }

    function setExemptFromFees(address _address) external onlyTeam {
        exemptFromFees[_address] = true;
    }

    function setExemptFromLimits(address _address) external onlyTeam {
        exemptFromLimits[_address] = true;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        //_approve(address(this), address(dexRouter), tokenAmount);

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapAndSendEmergency(uint256 tokens) external onlyTeam {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = address(this).balance - initialETHBalance;
        (bool success, ) = team.call{value: newBalance}("");
    }
}