//SPDX-License-Identifier: CC-BY-NC-ND-2.5
pragma solidity 0.8.16;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Clones.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

import "./Types.sol";
import "./Venture.sol";
import "./SignatureValidation.sol";

/**
 * @title ERC20FixedPriceAllocator
 * @author Jubi
 * @notice This contract allows a Venture to create a sale of Venture tokens,
 * and will allocate the purchased tokens to the relevant purchase accounts according to a distribution schedule
 */
contract ERC20FixedPriceAllocator is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    /// @notice The name used to identify this Allocator in dApps
    string public name;

    /// @notice A description about this Allocator for dApps
    string public description;

    /// @notice Is the allocator open/active
    bool public isOpen;

    /// @notice Escrow is active/is the hurdle amount yet to be reached
    bool public escrowActive;

    /// @notice Has the escrow amount been claimed
    bool public isEscrowClaimed;

    /// @notice Token price
    uint256 public tokenPrice;

    /// @notice Total amount of Venture tokens that can be purchased via this allocator
    uint256 public totalTokensForAllocation;

    /// @notice The minimum amount of tokens that need to be purchased for the sale to be successful
    uint256 public hurdle;

    /// @notice The portion of a purchase that remains after fees
    uint256 public ventureFunds;

    /// @notice The timestamp at which the distribution schedule to release tokens for claiming, starts.
    /// Typically happens after the Venture Token is minted and can be set using setVentureToken
    uint256 public releaseScheduleStartTimeStamp;

    /// @notice The number of seconds after starting the distribution schedule, that tokens will be locked from claiming
    uint256 public tokenLockDuration;

    /// @notice The duration over which tokens are released for claiming after the tokenLockDuration
    uint256 public releaseDuration;

    /// @notice The token accepted for purchasing the Venture Token
    IERC20 public purchaseToken;

    /// @notice The Venture Token that allocated for sale
    IERC20 public allocationToken;

    /// @notice merkle root that captures all valid invite codes
    bytes32 public inviteCodesMerkleRoot;

    /// @notice maps invitesCodes => wallets
    mapping(bytes32 => address) public claimedInvites;

    /// @notice the Venture that manages this contract
    Venture public venture;

    /// @notice Hashed domain separator as per EIP712
    bytes32 public DOMAIN_SEPARATOR;

    /// @notice Data hash of the signed terms of this allocator
    bytes32 public termsHash;

    /// @notice the URL where the terms of this allocator can be found
    string public termsUrl;

    /// @notice The signature of the token allocations terms by the venture's representative
    /// signature is for ALL invite codes and the entire token allocation, and counts as counter signature for each purchase
    bytes public ventureSignature;

    /// @notice Tokens that have been purchased by a specific address
    mapping(address => uint256) public allocation;

    /// @notice Total tokens allocated/purchased from this allocator
    uint256 public totalAllocationTokenAllocated;

    /// @notice Amount of tokens remaining that an account is allowed to purchase given their invite codes
    /// sum of allowance from cumulative invite codes - purchased tokens
    mapping(address => uint256) public remainingAccountAllocationTokenAllowance;

    /// @notice purchaseToken spent to purchase allocationToken by a specific address
    mapping(address => uint256) public paidAmounts;

    /// @notice Total purchaseToken collected by this allocator
    uint256 public totalPaidAmount;

    /// @notice Number of allocationToken claimed by a specific address
    mapping(address => uint256) public accountClaimed;

    /// @notice Total allocationToken claimed from this allocator
    uint256 public totalClaimed;

    /// @notice Has the hurdle been reached
    bool public isHurdleReached;

    /**
     * @notice This event is emitted when a purchase is made
     * @param account The account that purchased tokens
     * @param purchaseAmount The amount of purchaseToken that was paid
     * @param allocatedAmount The amount of allocationToken that will be allocated to the account
     * @param purchaseSignature The signature of the terms by the purchaser
     * @param ventureSignature The signature of the terms by the venture representative
     */
    event Purchase(
        address account,
        uint256 purchaseAmount,
        uint256 allocatedAmount,
        bytes purchaseSignature,
        bytes ventureSignature
    );

    /**
     * @notice This event is emitted a Claim is made
     * @param account The account that claimed allocationToken
     * @param amount The amount that was claimed
     */
    event Claimed(address account, uint256 amount);

    /**
     * @notice This event is emitted when an `admin` migrates the venture that manages this allocator
     * from `oldVenture` to `newVenture`
     * @param oldVenture The venture that is been deprecated
     * @param newVenture The venture that is assigned as the new manager
     * @param admin The admin account that perform the migration
     */
    event VentureMigrated(
        address indexed oldVenture,
        address indexed newVenture,
        address admin
    );

    /**
     * @dev Emitted when an amount of tokens is claimed from the escrow by an account.
     * @param amount The amount of tokens claimed.
     * @param account The account that claimed the tokens.
     */
    event EscrowClaimed(uint256 amount, address account);

    /**
     * @dev Emitted when the allocator is closed and no more allocations can be made.
     * @param account The account that closed the allocator.
     */
    event AllocatorClosed(address account);

    /**
     * @dev Emitted when the venture token address is set.
     * @param ventureToken The address of the venture token.
     */
    event AllocationTokenSet(address indexed ventureToken);

    /**
     * @dev Emitted when the hurdle is reached.
     */
    event HurdleReached();


    /**
     * @notice This function is used to initialize the contract
     * @dev PLEASE NOTE, this contract supports prices with the decimals specific to the purchase token, i.e. $USDC 1 as 1000000
     * Allocation token is only supported with 18 decimals
     * @param _founder The address of the founder
     * @param _config The configuration for this allocator
     */
    function initialize(
        address _founder,
        Types.ERC20FixedPriceAllocatorConfig memory _config
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        _transferOwnership(_config.venture.owner());
        name = _config.name;
        description = _config.description;
        venture = _config.venture;
        tokenPrice = _config.signatureStoreConfig.tokenPrice;
        allocationToken = _config.allocationToken;
        totalTokensForAllocation = _config.tokensForAllocation;
        hurdle = _config.signatureStoreConfig.hurdle;
        releaseScheduleStartTimeStamp = _config
            .signatureStoreConfig
            .releaseScheduleStartTimeStamp;
        tokenLockDuration = _config.signatureStoreConfig.tokenLockDuration;
        releaseDuration = _config.signatureStoreConfig.releaseDuration;
        inviteCodesMerkleRoot = _config.inviteCodesMerkleRoot;
        purchaseToken = _config.venture.treasuryToken();
        termsHash = _config.signatureStoreConfig.termsHash;
        termsUrl = _config.signatureStoreConfig.termsUrl;


        bytes32 founderDomain = SignatureUtil.hashDomain( SignatureUtil.EIP712Domain({
            name : name,
            version : '1',
            chainId : block.chainid,
            verifyingContract : _founder
        }));

        SignatureUtil.SignatureData memory signatureData = SignatureUtil.SignatureData({
            signer: _founder,
            termsUrl: _config.signatureStoreConfig.termsUrl,
            termsHash: _config.signatureStoreConfig.termsHash,
            numTokens: _config.tokensForAllocation,
            tokenPrice: _config.signatureStoreConfig.tokenPrice,
            hurdle: _config.signatureStoreConfig.hurdle,
            releaseScheduleStartTimeStamp: _config.signatureStoreConfig.releaseScheduleStartTimeStamp,
            tokenLockDuration: _config.signatureStoreConfig.tokenLockDuration,
            releaseDuration: _config.signatureStoreConfig.releaseDuration,
            inviteCode: _config.signatureStoreConfig.config.inviteCode
        });
        bool isSignatureValid = SignatureUtil.verifySignature(founderDomain, signatureData, _config.signatureStoreConfig.config.signature);
        require(isSignatureValid, "FixedPriceAllocator: Invalid signature");
        ventureSignature = _config.signatureStoreConfig.config.signature;

        DOMAIN_SEPARATOR = SignatureUtil.hashDomain( SignatureUtil.EIP712Domain({
            name : name,
            version : '1',
            chainId : block.chainid,
            verifyingContract : address(this)
        }));

        if (address(allocationToken) != address(0)) {
            allocationToken.safeTransferFrom(
                msg.sender,
                address(this),
                totalTokensForAllocation
            );
        }
        isOpen = true;
        escrowActive = true;
    }

    /**
     * @notice This function is used to purchase allocationToken, `ventureTokenPurchaseAmount` specifying the number of tokens being purchased as long as:
     * 1. The sale is open
     * 2. The invite code is valid
     * 3. The signature is valid
     * 4. The venture token purchase amount is above the min bounds specified by their invite codes for the first purchase
     * 5. The venture token purchase amount is below or equal to the remaining `remainingAccountAllocationTokenAllowance`
     * 6. There is sufficient unsold allocationToken to fulfill the purchase
     *
     * @param ventureTokenPurchaseAmount  amount of allocationToken to purchase
     * @param minVentureTokenPurchase min amount of allocationToken that can be purchased specified by the invite code
     * @param maxVentureTokenPurchase max amount of allocationToken that can be purchased specified by the invite code
     */
    function purchase(
        uint256 ventureTokenPurchaseAmount,
        uint256 minVentureTokenPurchase,
        uint256 maxVentureTokenPurchase,
        bytes32 inviteCode,
        bytes32[] calldata merkleProof,
        bytes memory signature
    ) external nonReentrant {
        /* TODO: just use msg.sender directly */
        address account = msg.sender;
        require(
            MerkleProof.verify(
                merkleProof,
                inviteCodesMerkleRoot,
                keccak256(
                    abi.encode(
                        inviteCode,
                        minVentureTokenPurchase,
                        maxVentureTokenPurchase
                    )
                )
            ),
            "FixedPriceAllocator: Invalid invite code"
        );
        require(
            ventureTokenPurchaseAmount >= minVentureTokenPurchase ||
                allocation[account] != 0,
            "FixedPriceAllocator: Can not purchase less than minimum amount"
        );
        if (claimedInvites[inviteCode] != address(0)) {
            if (claimedInvites[inviteCode] != account) {
                revert(
                    "FixedPriceAllocator: You can only purchase with one wallet per invite code"
                );
            }
            if (
                ventureTokenPurchaseAmount >
                remainingAccountAllocationTokenAllowance[account]
            ) {
                revert(
                    "FixedPriceAllocator: Maximum purchase amount for invite codes exceeded"
                );
            }
        } else {
            if (
                ventureTokenPurchaseAmount >
                (remainingAccountAllocationTokenAllowance[account] +
                    maxVentureTokenPurchase)
            ) {
                revert(
                    "FixedPriceAllocator: Maximum purchase amount for invite codes exceeded"
                );
            }
        }
        require(isOpen, "FixedPriceAllocator: Sale Closed");


        SignatureUtil.SignatureData memory signatureData = SignatureUtil.SignatureData({
            signer: msg.sender,
            termsUrl: termsUrl,
            termsHash: termsHash,
            numTokens: ventureTokenPurchaseAmount,
            tokenPrice: tokenPrice,
            hurdle: hurdle,
            releaseScheduleStartTimeStamp: releaseScheduleStartTimeStamp,
            tokenLockDuration: tokenLockDuration,
            releaseDuration: releaseDuration,
            inviteCode: inviteCode
        });

        bool isSignatureValid = SignatureUtil.verifySignature(DOMAIN_SEPARATOR, signatureData, signature);
        require(isSignatureValid, "FixedPriceAllocator: Invalid signature");

        // first time using this invite code
        if (claimedInvites[inviteCode] == address(0)) {
            // bump remaining allocation for this wallet address (i.e. same wallet can use multiple invite codes)
            remainingAccountAllocationTokenAllowance[
                account
            ] += maxVentureTokenPurchase;
        }

        uint256 remainingGlobalTokenAllocation = totalTokensForAllocation -
            totalAllocationTokenAllocated;
        if (remainingGlobalTokenAllocation < ventureTokenPurchaseAmount) {
            revert(
                "FixedPriceAllocator: Insufficient tokens available for purchase"
            );
        }

        allocation[account] += ventureTokenPurchaseAmount;
        remainingAccountAllocationTokenAllowance[
            account
        ] -= ventureTokenPurchaseAmount;
        totalAllocationTokenAllocated += ventureTokenPurchaseAmount;
        claimedInvites[inviteCode] = account;

        if (totalAllocationTokenAllocated == totalTokensForAllocation) {
            _close();
        }

        // the purchase tokens to transfer
        uint256 purchaseTokenAmount = allocationToPurchaseToken(
            ventureTokenPurchaseAmount
        );
        paidAmounts[account] += purchaseTokenAmount;
        totalPaidAmount += purchaseTokenAmount;

        if (totalAllocationTokenAllocated >= hurdle) {
            SafeERC20.safeTransferFrom(
                venture.treasuryToken(),
                msg.sender,
                venture.fundsAddress(),
                purchaseTokenAmount
            );
            if (!isHurdleReached) {
                isHurdleReached = true;
                emit HurdleReached();
            }
        } else {
            // escrow
            SafeERC20.safeTransferFrom(
                purchaseToken,
                msg.sender,
                address(this),
                purchaseTokenAmount
            );
        }

        emit Purchase(account, purchaseTokenAmount, ventureTokenPurchaseAmount, signature, ventureSignature);
    }

    /**
     * @notice Allows a purchaser to claim tokens that have been released and not yet claimed
     */
    function claim() external nonReentrant {
        require(
            !isOpen,
            "FixedPriceAllocator: Can only claim once allocator is closed"
        );
        if (allocation[msg.sender] == 0)
            revert(
                "FixedPriceAllocator: This account has not purchased any tokens, 0 claimable"
            );

        if (allocationToken == purchaseToken) {
            SafeERC20.safeTransfer(
                allocationToken,
                msg.sender,
                paidAmounts[msg.sender]
            );
            emit Claimed(
                msg.sender,
                paidAmounts[msg.sender]
            );
        } else {
            uint256 claimableAmount = calculateTotalTokensReleased(msg.sender) -
            accountClaimed[msg.sender];
            require(claimableAmount != 0, "FixedPriceAllocator: Nothing to claim");
            accountClaimed[msg.sender] += claimableAmount;
            totalClaimed += claimableAmount;
            SafeERC20.safeTransfer(
                allocationToken,
                msg.sender,
                claimableAmount
            );
            emit Claimed(msg.sender, claimableAmount);
        }
    }

    /**
     * @notice Transfers the amount that was held in escrow to the venture if the hurdle amount was reached
     */
    function claimEscrow() external {
        require(
            !isEscrowClaimed,
            "FixedPriceAllocator: Escrow has already been claimed"
        );
        require(
            venture.isAdminOrAllocatorManager(msg.sender),
            "FixedPriceAllocator: only allocator manager can claim escrow funds"
        );
        require(
            totalAllocationTokenAllocated >= hurdle,
            "FixedPriceAllocator: Sale has not reached hurdle"
        );
        uint256 escrowAmount = purchaseToken.balanceOf(address(this));
            SafeERC20.safeTransfer(
                venture.treasuryToken(),
                venture.fundsAddress(),
                escrowAmount
            );
        isEscrowClaimed = true;
        emit EscrowClaimed(escrowAmount, msg.sender);
    }

    /**
     * @notice Closes the allocator so that no further purchases can be made, and transfers any remaining tokens back to the venture
     */
    function close() external {
        require(
            venture.isAdminOrAllocatorManager(msg.sender),
            "FixedPriceAllocator: only allocator manager can close allocator"
        );
        require(
            isOpen,
            "FixedPriceAllocator: Allocator is already closed"
        );
        // If escrow amount is still held in contract, transfer to venture
        uint256 remainingAllocation;
        bool isAllocationTokenSet = (address(allocationToken) != address(0));
        _close();
        if (totalAllocationTokenAllocated >= hurdle) {
            if (!isEscrowClaimed) {
                uint256 escrowAmount = purchaseToken.balanceOf(address(this));
                    SafeERC20.safeTransfer(
                        venture.treasuryToken(),
                        venture.fundsAddress(),
                        escrowAmount
                    );
                isEscrowClaimed = true;
            }
            remainingAllocation =
                totalTokensForAllocation -
                totalAllocationTokenAllocated;
                // return any unsold venture tokens to venture wallet or venture contract.
                if(isAllocationTokenSet){
                    SafeERC20.safeTransfer(
                        allocationToken,
                        venture.fundsAddress(),
                        remainingAllocation
                    );
                }
        } else {
            remainingAllocation = totalTokensForAllocation;
            // return any unsold venture tokens to venture wallet or venture contract.
            if(isAllocationTokenSet){
                    SafeERC20.safeTransfer(
                    allocationToken,
                    venture.fundsAddress(),
                    remainingAllocation
                );
            }
            // when the allocator is closed if Hurdle is NOT met set the ventureToken to purchaseToken and remove any vesting so
            // funders can call claimFor to refund their initial investment
            allocationToken = purchaseToken;
            // This will make so allocation is claimable right away
            releaseScheduleStartTimeStamp =
                block.timestamp -
                releaseDuration -
                tokenLockDuration;
        }

        venture.markUnallocatedTokensReturned(address(this), remainingAllocation);
    }

    function _close() internal {
        isOpen = false;
        emit AllocatorClosed(msg.sender);
    }


    /**
     * @notice Calculates the amount of purchased tokens that has been released according to the release schedule
     * @param account The account to calculate the released amount for
     */
    function calculateReleased(
        address account
    ) public view returns (uint256 releasedAmount) {
        // TODO This is true with 0 sold also
        if (allocation[account] == 0)
            revert(
                "FixedPriceAllocator: This account has not purchased any tokens, 0 claimable"
            );
        if (
            totalAllocationTokenAllocated == totalClaimed ||
            allocation[account] == accountClaimed[account]
        ) {
            revert("FixedPriceAllocator: All tokens have been claimed");
        }
        if (address(allocationToken) == address(0)) {
            revert(
                "FixedPriceAllocator: Allocation Token has not been set yet"
            );
        }

        uint256 timestamp = block.timestamp;

        uint256 releaseStartTimestamp = releaseScheduleStartTimeStamp +
            tokenLockDuration;
        if (timestamp < releaseStartTimestamp) {
            return 0;
        }

        uint256 elapsedReleaseSeconds = timestamp - releaseStartTimestamp;
        // minimum claimDuration to 1 sec to prevent /0
        uint256 _releaseDuration = 1;
        if (releaseDuration != 0) {
            _releaseDuration = releaseDuration;
        }

        if (elapsedReleaseSeconds > _releaseDuration) {
            return allocation[account];
        }

        releasedAmount =
            (allocation[account] * elapsedReleaseSeconds) /
            _releaseDuration;
    }

    /**
     * @notice Sets the token address for the token that was sold and transfers the amount required to fulfill all claims to this contract
     * @param _allocationToken The token that was sold using this contract, the required amount will be transferred to the contract
     * @param _setReleaseScheduleStart If set to true, starts the distribution schedule
     * @dev Use '_setClaimableScheduleStart' if token minting did not happen on schedule, to start the schedule since the token is now available
     * @dev PLEASE NOTE, only 18 decimal tokens are supported
     */
    function setAllocationToken(
        IERC20 _allocationToken,
        bool _setReleaseScheduleStart
    ) external {
        require(
            !isOpen,
            "FixedPriceAllocator: Cannot set token while allocator is open"
        );
        require(
            venture.isAdminOrAllocatorManager(msg.sender),
            "FixedPriceAllocator: only allocator manager can set the token"
        );
        require(
            address(allocationToken) == address(0),
            "FixedPriceAllocator: Venture token already set"
        );
        require(
            address(_allocationToken) != address(purchaseToken),
            "FixedPriceAllocator: Can NOT set the claim token to purchase token"
        );
        require(
            address(_allocationToken) != address(0),
            "FixedPriceAllocator: Token address invalid"
        );
            SafeERC20.safeTransferFrom(
                _allocationToken,
                msg.sender,
                address(this),
                totalAllocationTokenAllocated
            );
        if (_setReleaseScheduleStart) {
            releaseScheduleStartTimeStamp = block.timestamp;
        }
        allocationToken = _allocationToken;
        emit AllocationTokenSet(address(_allocationToken));
    }

    /**
     * @notice Migrates this contract from being managed by current venture to a new venture `_newVenture`
     * All access control and admin rights are managed by the venture.
     * @param _newVenture The new venture contract that will manage this allocator
     */
    function migrateVenture(address _newVenture) external {
        require(
            _newVenture != address(0),
            "FixedPriceAllocator: invalid new venture"
        );
        Venture newVenture = Venture(_newVenture);
        require(
            newVenture.tokenSupply() > totalTokensForAllocation,
            "FixedPriceAllocator: Venture has insufficient token supply"
        );
        require(
            newVenture != venture,
            "FixedPriceAllocator: Can not update to same venture"
        );
        require(
            venture.isAdmin(msg.sender),
            "FixedPriceAllocator: only venture admin can update allocator"
        );
        require(
            newVenture.isAdmin(msg.sender),
            "FixedPriceAllocator: only venture admin can update allocator"
        );
        address oldVenture = address(venture);
        venture = newVenture;
        emit VentureMigrated(oldVenture, address(newVenture), msg.sender);
    }

    /**
     * @notice Calculates the amount of tokens that has been released according to the release schedule
     * @param account The account to calculate the released amount for
     */
    function calculateTotalTokensReleased(
        address account
    ) public view returns (uint256) {
        return calculateReleased(account);
    }

    /**
     * @notice Given an allocation amount, calculates the amount of purchase tokens.
     * Also used when escrow is being returned as hurdle has not been met.
     * accounts for the 18 decimals of both numbers (1e36), and then converts to decimals of purchase token. 
     * @param _allocation The amount of allocation tokens
     */
    function allocationToPurchaseToken(
        uint256 _allocation
    ) internal view returns (uint256) {
        uint256 purchaseTokenDecimals = 10**IERC20Metadata(address(purchaseToken)).decimals();
        return ((_allocation * tokenPrice * purchaseTokenDecimals) / 1e36);
    }
}
