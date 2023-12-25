// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LowLevelERC20Transfer.sol";
import "./ITransferManager.sol";
import "./ERC20.sol";
import "./IERC4626.sol";

import "./IStakingRewards.sol";

/**
 * @title WrappedLooksRareToken
 * @notice WrappedLooksRareToken is a LOOKS wrapper that is used for staking and auto-compounding.
 * @author LooksRare protocol team (👀,💎)
 */
contract WrappedLooksRareToken is ERC20, LowLevelERC20Transfer {
    /**
     * @notice The cooldown period for unwrap requests.
     */
    uint256 public constant UNWRAP_REQUEST_COOLDOWN = 1 weeks;

    /**
     * @notice The amount after fee for instant unwrap in basis points.
     */
    uint256 public constant INSTANT_UNWRAP_AMOUNT_AFTER_FEE_IN_BASIS_POINTS = 9_500;

    /**
     * @notice The LOOKS token address.
     */
    address public immutable LOOKS;

    /**
     * @notice The transfer manager to handle LOOKS approvals and transfers.
     */
    ITransferManager public immutable TRANSFER_MANAGER;

    /**
     * @dev The deployer of the contract. Only used for initialization.
     */
    address private immutable DEPLOYER;

    /**
     * @notice A unwrap request.
     * @param amount The amount of LOOKS to unwrap.
     * @param timestamp The timestamp of the unwrap request.
     */
    struct UnwrapRequest {
        uint216 amount;
        uint40 timestamp;
    }

    mapping(address requester => UnwrapRequest) public unwrapRequests;

    /**
     * @notice The staking rewards contract.
     */
    IStakingRewards public stakingRewards;

    /**
     * @notice The auto-compounder contract.
     */
    IERC4626 public autoCompounder;

    /**
     * @notice Whether the contract has been initialized. Initialize cannot be called twice.
     */
    bool private initialized;

    event Wrapped(address indexed wrapper, uint256 amount);
    event Initialized(address _stakingRewards, address _autoCompounder);
    event Staked(address indexed staker, uint256 amount);
    event AutoCompounded(address indexed staker, uint256 amount);
    event UnwrapRequestSubmitted(address indexed requester, uint256 amount);
    event UnwrapRequestCancelled(address indexed requester, uint256 amount);
    event UnwrapRequestCompleted(address indexed requester, uint256 amount);
    event InstantUnwrap(address indexed requester, uint256 amount);

    error WrappedLooksRareToken__AlreadyInitialized();
    error WrappedLooksRareToken__InsufficientBalance();
    error WrappedLooksRareToken__InvalidAddress();
    error WrappedLooksRareToken__NoUnwrapRequest();
    error WrappedLooksRareToken__OngoingUnwrapRequest();
    error WrappedLooksRareToken__TooEarlyToCompleteUnwrapRequest();
    error WrappedLooksRareToken__Unauthorized();

    /**
     * @param looks LooksRare token
     * @param transferManager Transfer manager
     */
    constructor(address looks, address transferManager) ERC20("Wrapped LooksRare Token", "wLOOKS") {
        LOOKS = looks;
        TRANSFER_MANAGER = ITransferManager(transferManager);
        DEPLOYER = msg.sender;
    }

    /**
     * @notice Set staking rewards and auto-compounder. Can only be called once.
     * @param _stakingRewards Staking rewards
     * @param _autoCompounder Auto-compounder
     */
    function initialize(address _stakingRewards, address _autoCompounder) external {
        if (msg.sender != DEPLOYER) {
            revert WrappedLooksRareToken__Unauthorized();
        }

        if (initialized) {
            revert WrappedLooksRareToken__AlreadyInitialized();
        }

        initialized = true;

        stakingRewards = IStakingRewards(_stakingRewards);
        autoCompounder = IERC4626(_autoCompounder);

        emit Initialized(_stakingRewards, _autoCompounder);
    }

    /**
     * @notice Wrap LOOKS to receive wLOOKS
     * @param amount Wrap amount
     */
    function wrap(uint256 amount) external {
        TRANSFER_MANAGER.transferERC20(LOOKS, msg.sender, address(this), amount);
        _mint(msg.sender, amount);

        emit Wrapped(msg.sender, amount);
    }

    /**
     * @notice Wrap LOOKS and deposit wLOOKS straight into StakingRewards
     * @param amount Wrap amount
     */
    function wrapAndStake(uint256 amount) external {
        TRANSFER_MANAGER.transferERC20(LOOKS, msg.sender, address(this), amount);
        _mint(address(this), amount);
        _approve(address(this), address(stakingRewards), amount);
        stakingRewards.stakeOnBehalf(amount, msg.sender);

        emit Staked(msg.sender, amount);
    }

    /**
     * @notice Wrap LOOKS and deposit wLOOKS straight into AutoCompounder
     * @param amount Wrap amount
     */
    function wrapAndAutoCompound(uint256 amount) external {
        TRANSFER_MANAGER.transferERC20(LOOKS, msg.sender, address(this), amount);
        _mint(address(this), amount);
        _approve(address(this), address(autoCompounder), amount);
        autoCompounder.deposit(amount, msg.sender);

        emit AutoCompounded(msg.sender, amount);
    }

    /**
     * @notice Submit unwrap request
     * @param amount Unwrap amount
     */
    function submitUnwrapRequest(uint216 amount) external {
        if (balanceOf(msg.sender) < amount) {
            revert WrappedLooksRareToken__InsufficientBalance();
        }

        if (unwrapRequests[msg.sender].timestamp != 0) {
            revert WrappedLooksRareToken__OngoingUnwrapRequest();
        }

        _burn(msg.sender, amount);

        unwrapRequests[msg.sender] = UnwrapRequest({amount: amount, timestamp: uint40(block.timestamp)});

        emit UnwrapRequestSubmitted(msg.sender, amount);
    }

    /**
     * @notice Complete unwrap request to receive LOOKS
     */
    function completeUnwrapRequest() external {
        uint256 requestedAt = unwrapRequests[msg.sender].timestamp;
        if (requestedAt == 0) {
            revert WrappedLooksRareToken__NoUnwrapRequest();
        }

        unchecked {
            if (requestedAt + UNWRAP_REQUEST_COOLDOWN > block.timestamp) {
                revert WrappedLooksRareToken__TooEarlyToCompleteUnwrapRequest();
            }
        }

        uint256 amount = unwrapRequests[msg.sender].amount;

        unwrapRequests[msg.sender].amount = 0;
        unwrapRequests[msg.sender].timestamp = 0;

        _executeERC20DirectTransfer(LOOKS, msg.sender, amount);

        emit UnwrapRequestCompleted(msg.sender, amount);
    }

    /**
     * @notice Cancel unwrap request and get back wLOOKS
     */
    function cancelUnwrapRequest() external {
        uint256 requestedAt = unwrapRequests[msg.sender].timestamp;
        if (requestedAt == 0) {
            revert WrappedLooksRareToken__NoUnwrapRequest();
        }

        uint256 amount = unwrapRequests[msg.sender].amount;

        unwrapRequests[msg.sender].amount = 0;
        unwrapRequests[msg.sender].timestamp = 0;

        _mint(msg.sender, amount);

        emit UnwrapRequestCancelled(msg.sender, amount);
    }

    /**
     * @notice Unwrap LOOKS instantly. 5% of the unwrap amount is burned.
     * @param amount Unwrap amount
     */
    function instantUnwrap(uint256 amount) external {
        if (balanceOf(msg.sender) < amount) {
            revert WrappedLooksRareToken__InsufficientBalance();
        }

        _burn(msg.sender, amount);

        uint256 transferAmount = (amount * INSTANT_UNWRAP_AMOUNT_AFTER_FEE_IN_BASIS_POINTS) / 10_000;
        _executeERC20DirectTransfer(LOOKS, msg.sender, transferAmount);
        unchecked {
            _executeERC20DirectTransfer(LOOKS, 0x000000000000000000000000000000000000dEaD, amount - transferAmount);
        }

        emit InstantUnwrap(msg.sender, amount);
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        if (to == address(this)) {
            revert WrappedLooksRareToken__InvalidAddress();
        }
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        if (to == address(this)) {
            revert WrappedLooksRareToken__InvalidAddress();
        }
        return super.transferFrom(from, to, value);
    }
}
