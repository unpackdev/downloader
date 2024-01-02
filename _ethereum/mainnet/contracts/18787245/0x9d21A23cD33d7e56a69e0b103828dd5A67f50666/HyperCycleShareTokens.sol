// SPDX-License-Identifier: MIT
/*
    Version 1 of the HyperCycle Share contract.
*/

pragma solidity 0.8.19;

import "./ERC721Holder.sol";
import "./ERC1155.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IHyperCycleLicense.sol";
import "./ICHYPC.sol";
import "./IHYPCSwapV2.sol";
import "./IHyperCycleShareTokens.sol";
import "./IHYPC.sol";

/*
@title HyperCycle Share ERC1155, revenue sharing contract.
@author Barry Rowe, Rodolfo Cova 
@notice This contract is a mechanism to share revenue for participants in the HyperCycle system.
      
        HyperCycle is a network of AI computation nodes offering different AI services in a 
        decentralized manner. In this system, there are license holders, token holders, hardware
        operators, and AI developers. Using the HyperCycleSwapV2 contract, an amount of HyPC (erc20)
        can be swapped for a cHyPC (containerized HyPC) token, which can then point towards a
        license (HyperCycleLicense) NFT id. At this point, the owner of this license can assign
        their license to some hardware running the HyperCycle Node Manager, and can from then
        on accept AI service requests on the network. 

        While all of this can be done by a single user, there are benefits to dividing up the
        responsibilities of each party, so a user can participate as a license holder, token holder,
        hardware operator, or AI developer. This is where the HyperCycle Share contracts come into
        play. The HyperCycleShareTokens contract is an ERC1155 contract that accepts a deposit of
        a license NFT and a cHyPC NFT, and creates two new tokens: a wealth token, and a revenue
        token. While the license and cHyPC are locked in the new Share, revenue can be deposited
        into the HyperCycleShareTokens by the hardware manager (that is, using the node manager
        software) with the depositRevenue() method. After some HyPC has been deposited this way,
        the revenue becomes locked for a minimum waiting period (for example, 7 days), after which,
        this revenue can be unlocked, and at that point, owners of the revenue token can claim 
        their portion of the share's income by using the claimRevenue() method. This will update 
        their withdrawable amount of HyPC that they can then withdraw from the contract. The revenue
        deposit delay is useful for ensuring more fairness of the revenue sharing. For instance,
        without a delay, the hardware operator could buy a lot of revenue tokens from an exchange,
        then make a huge revenue deposit into the contract, and then immediately claim their revenue
        and then sell the revenue tokens back to the exchange. With a delay period, the hardware
        operator would have to hold onto those tokens for the 7 day period, and with the pending
        deposit coming through, the revenue token price would increase (similar to dividend yielding
        stocks when leading up to the day a dividend will be paid out). The other holders of the
        revenue tokens can sell their tokens at the higher price, and then buy back the revenue
        tokens after the revenue is unlocked and claimable by the contract, when the price is lower.
        This counteracts the advantage the hardware operator,or users who would front run a deposit
        transaction, would have.

        Since revenue tokens can be transferred at any time, while revenue is collected only on the 
        claimRevenue call, whenever a transfer of revenue tokens happens, a claimRevenue call is 
        made for both the sender and receiver of the tokens first via the safeTransferFrom ERC1155 
        overrides defined at the end of the contract. This prevents the following situation:
        suppose Alice and Bob have 50% of the revenue tokens each, and the contract earns 1000 HyPC.
        Alice then sends Bob half of her revenue tokens. Bob now owns 75% of the revenue tokens and
        can claim 75% of the 1000 HyPC, even though the 1000 HyPC was deposited when Alice owned
        50% of those tokens. 

        The claimRevenue hook on the transfer of revenue tokens fixes this issue by forcing the
        revenue to be claimed whenever revenue tokens are transferred between parties. In effect,
        the issue is that revenue tokens are only fungible if they have collected revenue at the
        same time (if Alice claims revenue on her tokens while Bob has not, then these tokens
        are not equivalent to each other). If both holders of the tokens have collected at the
        same time however, then these tokens are indeed equivalent.

        Besides the revenue tokens, there are also the wealth tokens. In this contract they do not
        have any special usage, but are intended for use in future contracts (for example: a share
        manager contract) that can use them for governance functions. Right now, the current contract
        is intended to be used either via a multi-sig wallet with a general delgation mechanism 
        (eg: gnosis), or more likely via an external manager contract that interfaces with this 
        contract. In that case, the license holder and cHyPC holders would use the manager contract
        to create the share and divide the wealth and revenue tokens amongst themselves, or other
        parties, using governing mechanisms inside the manager contract.

        If the original creator of the share (or someone that had the share transferred to them) 
        decides to cancel the share itself by calling the cancelShareTokens() method, then the 
        original license and cHyPC NFTs are sent back to the creator (or new owner), and future
        deposits to share are halted. At this time, owners of the revenue tokens can claim their 
        last amounts of HyPC, and withdraw their HyPC from the contract.

        As well, while the typical use case is that the original creator of the share deposits 
        both the license and cHyPC tokens into the share contract, there are some use cases where 
        it might make sense to only deposit the license instead. This could be the case where 
        this creator is a smart contract that used the CrowdFundHYPCPoolV2 contract get an 
        assignment pointed to the license Id. In this case, the smart contract would have an 
        external guarantee that the license has backing but does not own the cHyPC itself. 
        In this case, a share can be created instead with a cHyPC id of 0, which will bypass the 
        cHyPC retrieval and assignment in that case. 
 
        Finally, there's also a message function to allow the owner of a share to set a message
        associated to this share. This is mainly intended for future manager contracts to use.
*/

