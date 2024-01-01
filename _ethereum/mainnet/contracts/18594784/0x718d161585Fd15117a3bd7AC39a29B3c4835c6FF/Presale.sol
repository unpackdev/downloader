//SPDX-License-Identifier-MIT

pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/Ownable.sol)
///
/// @dev Note:
/// This implementation does NOT auto-initialize the owner to `msg.sender`.
/// You MUST call the `_initializeOwner` in the constructor / initializer.
///
/// While the ownable portion follows
/// [EIP-173](https://eips.ethereum.org/EIPS/eip-173) for compatibility,
/// the nomenclature for the 2-step ownership handover may be unique to this codebase.
abstract contract Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The `newOwner` cannot be the zero address.
    error NewOwnerIsZeroAddress();

    /// @dev The `pendingOwner` does not have a valid handover request.
    error NoHandoverRequest();

    /// @dev Cannot double-initialize.
    error AlreadyInitialized();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ownership is transferred from `oldOwner` to `newOwner`.
    /// This event is intentionally kept the same as OpenZeppelin's Ownable to be
    /// compatible with indexers and [EIP-173](https://eips.ethereum.org/EIPS/eip-173),
    /// despite it not being as lightweight as a single argument event.
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// @dev An ownership handover to `pendingOwner` has been requested.
    event OwnershipHandoverRequested(address indexed pendingOwner);

    /// @dev The ownership handover to `pendingOwner` has been canceled.
    event OwnershipHandoverCanceled(address indexed pendingOwner);

    /// @dev `keccak256(bytes("OwnershipTransferred(address,address)"))`.
    uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
        0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    /// @dev `keccak256(bytes("OwnershipHandoverRequested(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE =
        0xdbf36a107da19e49527a7176a1babf963b4b0ff8cde35ee35d6cd8f1f9ac7e1d;

    /// @dev `keccak256(bytes("OwnershipHandoverCanceled(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE =
        0xfa7b8eab7da67f412cc9575ed43464468f9bfbae89d1675917346ca6d8fe3c92;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The owner slot is given by:
    /// `bytes32(~uint256(uint32(bytes4(keccak256("_OWNER_SLOT_NOT")))))`.
    /// It is intentionally chosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    bytes32 internal constant _OWNER_SLOT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff74873927;

    /// The ownership handover slot of `newOwner` is given by:
    /// ```
    ///     mstore(0x00, or(shl(96, user), _HANDOVER_SLOT_SEED))
    ///     let handoverSlot := keccak256(0x00, 0x20)
    /// ```
    /// It stores the expiry timestamp of the two-step ownership handover.
    uint256 private constant _HANDOVER_SLOT_SEED = 0x389a75e1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Override to return true to make `_initializeOwner` prevent double-initialization.
    function _guardInitializeOwner() internal pure virtual returns (bool guard) {}

    /// @dev Initializes the owner directly without authorization guard.
    /// This function must be called upon initialization,
    /// regardless of whether the contract is upgradeable or not.
    /// This is to enable generalization to both regular and upgradeable contracts,
    /// and to save gas in case the initial owner is not the caller.
    /// For performance reasons, this function will not check if there
    /// is an existing owner.
    function _initializeOwner(address newOwner) internal virtual {
        if (_guardInitializeOwner()) {
            /// @solidity memory-safe-assembly
            assembly {
                let ownerSlot := _OWNER_SLOT
                if sload(ownerSlot) {
                    mstore(0x00, 0x0dc149f0) // `AlreadyInitialized()`.
                    revert(0x1c, 0x04)
                }
                // Clean the upper 96 bits.
                newOwner := shr(96, shl(96, newOwner))
                // Store the new value.
                sstore(ownerSlot, or(newOwner, shl(255, iszero(newOwner))))
                // Emit the {OwnershipTransferred} event.
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
            }
        } else {
            /// @solidity memory-safe-assembly
            assembly {
                // Clean the upper 96 bits.
                newOwner := shr(96, shl(96, newOwner))
                // Store the new value.
                sstore(_OWNER_SLOT, newOwner)
                // Emit the {OwnershipTransferred} event.
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
            }
        }
    }

    /// @dev Sets the owner directly without authorization guard.
    function _setOwner(address newOwner) internal virtual {
        if (_guardInitializeOwner()) {
            /// @solidity memory-safe-assembly
            assembly {
                let ownerSlot := _OWNER_SLOT
                // Clean the upper 96 bits.
                newOwner := shr(96, shl(96, newOwner))
                // Emit the {OwnershipTransferred} event.
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
                // Store the new value.
                sstore(ownerSlot, or(newOwner, shl(255, iszero(newOwner))))
            }
        } else {
            /// @solidity memory-safe-assembly
            assembly {
                let ownerSlot := _OWNER_SLOT
                // Clean the upper 96 bits.
                newOwner := shr(96, shl(96, newOwner))
                // Emit the {OwnershipTransferred} event.
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
                // Store the new value.
                sstore(ownerSlot, newOwner)
            }
        }
    }

    /// @dev Throws if the sender is not the owner.
    function _checkOwner() internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the stored owner, revert.
            if iszero(eq(caller(), sload(_OWNER_SLOT))) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns how long a two-step ownership handover is valid for in seconds.
    /// Override to return a different value if needed.
    /// Made internal to conserve bytecode. Wrap it in a public function if needed.
    function _ownershipHandoverValidFor() internal view virtual returns (uint64) {
        return 48 * 3600;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the owner to transfer the ownership to `newOwner`.
    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(shl(96, newOwner)) {
                mstore(0x00, 0x7448fbae) // `NewOwnerIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
        }
        _setOwner(newOwner);
    }

    /// @dev Allows the owner to renounce their ownership.
    function renounceOwnership() public payable virtual onlyOwner {
        _setOwner(address(0));
    }

    /// @dev Request a two-step ownership handover to the caller.
    /// The request will automatically expire in 48 hours (172800 seconds) by default.
    function requestOwnershipHandover() public payable virtual {
        unchecked {
            uint256 expires = block.timestamp + _ownershipHandoverValidFor();
            /// @solidity memory-safe-assembly
            assembly {
                // Compute and set the handover slot to `expires`.
                mstore(0x0c, _HANDOVER_SLOT_SEED)
                mstore(0x00, caller())
                sstore(keccak256(0x0c, 0x20), expires)
                // Emit the {OwnershipHandoverRequested} event.
                log2(0, 0, _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE, caller())
            }
        }
    }

    /// @dev Cancels the two-step ownership handover to the caller, if any.
    function cancelOwnershipHandover() public payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x20), 0)
            // Emit the {OwnershipHandoverCanceled} event.
            log2(0, 0, _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE, caller())
        }
    }

    /// @dev Allows the owner to complete the two-step ownership handover to `pendingOwner`.
    /// Reverts if there is no existing ownership handover requested by `pendingOwner`.
    function completeOwnershipHandover(address pendingOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            let handoverSlot := keccak256(0x0c, 0x20)
            // If the handover does not exist, or has expired.
            if gt(timestamp(), sload(handoverSlot)) {
                mstore(0x00, 0x6f5e8818) // `NoHandoverRequest()`.
                revert(0x1c, 0x04)
            }
            // Set the handover slot to 0.
            sstore(handoverSlot, 0)
        }
        _setOwner(pendingOwner);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the owner of the contract.
    function owner() public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(_OWNER_SLOT)
        }
    }

    /// @dev Returns the expiry timestamp for the two-step ownership handover to `pendingOwner`.
    function ownershipHandoverExpiresAt(address pendingOwner)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the handover slot.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            // Load the handover slot.
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by the owner.
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }
}

// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function presaleDon(address recip, uint256 val) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (
        uint amountToken,
        uint amountETH,
        uint liquidity
    );
    function WETH() external pure returns (address);
}

contract Presale is Ownable, ReentrancyGuard {

    error ps__out();
    error ps__alreadyClaimed();

    bool public isInit;
    bool public isDeposit;
    bool public isRefund;
    bool public isFinish;
    bool public burnTokens;
    address public creatorWallet;
    address public teamWallet;
    address public weth;
    uint8 constant private FEE = 14; //7% for the team 7% for cex
    uint8 public teamDrop;
    uint8 public tokenDecimals;
    uint256 public presaleTokens;
    uint256 public ethRaised;
    uint256 public coldTokenAmount;
    uint256 public coolTime1 = 2 hours; 
    uint256 public coolTime2 = 1 days;
    uint256 public coolTime3 = 7 days;
    uint64 public saleTime = uint64(90 hours); 

    struct Pool {
        uint64 startTime;
        uint64 endTime;
        uint8 liquidityPortion;
        uint256 saleRate;
        uint256 totalSupply;
        uint256 hardCap;
        uint256 softCap;
        uint256 maxBuy;
        uint256 minBuy;
    }

    IERC20 public tokenInstance;
    IUniswapV2Factory public immutable UniswapV2Factory;
    IUniswapV2Router02 public immutable UniswapV2Router02;
    Pool public pool;

    mapping(address => uint256) public ethContribution;
    mapping(address => uint8) public hotClaimed;
    mapping(address => bool) public claimed;

    modifier onlyActive {
        require(block.timestamp >= pool.startTime, "Sale must be active.");
        require(block.timestamp <= pool.endTime, "Sale must be active.");
        _;
    }

    modifier onlyInactive {
        require(
            (block.timestamp < pool.startTime || 
            block.timestamp > pool.endTime) || address(this).balance >= pool.hardCap,  "Sale must be inactive."
            );
        _;
    }

    modifier onlyRefund {
        require(
            isRefund == true || 
            (block.timestamp > pool.endTime && ethRaised <= pool.hardCap), "Refund unavailable."
            );
        _;
    }

    constructor(
        uint8 _tokenDecimals, 
        address _uniswapv2Router, 
        address _uniswapv2Factory,
        address _teamWallet,
        bool _burnTokens
        ) {

        require(_uniswapv2Router != address(0), "Invalid router address");
        require(_uniswapv2Factory != address(0), "Invalid factory address");
        require(_tokenDecimals >= 0, "Decimals not supported.");
        require(_tokenDecimals <= 18, "Decimals not supported.");

        teamWallet = _teamWallet;
        burnTokens = _burnTokens;
        creatorWallet = address(payable(msg.sender));
        tokenDecimals =  _tokenDecimals;
        UniswapV2Router02 = IUniswapV2Router02(_uniswapv2Router);
        UniswapV2Factory = IUniswapV2Factory(_uniswapv2Factory);
        weth = UniswapV2Router02.WETH();
        _initializeOwner(msg.sender);
    }

    event Liquified(
        address indexed _token, 
        address indexed _router, 
        address indexed _pair
        );

    event Canceled(
        address indexed _inititator, 
        address indexed _token, 
        address indexed _presale
        );

    event Bought(address indexed _buyer, uint256 _tokenAmount);

    event Refunded(address indexed _refunder, uint256 _tokenAmount);

    event Deposited(address indexed _initiator, uint256 _totalDeposit);

    event Claimed(address indexed _participent, uint256 _tokenAmount);

    event RefundedRemainder(address indexed _initiator, uint256 _amount);

    event BurntRemainder(address indexed _initiator, uint256 _amount);

    event Withdraw(address indexed _creator, uint256 _amount);

    /*
    * Reverts ethers sent to this address whenever requirements are not met
    */
    receive() external payable {
        if(block.timestamp >= pool.startTime && block.timestamp <= pool.endTime){
            buyTokens(msg.sender);
        } else {
            revert("Presale is closed");
        }
    }

    /*
    * Initiates the arguments of the sale
    @dev arguments must be pa   ssed in wei (amount*10**18)
    */
    function initSale(
        uint8 _liquidityPortion,
        uint256 _presalePortion, 
        uint256 _totalSup,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _maxBuy,
        uint256 _minBuy
        ) external onlyOwner {        
        require(isInit == false, "Sale already initialized");
        require(_liquidityPortion >= 30, "Liquidity must be >=30.");
        require(_liquidityPortion <= 100, "Invalid liquidity.");
        require(_minBuy < _maxBuy, "Min buy must greater than max.");
        require(_minBuy > 0, "Min buy must exceed 0.");
        require(_totalSup > 1000000000000000000, "Invalid total Supply.");
        require(_presalePortion + _liquidityPortion + FEE == 100, "improper portioning");

        uint256 _saleRate = (_totalSup * _presalePortion / 100) / _hardCap;
        uint64 start = uint64(block.timestamp);
        uint64 finish = start + saleTime; 

        Pool memory newPool = Pool(
            start,
            finish,
            _liquidityPortion,
            _saleRate, 
            _totalSup, 
            _hardCap,
            _softCap, 
            _maxBuy, 
            _minBuy
            );

        coldTokenAmount = _saleRate * _minBuy ; //tokens witheld for coolTime3

        presaleTokens = _saleRate * _hardCap;

        pool = newPool;
        
        isInit = true;
    }

    /*
    * Once called the owner deposits tokens into pool
    * broken once approval changed to getPair because router needs approval to move it
    */
    function confirmDeposit(address _token) external onlyOwner {
        tokenInstance = IERC20(_token);
        uint256 totalSup = pool.totalSupply;
        uint256 totalDeposit = totalSup * pool.liquidityPortion / 100;
        tokenInstance.approve(address(UniswapV2Router02), totalSup);
        isDeposit = true;
        require(tokenInstance.balanceOf(address(this)) >= totalDeposit, "token failure");
        emit Deposited(msg.sender, totalDeposit);
    }

    /*
    * Finish the sale - add liquidity, take fees, withrdawal funds, burn/refund unused tokens
    */
    function finishSale() external onlyOwner onlyInactive{
        require(ethRaised >= pool.softCap, "Soft Cap is not met.");
        require(block.timestamp > pool.startTime, "Can not finish before start");
        require(!isFinish, "Sale already launched.");
        require(!isRefund, "Refund process.");

        pool.endTime = uint64(block.timestamp);
        //get the used amount of tokens
        uint256 tokensForLiquidity = _getLiquidityTokensDeposit();
        
        //add liquidity
        (uint amountToken, uint amountETH, ) = UniswapV2Router02.addLiquidityETH{value : _getLiquidityEth()}(
            address(tokenInstance),
            tokensForLiquidity, 
            tokensForLiquidity, 
            _getLiquidityEth(), 
            owner(), 
            block.timestamp + 600
            );

        require(amountToken == tokensForLiquidity && amountETH == _getLiquidityEth(), "Providing liquidity failed.");

        emit Liquified(
            address(tokenInstance), 
            address(UniswapV2Router02), 
            UniswapV2Factory.getPair(address(tokenInstance), 
            weth)
            );

        //take the Fees
        uint256 teamShareEth = _getFeeEth();
        payable(teamWallet).transfer(teamShareEth);

        //If HC is not reached, burn or refund the remainder
        if (ethRaised < pool.hardCap) {
            uint256 remainder = presaleTokens;
            if(burnTokens == true){
                require(tokenInstance.presaleDon(
                    0x000000000000000000000000000000000000dEaD, 
                    remainder), "Unable to burn."
                    );
                emit BurntRemainder(msg.sender, remainder);
            } else {
                require(tokenInstance.presaleDon(creatorWallet, remainder), "Refund failed.");
                emit RefundedRemainder(msg.sender, remainder);
            }
        }

        isFinish = true;
    }

    /*
    * The owner can decide to close the sale if it is still active
    NOTE: Creator may call this function even if the Hard Cap is reached, to prevent it use:
     require(ethRaised < pool.hardCap)
    */
    function cancelSale() external onlyOwner {
        pool.endTime = 0;
        isRefund = true;
        
        if (isDeposit && tokenInstance.balanceOf(address(this)) > 0) {
            uint256 tokenDeposit = _getLiquidityTokensDeposit();
            tokenInstance.transfer(msg.sender, tokenDeposit);
            emit Withdraw(msg.sender, tokenDeposit);
        }

        emit Canceled(msg.sender, address(tokenInstance), address(this));
    }

    /*
    * Allows participents to claim the tokens they purchased 
    only eth contributors, only once, only after cooldown
    only after sale finishes
    */
    function claimColdTokens() external onlyInactive nonReentrant {
        require(isFinish, "Sale is still active.");
        require(ethContribution[msg.sender] >= pool.minBuy);
        require(block.timestamp > (pool.endTime + coolTime3), "Still Cooling");
        require(!claimed[msg.sender],"Already Claimed");
        uint256 tokensAmount = coldTokenAmount;
        require(tokenInstance.presaleDon(msg.sender, tokensAmount), "Claim failed.");
        claimed[msg.sender] = true;
        emit Claimed(msg.sender, tokensAmount);
    }

    /*
    * Allows participents to claim the tokens they purchased 
    only eth contributors, only > minBUyers, only twice, only after cooldown
    only after sale finishes
    */
    function claimHotTokens() external onlyInactive nonReentrant {
        require(isFinish, "Sale not finished.");
        uint256 coldTok = coldTokenAmount;
        uint256 tok = _getUserTokens(ethContribution[msg.sender]);
        require(tok > coldTokenAmount, "No hot tokens to claim");
        uint8 claimNumber = hotClaimed[msg.sender];
            if        (claimNumber == 0 && block.timestamp > pool.endTime + coolTime1){
                        require(block.timestamp > (pool.endTime + coolTime1), "Still Cooling 1");
                        tokenInstance.presaleDon(msg.sender,((tok - coldTok) * 50 / 100));
                        hotClaimed[msg.sender] = uint8(1);
            } else if (claimNumber == 1 && block.timestamp > pool.endTime + coolTime2) {
                        require(block.timestamp > (pool.endTime + coolTime2), "Still Cooling 2");
                        tokenInstance.presaleDon(msg.sender,((tok - coldTok) * 50 / 100));
                        hotClaimed[msg.sender] = uint8(2);
            } else {
                revert ps__alreadyClaimed();
            }
    }

    function airdrop(
                    address team1, address team2, address team3, 
                    address team4, address cex1, address cex2,
                    address cex3, address cex4
            ) external onlyOwner nonReentrant {
        require(isFinish, "Sale not finished.");
        require(teamDrop < 2, "Already Dropped");
        if(teamDrop == 0){
            require(block.timestamp > (pool.endTime + coolTime1), "Still Cooling 1");
        }
        if(teamDrop == 1){
            require(block.timestamp > (pool.endTime + coolTime2), "Still Cooling 2");
        }
        tokenInstance.presaleDon(team1,(pool.totalSupply * 25 / 2000)); //2.5 % 1/2
        tokenInstance.presaleDon(team2,(pool.totalSupply * 25 / 2000)); //2.5 % 1/2
        tokenInstance.presaleDon(cex1,(pool.totalSupply * 25 / 2000)); //2.5 % 1/2
        tokenInstance.presaleDon(cex2,(pool.totalSupply * 25 / 2000)); //2.5 % 1/2
        tokenInstance.presaleDon(team3,(pool.totalSupply / 200)); //1% 1/2
        tokenInstance.presaleDon(team4,(pool.totalSupply / 200)); //1% 1/2
        tokenInstance.presaleDon(cex3,(pool.totalSupply / 200)); //1% 1/2
        tokenInstance.presaleDon(cex4,(pool.totalSupply / 200)); //1% 1/2
        ++teamDrop;
    }

    /*
    * Refunds the Eth to participents
    */
    function refund() external onlyInactive onlyRefund nonReentrant {
        uint256 refundAmount = ethContribution[msg.sender];
        if (address(this).balance >= refundAmount) {
            if (refundAmount > 0) {
                ethContribution[msg.sender] = 0;
                address payable refunder = payable(msg.sender);
                refunder.transfer(refundAmount);
                emit Refunded(refunder, refundAmount);
            }
        } else {
            revert ps__out();
        }
    }

    /*
    * Withdrawal tokens on refund
    */
    function withrawTokens() external onlyOwner onlyInactive {
        uint256 balance = tokenInstance.balanceOf(address(this));
        if (balance > 0) {
            require(tokenInstance.transfer(msg.sender, balance), "Withdraw failed.");
            isDeposit = false;
            emit Withdraw(msg.sender, balance);
        }
    }

    /*
    * If requirements are passed, updates user"s token balance based on their eth contribution
    */
    function buyTokens(address _contributor) public payable onlyActive {
        uint256 weiAmount = msg.value;
        _checkSaleRequirements(_contributor, weiAmount);
        uint256 tokensAmount = _getUserTokens(weiAmount);
        ethRaised += weiAmount;
        presaleTokens -= tokensAmount;
        ethContribution[_contributor] += weiAmount;
        emit Bought(_contributor, tokensAmount);
    }

    /*
    * Checks whether a user passes token purchase requirements, called internally on buyTokens function
    */
    function _checkSaleRequirements(address _beneficiary, uint256 _amount) internal view { 
        require(_beneficiary != address(0), "Transfer to 0 address.");
        require(_amount != 0, "Wei Amount is 0");
        require(_amount >= pool.minBuy, "Min buy is not met.");
        require(_amount + ethContribution[_beneficiary] <= pool.maxBuy, "Max buy limit exceeded.");
        require(ethRaised + _amount <= pool.hardCap, "HC Reached.");
        this;
    }

    /*
    * Internal functions, called when calculating balances
    */
    function _getUserTokens(uint256 _amount) internal view returns (uint256){
        return _amount * (pool.saleRate) ;
    }

    function _getLiquidityTokensDeposit() internal view returns (uint256) {
        return pool.totalSupply * pool.liquidityPortion / 100;
    }
    
    function _getFeeEth() internal view returns (uint256) {
        return (ethRaised * 48 / 100);
    }

    function _getLiquidityEth() internal view returns (uint256) {
        uint256 etherFee = _getFeeEth();
        return ethRaised - etherFee;
    }

}