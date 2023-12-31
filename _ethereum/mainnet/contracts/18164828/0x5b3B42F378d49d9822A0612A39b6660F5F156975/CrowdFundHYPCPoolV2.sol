// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ICHYPC.sol";
import "./IHYPC.sol";
import "./IHYPCSwap.sol";

import "./Strings.sol";

/**
    @title  Crowd Funded HyPC Pool V2
    @author Barry Rowe, David Liendo
    @notice This contract allows users to pool their HyPC together to swap for c_HyPC (containerized HyPC) that
            can be used to back a license in the HyperCycle ecosystem. Unlike HyPC, which is an ERC20, c_HyPC
            is a ERC721, with each token corresponding to 2^19 = 524,288 HyPC, and can have a string assigned
            to it via its contract. These c_HyPC can be obtained by using the swap contract to deposit 524,288
            HyPC for 1 c_HyPC, and can be redeemed for the deposited HyPC again using the same swap contract.

            Since swapping HyPC for c_HyPC requires a lot of funds, a pooling contract is useful for users 
            wanting to have c_HyPC back their license (via the assignment string). In this case, a license 
            holder can create a proposal in the pool for 1 c_HyPC to back their license. They put up some 
            backing HyPC as collateral for this loan, that will be used as interest payments for the users
            that provide HyPC for the proposal. Unlike in V1 of this pool contract, a license holder can
            create a proposal for multiple c_HyPC instead just one.

            As an example, a manager wants to borrow a c_HyPC for 18 months (78 weeks). The manager puts up 
            50,000 HyPC as collateral to act as interest for the user that deposit to this proposal. This means
            that the yearly APR for a depositor to the proposal will be: 50,000/524,288 * (26/39) = 0.063578288
            or roughly 6.35% (26 being the number of 2 week periods in a year, and 39 the number of 2 week
            periods in the proposal's term). The depositors can then claim this interest every period (2 weeks) 
            until the end of the proposal, at which point they can then withdraw and get back their initial 
            deposit. While the proposal is active, the c_HyPC is held by the pool contract itself, though the 
            manager that created the proposal can change the assignement of the swapped for c_HyPC.

            All amounts of HyPC follow the token's native 6 decimals of percision. Dimensionless amounts,
            like that of the APR calcuation, are also held to 6 decimals of percision. General units are
            as follows:

            HyPC = 6 decimals, (eg: 1.2 HyPC = 1,200,000)
            timestamps = 0 decimals, seconds (eg: startTime = block.timestamp)
            periods = 0 decimals, 2 weeks (ie: 1 period = 2*7*24*60*60 seconds, 18 months = 34 periods)
            interestRate = 6 decimals, dimensionless ( 10% = 100,000 )
            
*/

/* General Errors (modifiers) */
///@dev Error for proposal index being invalid.
error InvalidProposalIndex();
///@dev Error for when the sender must be the owner of the proposal.
error MustBeProposalOwner();
///@dev Error for user deposit index being invalid.
error InvalidDepositIndex();

/* Constructor Errors */
///@dev Error if given an invalid HyPC token address on construction
error InvalidToken();
///@dev Error if given an invalid CHyPC NFT address on construction
error InvalidNFT();
///@dev Error if given an invalid Swap address on construction
error InvalidSwapContract();

/* Create Proposal Errors */
///@dev Error for when the term number is not < 3 (18, 24, and 36 months respectively)
error InvalidTermNumber();
///@dev Error for when the proposal deadline is not later than the current block plus 1 hour buffer.
error DeadlineMustBeInFutureByOneHour();
///@dev Error for when the number of NFTs in a proposal is 0.
error NumberNFTsPositive();
///@dev Error for when the number of NFTs is way too large (>4096).
error NumberNFTsTooLarge();

///@dev Errof for when the poolFee in the request doesn't match.
error PoolFeeDoesntMatch();

/* createDeposit Errors */
///@dev Error for when the proposal it not pending.
error ProposalIsNotPending();
///@dev Error for when the proposal is expired.
error ProposalIsExpired();
///@dev Error for when the HyPC deposit amount is 0.
error HYPCDepositMustBePositive();
///@dev Error for when the HyPC exceeds the requested amount.
error HYPCDepositExceedsProposalRequest();

/* transferDeposit Errors */
///@dev Error for when you try to transfer a deposit to yourself
error CantTransferDepositToSelf();
///@dev Error for when you try to transfer to an address that is not registered.
error AddressNotRegistered();

/* transferProposal Errors */
///@dev Error for when trying to transfer a proposal to yourself.
error CantTransferProposalToSelf();