/* Errors */
// Modifier Errors
//@dev Error for when requiring the caller to be the owner of the share
error MustBeShareOwner();
//@dev Error for when the given share has to be active (not previously cancelled).
error ShareMustBeActive();
//@dev Error for when the given shareNumber has not been created yet.
error ShareDoesntExist();
//@dev Error for when the pending deposit does not exist.
error PendingDepositMustExist();

/* Constructor Errors */

//@dev Error for when the give end share number would cause an overflow when creating the token Ids.
error EndShareNumberWouldOverflow();
//@dev Error for when the inputed end number is greater than 2 times the start number.
//     This ensures that 2 times the current share number (ie: the revenueToken id) will be unique.
//     This error is also raised when the endNumber given is less than the startNumber.
error InvalidShareNumberRange();
//@dev Error for when the license contract address is zero.
error InvalidLicenseAddress();
//@dev Error for when the swapV2 contract address is zero.
error InvalidSwapV2Address();
//@dev Error for when the HyPC contract address is zero.
error InvalidHYPCAddress();
//@dev Error for when the cHyPCV1 contract address is zero.
error InvalidCHYPCV1Address();
//@dev Error for when the startLimit amount for the constructor is outside the share number range.
error InvalidStartingLimit();

/* increaseShareLimit Errors */
//@dev Error for when trying to increase the soft share limit beyond the endShareNumber.
error ShareLimitIncreasedTooMuch();

/* createShareTokens Errors */
//@dev Error for when trying to create a share beyond the share limit.
error CantCreateSharesBeyondShareLimit();
//@dev Error for when trying to create a share without CHYPC backing (via SwapV1 or SwapV2).
error LicenseMustHaveCHYPCBacking();

/* unlockRevenue Errors */
//@dev Error for when trying to unlock a pending deposits before the delay time has passed.
error UnlockingRevenueTooEarly();

/* claimRevenue Errors */
//@dev Error for when trying to claim revenue for a share when you don't have any of its revenue tokens.
error NoRevenueTokensForThisShare();
//@dev Error for when trying to claim revenue when there is none to claim.
error NoRevenueToClaim();

/* transferShareOwnership Errors */
//@dev Error for when trying to transfer ownership of a share to the zero address.
error CantTransferToZeroAddress();

/* cancelShareTokens Errors */
//@dev Error for when trying to cancel a share before the MIN_DURATION time has passed.
error ShareMinDurationHasNotPassed();

/* withdrawEarnings Errors */
//@dev Error for when trying to withdraw claimed revenue when there is none in the contract.
error NothingToWithdraw();

/* burn Errors */
//@dev Error for when trying to burn revenue tokens that have unclaimed revenue
error MustClaimRevenueToBurnTokens();
//@dev Error for when trying to burn revenue tokens before a share has ended.
error ShareMustBeEnded();
//@dev Error for when trying to burn zero revenue tokens.
error MustBurnSomeRevenueTokens();
//@dev Error for when user trys to burn more revenue tokens than they own.
error NotEnoughRevenueTokensOwned();
//@dev Error for when trying to burn zero wealth tokens.
error MustBurnSomeWealthTokens();
//@dev Error for when user trys to burn more wealth tokens than they own.
error NotEnoughWealthTokensOwned();


