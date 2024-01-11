// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

/// Thrown when a caller is not an owner
error NotAnOwner(address caller);

/// Thown when address(0) is encountered
error ZeroAddress();

/// Thrown when amount exceeds ticketsAvailable
error AmountExceedsTicketsAvailable(uint256 amount, uint256 ticketsAvailable);

/// Thrown when amount exceeds balance
error InsufficientBalance(uint256 amount, uint256 balance);

/// Thrown when amount exceeds allowance
error InsufficientAllowance(uint256 amount, uint256 allowance);

/// Thrown when purchase is prohibited in phase
error PurchaseProhibited(uint256 phase);

/// Thrown when amount is below the minimum purchase amount
error InsufficientAmount(uint256 amount, uint256 minimum);

/// Thrown when the user is not whitelisted
error NotWhitelisted(address user);

/// Thrown when removal is prohibited in phase
error RemovalProhibited(uint256 phase);

/*
 * Allow users to purchase outputToken using inputToken via the medium of tickets
 * Purchasing tickets with the inputToken is mediated by the INPUT_RATE and
 * withdrawing tickets for the outputToken is mediated by the OUTPUT_RATE
 * 
 * Purchasing occurs over 2 purchase phases:
 *  1: purchases are limited to whitelisted addresses
 *  2: purchases are open to any address
 * 
 * Withdrawals of tokens equivalent in value to purchased tickets occurs immediately
 * upon completion of purchase transaction
 */