/* startProposal Errors */
///@dev Error for when trying to start a proposal that hasn't been filled yet.
error ProposalMustBeFilled();

/* swapTokens Errors */
///@dev Error for when the proposal is not in the started state.
error ProposalMustBeInStartedState();
///@dev Error for when trying to swap too many tokens.
error SwappingTooManyTokens();

/* redeemTokens Errors */
///@dev Error for when the proposal must be in the completed state.
error ProposalMustBeCompleted();
///@dev Error for when trying to redeem too many tokens.
error RedeemingTooManyTokens();

/* withdrawDeposit Errors */
///@dev Error for when the proposal is in the started state
error ProposalMustNotBeInStartedState();
///@dev Error for when trying to withdraw a deposit before collecting the interest.
error DepositMustBeUpdatedBeforeWithdrawn();
///@dev Error for when trying to withdraw a deposit before redeeming the tokens.
error TokensMustBeRedeemedFirst();

/* updateDeposit Errors */
///@dev Error for when the proposal is not in the started or completed states.
error ProposalMustBeStartedOrCompleted();
///@dev Error for when not enough time has passed since the last interest collection.
error NotEnoughTimeSinceLastInterestCollection();

/* completeProposal Errors */
///@dev Error for when trying to complete a proposal before it reaches the end of its term.
error ProposalMustReachEndOfTerm();

/* finishProposal Errors */
///@dev Error for when there are still tokens left to redeem.
error TokensStillNeedToBeRedeemed();
///@dev Error for when users still need to withdraw from the proposal.
error UsersMustWithdrawFromProposal();
///@dev Error for when backing funds are 0.
error BackingFundsMustBePositive();

/* changeAssignment Errors */
///@dev Error for when the token index in the proposal is invalid
error InvalidTokenIndex();

