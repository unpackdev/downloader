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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/NestXRaffle.sol


pragma solidity ^0.8.0;





contract PhenixRaffle is Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_TICKET_COUNT = 100000;

    mapping(address => bool) public adminMapping;
    uint256 public adminFeePercentage;
    uint256 public adminDiscountedFeePercentage;
    uint256 public adminFeePercentageDenominator;
    address public discountNFTAddress;
    address public adminAddress;
    uint256 public maxRaffleDuration;
    bool public paused;

    enum RaffleStatus {
        OPEN,
        CLAIMED,
        REFUNDED
    }

    struct Entry {
        uint256 raffleId;
        address participant;
        uint256 numberOfTickets;
    }

    struct Pricing {
        uint256 ethTicketPrice;
        uint256 tokenTicketPrice;
        address tokenTicketAddress;
    }

    struct TimeFrame {
        uint256 raffleStartTimestamp;
        uint256 raffleEndTimestamp;
    }

    struct Rewards {
        uint256 ethReward;
        address tokenRewardAddress;
        uint256 tokenReward;
        address[] erc721Addresses;
        uint256[] tokenIds;
    }

    struct Raffle {
        uint256 raffleId;
        Pricing pricing;
        uint256 totalTickets;
        uint256 soldTickets;
        TimeFrame timeFrame;
        Rewards rewards;
        address host;
        address winner;
        uint256 totalCollectedETH;
        uint256 totalCollectedTokens;
        RaffleStatus status;
    }

    Raffle[] public raffles;
    mapping(address => uint256[]) public userRaffles;
    mapping(address => bool) public allowedTokenAddresses;
    mapping(uint256 => Entry[]) public raffleEntries;
    mapping(address => mapping(uint256 => uint256[])) public userRaffleEntries;
    mapping(uint256 => mapping(address => uint256)) public totalEthSpent;
    mapping(uint256 => mapping(address => uint256)) public totalTokensSpent;
    bool public strictCanceling;

    constructor(address _discountNFTAddress, address _adminAddress) {
        adminFeePercentage = 50;
        adminDiscountedFeePercentage = 25;
        adminFeePercentageDenominator = 1000;
        discountNFTAddress = _discountNFTAddress;
        maxRaffleDuration = 2419804; // 4 Weeks
        adminAddress = _adminAddress;
    }

    modifier onlyAdmin() {
        require(
            adminMapping[msg.sender] || msg.sender == owner(),
            "Only admin can call this function."
        );
        _;
    }

    modifier canEnterRaffle(uint256 raffleId) {
        require(
            raffles[raffleId].status == RaffleStatus.OPEN &&
                raffles[raffleId].timeFrame.raffleEndTimestamp >
                block.timestamp &&
                raffles[raffleId].winner == address(0),
            "Cannot Enter Raffle."
        );
        _;
    }

    modifier notPaused() {
        require(!paused, "Paused");
        _;
    }

    function setMaxRaffleDuration(uint256 _seconds) external onlyOwner {
        maxRaffleDuration = _seconds;
    }

    function setAdminStatus(address _address, bool _status) external onlyOwner {
        adminMapping[_address] = _status;
    }

    function setAllowedTokenAddresses(
        address[] calldata _addresses,
        bool status
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowedTokenAddresses[_addresses[i]] = status;
        }
    }

    function setPaused(bool status) external onlyAdmin {
        paused = status;
    }

    function setStrictCancelling(bool status) external onlyAdmin {
        strictCanceling = status;
    }

    function setAdminAddress(address _address) external onlyOwner {
        adminAddress = _address;
    }

    function setAdminFeeSettings(
        uint256 _adminFeePercentage,
        uint256 _adminDiscountFeePercentage,
        uint256 _adminFeePercentageDenominator
    ) external onlyOwner {
        require(
            _adminFeePercentage < _adminFeePercentageDenominator &&
                _adminDiscountFeePercentage < _adminFeePercentageDenominator,
            "Invalid Params"
        );

        adminFeePercentage = _adminFeePercentage;
        adminDiscountedFeePercentage = _adminDiscountFeePercentage;
        adminFeePercentageDenominator = _adminFeePercentageDenominator;
    }

    function setDiscountNFTAddress(
        address _discountNFTAddress
    ) external onlyOwner {
        discountNFTAddress = _discountNFTAddress;
    }

    function createRaffle(
        Pricing memory _pricing,
        uint256 _totalTickets,
        TimeFrame memory _timeFrame,
        Rewards memory _rewards
    ) public payable notPaused {
        require(
            _timeFrame.raffleEndTimestamp.sub(
                _timeFrame.raffleStartTimestamp
            ) <= maxRaffleDuration,
            "Duration too long."
        );
        require(
            (_pricing.tokenTicketAddress == address(0) ||
                allowedTokenAddresses[_pricing.tokenTicketAddress]) &&
                (_rewards.tokenRewardAddress == address(0) ||
                    allowedTokenAddresses[_rewards.tokenRewardAddress]),
            "Token Address not permitted."
        );
        require(
            _rewards.erc721Addresses.length == _rewards.tokenIds.length,
            "ERC721 Address and token ID length must match."
        );

        // Transfer ETH reward to the contract
        if (_rewards.ethReward > 0) {
            require(
                msg.value == _rewards.ethReward,
                "ETH reward amount must match transaction value."
            );
        }

        // Transfer token reward to the contract
        if (_rewards.tokenReward > 0) {
            require(
                _rewards.tokenRewardAddress != address(0),
                "Token address must be set."
            );
            require(
                IERC20(_rewards.tokenRewardAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _rewards.tokenReward
                ),
                "Token transfer failed."
            );
        }

        // Transfer ERC721 rewards to the contract
        if (_rewards.erc721Addresses.length > 0) {
            for (uint256 i = 0; i < _rewards.erc721Addresses.length; i++) {
                require(
                    _rewards.erc721Addresses[i] != address(0),
                    "ERC721 address must be set."
                );
                require(
                    IERC721(_rewards.erc721Addresses[i]).ownerOf(
                        _rewards.tokenIds[i]
                    ) == msg.sender,
                    "ERC721 token not owned by sender."
                );
                IERC721(_rewards.erc721Addresses[i]).transferFrom(
                    msg.sender,
                    address(this),
                    _rewards.tokenIds[i]
                );
            }
        }

        uint256 raffleId = raffles.length;
        userRaffles[msg.sender].push(raffleId);
        raffles.push(
            Raffle({
                raffleId: raffleId,
                pricing: _pricing,
                totalTickets: _totalTickets,
                soldTickets: 0,
                timeFrame: _timeFrame,
                rewards: _rewards,
                host: msg.sender,
                winner: address(0),
                totalCollectedETH: 0,
                totalCollectedTokens: 0,
                status: RaffleStatus.OPEN
            })
        );
    }

    function addTicketsToRaffle(
        uint256 _raffleId,
        uint256 _numTickets,
        address _participant
    ) external onlyAdmin {
        _addTicketsToRaffle(_raffleId, _numTickets, _participant);
    }

    function _addTicketsToRaffle(
        uint256 _raffleId,
        uint256 _numTickets,
        address _participant
    ) internal {
        // Check that the raffle is open for entries
        require(_numTickets > 0, "One or more tickets required.");
        require(
            _participant != raffles[_raffleId].host,
            "Host cannot participate."
        );

        require(
            block.timestamp <= raffles[_raffleId].timeFrame.raffleEndTimestamp,
            "Raffle no longer accepting entries."
        );

        require(
            raffles[_raffleId].totalTickets == 0 ||
                raffles[_raffleId].soldTickets.add(_numTickets) <=
                raffles[_raffleId].totalTickets,
            "Not enough tickets available for purchase."
        );

        // Add entry to raffle entries array
        userRaffleEntries[_participant][_raffleId].push(
            raffleEntries[_raffleId].length
        );
        raffleEntries[_raffleId].push(
            Entry({
                raffleId: _raffleId,
                participant: _participant,
                numberOfTickets: _numTickets
            })
        );

        // Update raffle sold tickets
        raffles[_raffleId].soldTickets = raffles[_raffleId].soldTickets.add(
            _numTickets
        );
    }

    function _getAdminFeeNumerator(
        address _userAddress
    ) internal view returns (uint256) {
        if (
            discountNFTAddress != address(0) &&
            IERC721(discountNFTAddress).balanceOf(_userAddress) > 0
        ) {
            return adminDiscountedFeePercentage;
        }

        return adminFeePercentage;
    }

    function buyTicketsWithEth(
        uint256 _raffleId,
        uint256 _numTickets
    ) external payable notPaused canEnterRaffle(_raffleId) {
        require(
            raffles[_raffleId].pricing.ethTicketPrice > 0,
            "ETH ticket price not set for this raffle."
        );
        require(
            msg.value ==
                raffles[_raffleId].pricing.ethTicketPrice.mul(_numTickets),
            "Incorrect amount of ETH sent."
        );

        _addTicketsToRaffle(_raffleId, _numTickets, msg.sender);

        raffles[_raffleId].totalCollectedETH = raffles[_raffleId]
            .totalCollectedETH
            .add(msg.value);

        totalEthSpent[_raffleId][msg.sender] = totalEthSpent[_raffleId][
            msg.sender
        ].add(msg.value);
    }

    function buyTicketsWithTokens(
        uint256 _raffleId,
        uint256 _numTickets
    ) external notPaused canEnterRaffle(_raffleId) {
        require(
            raffles[_raffleId].pricing.tokenTicketPrice > 0,
            "Token ticket price not set for this raffle."
        );

        uint256 totalTokens = raffles[_raffleId].pricing.tokenTicketPrice.mul(
            _numTickets
        );

        // Transfer tokens from participant to contract
        require(
            IERC20(raffles[_raffleId].pricing.tokenTicketAddress).transferFrom(
                msg.sender,
                address(this),
                totalTokens
            ),
            "Token transfer failed."
        );

        _addTicketsToRaffle(_raffleId, _numTickets, msg.sender);

        raffles[_raffleId].totalCollectedTokens = raffles[_raffleId]
            .totalCollectedTokens
            .add(totalTokens);

        totalTokensSpent[_raffleId][msg.sender] = totalTokensSpent[_raffleId][
            msg.sender
        ].add(totalTokens);
    }

    function _distributeFees(uint256 _raffleId) internal {
        uint256 _adminFeePercentage = _getAdminFeeNumerator(msg.sender);

        // Distribute ETH fees
        if (
            _adminFeePercentage > 0 && raffles[_raffleId].totalCollectedETH > 0
        ) {
            uint256 adminFeeETH = raffles[_raffleId]
                .totalCollectedETH
                .mul(_adminFeePercentage)
                .div(adminFeePercentageDenominator);
            (bool sent, ) = payable(adminAddress).call{value: adminFeeETH}("");
            require(sent, "Failed to send ETH admin fee.");
            (bool sentHost, ) = payable(raffles[_raffleId].host).call{
                value: raffles[_raffleId].totalCollectedETH.sub(adminFeeETH)
            }("");
            require(sentHost, "Failed to send ETH to host.");
        }

        // Distribute token fees
        if (
            _adminFeePercentage > 0 &&
            raffles[_raffleId].totalCollectedTokens > 0
        ) {
            uint256 adminFeeTokens = raffles[_raffleId]
                .totalCollectedTokens
                .mul(_adminFeePercentage)
                .div(adminFeePercentageDenominator);
            require(
                IERC20(raffles[_raffleId].pricing.tokenTicketAddress).transfer(
                    adminAddress,
                    adminFeeTokens
                ),
                "Failed to send token admin fee."
            );
            require(
                IERC20(raffles[_raffleId].pricing.tokenTicketAddress).transfer(
                    raffles[_raffleId].host,
                    raffles[_raffleId].totalCollectedTokens.sub(adminFeeTokens)
                ),
                "Failed to send tokens to host."
            );
        }
    }

    function selectWinner(
        uint256 _raffleId,
        address _winner
    ) external onlyAdmin {
        // Check that the raffle is closed or all tickets are sold
        require(
            raffles[_raffleId].soldTickets > 0 &&
                (block.timestamp >
                    raffles[_raffleId].timeFrame.raffleEndTimestamp ||
                    raffles[_raffleId].totalTickets ==
                    raffles[_raffleId].soldTickets),
            "Raffle is not yet closed or no tickets sold."
        );

        require(
            raffles[_raffleId].winner == address(0),
            "Winner has been selected."
        );

        // Set the winner
        raffles[_raffleId].winner = _winner;
    }

    function claimRafflePrize(uint256 _raffleId) external notPaused {
        // Check that the winner has been selected and that the raffle is claimed
        require(
            raffles[_raffleId].winner != address(0),
            "Winner has not been selected."
        );
        require(
            raffles[_raffleId].status == RaffleStatus.OPEN,
            "Prize has already been claimed."
        );

        raffles[_raffleId].status = RaffleStatus.CLAIMED;

        _distributeFees(_raffleId);
        _distributePrizes(_raffleId, raffles[_raffleId].winner);
    }

    function cancelRaffle(uint256 _raffleId) external {
        require(
            (msg.sender == raffles[_raffleId].host ||
                adminMapping[msg.sender] ||
                msg.sender == owner()) &&
                raffles[_raffleId].status == RaffleStatus.OPEN &&
                (!strictCanceling || raffles[_raffleId].soldTickets == 0),
            "Cannot Cancel Raffle"
        );

        raffles[_raffleId].status = RaffleStatus.REFUNDED;
        _distributePrizes(_raffleId, raffles[_raffleId].host);
    }

    function refundTickets(uint256 _raffleId) external {
        require(
            raffles[_raffleId].status == RaffleStatus.REFUNDED,
            "Raffle must be cancelled."
        );

        uint256 ethRefundAmount = totalEthSpent[_raffleId][msg.sender];
        uint256 tokenRefundAmount = totalTokensSpent[_raffleId][msg.sender];

        // Check if there is any ETH to refund
        if (ethRefundAmount > 0) {
            // Update the mapping
            totalEthSpent[_raffleId][msg.sender] = 0;

            // Send the ETH back to the user
            (bool sent, ) = payable(msg.sender).call{value: ethRefundAmount}(
                ""
            );
            require(sent, "Failed to send ETH refund.");
        }

        // Check if there are any tokens to refund
        if (tokenRefundAmount > 0) {
            // Update the mapping
            totalTokensSpent[_raffleId][msg.sender] = 0;

            // Send the tokens back to the user
            require(
                IERC20(raffles[_raffleId].pricing.tokenTicketAddress).transfer(
                    msg.sender,
                    tokenRefundAmount
                ),
                "Failed to send token refund."
            );
        }
    }

    function _distributePrizes(uint256 _raffleId, address _recipient) internal {
        // Send ETH reward
        if (raffles[_raffleId].rewards.ethReward > 0) {
            (bool sent, ) = payable(_recipient).call{
                value: raffles[_raffleId].rewards.ethReward
            }("");
            require(sent, "Failed to send ETH reward.");
        }

        // Send token reward
        if (raffles[_raffleId].rewards.tokenReward > 0) {
            require(
                IERC20(raffles[_raffleId].rewards.tokenRewardAddress).transfer(
                    _recipient,
                    raffles[_raffleId].rewards.tokenReward
                ),
                "Failed to send token reward."
            );
        }

        // Send ERC721 rewards
        for (
            uint256 i = 0;
            i < raffles[_raffleId].rewards.erc721Addresses.length;
            i++
        ) {
            IERC721(raffles[_raffleId].rewards.erc721Addresses[i]).transferFrom(
                    address(this),
                    _recipient,
                    raffles[_raffleId].rewards.tokenIds[i]
                );
        }
    }

    function getRaffles(
        uint256 _startingIndex,
        uint256 _lastIndex
    ) external view returns (Raffle[] memory) {
        if (_startingIndex == 0 && _lastIndex == 0) {
            return raffles;
        }

        uint256 resultLength = _lastIndex - _startingIndex + 1;
        Raffle[] memory result = new Raffle[](resultLength);

        uint256 resultIndex = 0;
        for (
            uint256 i = _startingIndex;
            i <= _lastIndex && i < raffles.length;
            i++
        ) {
            result[resultIndex] = raffles[i];
            resultIndex++;
        }

        return result;
    }

    function getUserRaffles(
        address _address,
        uint256 _startingIndex,
        uint256 _lastIndex
    ) external view returns (Raffle[] memory) {
        uint256 resultLength = 0;

        if (_startingIndex == 0 && _lastIndex == 0) {
            resultLength = userRaffles[_address].length;
            _lastIndex = resultLength;
        } else {
            resultLength = _lastIndex - _startingIndex + 1;
        }

        Raffle[] memory result = new Raffle[](resultLength);

        uint256 resultIndex = 0;
        for (
            uint256 i = _startingIndex;
            i <= _lastIndex && i < userRaffles[_address].length;
            i++
        ) {
            result[resultIndex] = raffles[userRaffles[_address][i]];
            resultIndex++;
        }

        return result;
    }

    function getRaffleEntries(
        uint256 _raffleId,
        uint256 _startingIndex,
        uint256 _lastIndex
    ) external view returns (Entry[] memory) {
        if (_startingIndex == 0 && _lastIndex == 0) {
            return raffleEntries[_raffleId];
        }

        uint256 resultLength = _lastIndex - _startingIndex + 1;
        Entry[] memory result = new Entry[](resultLength);

        uint256 resultIndex = 0;
        Entry[] storage entries = raffleEntries[_raffleId];
        for (
            uint256 i = _startingIndex;
            i <= _lastIndex && i < entries.length;
            i++
        ) {
            result[resultIndex] = entries[i];
            resultIndex++;
        }

        return result;
    }

    function getUserRaffleEntries(
        address _address,
        uint256 _raffleId,
        uint256 _startingIndex,
        uint256 _lastIndex
    ) external view returns (Entry[] memory) {
        uint256 resultLength = 0;

        if (_startingIndex == 0 && _lastIndex == 0) {
            resultLength = userRaffleEntries[_address][_raffleId].length;
            _lastIndex = resultLength;
        } else {
            resultLength = _lastIndex - _startingIndex + 1;
        }

        Entry[] memory result = new Entry[](resultLength);

        uint256 resultIndex = 0;
        for (
            uint256 i = _startingIndex;
            i <= _lastIndex && i < raffles.length;
            i++
        ) {
            result[resultIndex] = raffleEntries[_raffleId][
                userRaffleEntries[_address][_raffleId][i]
            ];

            resultIndex++;
        }

        return result;
    }

    function getRafflesCount() external view returns (uint256) {
        return raffles.length;
    }

    function getRaffleEntryCount(
        uint256 _raffleId
    ) external view returns (uint256) {
        return raffleEntries[_raffleId].length;
    }
}