contract PublicPresale is Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * Purchase phase determines ticket purchase eligiblity
     *  0: is the default on contract creation
     *     purchases are prohibited
     *  1: manually set by the owner
     *     purchases are limited to whitelisted addresses
     *  2: begins automatically PURCHASE_PHASE_DURATION after the start of WhitelistOnly
     *     purchases are open to any address
     */
    enum PurchasePhase {
        NoPurchase,
        WhitelistOnly,
        Purchase
    }

    /// Maximum number of tickets available for purchase at the start of the sale
    uint256 public constant TICKET_MAX = 2000;

    /// Minimum number of tickets that can be purchased at a time
    uint256 public constant MINIMUM_TICKET_PURCHASE = 1;

    /// Unsold tickets available for purchase
    /// ticketsAvailable = TICKET_MAX - (sum(user.purchased) for user in whitelist)
    /// where user.purchased is in range [0, user.maxTicket] for user in whitelist
    uint256 public ticketsAvailable;

    /// Token exchanged to purchase tickets, i.e. USDC
    IERC20 public inputToken;

    /// Number of tickets a user gets per `inputToken`
    uint256 public INPUT_RATE;

    /// Token being sold in presale and redeemable by exchanging tickets, i.e. HELIX
    IERC20 public outputToken;

    /// Number of `outputTokens` a user gets per ticket
    uint256 public OUTPUT_RATE;

    /// Number of decimals on the `inputToken` used for calculating ticket exchange rates
    uint256 public constant INPUT_TOKEN_DECIMALS = 1e6;

    /// Number of decimals on the `outputToken` used for calculating ticket exchange rates
    uint256 public constant OUTPUT_TOKEN_DECIMALS = 1e18;

    /// Address that receives `inputToken`s sold in exchange for tickets
    address public treasury;

    /// Current PurchasePhase
    PurchasePhase public purchasePhase;

    /// Length of purchase phases > 0 (in seconds), 86400 == 1 day
    uint256 public immutable PURCHASE_PHASE_DURATION;

    /// Timestamp after which the current PurchasePhase has ended
    uint256 public purchasePhaseEndTimestamp;

    /// Owners who can whitelist users
    address[] public owners;

    /// true if address is an owner and false otherwise
    mapping(address => bool) public isOwner;

    /// true if user can purchase tickets during WhitelistOnly PurchasePhase and false otherwise
    mapping(address => bool) public whitelist;

    /// Emitted when a user purchases amount of tickets
    event Purchased(address indexed user, uint256 amount);

    /// Emitted when an owner burns amount of tickets
    event Burned(uint256 amount);

    /// Emitted when a user withdraws amount of tickets
    event Withdrawn(address indexed user, uint256 amount);

    /// Emitted when an existing owner adds a new owner
    event OwnerAdded(address indexed owner, address indexed newOwner);

    /// Emitted when the purchase phase is set
    event SetPurchasePhase(
        PurchasePhase purchasePhase, 
        uint256 startTimestamp, 
        uint256 endTimestamp
    );

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotAnOwner(msg.sender);
        _;
    }

    modifier onlyValidAddress(address _address) {
        if (_address == address(0)) revert ZeroAddress();
        _;
    }

    modifier onlyValidAmount(uint256 _amount) {
        if (_amount > ticketsAvailable) {
            revert AmountExceedsTicketsAvailable(_amount, ticketsAvailable);
        }
        _;
    }

    constructor(
        address _inputToken,
        address _outputToken, 
        address _treasury,
        uint256 _INPUT_RATE, 
        uint256 _OUTPUT_RATE,
        uint256 _PURCHASE_PHASE_DURATION
    ) 
        onlyValidAddress(_inputToken)
        onlyValidAddress(_outputToken)
        onlyValidAddress(_treasury)
    {
        inputToken = IERC20(_inputToken);
        outputToken = IERC20(_outputToken);

        INPUT_RATE = _INPUT_RATE;
        OUTPUT_RATE = _OUTPUT_RATE;

        treasury = _treasury;

        isOwner[msg.sender] = true;
        owners.push(msg.sender);

        ticketsAvailable = TICKET_MAX;

        PURCHASE_PHASE_DURATION = _PURCHASE_PHASE_DURATION;
    }

    /// Purchase _amount of tickets
    function purchase(uint256 _amount) 
        external 
        whenNotPaused
        nonReentrant 
        onlyValidAmount(_amount) 
    {
        // Want to be in the latest phase
        updatePurchasePhase();
   
        // Proceed only if the purchase is valid
        _validatePurchase(msg.sender, _amount);

        // Update the contract's remaining tickets
        ticketsAvailable -= _amount;
        
        // Get the `inputTokenAmount` in `inputToken` to purchase `amount` of tickets
        uint256 inputTokenAmount = getAmountOut(_amount, inputToken); 

        // Pay for the `amount` of tickets
        uint256 balance = inputToken.balanceOf(msg.sender);
        if (inputTokenAmount > balance) revert InsufficientBalance(inputTokenAmount, balance);
    
        uint256 allowance = inputToken.allowance(msg.sender, address(this));
        if (inputTokenAmount > allowance) {
            revert InsufficientAllowance(inputTokenAmount, allowance);
        }

        // Pay for the tickets by withdrawing inputTokenAmount from caller
        inputToken.safeTransferFrom(msg.sender, treasury, inputTokenAmount);
        
        // Get the amount of tokens caller can purchase for `amount`
        uint256 outputTokenAmount = getAmountOut(_amount, outputToken);
        
        // Transfer `amount` of tickets to caller
        outputToken.safeTransfer(msg.sender, outputTokenAmount);

        emit Purchased(msg.sender, _amount);
    }

    /// Return the address array of registered owners
    function getOwners() external view returns(address[] memory) {
        return owners;
    }

    /// Return true if _amount is removable by owner
    function isRemovable(uint256 _amount) external view onlyOwner returns (bool) {
        return _amount <= ticketsAvailable;
    }

    /// Used to destroy _outputToken equivalant in value to _amount of tickets
    function burn(uint256 _amount) external onlyOwner { 
        _remove(_amount);

        uint256 tokenAmount = getAmountOut(_amount, outputToken);
        outputToken.burn(address(this), tokenAmount);

        emit Burned(_amount);
    }

    /// Used to withdraw _outputToken equivalent in value to _amount of tickets to owner
    function withdraw(uint256 _amount) external onlyOwner {
        _remove(_amount);

        // transfer to `to` the `tokenAmount` equivalent in value to `amount` of tickets
        uint256 tokenAmount = getAmountOut(_amount, outputToken);
        outputToken.safeTransfer(msg.sender, tokenAmount);

        emit Withdrawn(msg.sender, _amount);
    }

    /// Called externally by the owner to manually set the _purchasePhase
    function setPurchasePhase(PurchasePhase _purchasePhase) external onlyOwner {
        _setPurchasePhase(_purchasePhase);
    }

    /// Called externally to grant multiple _users permission to purchase tickets during 
    /// WithdrawOnly phase
    function whitelistAdd(address[] calldata _users) external onlyOwner {
        uint256 length = _users.length;
        for (uint256 i = 0; i < length; i++) {
            address user = _users[i]; 
            whitelist[user] = true;
        }
    }

    /// Revoke permission for _user to purchase tickets
    function whitelistRemove(address _user) external onlyOwner {
        delete whitelist[_user];
    }

    /// Add a new _owner to the contract, only callable by an existing owner
    function addOwner(address _owner) external onlyOwner onlyValidAddress(_owner) {
        if (isOwner[_owner]) return;
        isOwner[_owner] = true;
        owners.push(_owner);

        emit OwnerAdded(msg.sender, _owner);
    }

    // remove an existing owner from the contract, only callable by an owner
    function removeOwner(address owner) external onlyValidAddress(owner) onlyOwner {
        require(isOwner[owner], "VipPresale: NOT AN OWNER");
        isOwner[owner] = false;

        // array remove by swap 
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
            }
        }
    }

    /// Called by the owner to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// Called by the owner to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// Called periodically and, if sufficient time has elapsed, update the PurchasePhase
    function updatePurchasePhase() public {
        if (purchasePhase == PurchasePhase.WhitelistOnly && 
            block.timestamp >= purchasePhaseEndTimestamp
        ) {
            _setPurchasePhase(PurchasePhase.Purchase);
        }
    }

    /// Get _amountOut of _tokenOut for _amountIn of tickets
    function getAmountOut(uint256 _amountIn, IERC20 _tokenOut) 
        public 
        view 
        returns (uint256 amountOut
    ) {
        if (address(_tokenOut) == address(inputToken)) {
            amountOut = _amountIn * INPUT_RATE * INPUT_TOKEN_DECIMALS;
        } else if (address(_tokenOut) == address(outputToken)) {
            amountOut = _amountIn * OUTPUT_RATE * OUTPUT_TOKEN_DECIMALS;
        }
        // else default to 0
    }

    // Called internally to update the _purchasePhase
    function _setPurchasePhase(PurchasePhase _purchasePhase) private {
        purchasePhase = _purchasePhase;
        purchasePhaseEndTimestamp = block.timestamp + PURCHASE_PHASE_DURATION;
        emit SetPurchasePhase(_purchasePhase, block.timestamp, purchasePhaseEndTimestamp);
    }

    // Validate whether _user is eligible to purchase _amount of tickets
    function _validatePurchase(address _user, uint256 _amount) 
        private 
        view 
        onlyValidAddress(_user)
    {
        if (purchasePhase == PurchasePhase.NoPurchase) {
            revert PurchaseProhibited(uint(purchasePhase));
        }
        if (_amount < MINIMUM_TICKET_PURCHASE) {
            revert InsufficientAmount(_amount, MINIMUM_TICKET_PURCHASE);
        }
        if (purchasePhase == PurchasePhase.WhitelistOnly) { 
            if (!whitelist[_user]) revert NotWhitelisted(_user);
        }
    }

    // Used internally to remove _amount of tickets from circulation and transfer an 
    // amount of _outputToken equivalent in value to _amount to owner
    function _remove(uint256 _amount) private onlyValidAmount(_amount) {
        // proceed only if the removal is valid
        // note that only owners can make removals
        if (purchasePhase != PurchasePhase.NoPurchase) {
            revert RemovalProhibited(uint(purchasePhase));
        }

        // decrease the tickets available by the amount being removed
        ticketsAvailable -= _amount;
    }
} 