contract HyperCycleShareTokens is 
    ERC1155, ERC721Holder, Ownable, ReentrancyGuard, IHyperCycleShareTokens {

    //@dev Contract interfaces
    IHYPC private immutable hypcToken;
    ICHYPC private immutable chypcV1Contract;
    IHYPCSwapV2 private immutable swapV2Contract;
    IHyperCycleLicense private immutable licenseContract;

    // Contract constants
    //@dev The max supply to use for revenue tokens.
    uint256 public constant REVENUE_TOKEN_MAX_SUPPLY = 2**20;
    //@dev The max supply to use for wealth tokens.
    uint256 public constant WEALTH_TOKEN_MAX_SUPPLY = 2**20;
    //@dev The minimum time that has to pass before a share can be cancelled.
    uint256 public constant MIN_SHARE_DURATION = 24 hours;
    //@dev The number of decimals to use when doing revenue sharing calculations.
    uint256 public constant RATIO_DECIMALS = 10**12;

    //@dev Enum for the status of a share.
    enum Status {
        NOT_CREATED,
        STARTED,
        ENDED
    }

    //@dev Struct for data specific to a single share, accessible via the following mapping.
    struct ShareData {
        uint256 licenseId;
        uint256 chypcId;
        Status status;
        address owner;
        uint256 rTokenNumber;
        uint256 wTokenNumber;
        uint256 rTokenSupply;
        uint256 wTokenSupply;
        uint256 startTimestamp;
        uint256 revenueDeposited;
        uint256 revenueDepositDelay;
        string message;
        bool chypcTokenHeld;
    }

    //@dev Struct for storing pending share deposits
    //struct PendingDeposit {
    //    uint256 availableAtTimestamp;
    //    uint256 amount;
    //}

    // Mappings
    //@dev Main storage for individual share information
    mapping(uint256=>ShareData) public shareData;
    //@dev Storage for keeping track of the last totalRevenue a revenue token owner claimed their
    //     revenue against.
    mapping(uint256=>mapping(address=>uint256)) public lastShareClaimRevenue;
    //@dev Storage for keeping track of how much HyPC a given address can withdraw, updated by
    //     claimRevenue() calls.
    mapping(uint256=>mapping(address=>uint256)) public withdrawableAmounts;
    //@dev Helper function to get the last shareNumber to use this given licenseId NFT.
    mapping(uint256=>uint256) public licenseToShareNumber;
    //@dev Storage array for pending revenue deposits.
    mapping(uint256=> PendingDeposit[]) public pendingDeposits;

    // Variables
    //@dev The starting shareNumber to be issued.
    uint256 public startShareNumber;
    //@dev The last possible shareNumber to be issued.
    uint256 public endShareNumber;

    //@dev Soft limit for the upper value of shareNumbers. Can be increased by the owner of this
    //     contract.
    uint256 public shareLimitNumber;
    //@dev The next valid shareNumber to be issued.
    uint256 public currentShareNumber;
    //@dev The total amount of HyPC deposited so far into this contract.
    uint256 public totalDeposited;

    // Events
    // @dev   The event for when the contract owner increase the soft share limit.
    // @param amount: The amount that the soft shareNumber limit was increased by.
    event IncreaseShareLimit(uint256 amount);

    // @dev   The event for when a user creates a new share.
    // @param licenseNumber: The HyperCycleLicense NFT id used for this share.
    // @param chypcNumber: The SwapV2 cHyPC NFT id used for this share.
    // @param owner: The user that created this share.
    // @param shareNumber: The shareNumber given to this new share.
    // @param rToken: The revenue token id in this contract for this share.
    // @param wToken: The wealth token id in the contract for this share.
    // @param startTime: The timestamp for when this share was created.
    // @param startingMessage: The message assigned to this share when created.
    event CreateShare(
        uint256 licenseNumber, 
        uint256 chypcNumber,
        address owner, 
        uint256 shareNumber,
        bool chypcTokenHeld
    );

    // @dev   The event for when an owner of a share transfers it to someone else.
    // @param shareNumber: The share being transferred.
    // @param to: The address this share is being transferred to.
    event ShareOwnershipTransferred(uint256 shareNumber, address to);

    // @dev   The event for when an owner of a share changes the pending revenue delay.
    // @param shareNumber: The share to change the maximum revenue deposit of.
    // @param newDelay: The new pending revenue minimum delay, in seconds.
    event PendingRevenueDelayChange(uint256 shareNumber, uint256 newDelay);

    // @dev   The event for when revenue is deposited into a share.
    // @param shareNumber: The share receiving the revenue.
    // @param amount: The amount of HyPC being deposited.
    // @param timestamp: The time this revenue was deposited.
    event RevenueDeposited(uint256 shareNumber, uint256 amount, uint256 timestamp);
 
    // @dev   The event for when pending revenue is deposited into a share.
    // @param shareNumber: The share receiving the revenue.
    // @param amount: The amount of HyPC being deposited.
    // @param pendingUntil: The time this deposit becomes available to be claimed.
    event PendingRevenueDeposit(uint256 shareNumber, uint256 index, uint256 amount);
 
    // @dev   The event for when a share is cancelled and the NFTs returned to the owner.
    // @param shareNumber: The share being cancelled.
    // @param chypcNumber: The cHyPC NFT id being returned.
    // @param licenseNumber: The license NFT id being returned.
    event CancelledSharedTokens(uint256 shareNumber, uint256 chypcNumber, uint256 licenseNumber);

    // @dev   The event for when an address claims HyPC from deposits.
    // @param shareNumber: The share whose revenue is being withdrawn.
    // @param claimer: The address withdrawing its claimed revenue.
    // @param amount: The amount of HyPC claimed.
    event ClaimRevenue(uint256 shareNumber, address claimer, uint256 amount);
 
    // @dev   The event for when an address withdraws its claimed HyPC from deposits.
    // @param shareNumber: The share whose revenue is being withdrawn.
    // @param claimer: The address withdrawing its claimed revenue.
    // @param amount: The amount of HyPC that was withdrawn.
    event EarningsWithdrawal(uint256 shareNumber, address claimer, uint256 amount);

    // @dev   The event for when an share has its message changed.
    // @param shareNumber: The share whose message is being changed.
    // @param message: The new message
    event ShareMessageChangedTo(uint256 shareNumber, string message);
 
    // Modifiers
    // @dev   Checks if the sender is the owner of this share.
    // @param shareNumber: The share id to check.
    modifier shareOwner(uint256 shareNumber) {
        if (shareData[shareNumber].owner != msg.sender) revert MustBeShareOwner();
        _;
    }
 
    // @dev   Checks if the given share is still active.
    // @param shareNumber: The share id to check.
    modifier shareActive(uint256 shareNumber) {
        if (shareData[shareNumber].status != Status.STARTED) revert ShareMustBeActive();
        _;
    }

    // @dev   Checks if the given share was created.
    // @param shareNumber: The share id to check.
    modifier shareExists(uint256 shareNumber) {
        if (shareData[shareNumber].status == Status.NOT_CREATED) revert ShareDoesntExist();
        _;
    }

    // @dev   Checks if the given share has been ended.
    // @param shareNumber: The share id to check.
    modifier shareEnded(uint256 shareNumber) {
        if (shareData[shareNumber].status != Status.ENDED) revert ShareMustBeEnded();
        _;
    }

    // @dev   Checks if the given pending deposit exists.
    // @param shareNumber: The share to check the pending deposits of.
    // @param index: The index to check
    modifier pendingDepositExists(uint256 shareNumber, uint256 index) {
        if (index >= pendingDeposits[shareNumber].length) revert PendingDepositMustExist();
        _;
    }

    /**
        @dev   The constructor takes in the share range to use, from startNumber to endNumber
               inclusive, as well as the contract addresses for the license and cHyPC NFTs, and the
               address for the HyPC token. The revenue token Id for a share is twice its shareNumber,
               and twice the shareNumber plus one for the corresponding wealth token. To ensure no
               overlap between shareNumbers and token Ids, the endNumber must be greater than or
               equal to the startNumber and less than the startNumber times two.
        @param startNumber: The first shareNumber id to use.
        @param endNumber: The last shareNumber id to use.
        @param startLimit: The starting shareLimtt to use.
        @param licenseAddress: The license ERC721 contract address.
        @param swapV2Address: The cHyPC ERC721 contract address.
        @param hypcAddress: The HyPC ERC20 contract address.
    */
    constructor(uint256 startNumber, uint256 endNumber, uint256 startLimit, address licenseAddress,
                address chypcV1Address, address swapV2Address, address hypcAddress) ERC1155("") {
        if (endNumber >= 2**255 - 2) revert EndShareNumberWouldOverflow();
        if (endNumber/2 >= startNumber) revert InvalidShareNumberRange();
        if (endNumber < startNumber) revert InvalidShareNumberRange();
        if (licenseAddress == address(0)) revert InvalidLicenseAddress();
        if (swapV2Address == address(0)) revert InvalidSwapV2Address();
        if (hypcAddress == address(0)) revert InvalidHYPCAddress();
        if (chypcV1Address == address(0)) revert InvalidCHYPCV1Address();
        if (startLimit < startNumber || startLimit > endNumber) revert InvalidStartingLimit();

        startShareNumber = startNumber;//8590983168 = 2**33+2**20
        endShareNumber = endNumber;//8592031743 = 2**33 + 2**21 - 1

        shareLimitNumber = startLimit;
        currentShareNumber = startShareNumber;

        chypcV1Contract = ICHYPC(chypcV1Address);
        swapV2Contract = IHYPCSwapV2(swapV2Address);
        licenseContract = IHyperCycleLicense(licenseAddress);
        hypcToken = IHYPC(hypcAddress);
    }

    // @notice Allows the owner of the contract to increase the soft limit of share numbers in the
    //         contract. This is put in place to alow future upgrades of this contract to reserve
    //         higher ranges of shareNumbers, and restrict the older contract from overlapping the
    //         shareNumbers.
    // @param  number: The amount to increase the soft share limit by. 
    function increaseShareLimit(uint256 number) external onlyOwner {
        if (shareLimitNumber+number > endShareNumber) revert ShareLimitIncreasedTooMuch();

        shareLimitNumber+=number;
        emit IncreaseShareLimit({amount: number});
    }

    // @notice Allows a user to create a new share. Takes the given licenseNumber and chypcNumber NFTs
    //         and sends the wealth and revenue tokens to the owner for the corresponding created
    //         share.
    // @param  licenseNumber: The license NFT Id to deposit into this share.
    // @param  chypcNumber: The cHyPC NFT Id to deposit into this share.
    function createShareTokens(uint256 licenseNumber, uint256 chypcNumber, bool chypcTokenHeld, string memory startingMessage, uint256 revenueDepositDelay) external nonReentrant {
        if (currentShareNumber > shareLimitNumber) revert CantCreateSharesBeyondShareLimit();
        if (!chypcTokenHeld) {
            _verifyCHYPCAssignment(chypcNumber, licenseNumber);
        }

        address to = msg.sender;

        uint256 shareNumber = currentShareNumber;
        uint256 rTokenType = shareNumber*2;
        uint256 wTokenType = shareNumber*2+1;
        currentShareNumber+=1;

        shareData[shareNumber] = ShareData(
            licenseNumber, 
            chypcNumber, 
            Status.STARTED, 
            to, 
            rTokenType, 
            wTokenType, 
            REVENUE_TOKEN_MAX_SUPPLY,
            WEALTH_TOKEN_MAX_SUPPLY,
            block.timestamp, 
            0,
            revenueDepositDelay,
            startingMessage,
            chypcTokenHeld
        );
        licenseToShareNumber[licenseNumber] = shareNumber;

        licenseContract.safeTransferFrom(to, address(this), licenseNumber);

        if (chypcTokenHeld) {
            swapV2Contract.safeTransferFrom(to, address(this), chypcNumber);
            swapV2Contract.assignNumber(chypcNumber, licenseNumber);
        }

        _mint(to, rTokenType, REVENUE_TOKEN_MAX_SUPPLY, "");
        _mint(to, wTokenType, WEALTH_TOKEN_MAX_SUPPLY, ""); 
       
        emit CreateShare({licenseNumber: licenseNumber, 
            chypcNumber: chypcNumber, 
            owner: to, 
            shareNumber: shareNumber, 
            chypcTokenHeld: chypcTokenHeld
        });
    }

    // @notice An internal function to check the backing of the license from the given
    //         chypcNumber. This checks assignments via the SwapV2 contract first, and
    //         then the SwapV1 contract.
    // @param  chypcNumber: The cHyPC NFT Id pointing to the licenseNumber.
    // @param  licenseNumber: The license NFT Id to deposit into this share.
    function _verifyCHYPCAssignment(uint256 chypcNumber, uint256 licenseNumber) internal {
        string memory stringAssigned = Strings.toString(licenseNumber);

        if (swapV2Contract.getAssignmentNumber(chypcNumber) != licenseNumber && 
            !Strings.equal(swapV2Contract.getAssignmentString(chypcNumber), stringAssigned) && 
            !Strings.equal(chypcV1Contract.getAssignment(chypcNumber), stringAssigned)) {
            revert LicenseMustHaveCHYPCBacking();
        }
    }

    // @notice Transfers the ownership of a share to another address. Useful for transferring from an
    //         existing multi-sig or manager contract to another one.
    // @param  shareNumber: The share to transfer to a new owner
    // @parma  to: The new owner of this share.
    function transferShareOwnership(uint256 shareNumber, address to) external shareOwner(shareNumber) shareActive(shareNumber) {
        if (to == address(0)) revert CantTransferToZeroAddress();
        shareData[shareNumber].owner = to;
        emit ShareOwnershipTransferred({shareNumber: shareNumber, to: to});
    }

    // @notice Changes the maximum allowed revenue deposit.
    // @param  shareNumber: The share to change the maximum revenue deposit of.
    // @param  newDelay: The new delay to wait for in seconds.
    function changePendingRevenueDelay(uint256 shareNumber, uint256 newDelay) external shareOwner(shareNumber) shareActive(shareNumber) {
        shareData[shareNumber].revenueDepositDelay = newDelay;
        emit PendingRevenueDelayChange({shareNumber: shareNumber, newDelay: newDelay});
    }

    // @notice Cancels a given share and returns the deposited license and cHyPC NFTs to the owner.
    //         Once cancelled, no more revenue can be deposited to this share, but existing owners
    //         of revenue tokens can still claim any deposited HyPC they previously didn't claim.
    // @param  shareNumber: The share to cancel.
    function cancelShareTokens(uint256 shareNumber) external shareOwner(shareNumber) shareActive(shareNumber) nonReentrant {
        if (shareData[shareNumber].startTimestamp + MIN_SHARE_DURATION > block.timestamp) revert ShareMinDurationHasNotPassed();

        uint256 licenseNumber = shareData[shareNumber].licenseId;
        uint256 chypcNumber = shareData[shareNumber].chypcId;
        bool chypcTokenHeld = shareData[shareNumber].chypcTokenHeld;
        shareData[shareNumber].status = Status.ENDED;
        delete licenseToShareNumber[licenseNumber];

        if (chypcTokenHeld) {
            swapV2Contract.assignNumber(chypcNumber, 0);
            swapV2Contract.safeTransferFrom(address(this), msg.sender, chypcNumber);
        }
        licenseContract.safeTransferFrom(address(this), msg.sender, licenseNumber);      
        emit CancelledSharedTokens({
            shareNumber: shareNumber, 
            chypcNumber: chypcNumber, 
            licenseNumber: licenseNumber
        });
    }
   
    // @notice Sets the stored message for this share.
    // @param  shareNumber: The share to set the message of.
    // @param  message: The message to set for this share.
    function setShareMessage(uint256 shareNumber, string memory message) external shareOwner(shareNumber) shareActive(shareNumber) {
        shareData[shareNumber].message = message;
        emit ShareMessageChangedTo({shareNumber: shareNumber, message: message});
    }

    /* Revenue sharing functions */
    // @notice Deposits revenue into a share. It remains locked until it is later released.
    // @param  shareNumber: The share this revenue is deposited for.
    // @param  amt: The amount of HyPC being deposited.
    function depositRevenue(uint256 shareNumber, uint256 amt) external shareActive(shareNumber) {
        pendingDeposits[shareNumber].push(
            PendingDeposit({
                availableAtTimestamp: block.timestamp+shareData[shareNumber].revenueDepositDelay,
                amount: amt
            })
        );
        hypcToken.transferFrom(msg.sender, address(this), amt);
        emit PendingRevenueDeposit({
            shareNumber: shareNumber, 
            index: pendingDeposits[shareNumber].length-1, 
            amount: amt
        });
    }

    // @notice Unlocks a pending revenue deposit to be claimable by the rToken holders
    // @param shareNumber: The share this revenue is being unlocked for.
    // @param index: The index of the pending deposit to unlock.
    function unlockRevenue(uint256 shareNumber, uint256 index) external pendingDepositExists(shareNumber, index) {
        PendingDeposit memory pd = pendingDeposits[shareNumber][index];
        if (pd.availableAtTimestamp > block.timestamp) {
            revert UnlockingRevenueTooEarly();
        }
        totalDeposited += pd.amount;
        shareData[shareNumber].revenueDeposited += pd.amount;

        //Remove old index now;
        if (pendingDeposits[shareNumber].length > 1 && index < pendingDeposits[shareNumber].length -1 ) {
            pendingDeposits[shareNumber][index] = pendingDeposits[shareNumber][pendingDeposits[shareNumber].length -1];
        }
        pendingDeposits[shareNumber].pop();

        emit RevenueDeposited({
            shareNumber: shareNumber, 
            amount: pd.amount,
            timestamp: block.timestamp
        });
    }

    // @notice Internal function for claiming revenue share of a token. This is called whenever a
    //         revenue token holder wants to claim their propotional revenue in this contract. This
    //         is also called whenever a user transfers revenue tokens to another user as mentioned
    //         in the contract description above.
    // @param  shareNumber: The share to claim revenue for.
    // @param  claimerAddress: The address claiming their revenue.
    function _claimRevenue(uint256 shareNumber, address claimerAddress) internal returns (uint256) {
        uint256 rTokenNumber = shareData[shareNumber].rTokenNumber;
        uint256 revenueDeposited = shareData[shareNumber].revenueDeposited;
        uint256 ownershipRatio = RATIO_DECIMALS*balanceOf(claimerAddress, rTokenNumber)/REVENUE_TOKEN_MAX_SUPPLY;

        uint256 amountToGiveAddress = (revenueDeposited-lastShareClaimRevenue[shareNumber][claimerAddress])*ownershipRatio/RATIO_DECIMALS;
        lastShareClaimRevenue[shareNumber][claimerAddress] = revenueDeposited;
        withdrawableAmounts[shareNumber][claimerAddress] += amountToGiveAddress;
        emit ClaimRevenue(shareNumber, claimerAddress, amountToGiveAddress);
        return amountToGiveAddress;
    }

    // @notice External function for _claimRevenue for when a user wants to explictly claim their
    //         revenue for a given share (without any revenue token transfer).
    // @param  shareNumber: The share to claim the revenue of.
    function claimRevenue(uint256 shareNumber) external shareExists(shareNumber) {
        if (balanceOf(msg.sender, shareData[shareNumber].rTokenNumber) == 0) revert NoRevenueTokensForThisShare();
        if (_claimRevenue(shareNumber, msg.sender) == 0) revert NoRevenueToClaim();
    }

    // @notice Internal function for withdrawEarnings, which withdraws HyPC from the share.
    // @param  shareNumber: The share to withdraw from.
    function _withdrawEarnings(uint256 shareNumber) internal shareExists(shareNumber) {
        uint256 amt = withdrawableAmounts[shareNumber][msg.sender];
        if (amt == 0) revert NothingToWithdraw();
        withdrawableAmounts[shareNumber][msg.sender] = 0;
        hypcToken.transfer(msg.sender, amt);
        emit EarningsWithdrawal({
            shareNumber: shareNumber,
            claimer: msg.sender,
            amount: amt
        });
    }

    // @notice Withdraws claimed revenue for this user, if there is any.
    // @param  shareNumber: The share to withdraw revenue from.
    function withdrawEarnings(uint256 shareNumber) external {
        _withdrawEarnings(shareNumber);
    }

    // @notice Utility function to claim and withdraw from a share.
    // @param  shareNumber: The share to claim and withdraw revenue from.
    function claimAndWithdraw(uint256 shareNumber) external {
        if (balanceOf(msg.sender, shareData[shareNumber].rTokenNumber) == 0) revert NoRevenueTokensForThisShare();
        if (_claimRevenue(shareNumber, msg.sender) == 0) revert NoRevenueToClaim();
        _withdrawEarnings(shareNumber);
    }

    // @notice Allows a user to burn revenue tokens from an ended share.
    // @param  shareNumber: The share to burn revenue tokens from.
    // @param  amount: The amount of revenue tokens to burn.
    function burnRevenueTokens(uint256 shareNumber, uint256 amount) external shareEnded(shareNumber) {
        if (_claimRevenue(shareNumber, msg.sender) > 0) revert MustClaimRevenueToBurnTokens();
        if (amount == 0) revert MustBurnSomeRevenueTokens();
        if (balanceOf(msg.sender, shareData[shareNumber].rTokenNumber) < amount) revert NotEnoughRevenueTokensOwned();
        shareData[shareNumber].rTokenSupply -= amount;
        _burn(msg.sender, shareData[shareNumber].rTokenNumber, amount);
    }

    // @notice Allows a user to burn wealth tokens from an ended share.
    // @param  shareNumber: The share to burn wealth tokens from.
    // @param  amount: The amount of wealth tokens to burn.
    function burnWealthTokens(uint256 shareNumber, uint256 amount) external shareOwner(shareNumber) shareEnded(shareNumber) {
        if (amount == 0) revert MustBurnSomeWealthTokens();
        if (balanceOf(msg.sender, shareData[shareNumber].wTokenNumber) < amount) revert NotEnoughWealthTokensOwned();
        shareData[shareNumber].wTokenSupply -= amount;
    }

    /* Getters */
    // @notice Returns the license NFT Id for a share.
    // @param  shareNumber: The share to get the license Id of.
    // @return licenseId: The license NFT Id.
    function getShareLicenseId(uint256 shareNumber) external view returns (uint256) {
        return shareData[shareNumber].licenseId;
    }

    // @notice Returns the cHypC NFT Id for a share.
    // @param  shareNumber: The share to get the cHyPC Id of.
    // @return chypcId: The cHyPC NFT Id.
    function getShareCHyPCId(uint256 shareNumber) external view returns (uint256) {
        return shareData[shareNumber].chypcId;
    }

    // @notice Returns the owner of a share.
    // @param  shareNumber: The share to get the owner of.
    // @return owner: The owner address.
    function getShareOwner(uint256 shareNumber) external view returns (address) {
        return shareData[shareNumber].owner;
    }

    // @notice Returns the revenue token Id for a share.
    // @param  shareNumber: The share to get the revenue token Id of.
    // @return rTokenNumber: The revenue token Id.
    function getShareRevenueTokenId(uint256 shareNumber) external view returns (uint256) {
        return shareData[shareNumber].rTokenNumber;
    }

    // @notice Returns the wealth token Id for a share.
    // @param  shareNumber: The share to get the wealth token Id of.
    // @return wTokenNumber: The wealth token Id.
    function getShareWealthTokenId(uint256 shareNumber) external view returns (uint256) {
        return shareData[shareNumber].wTokenNumber;
    }

    // @notice Returns the total revenue obtained for a share.
    // @param  shareNumber: The share to get the total revenue of.
    // @return revenueDeposited: The total revenue deposited for this share.
    function getShareTotalRevenue(uint256 shareNumber) external view returns (uint256) {
        return shareData[shareNumber].revenueDeposited;
    }

    // @notice Returns the start time of a share.
    // @param  shareNumber: The share to get the start time of.
    // @return startTimestamp: The block timestamp when this share was created.
    function getShareStartTime(uint256 shareNumber) external view returns (uint256) {
        return shareData[shareNumber].startTimestamp;
    }

    // @notice Returns the message for a share.
    // @param  shareNumber: The share to get the message of.
    // @return message: The message that was set for this share.
    function getShareMessage(uint256 shareNumber) external view returns (string memory) {
        return shareData[shareNumber].message;
    }

    // @notice Returns whether the given share is active.
    // @param  shareNumber: The share to get the status of.
    // @return active: Returns true if the share is active, otherwise false.
    function isShareActive(uint256 shareNumber) external view returns (bool) {
        return shareData[shareNumber].status == Status.STARTED;
    }

    // @notice Returns whether the given share was created yet or not.
    // @param  shareNumber: The share to get the created status of.
    // @return active: Returns true if the share was created, otherwise false.
    function shareCreated(uint256 shareNumber) external view returns (bool) {
        return shareData[shareNumber].status != Status.NOT_CREATED;
    }

    // @notice Returns the total supply of revenue tokens for a share.
    // @param  shareNumber: The share to get the total supply of revenue tokens.
    function getRevenueTokenTotalSupply(uint256 shareNumber) external shareExists(shareNumber) view returns (uint256) {
        return shareData[shareNumber].rTokenSupply;
    }

    // @notice Returns the total supply of wealth tokens for a share.
    // @param  shareNumber: The share to get the total supply of wealth tokens.
    function getWealthTokenTotalSupply(uint256 shareNumber) external shareExists(shareNumber) view returns (uint256) {
        return shareData[shareNumber].wTokenSupply;
    }

    // @notice Returns the pending deposit at the given index.
    // @param  shareNumber: The share to get the pending deposit of.
    // @param  index: The index to look up.
    function getPendingDeposit(uint256 shareNumber, uint256 index) external pendingDepositExists(shareNumber, index) view returns (PendingDeposit memory) {
        return pendingDeposits[shareNumber][index];
    }

    // @notice Returns the length of the pending deposits array for this shareNumber.
    // @param  shareNumber: The share to look up.
    function getPendingDepositsLength(uint256 shareNumber) external shareExists(shareNumber) view returns (uint256) {
        return pendingDeposits[shareNumber].length;
    }

    /* ERC1155 Overrides */

    // @notice Override hooks into the transfer functions of the ERC1155 contract for revenue 
    //         claiming. This allows ERC20-like tokens to be used for revenue sharing purposes.
    //         See ERC1155 contract for details on parameters.
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) public override(ERC1155, IERC1155) {
        //@dev If this is a revenue sharing token, then update the claimed revenue before transfering
        if (id % 2 == 0) {   
            uint256 shareNumber = id/2;
            if (shareData[shareNumber].status == Status.NOT_CREATED) revert ShareDoesntExist();
            _claimRevenue(shareNumber, from);
            _claimRevenue(shareNumber, to);
        }
        super.safeTransferFrom(from, to, id, value, data);  
    }

    // @notice Override hooks into the batch transfer functions of the ERC1155 contract for revenue 
    //         claiming. This allows ERC20-like tokens to be used for revenue sharing purposes.
    //         See ERC1155 contract for details on parameters.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public override(ERC1155, IERC1155) {
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            if (id % 2 == 0) {   
                uint256 shareNumber = id/2;
                if (shareData[shareNumber].status == Status.NOT_CREATED) revert ShareDoesntExist();
                _claimRevenue(shareNumber, from);
                _claimRevenue(shareNumber, to);
            }
        }
        super.safeBatchTransferFrom(from, to, ids, values, data);
    }
}