contract CrowdFundHYPCPoolV2 is ERC721Holder, Ownable, ReentrancyGuard {
    enum Term {
        PENDING,
        STARTED,
        CANCELLED,
        COMPLETED
    }

    struct ContractProposal {
        address owner;
        uint256 term;
        uint256 interestRateAPR;
        uint256 deadline;
        uint256 startTime;
        uint256 depositedAmount;
        uint256 backingFunds;
        Term status;
        uint256[] tokenIds;
        uint256 numberNFTs;
    }

    struct UserDeposit {
        uint256 amount;
        uint256 proposalIndex;
        uint256 interestTime;
    }

    ContractProposal[] public proposals;
    mapping(address => UserDeposit[]) public userDeposits;

    mapping(address => bool) public transferRegistry;

    /// @notice The HyPC ERC20 contract
    IHYPC public immutable hypcToken;

    /// @notice The c_HyPC ERC721 contract
    ICHYPC public immutable hypcNFT;

    /// @notice The HyPC/c_HyPC swapping contract
    IHYPCSwap public immutable swapContract;

    /** 
        @notice The pool fee set by the pool owner and is collected for each created proposal. 
                This is given in HyPC with 6 decimals, and is per c_HyPC requested, so a
                proposal for two c_HyPC will collect two times the poolFee.
    */
    uint256 public poolFee = 0;

    uint256 private constant PROPOSAL_CREATION_DEADLINE_BUFFER = 3600; //1 hour
    //Timing is done PER WEEK, with the assumption that 1 year = 52 weeks
    uint256 private constant _2_WEEKS = 60 * 60 * 24 * 14;
    uint256 private constant _18_MONTHS = 60 * 60 * 24 * 7 * 78; //78 weeks
    uint256 private constant _24_MONTHS = 60 * 60 * 24 * 7 * 104; //104 weeks
    uint256 private constant _36_MONTHS = 60 * 60 * 24 * 7 * 156; //156 weeks

    uint256 private constant SIX_DECIMALS = 10 ** 6;
    uint256 private constant APR_DECIMALS = 10 ** 6;
    uint256 private constant PERIODS_PER_YEAR = 26;
    uint256 private constant PERIODS_PER_YEAR_TIMES_APR_DECIMALS = PERIODS_PER_YEAR * APR_DECIMALS;
    uint256 private constant HYPC_PER_CHYPC_SIX_DECIMALS = 2 ** 19 * SIX_DECIMALS;

    //@dev Rough leeway parameter for the last deposit of a proposal (1 HyPC).
    uint256 private constant DEPOSIT_FILL_LEEWAY = SIX_DECIMALS;

    //@dev Rough guideline for the maximum number nfts available in the CHYPC contract.
    uint256 private constant MAX_NFTS = 4096;

    //Events
    /// @dev   The event for when a manager creates a proposal.
    /// @param proposalIndex: the proposal that was created
    /// @param owner: the proposal creator's address
    /// @param numberNFTs: the number of NFTs for for this proposal
    /// @param deadline: the deadline in blocktime seconds for this proposal to be filled.
    event ProposalCreated(uint256 indexed proposalIndex, address indexed owner, uint256 numberNFTs, uint256 deadline);

    /// @dev   The event for when a proposal is canceled by its creator
    /// @param proposalIndex: the proposal that was canceled
    /// @param owner: The creator's address
    event ProposalCanceled(uint256 indexed proposalIndex, address indexed owner);

    /// @dev   The event for when a proposal is finished by its creator
    /// @param proposalIndex: the proposal that was finished
    /// @param owner: the creator of the proposal
    event ProposalFinished(uint256 indexed proposalIndex, address indexed owner);

    /// @dev   The event for when a user submits a deposit towards a proposal
    /// @param proposalIndex: the proposal this deposit was made towards
    /// @param user: the user address that submitted this deposit
    /// @param amount: the amount of HyPC the user deposited to this proposal.
    event DepositCreated(uint256 indexed proposalIndex, address indexed user, uint256 amount);

    /// @dev   The event for when a user withdraws a previously created deposit
    /// @param depositIndex: the user's deposit index that was withdrawn
    /// @param user: the user's address
    /// @param amount: the amount of HyPC that was withdrawn.
    event WithdrawDeposit(uint256 indexed depositIndex, address indexed user, uint256 amount);

    /// @dev   The event for when a user updates their deposit and gets interest.
    /// @param depositIndex: the deposit index for this user
    /// @param user: the address of the user
    /// @param interestChange: the amount of HyPC interest given to this user for this update.
    event UpdateDeposit(uint256 indexed depositIndex, address indexed user, uint256 interestChange);

    /// @dev   The event for when a user transfers their deposit to another user.
    /// @param depositIndex: the deposit index for this user
    /// @param user: the address of the user
    /// @param to: the address that this deposit was sent to
    /// @param amount: the amount of HyPC in this deposit.
    event TransferDeposit(uint256 indexed depositIndex, address indexed user, address indexed to, uint256 amount);

    /// @dev   The event for when a proposal owner transfers their proposal to another user.
    /// @param proposalIndex: the proposal index for this
    /// @param user: the address of the user
    /// @param to: the address that this proposal was sent to
    /// @param numberNFTs: the number of c_HyPC requested for this proposal.
    event TransferProposal(uint256 indexed proposalIndex, address indexed user, address indexed to, uint256 numberNFTs);

    /// @dev   The event for when a manager changes the assigned string of a token in a proposal.
    /// @param proposalIndex: Index of the changed proposal.
    /// @param owner: the address of the proposal's owner.
    /// @param assignment: string that the proposal's assignment was changed to.
    /// @param tokenIndex: the index inside the proposal.tokenIds array being changed.
    /// @param assignmentRef: string that the proposal's assignment was changed to.
    event AssignmentChanged(
        uint256 indexed proposalIndex,
        address indexed owner,
        string indexed assignment,
        uint256 tokenIndex,
        string assignmentRef
    );

    /// @dev The event for a token swap.
    /// @param user: Address of the user calling the swap function.
    /// @param proposalIndex: Proposal whose tokens are being swappped.
    /// @param tokensToSwap: Amount of tokens swapped.
    event TokensSwapped(address indexed user, uint256 indexed proposalIndex, uint256 tokensToSwap);

    /// @dev   The event for when tokens has been redeemed.
    /// @param user: Address of the user redeeming the tokens
    /// @param proposalIndex: Index of the proposal from where the tokens will be redeemed
    /// @param redeemedTokens: Amount of tokens redeemed.
    event TokensRedeemed(address indexed user, uint256 indexed proposalIndex, uint256 redeemedTokens);

    /// @dev   The event for when a proposal is started.
    /// @param user: Address of the user that started the proposal
    /// @param proposalIndex: Index of the proposal that was started.
    event ProposalStarted(address indexed user, uint256 indexed proposalIndex, uint256 timestamp);

    /// @dev   The event for when a proposal is started.
    /// @param user: Address of the user that completed the proposal
    /// @param proposalIndex: Index of the proposal that was completed.
    event ProposalCompleted(address indexed user, uint256 indexed proposalIndex, uint256 timestamp);

    /// @dev   The event for when pool fee has been set.
    /// @param poolFee: The fee per token to charge for creating a proposal..
    event PoolFeeSet(uint256 indexed poolFee);

    /// @dev   The event for when a user adds or removes themselves from the transferRegistry
    /// @param flag: The status for this address receiving transfers (true) or not (false)
    event TransferRegistry(address indexed user, bool flag);

    //Modifiers
    /// @dev   Checks that this proposal index has been created.
    /// @param proposalIndex: the proposal index to check
    modifier validIndex(uint256 proposalIndex) {
        if (proposalIndex >= proposals.length) {
            revert InvalidProposalIndex();
        }
        _;
    }

    /// @dev   Checks that the transaction sender is the proposal owner
    /// @param proposalIndex: the proposal index to check ownership of.
    modifier proposalOwner(uint256 proposalIndex) {
        if (msg.sender != proposals[proposalIndex].owner) {
            revert MustBeProposalOwner();
        }
        _;
    }

    /// @dev   Checks that the transaction sender's deposit index is valid.
    /// @param depositIndex: the sender's index to check.
    modifier validDeposit(uint256 depositIndex) {
        if (depositIndex >= userDeposits[msg.sender].length) {
            revert InvalidDepositIndex();
        }
        _;
    }

    /**
        @dev   The constructor takes in the HyPC token, c_HyPC token, and Swap contract addresses to populate
               the contract interfaces.
        @param hypcTokenAddress: the address for the HyPC token contract.
        @param hypcNFTAddress: the address for the CHyPC token contract.
        @param swapContractAddress: the address of the Swap contract.
    */
    constructor(address hypcTokenAddress, address hypcNFTAddress, address swapContractAddress, uint256 defaultFee) {
        if (hypcTokenAddress == address(0)) {
            revert InvalidToken();
        } else if (hypcNFTAddress == address(0)) {
            revert InvalidNFT();
        } else if (swapContractAddress == address(0)) {
            revert InvalidSwapContract();
        }

        hypcToken = IHYPC(hypcTokenAddress);
        hypcNFT = ICHYPC(hypcNFTAddress);
        swapContract = IHYPCSwap(swapContractAddress);

        //pool fee is set to the given default
        poolFee = defaultFee;
        emit PoolFeeSet(defaultFee);
    }

    /// @notice Allows the owner of the pool to set the fee on proposal creation.
    /// @param  fee: the fee in HyPC, per requested c_HyPC, to charge the proposal creator on creation.
    function setPoolFee(uint256 fee) external onlyOwner {
        poolFee = fee;
        emit PoolFeeSet(fee);
    }

    /**
        @notice Allows someone to create a proposal to have HyPC pooled together to swap for c_HyPC token(s).
                The creator specifies the term length for this proposal, the number of c_HyPCs to request,
                and then supplies an amount of HyPC to act as interest for the depositors of the
                proposal.
        @param  termNum: either 0, 1, or 2, corresponding to 18 months, 24 months or 36 months respectively.
        @param  backingFunds: the amount of HyPC that the creator puts up to create the proposal, which acts
                as the interest to give to the depositors during the course of the proposal's term.
        @param  numberNFTs: the number of c_HyPC that this proposal is requesting.
        @param  deadline: the block timestamp that this proposal must be filled by in order to be started.
        @param  specifiedFee: The fee that the creator expects to pay per token
        @dev    The specifiedFee parameter is used to prevent a pool owner from front-running a transaction
                to increase the poolFee after a creator has submitted a transaction.
        @dev    The interest rate calculation for the variable interestRateAPR is described in the contract's
                comment section. The only difference here is that there is an extra term in the numerator of
                APR_DECIMALS since we can't have floating point numbers by default in solidity.
    */
    function createProposal(
        uint256 termNum,
        uint256 backingFunds,
        uint256 numberNFTs,
        uint256 deadline,
        uint256 specifiedFee
    ) external {
        if (termNum >= 3) {
            revert InvalidTermNumber();
        } else if (deadline <= block.timestamp + PROPOSAL_CREATION_DEADLINE_BUFFER) {
            revert DeadlineMustBeInFutureByOneHour();
        } else if (numberNFTs == 0) {
            revert NumberNFTsPositive();
        } else if (numberNFTs > MAX_NFTS) {
            revert NumberNFTsTooLarge();
        } else if (specifiedFee != poolFee) {
            revert PoolFeeDoesntMatch();
        }

        uint256 termLength;
        if (termNum == 0) {
            termLength = _18_MONTHS;
        } else if (termNum == 1) {
            termLength = _24_MONTHS;
        } else {
            termLength = _36_MONTHS;
        }

        uint256 requiredFunds = HYPC_PER_CHYPC_SIX_DECIMALS * numberNFTs;
        uint256 periods = termLength / _2_WEEKS;

        uint256 interestRateAPR = (backingFunds * PERIODS_PER_YEAR_TIMES_APR_DECIMALS) / (requiredFunds * periods);

        proposals.push(
            ContractProposal({
                owner: msg.sender,
                term: termLength,
                interestRateAPR: interestRateAPR,
                deadline: deadline,
                backingFunds: backingFunds,
                tokenIds: new uint256[](0),
                numberNFTs: numberNFTs,
                startTime: 0,
                status: Term.PENDING,
                depositedAmount: 0
            })
        );

        hypcToken.transferFrom(msg.sender, address(this), backingFunds);
        hypcToken.transferFrom(msg.sender, owner(), poolFee * numberNFTs);
        emit ProposalCreated(proposals.length, msg.sender, numberNFTs, deadline);
    }

    /**
        @notice Lets a user creates a deposit for a pending proposal and submit the specified amount of 
                HyPC to back it.
        @param  proposalIndex: the proposal index that the user wants to back.
        @param  amount: the amount of HyPC the user wishes to deposit towards this proposal.
    */
    function createDeposit(uint256 proposalIndex, uint256 amount) external validIndex(proposalIndex) {
        ContractProposal memory proposalData = proposals[proposalIndex];

        if (proposalData.status != Term.PENDING) {
            revert ProposalIsNotPending();
        } else if (block.timestamp >= proposalData.deadline) {
            revert ProposalIsExpired();
        } else if (amount == 0) {
            revert HYPCDepositMustBePositive();
        }

        uint256 total_required_funds = HYPC_PER_CHYPC_SIX_DECIMALS * proposalData.numberNFTs;

        //If amount is bigger than the requested amount because of the leeway parameter,
        //truncate the amount to just the remaining bit.
        uint256 original_amount = amount;
        if (proposalData.depositedAmount + amount > total_required_funds) {
            amount = total_required_funds - proposalData.depositedAmount;
            if (original_amount - amount > DEPOSIT_FILL_LEEWAY) revert HYPCDepositExceedsProposalRequest();
        }

        //Register deposit into proposal's array
        proposals[proposalIndex].depositedAmount += amount;

        //Register user's deposit
        userDeposits[msg.sender].push(UserDeposit({proposalIndex: proposalIndex, amount: amount, interestTime: 0}));
        hypcToken.transferFrom(msg.sender, address(this), amount);
        emit DepositCreated(proposalIndex, msg.sender, amount);
    }

    /**
        @notice Lets a user that owns a deposit for a proposal to transfer the ownership of that
                deposit to another user. This is useful for liquidity since deposit can be tied up for
                fairly long periods of time.
        @param  depositIndex: the index of this users deposits array that they wish to transfer.
        @param  to: the address of the user to send this deposit to
        @dev    Deposit objects are deleted from the deposits array after being transferred. The deposit is 
                deleted and the last entry of the array is copied to that index so the array can be decreased
                in length, so we can avoid iterating through the array.
    */
    function transferDeposit(uint256 depositIndex, address to) external validDeposit(depositIndex) {
        if (to == msg.sender) {
            revert CantTransferDepositToSelf();
        } else if (transferRegistry[to] != true) {
            revert AddressNotRegistered();
        }

        UserDeposit[] memory depositDataArray = userDeposits[msg.sender];
        UserDeposit memory depositData = depositDataArray[depositIndex];

        //Copy deposit to the new address
        userDeposits[to].push(depositData);
        uint256 amount = depositData.amount;

        //Delete this user deposit now.
        //If the deposit is not the last one, then swap it with the last one.
        if (depositDataArray.length > 1 && depositIndex < depositDataArray.length - 1) {
            userDeposits[msg.sender][depositIndex] = depositDataArray[depositDataArray.length - 1];
        }
        userDeposits[msg.sender].pop();
        emit TransferDeposit(depositIndex, msg.sender, to, amount);
    }

    /**
        @notice Lets a proposal owner transfer their proposal to another address.
        @param  proposalIndex: the index of the proposal that they wish to transfer.
        @param  to: the address to send this proposal to
    */
    function transferProposal(
        uint256 proposalIndex,
        address to
    ) external validIndex(proposalIndex) proposalOwner(proposalIndex) {
        if (to == msg.sender) {
            revert CantTransferProposalToSelf();
        } else if (transferRegistry[to] != true) {
            revert AddressNotRegistered();
        }

        proposals[proposalIndex].owner = to;
        emit TransferProposal(proposalIndex, msg.sender, to, proposals[proposalIndex].numberNFTs);
    }

    /**
        @notice Marks a proposal as started after it has received enough HyPC. At this point the proposal
                sets the timestamp for the length of the term and interest payments. 
                periods.
        @param  proposalIndex: the proposal to start.
    */
    function startProposal(uint256 proposalIndex) external validIndex(proposalIndex) {
        ContractProposal memory proposalData = proposals[proposalIndex];

        if (proposalData.status != Term.PENDING) {
            revert ProposalIsNotPending();
        } else if (block.timestamp >= proposalData.deadline) {
            revert ProposalIsExpired();
        } else if (proposalData.depositedAmount != HYPC_PER_CHYPC_SIX_DECIMALS * proposalData.numberNFTs) {
            revert ProposalMustBeFilled();
        }

        //Start the proposal now:
        proposals[proposalIndex].status = Term.STARTED;
        proposals[proposalIndex].startTime = block.timestamp;
        emit ProposalStarted(msg.sender, proposalIndex, block.timestamp);
    }

    /**
        @notice Once a proposal has started, this swaps the deposited HyPC for c_HyPC so that it can
                be assigned by the proposal owner.
        @param  proposalIndex: the index of the proposal to use.
        @param  tokensToSwap: the number of tokens to swap with this call.
        @dev    This function is needed to swap HyPC for c_HyPC aftter a proposal has been started.
                This is split away from the startProposal function in PoolV1  since potentially there 
                could be many swaps required.
    */
    function swapTokens(uint256 proposalIndex, uint256 tokensToSwap) external nonReentrant validIndex(proposalIndex) {
        ContractProposal memory proposalData = proposals[proposalIndex];

        if (proposalData.status != Term.STARTED) {
            revert ProposalMustBeInStartedState();
        } else if (tokensToSwap + proposalData.tokenIds.length > proposalData.numberNFTs) {
            revert SwappingTooManyTokens();
        }

        //approve first
        hypcToken.approve(address(swapContract), tokensToSwap * HYPC_PER_CHYPC_SIX_DECIMALS);

        uint256 _i;
        for (_i = 0; _i < tokensToSwap; _i++) {
            uint256 tokenId = swapContract.nfts(0);
            proposals[proposalIndex].tokenIds.push(tokenId);

            //Swap for CHYPC
            swapContract.swap();
        }
        assert(proposals[proposalIndex].tokenIds.length >= tokensToSwap);
        emit TokensSwapped(msg.sender, proposalIndex, tokensToSwap);
    }

    /**
        @notice Once a proposal has completed, this redeems the previously swapped c_HyPC back to HyPC
                so that it can be withdrawn by the owners of the deposits.
        @param  proposalIndex: the index of the proposal to use.
        @param  tokensToRedeem: the number of tokens to reedem with this call.
        @dev    This function is needed to redeem c_HyPC for HyPC after a proposal has been completed.
                This allows a user with a deposit to reclaim their original deposited HyPC.
    */
    function redeemTokens(
        uint256 proposalIndex,
        uint256 tokensToRedeem
    ) external nonReentrant validIndex(proposalIndex) {
        ContractProposal memory proposalData = proposals[proposalIndex];

        if (proposalData.status != Term.COMPLETED) {
            revert ProposalMustBeCompleted();
        } else if (tokensToRedeem > proposalData.tokenIds.length) {
            revert RedeemingTooManyTokens();
        }

        uint256 _i;
        for (_i = 0; _i < tokensToRedeem; _i++) {
            //unassign token and redeem it.
            uint256 tokenId = proposalData.tokenIds[proposalData.tokenIds.length - _i - 1];
            proposals[proposalIndex].tokenIds.pop();

            hypcNFT.assign(tokenId, '');
            hypcNFT.approve(address(swapContract), tokenId);
            swapContract.redeem(tokenId);
        }

        emit TokensRedeemed(msg.sender, proposalIndex, tokensToRedeem);
    }

    /**
        @notice If a proposal hasn't been started yet, then the creator can cancel it and get back their
                backing HyPC. Users who have deposited can then withdraw their deposits with the withdrawDeposit
                function given below.
        @param  proposalIndex: the proposal index to cancel.
    */
    function cancelProposal(uint256 proposalIndex) external validIndex(proposalIndex) proposalOwner(proposalIndex) {
        if (proposals[proposalIndex].status != Term.PENDING) {
            revert ProposalIsNotPending();
        }

        uint256 amount = proposals[proposalIndex].backingFunds;
        proposals[proposalIndex].backingFunds = 0;
        proposals[proposalIndex].status = Term.CANCELLED;
        hypcToken.transfer(msg.sender, amount);

        emit ProposalCanceled(proposalIndex, msg.sender);
    }

    /**
        @notice Allows a user to withdraw their deposit from a proposal if that proposal has been canceled,
                passed its deadline, has not been started yet, or has come to term. In effect this means that
                to withdraw a token, all status states are ok except the STARTED state. For the case of a proposal
                that has come to term, then the user has to update their deposit to claim any remaining 
                interest first, and all of the proposal's c_HyPC need to be redeemed.
        @param  depositIndex: the index of this user's deposits array that they wish to withdraw.
    */
    function withdrawDeposit(uint256 depositIndex) external validDeposit(depositIndex) {
        UserDeposit[] memory depositDataArray = userDeposits[msg.sender];
        UserDeposit memory depositData = userDeposits[msg.sender][depositIndex];
        uint256 proposalIndex = depositData.proposalIndex;
        ContractProposal memory proposalData = proposals[proposalIndex];
        Term status = proposalData.status;

        if (status == Term.STARTED) {
            revert ProposalMustNotBeInStartedState();
        }

        if (status == Term.COMPLETED) {
            if (depositData.interestTime != proposalData.startTime + proposalData.term) {
                revert DepositMustBeUpdatedBeforeWithdrawn();
            }
            if (proposalData.tokenIds.length != 0) {
                revert TokensMustBeRedeemedFirst();
            }
        }

        uint256 amount = depositData.amount;
        proposals[proposalIndex].depositedAmount -= amount;

        //Delete this user deposit now.
        //If the deposit is not the last one, then swap it with the last one.
        if (depositDataArray.length > 1 && depositIndex < depositDataArray.length - 1) {
            userDeposits[msg.sender][depositIndex] = depositDataArray[depositDataArray.length - 1];
        }
        userDeposits[msg.sender].pop();

        hypcToken.transfer(msg.sender, amount);

        emit WithdrawDeposit(depositIndex, msg.sender, amount);
    }

    /**
        @notice Updates a user's deposit and sends them the accumulated interest from the amount of two week
                periods that have passed.
        @param  depositIndex: the index of this user's deposits array that they wish to update.
        @dev    The interestChange variable takes the user's deposit amount and multiplies it by the 
                proposal's calculated interestRateAPR to get the the yearly interest for this deposit with
                6 extra decimal places. It divides this by the number of periods in a year to get the interest
                from one two-week period, and multiplies it by the number of two week periods that have passed
                since this function was called to account for periods that were previously skipped. Finally,
                it divides the result by APR_DECIMALS to remove the extra decimal places.
    */
    function updateDeposit(uint256 depositIndex) external validDeposit(depositIndex) {
        //get some interest from this deposit
        UserDeposit memory deposit = userDeposits[msg.sender][depositIndex];

        ContractProposal memory proposalData = proposals[deposit.proposalIndex];

        if (proposalData.status != Term.STARTED && proposalData.status != Term.COMPLETED) {
            revert ProposalMustBeStartedOrCompleted();
        }

        if (deposit.interestTime == 0) {
            userDeposits[msg.sender][depositIndex].interestTime = proposalData.startTime;
        }

        uint256 endTime = block.timestamp;
        if (endTime > proposalData.startTime + proposalData.term) {
            endTime = proposalData.startTime + proposalData.term;
        }

        //@dev Don't use depositData since the interestTime could have been changed above
        uint256 periods = (endTime - userDeposits[msg.sender][depositIndex].interestTime) / _2_WEEKS;
        if (periods == 0) {
            revert NotEnoughTimeSinceLastInterestCollection();
        }

        uint256 interestChange = (deposit.amount * periods * proposalData.interestRateAPR) /
            (PERIODS_PER_YEAR_TIMES_APR_DECIMALS);

        //send this interestChange to the user and update both the backing funds and the interest time;
        userDeposits[msg.sender][depositIndex].interestTime += periods * _2_WEEKS;
        proposals[deposit.proposalIndex].backingFunds -= interestChange;

        hypcToken.transfer(msg.sender, interestChange);
        emit UpdateDeposit(depositIndex, msg.sender, interestChange);
    }

    /**
        @notice This completes the proposal after it has come to term, allowing the underlying c_HyPC to be
                redeemed by the contract so it can be given back to the depositors.
        @param  proposalIndex: the proposal's index to complete.
    */
    function completeProposal(uint256 proposalIndex) external validIndex(proposalIndex) {
        ContractProposal memory proposalData = proposals[proposalIndex];
        if (proposalData.status != Term.STARTED) {
            revert ProposalMustBeInStartedState();
        } else if (block.timestamp < proposalData.startTime + proposalData.term) {
            revert ProposalMustReachEndOfTerm();
        }

        proposals[proposalIndex].status = Term.COMPLETED;
        emit ProposalCompleted(msg.sender, proposalIndex, block.timestamp);
    }

    /**
        @notice This allows the creator of a completed proposal to claim any left over backingFunds interest
                after all users have withdrawn their deposits from this proposal.
        @param  proposalIndex: the proposal's index to be finished.
    */
    function finishProposal(uint256 proposalIndex) external validIndex(proposalIndex) proposalOwner(proposalIndex) {
        ContractProposal memory proposalData = proposals[proposalIndex];

        if (proposalData.status != Term.COMPLETED) {
            revert ProposalMustBeCompleted();
        } else if (proposalData.tokenIds.length != 0) {
            revert TokensStillNeedToBeRedeemed();
        } else if (proposalData.depositedAmount != 0) {
            revert UsersMustWithdrawFromProposal();
        } else if (proposalData.backingFunds == 0) {
            revert BackingFundsMustBePositive();
        }

        uint256 amountToSend = proposalData.backingFunds;
        proposals[proposalIndex].backingFunds = 0;

        hypcToken.transfer(msg.sender, amountToSend);
        emit ProposalFinished(proposalIndex, msg.sender);
    }

    /**
        @notice This allows a proposal creator to change the assignment of a c_HyPC token that was swapped for
                in a fulfilled proposal.
        @param  proposalIndex: the proposal's index to have its c_HyPC assignment changed.
        @param  tokenIndex: the index for the token inside the proposal.tokenIds array.
    */
    function changeAssignment(
        uint256 proposalIndex,
        uint256 tokenIndex,
        string memory assignmentString
    ) external validIndex(proposalIndex) proposalOwner(proposalIndex) {
        ContractProposal memory proposalData = proposals[proposalIndex];

        if (proposalData.status != Term.STARTED) {
            revert ProposalMustBeInStartedState();
        } else if (tokenIndex >= proposalData.tokenIds.length) {
            revert InvalidTokenIndex();
        }

        uint256 tokenId = proposalData.tokenIds[tokenIndex];
        hypcNFT.assign(tokenId, assignmentString);

        emit AssignmentChanged(proposalIndex, msg.sender, assignmentString, tokenId, assignmentString);
    }

    /**
        @notice This allows a receving user of a deposit or proposal to first register their address so they 
                can receive the deposit/proposal. This is a safeguard against the sender from fat-fingering
                their address and sending it an invalid address.
    */
    function addToTransferRegistry() external {
        transferRegistry[msg.sender] = true;
        emit TransferRegistry(msg.sender, true);
    }

    /**
        @notice This deletes a user from the transferRegistry. Mostly not needed, but is here for completeness.
    */
    function removeFromTransferRegistry() external {
        delete transferRegistry[msg.sender];
        emit TransferRegistry(msg.sender, false);
    }

    //Getters
    /// @notice Returns a user's deposits
    /// @param  user: the user's address.
    /// @return The UserDeposits array for this user
    function getUserDeposits(address user) external view returns (UserDeposit[] memory) {
        return userDeposits[user];
    }

    /// @notice Returns the length of a user's deposits array
    /// @param  user: the user's address
    /// @return The length of the user deposits array.
    function getDepositsLength(address user) external view returns (uint256) {
        return userDeposits[user].length;
    }

    /// @notice Returns the total number of proposals submitted to the contract so far.
    /// @return The length of the contract proposals array.
    function getProposalsLength() external view returns (uint256) {
        return proposals.length;
    }

    /// @notice Returns the number of tokens swapped for in the given  proposal.
    /// @return The length of the proposal's tokenIds array.
    function getProposalTokensLength(uint256 proposalIndex) external view returns (uint256) {
        return proposals[proposalIndex].tokenIds.length;
    }

    /// @notice Returns the tokenId for a tokenIndex in the proposal's tokenIds array.
    /// @return The tokenId for the tokenIndex index of tokenIds.
    function getProposalTokenId(uint256 proposalIndex, uint256 tokenIndex) external view returns (uint256) {
        return proposals[proposalIndex].tokenIds[tokenIndex];
    }

    /// @notice Returns the assignmentString for an tokenIndex in the proposal's tokenIds array.
    /// @return The length of the assignmentString for the tokenIndex of tokenIds.
    function getProposalAssignmentString(
        uint256 proposalIndex,
        uint256 tokenIndex
    ) external view returns (string memory) {
        return hypcNFT.getAssignment(proposals[proposalIndex].tokenIds[tokenIndex]);
    }
}
