//SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC721Receiver.sol";

/**
 * @title StakingPool
 * @author gotbit
 * @notice Contract represents aт NFT staking pool. It is created as a proxy clone. Contract can accept ERC20 tokens or native currency as a reward token. It accepts 1 / 2 ERC721 / ERC1155 NFTs as staking asset.
 */
contract NFTStakingPool is ERC165 {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    enum NFTType {
        ERC721,
        ERC1155
    }

    struct Stake {
        address owner;
        uint256[] ids;
        uint256[] amounts;
        uint32 lastClaimTimestamp;
        uint32 periodIndex;
        uint32 timestamp;
        uint32 unstakedAtBlockTimestamp;
    }

    struct Range {
        uint256 lowerId; // included into range
        uint256 upperId; // included into range
        uint256[] blackListedIds; // excluded from range (blacklistedIds must be in range)
    }

    struct Period {
        uint128 duration;
        uint128 aprNumerator;
    }

    struct UnstakeData {
        uint64 instantUnstakeDelay; // <= Min stake period
        uint64 liquidationDelay; // >= MIN_LIQUIDATION_DELAY
        uint64 instantUnstakePenalty; // nominated in percents multiplied by ACCURACY
        uint64 earlyUnstakePenalty; // nominated in percents multiplied by ACCURACY
    }

    struct NFTConfig {
        address nft;
        NFTType nftType;
        Range[] whitelist;
        uint256 basePrice;
        uint256 copyLimit;
    }

    // CONSTANTS ----------------------------------------------------------------------

    uint256 public constant ACCURACY = 10 ** 3;
    uint256 public constant YEAR = 365 days; // one year in seconds
    uint256 public constant MIN_STAKE_PERIOD = 1 days + 1; // due to technical reasons add 1 sec for early unstake after instant unstake
    uint256 public constant MAX_STAKE_PERIOD = 5 * YEAR;
    uint256 public constant MAX_COPY_AMOUNT = 10 ** 18;
    uint256 public constant MAX_BASE_PRICE = 10 ** 55; // 10 ** 55 * MAX COPY AMOUNT * aprNumerator < 10**77
    uint256 public constant MIN_BASE_PRICE = 10 ** 3;
    uint256 public constant STAKING_PERIODS_LIMIT = 10; // max staking periods count
    uint256 public constant ONE_HUNDRED = 100; // 100%
    uint256 public constant MAX_APR_NUMERATOR = ACCURACY * 10000; // max apr = 10_000%
    uint256 public constant MIN_LIQUIDATION_DELAY = 7 days;
    uint256 public constant NFT_RANGES_LIMIT = 10; // limit of ids ranges for NFT WL
    uint256 public constant BLACKLIST_LIMIT = 10; // max blacklisted nfts count
    uint256 public constant LIMIT_IDS = 500; // 500 IDs per each contract
    uint256 public constant NFTS_LIMIT = 10;
    uint256 public constant MAX_FEE = 300 * ACCURACY; // 300%
    uint256 public constant MULTIPLE_STAKES_IDS_LIMIT = 1;
    uint256 public constant REWARDS_ACCUMULATE_THRESHOLD = 5 minutes;

    // IMMUTABLE ----------------------------------------------------------------------

    address public owner;
    Period[] public stakingPeriods;

    NFTConfig[] public nftConfigs;

    // token if != 0x0, else native currency
    IERC20 public rewardToken;
    // token != 0x0
    IERC20 public bonusToken;
    uint256 public bonusQuoteForUnstake;

    UnstakeData public unstakeInfo;

    // MUTABLE ----------------------------------------------------------------------

    // id => stake
    mapping(uint256 => Stake) public stakes;
    // user => ids array
    mapping(address => uint256[]) public idsByUser;
    // user => acive ids set
    mapping(address => EnumerableSet.UintSet) private activeIdsByUser;
    EnumerableSet.UintSet private activeStakeIds;
    // user => received status
    mapping(uint256 => bool) public receivedBonus;
    // NFT => bool
    mapping(address => bool) public isNFT;
    // max potential reward debt
    uint256 public maxPotentialDebt;
    // bonus token balance (if reward token != bonus token)
    uint256 public bonusBalance;

    string public name;
    string public link;
    uint256 public globalId;

    bool public paused;

    // EVENTS ----------------------------------------------------------------------

    event Staked(
        address indexed user,
        uint256 indexed id,
        uint256[] ids,
        uint256[] amounts,
        uint256 stakingPeriodIndex
    );
    event Withdrawn(address indexed user, uint256 indexed id);
    event Claimed(address indexed user, uint256 indexed id, uint256 rewards);
    event Received(address indexed from, uint256 amount);
    event Liquidated(address indexed user, uint256 indexed id);

    // ERRORS ----------------------------------------------------------------------

    error ContractInit();
    error IndexOutOfBounds();
    error NotSupportedID();
    error NotSet();
    error AlreadySet();
    error NotReceiveETH();
    error NotOwner();
    error MaxPotentialDebtExceeded();
    error PaymentFailure();
    error Duplicate();
    error EmptyStr();
    error WrongRange();
    error Paused();
    error ZeroAddress();

    error ValueTooHigh(string message);
    error ValueTooLow(string message);
    error ValueZero(string message);
    error InvalidLength(string message);
    error IntervalsCrossover(string message);
    error InterfaceNotSupported(string message);
    error InvalidState(string message);

    // MODIFIERS ----------------------------------------------------------------------

    modifier whenBonusSet() {
        if (address(bonusToken) == address(0)) revert NotSet();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlySupportedId(uint256 id) {
        if (id > globalId || globalId == 0) revert IndexOutOfBounds();
        _;
    }

    // EXTERNAL WRITE ----------------------------------------------------------------------

    /// @notice default receive payable function to accept ether
    receive() external payable {
        if (address(rewardToken) != address(0)) revert NotReceiveETH();
        emit Received(msg.sender, msg.value);
    }

    /// @notice Adds new bonus amount to contract
    /// @param from Token holder
    /// @param amount Bonus token amount
    function addBonus(
        address from,
        uint256 amount
    ) external onlyOwner whenBonusSet {
        if (amount == 0) revert ValueZero('amount');

        bonusBalance += amount;
        bonusToken.safeTransferFrom(from, address(this), amount);
    }

    /// @notice Inutializes contract
    /// @dev Is called by the staking aggregator
    /// @param rewardToken_ - reward token address
    /// @param nftConfigs_ - NFTConfig struct array
    /// @param periods_ - array of structs with stakingPeriods, APRs
    /// @param unstakeData_ - struct with instant / early unstake fees and instant / liquidation delays
    /// @param bonusToken_ - bonus token address
    /// @param bonusQuoteForUnstake_ - amount of a bonus quote which is given to a user after unstake
    function initialize(
        IERC20 rewardToken_,
        NFTConfig[] calldata nftConfigs_,
        Period[] calldata periods_,
        UnstakeData calldata unstakeData_,
        IERC20 bonusToken_,
        uint256 bonusQuoteForUnstake_
    ) external {
        if (nftConfigs.length != 0) revert ContractInit();

        if (nftConfigs_.length == 0 || nftConfigs_.length > NFTS_LIMIT)
            revert InvalidLength('nft config');
        if (periods_.length == 0 || periods_.length > STAKING_PERIODS_LIMIT)
            revert InvalidLength('periods');

        if (unstakeData_.instantUnstakeDelay >= MIN_STAKE_PERIOD)
            revert ValueTooHigh('instant delay');
        if (unstakeData_.liquidationDelay < MIN_LIQUIDATION_DELAY)
            revert ValueTooLow('liquidation delay');

        if (unstakeData_.instantUnstakePenalty > MAX_FEE)
            revert ValueTooHigh('instant penalty');
        if (unstakeData_.earlyUnstakePenalty > MAX_FEE)
            revert ValueTooHigh('early penalty');

        owner = msg.sender;
        unstakeInfo = unstakeData_;
        rewardToken = rewardToken_;

        if (address(bonusToken_) != address(0) && bonusQuoteForUnstake_ != 0) {
            bonusToken = bonusToken_;
            bonusQuoteForUnstake = bonusQuoteForUnstake_;
        }

        // CHECK STAKING PERIODS + APRs
        _checkPeriod(periods_[0]);
        stakingPeriods.push(periods_[0]);
        for (uint256 i = 1; i < periods_.length; ) {
            // make sure that periods are sorted and unique
            if (periods_[i].duration <= periods_[i - 1].duration)
                revert IntervalsCrossover('periods');

            _checkPeriod(periods_[i]);

            // add the new Period
            stakingPeriods.push(periods_[i]);
            unchecked {
                ++i;
            }
        }
        // added periods

        // CHECK NFTs + WL + BL + BASE PRICE + COPY LIMIT
        for (uint256 i; i < nftConfigs_.length; ) {
            NFTConfig memory config = nftConfigs_[i];
            if (config.nft == address(0)) revert ZeroAddress();
            // check for NFT duplicate
            if (isNFT[config.nft]) revert Duplicate();
            // remember nft address
            isNFT[config.nft] = true;

            if (config.nftType == NFTType.ERC1155) {
                if (
                    !IERC1155(config.nft).supportsInterface(
                        type(IERC1155).interfaceId
                    )
                ) revert InterfaceNotSupported('ERC1155');
            } else {
                if (
                    !IERC721(config.nft).supportsInterface(
                        type(IERC721).interfaceId
                    )
                ) revert InterfaceNotSupported('ERC721');
            }

            // check whitelist + blacklist + allowd id limit
            _checkWhitelist(config.whitelist);

            // check base price
            if (config.basePrice > MAX_BASE_PRICE)
                revert ValueTooHigh('base price');
            if (config.basePrice < MIN_BASE_PRICE)
                revert ValueTooLow('base price');

            // check copy amount

            // not allowed empty stake positions
            if (config.copyLimit == 0) revert ValueZero('copy limit');

            if (config.nftType == NFTType.ERC721) {
                // ERC721 can not have copies
                if (config.copyLimit > 1) revert ValueTooHigh('copy limit');
            } else {
                // ERC1155

                if (nftConfigs_.length == 1) {
                    // Single staking => copy limit <= MAX COPY LIMIT
                    if (config.copyLimit > MAX_COPY_AMOUNT)
                        revert ValueTooHigh('copy limit');
                } else {
                    // Multiple staking => only 1 NFT
                    // if MULTIPLE_STAKES_IDS_LIMIT == 1 => only 1 is allowed
                    if (config.copyLimit > MULTIPLE_STAKES_IDS_LIMIT)
                        revert ValueTooHigh('copy limit');
                }
            }

            // add new config
            nftConfigs.push(nftConfigs_[i]);

            unchecked {
                ++i;
            }
        }
        // added configs
    }

    /// @notice Allows users to stake their NFTs in order to earn rewards
    /// @param ids - an array of ids (one for each NFT collection)
    /// @param amounts - an array of amounts (one for each NFT collection and id)
    /// @param stakingPeriodIndex - index of a desired staking period (duration / apr)
    function stake(
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256 stakingPeriodIndex
    ) external {
        if (paused) revert Paused();
        // check lengths
        uint256 nftCount = nftConfigs.length;
        NFTConfig[] memory configs = nftConfigs;

        if (ids.length != nftCount) revert InvalidLength('ids');
        if (amounts.length != nftCount) revert InvalidLength('amounts');

        // check if a staking period with a given index exists
        if (stakingPeriodIndex >= stakingPeriods.length)
            revert IndexOutOfBounds();

        for (uint256 i; i < ids.length; ) {
            if (!inWhitelist(i, ids[i])) revert NotSupportedID();
            if (amounts[i] == 0) revert ValueZero('amount');
            if (amounts[i] > configs[i].copyLimit)
                revert ValueTooHigh('amount');

            unchecked {
                ++i;
            }
        }

        // increase max potential debt

        Period memory period = stakingPeriods[stakingPeriodIndex];

        maxPotentialDebt += _calculateRewardsForDurationAndStakingPeriod(
            amounts,
            period.aprNumerator,
            period.duration
        );

        uint256 balance = contractBalance();

        // ETH is transferred instantly, ERC20 is transferred manually in the end of tx
        address rewardTokenAddress = address(rewardToken);
        address bonusTokenAddress = address(bonusToken);

        if (rewardTokenAddress != address(0)) {
            // ERC20 => possible bonusToken == stakingToken
            uint256 bonusBalanceLocal = bonusBalance;
            if (
                bonusTokenAddress == rewardTokenAddress &&
                bonusBalanceLocal != 0
            ) {
                // reserve a part of contract balance for rewards
                balance -= bonusBalanceLocal;
            }
        }

        // else
        // ETH => impossible bonusToken == stakingToken
        // bonus token not set => no reserved balance
        // bonus token set and != staking token => no receved balance

        // min debt exceeds current balance => revert
        if (maxPotentialDebt > balance) revert MaxPotentialDebtExceeded();

        // increase global id
        uint256 id = ++globalId;

        // add stake
        stakes[id] = Stake({
            owner: msg.sender,
            ids: ids,
            amounts: amounts,
            lastClaimTimestamp: uint32(block.timestamp), // no claim yet
            periodIndex: uint32(stakingPeriodIndex),
            timestamp: uint32(block.timestamp),
            unstakedAtBlockTimestamp: 0
        });

        idsByUser[msg.sender].push(id);
        activeIdsByUser[msg.sender].add(id);
        activeStakeIds.add(id);

        emit Staked(msg.sender, id, ids, amounts, stakingPeriodIndex);

        // receive funds
        _transferNFT(
            nftCount,
            configs,
            msg.sender,
            address(this),
            ids,
            amounts
        );
    }

    /// @notice Allows user to withdraw staked NFTs + claim earned rewards - penalties
    /// @param id Stake id
    function withdraw(uint256 id) external payable onlySupportedId(id) {
        Stake storage _stake = stakes[id];
        // check if already unstaked
        if (_stake.unstakedAtBlockTimestamp != 0)
            revert InvalidState('unstaked');

        // check if can be unstaked by user (NOT liquidation)

        Period memory period = stakingPeriods[_stake.periodIndex];
        if (
            block.timestamp >
            _stake.timestamp + period.duration + unstakeInfo.liquidationDelay
        ) revert InvalidState('liquidated');

        // check if stake owner unstakes position
        if (_stake.owner != msg.sender) revert NotOwner();

        // strict < (because real duration < stake period => early unstake)
        if (block.timestamp < _stake.timestamp + period.duration) {
            // EARLY UNSTAKE
            (, uint256 earnedAmount, uint256 claimedAmount) = _internalClaim(
                id,
                _stake,
                period,
                false,
                true
            );

            // early / instant unstake => pay fees to unstake
            uint256 actualStakingTime = block.timestamp - _stake.timestamp;
            UnstakeData memory unstakeDataLocal = unstakeInfo;
            uint256 fee;
            if (actualStakingTime < unstakeDataLocal.instantUnstakeDelay) {
                // INSTANT UNSTAKE
                fee = unstakeDataLocal.instantUnstakePenalty;
            } else {
                // EARLY UNSTAKE
                fee = unstakeDataLocal.earlyUnstakePenalty;
            }

            // the goal is: contract holds all earned reward + fees
            // target amount = earned * (100% + fee)
            uint256 rewardPenalty = (earnedAmount * fee) /
                (ONE_HUNDRED * ACCURACY);

            // user has to payback all claimed rewards + reward fee
            uint256 rewardToContract = claimedAmount + rewardPenalty;

            // update stake struct
            stakes[id].lastClaimTimestamp = _stake.timestamp;

            _deactivateStake(id, msg.sender);

            // request fees + claimed rewards
            _accept(msg.sender, rewardToContract);
        } else {
            // late unstake => pay left rewards
            (uint256 reward, , ) = _internalClaim(
                id,
                _stake,
                period,
                false,
                false
            );

            // update stake struct
            stakes[id].lastClaimTimestamp = uint32(block.timestamp);

            // NO LIQUIDATION HERE, THE RETURN STATEMENT FOR LIQUIDATION IS ABOVE
            // unstake in time => if bonus not set => no ability to receive bonus => make bonus inactive
            if (address(bonusToken) == address(0))
                _deactivateStake(id, _stake.owner);

            // pay left rewards
            if (reward != 0) _pay(msg.sender, reward);
        }

        emit Withdrawn(msg.sender, id);

        // transfer principal NFT back
        _transferNFT(
            _stake.ids.length,
            nftConfigs,
            address(this),
            msg.sender,
            _stake.ids,
            _stake.amounts
        );
    }

    /// @notice Allows owner to liquidate stake position
    /// @param id Stake id
    /// @param transferFunds Flag (true if transfer principal and rewards to recepient address, else if leave funds on contract address)
    /// @param recepient Fees receiver address
    function liquidate(
        uint256 id,
        bool transferFunds,
        address recepient
    ) external onlyOwner onlySupportedId(id) {
        Stake storage _stake = stakes[id];
        if (_stake.unstakedAtBlockTimestamp != 0)
            revert InvalidState('unstaked');
        // check if can be unstaked by user (NOT liquidation)
        Period storage period = stakingPeriods[_stake.periodIndex];
        if (
            block.timestamp <=
            _stake.timestamp + period.duration + unstakeInfo.liquidationDelay
        ) revert InvalidState('only withdraw');

        (uint256 reward, , ) = _internalClaim(id, _stake, period, false, false);

        _deactivateStake(id, _stake.owner);

        if (recepient == address(0)) revert ZeroAddress();

        emit Liquidated(msg.sender, id);

        // pay rewards if needed
        if (transferFunds) {
            if (reward != 0) _pay(recepient, reward);
        }

        // transfer principal NFT to recepient
        _transferNFT(
            _stake.ids.length,
            nftConfigs,
            address(this),
            recepient,
            _stake.ids,
            _stake.amounts
        );
    }

    /// @notice Internal withdraw / claim / liquidate logic
    /// @param id - stake id
    /// @param stakeData - stake struct instance
    /// @param period - period struct instance
    /// @param isClaim - flag showing if set stake to unstaked or not
    /// @param useRewardAccumulateThreshold - flag showing if earned amount should be calculated not continuously by with a certain step
    /// @return reward - current reward accumulated,  earnedAmount - total reward accumulated,  claimedAmount - previously claimed reward
    function _internalClaim(
        uint256 id,
        Stake memory stakeData,
        Period memory period,
        bool isClaim,
        bool useRewardAccumulateThreshold
    )
        private
        returns (uint256 reward, uint256 earnedAmount, uint256 claimedAmount)
    {
        uint256 claimDuration = stakeData.lastClaimTimestamp -
            stakeData.timestamp;
        claimedAmount = _calculateRewardsForDurationAndStakingPeriod(
            stakeData.amounts,
            period.aprNumerator,
            claimDuration
        );

        uint256 stakeDuration = getStakeRealDuration(id);
        reward =
            _calculateRewardsForDurationAndStakingPeriod(
                stakeData.amounts,
                period.aprNumerator,
                stakeDuration
            ) -
            claimedAmount; // total earned reward - claimed reward

        if (useRewardAccumulateThreshold) {
            // duration accumulates each REWARDS_ACCUMULATE_THRESHOLD seconds (not continuously)
            stakeDuration -= stakeDuration % REWARDS_ACCUMULATE_THRESHOLD;
        }

        earnedAmount = _calculateRewardsForDurationAndStakingPeriod(
            stakeData.amounts,
            period.aprNumerator,
            stakeDuration
        );

        if (isClaim) {
            if (reward == 0) revert ValueZero('reward'); // reward = 0, claim => revert
            maxPotentialDebt -= reward;
            stakes[id].lastClaimTimestamp = uint32(block.timestamp);
        } else {
            // substract the max potential debt
            maxPotentialDebt -= _calculateRewardsForDurationAndStakingPeriod(
                stakeData.amounts,
                period.aprNumerator,
                period.duration - claimDuration // substract only unclaimed reward
            );
            stakes[id].unstakedAtBlockTimestamp = uint32(block.timestamp);
        }
    }

    /// @notice Allows to claim all currently earned reward without unstaking the principal
    /// @param id Stake id
    function claim(uint256 id) external onlySupportedId(id) {
        Stake storage _stake = stakes[id];
        if (_stake.unstakedAtBlockTimestamp != 0)
            revert InvalidState('unstaked');
        if (_stake.owner != msg.sender) revert NotOwner();
        // check if stake is in progress
        Period storage period = stakingPeriods[_stake.periodIndex];
        if (block.timestamp > _stake.timestamp + period.duration)
            revert InvalidState('period ended');

        (uint256 reward, , ) = _internalClaim(id, _stake, period, true, false);

        // ALL TRANSFERS -------------------------------------------------------

        emit Claimed(msg.sender, id, reward);

        // reward != 0 here
        _pay(msg.sender, reward);
    }

    /// @notice Allows user to receive bonus if stake was unstaked safely (not early / instant unstake, not liquidation)
    /// @param id Stake id
    function receiveBonus(
        uint256 id
    ) external whenBonusSet onlySupportedId(id) {
        Stake storage _stake = stakes[id];
        if (receivedBonus[id]) revert InvalidState('received');

        // stake must be withdrawn
        if (_stake.unstakedAtBlockTimestamp == 0)
            revert InvalidState('not unstaked');
        if (_stake.owner != msg.sender) revert NotOwner();

        Period storage period = stakingPeriods[_stake.periodIndex];

        // unstake timestamp != 0 && unstake timestamp > stake timestamp
        uint256 holdTime = _stake.unstakedAtBlockTimestamp - _stake.timestamp;
        if (holdTime > period.duration + unstakeInfo.liquidationDelay)
            revert InvalidState('liquidated');
        if (holdTime < period.duration) revert InvalidState('early withdraw');

        // prevent from double spend
        receivedBonus[id] = true;

        _deactivateStake(id, msg.sender);

        // check bonus balance is sufficient, works even if reward token = bonus token
        if (bonusBalance < bonusQuoteForUnstake)
            revert ValueTooLow('bonus balance');

        bonusBalance -= bonusQuoteForUnstake;

        bonusToken.safeTransfer(_stake.owner, bonusQuoteForUnstake);
    }

    /// @notice Sets paused state for the contract (can be called by the owner only)
    /// @param paused_ paused flag
    function setPaused(bool paused_) external onlyOwner {
        paused = paused_;
    }

    /// @notice Can withdraw extra bonus tokens from the pool contract (can be called by the owner only)
    /// @param recepient - recepient address
    /// @param amount - bonus amount
    function emergencyWithdrawBonus(
        address recepient,
        uint256 amount
    ) external onlyOwner whenBonusSet {
        if (recepient == address(0)) revert ZeroAddress();
        if (amount == 0) revert ValueZero('amount');
        if (amount > bonusBalance) revert ValueTooHigh('amount');

        bonusBalance -= amount;

        bonusToken.safeTransfer(recepient, amount);
    }

    /// @notice Can withdraw extra funds from the pool contract (can be called by the owner only)
    /// @param recepient - recepient address
    /// @param amount - funds amount
    function emergencyWithdrawFunds(
        address payable recepient,
        uint256 amount
    ) external onlyOwner {
        if (recepient == address(0)) revert ZeroAddress();
        if (amount == 0) revert ValueZero('amount');
        if (amount > getRewardsAvailable()) revert ValueTooHigh('amount');
        _pay(recepient, amount);
    }

    /// @notice Sets new name and image link for the pool contract
    /// @param name_ New name string
    /// @param link_ New image link string
    function setNameAndLink(
        string calldata name_,
        string calldata link_
    ) external onlyOwner {
        if ((bytes(name_)).length == 0) revert EmptyStr();
        if ((bytes(link_)).length == 0) revert EmptyStr();
        name = name_;
        link = link_;
    }

    /// @notice Sets new whitelist for a given NFT collection
    /// @param nftIndex nft collection index in nftConfigs array
    /// @param whitelist_ new whitelist
    function setWhitelist(
        uint256 nftIndex,
        Range[] memory whitelist_
    ) external onlyOwner {
        if (nftIndex >= nftConfigs.length) revert IndexOutOfBounds();
        _checkWhitelist(whitelist_);

        uint256 len = whitelist_.length;
        delete nftConfigs[nftIndex].whitelist;
        for (uint256 i; i < len; ) {
            nftConfigs[nftIndex].whitelist.push(whitelist_[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice ERC165 function supportsInterface, in this case it detects that a contract is IERC1155 / IERC721 Receiver
    /// @return interfaceId - the corresponding bytes representation of interface id
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice ERC1155 function onERC1155Received
    /// @return selector - the corresponding bytes representation of this function signature
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @notice ERC1155 function onERC1155BatchReceived
    /// @return selector - the corresponding bytes representation of this function signature
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /// @notice ERC721 function onERC721Received
    /// @return selector - the corresponding bytes representation of this function signature
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // PUBLIC VIEW ----------------------------------------------------------------------

    /// @notice Checks if a certain ID is allowed by the corresponding whitelist
    /// @dev Uses max O(M + N), where M - WL length (M <= 10), N - sum of BL`s lengths (N <= 10)
    /// @param nftIndex - NFTs index in protocol
    /// @param id - NFT id
    /// @return true - if id is allowed for the NFT WL, else - false
    function inWhitelist(
        uint256 nftIndex,
        uint256 id
    ) public view returns (bool) {
        if (nftIndex >= nftConfigs.length) revert IndexOutOfBounds();
        NFTConfig memory config = nftConfigs[nftIndex];

        for (uint256 rangeIndex; rangeIndex < config.whitelist.length; ) {
            Range memory range = config.whitelist[rangeIndex];
            // check if id is in range
            if (id >= range.lowerId && id <= range.upperId) {
                // check if id is not blacklisted
                for (
                    uint256 blacklistId;
                    blacklistId < range.blackListedIds.length;

                ) {
                    // return False if id is in BL
                    if (id == range.blackListedIds[blacklistId]) return false;

                    unchecked {
                        ++blacklistId;
                    }
                }

                // ID in range and is not blacklisted => ID is allowed
                return true;
            }

            // Continue => check the next range
            unchecked {
                ++rangeIndex;
            }
        }

        // all rounds are checked => ID is not included into rounds
        return false;
    }

    /// @notice Allows to view staking token contract balance
    /// @return balance of staking token contract balance
    function contractBalance() public view returns (uint256) {
        if (address(rewardToken) != address(0))
            return rewardToken.balanceOf(address(this));
        else return address(this).balance;
    }

    /// @notice Returns rewards which can be distributed to new users
    /// @return Max reward available at the moment
    function getRewardsAvailable() public view returns (uint256) {
        // maxPotentialDebt = sum of principal + sum of max potential reward
        uint256 balance = contractBalance();
        // can not withdraw bonus here
        uint256 debt;
        if (address(bonusToken) == address(rewardToken))
            debt = maxPotentialDebt + bonusBalance;
        else debt = maxPotentialDebt;

        return (balance > debt) ? balance - debt : 0;
    }

    /// @notice Allows to view current user earned rewards
    /// @param id to view rewards
    /// @return earned - Amount of rewards for the selected user stake
    function earned(uint256 id) external view returns (uint256) {
        Stake storage _stake = stakes[id];
        if (_stake.unstakedAtBlockTimestamp == 0) {
            // ACTIVE STAKE => calculate amount + increase reward per token
            // amountForDuration >= amount
            Period storage period = stakingPeriods[_stake.periodIndex];
            return
                _calculateRewardsForDurationAndStakingPeriod(
                    _stake.amounts,
                    period.aprNumerator,
                    getStakeRealDuration(id)
                );
        }

        // INACTIVE STAKE
        return 0;
    }

    /// @notice Returns the stake exact hold time
    /// @param id stake id
    /// @return duration - stake exact hold time
    function getStakeRealDuration(
        uint256 id
    ) internal view returns (uint256 duration) {
        Stake storage _stake = stakes[id];
        Period storage period = stakingPeriods[_stake.periodIndex];
        uint256 holdTime = block.timestamp - _stake.timestamp;
        uint256 stakingPeriod = period.duration;
        duration = holdTime > stakingPeriod ? stakingPeriod : holdTime;
    }

    /// @notice Returns all available staking periods
    /// @return periods - an array of Period structs
    function getStakePeriods() external view returns (Period[] memory) {
        return stakingPeriods;
    }

    /// @notice Returns all available nft configs
    /// @return configs - an array of NFTConfig structs
    function getNFTConfigs() external view returns (NFTConfig[] memory) {
        return nftConfigs;
    }

    /// @notice Returns a stake struct with a given id
    /// @return stake - Stake struct instance
    function getStake(uint256 id) external view returns (Stake memory) {
        return stakes[id];
    }

    /// @notice Allows to get a slice of user stake ids array
    /// @param user user account
    /// @param offset Starting index in user ids array
    /// @param length return array length
    /// @return Array-slice of user stake ids
    function getUserStakesIdsSlice(
        address user,
        uint256 offset,
        uint256 length
    ) external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](length);
        for (uint256 i; i < length; ) {
            res[i] = idsByUser[user][i + offset];
            unchecked {
                ++i;
            }
        }
        return res;
    }

    /// @notice Allows to get a slice of current active stake ids array
    /// @param offset Starting index in ids array
    /// @param length return array length
    /// @return Array-slice of active stake ids
    function getActiveStakesIdsSlice(
        uint256 offset,
        uint256 length
    ) external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](length);
        for (uint256 i; i < length; ) {
            res[i] = activeStakeIds.at(i + offset);
            unchecked {
                ++i;
            }
        }
        return res;
    }

    /// @notice Allows to get a slice of current active user`s stake ids array
    /// @param user - staker address
    /// @param offset Starting index in user ids array
    /// @param length return array length
    /// @return Array-slice of user active stake ids
    function getUserActiveStakesIdsSlice(
        address user,
        uint256 offset,
        uint256 length
    ) external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](length);
        for (uint256 i; i < length; ) {
            res[i] = activeIdsByUser[user].at(i + offset);
            unchecked {
                ++i;
            }
        }
        return res;
    }

    /// @notice Allows to get a length of current active user`s stake ids array
    /// @param user - staker address
    /// @return Length of user active stake ids array
    function getUserActiveStakesIdsLength(
        address user
    ) external view returns (uint256) {
        return activeIdsByUser[user].length();
    }

    /// @notice Allows to get a length of current active stake ids array
    /// @return Length of active stake ids array
    function getActiveStakesIdsLength() external view returns (uint256) {
        return activeStakeIds.length();
    }

    /// @notice Allows to get a length of user`s stake ids array
    /// @param user - staker address
    /// @return Length of user stake ids array
    function getUserStakesLength(address user) external view returns (uint256) {
        return idsByUser[user].length;
    }

    // PRIVATE ----------------------------------------------------------------------

    /// @notice Calculates the max potential reward after unstake for a stake (without substracting penalties)
    /// @param amounts - staked NFT`s copy amounts
    /// @param aprNumerator - APR numerator
    /// @param duration - stake hold period
    /// @return reward potential unstaked reward
    function _calculateRewardsForDurationAndStakingPeriod(
        uint256[] memory amounts,
        uint256 aprNumerator,
        uint256 duration
    ) private view returns (uint256) {
        uint256 rewardNumerator;
        uint256 len = nftConfigs.length;
        for (uint256 nftIndex; nftIndex < len; ) {
            // only one storage accessing here
            rewardNumerator +=
                nftConfigs[nftIndex].basePrice *
                amounts[nftIndex];
            unchecked {
                ++nftIndex;
            }
        }

        return
            (rewardNumerator * aprNumerator * duration) /
            (YEAR * ONE_HUNDRED * ACCURACY);
    }

    /// @notice Checks if a period is correcty set
    /// @param period - Period struct instance
    function _checkPeriod(Period memory period) private pure {
        if (period.duration < MIN_STAKE_PERIOD) revert ValueTooLow('duration');
        if (period.duration > MAX_STAKE_PERIOD) revert ValueTooHigh('duration');

        if (period.aprNumerator > MAX_APR_NUMERATOR) revert ValueTooHigh('apr');
    }

    /// @notice Checks if a whitelist is correcty set
    /// @param whitelist - Range[] struct instance array, the new whitelist
    function _checkWhitelist(Range[] memory whitelist) private pure {
        if (whitelist.length == 0 || whitelist.length > NFT_RANGES_LIMIT)
            revert InvalidLength('ranges');
        // check if total IDS number is <= 500
        uint256 totalIdsCount = _checkWhitelistRange(whitelist[0]);
        uint256 totalBlackListLength = whitelist[0].blackListedIds.length;

        // max LIMIT_IDS allowed for each whitelist
        if (totalIdsCount > LIMIT_IDS) revert ValueTooHigh('ids count');
        // max BLACKLIST_LIMIT allowed for blacklist in total
        if (totalBlackListLength > BLACKLIST_LIMIT) revert ValueTooHigh('bl');

        for (uint256 i = 1; i < whitelist.length; ) {
            Range memory range = whitelist[i];
            totalIdsCount += _checkWhitelistRange(range);
            totalBlackListLength += whitelist[i].blackListedIds.length;

            // max LIMIT_IDS allowed for each whitelist
            if (totalIdsCount > LIMIT_IDS) revert ValueTooHigh('ids count');
            // max BLACKLIST_LIMIT allowed for blacklist in total
            if (totalBlackListLength > BLACKLIST_LIMIT)
                revert ValueTooHigh('bl');

            // check ranges not overlap and are sorted
            if (range.lowerId <= whitelist[i - 1].upperId)
                revert IntervalsCrossover('ranges');

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Checks if a range is correcty set
    /// @param range - Range struct instance
    function _checkWhitelistRange(
        Range memory range
    ) private pure returns (uint256 length) {
        /*
            1) check lowerId <= upperId
            2) check all blacklistedIds in range (>= lowerId && <= upperId)
            3) check range allows at least id (blacklist.len < rangeLen)
        */
        if (range.lowerId > range.upperId) revert WrongRange();

        uint256 rangeLen = range.upperId - range.lowerId + 1;
        uint256 blLength = range.blackListedIds.length;

        if (rangeLen <= blLength) revert InvalidLength('bl > range');

        for (uint256 j; j < blLength; ) {
            if (
                range.blackListedIds[j] < range.lowerId ||
                range.blackListedIds[j] > range.upperId
            ) revert IndexOutOfBounds();
            unchecked {
                ++j;
            }
        }

        return rangeLen - blLength;
    }

    /// @notice Internal function to transfer ERC721 and ERC1155 NFTs
    /// @param nftCount - NFT collections count
    /// @param configs - NFT configs
    /// @param from - NFT holder
    /// @param to - NFT receiver
    /// @param ids - an array of ids (one for each NFT collection)
    /// @param amounts - an array of amounts (one for each NFT collection and id)
    function _transferNFT(
        uint256 nftCount,
        NFTConfig[] memory configs,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) private {
        for (uint256 i; i < nftCount; ) {
            if (NFTType.ERC1155 == configs[i].nftType) {
                IERC1155(configs[i].nft).safeTransferFrom(
                    from,
                    to,
                    ids[i],
                    amounts[i],
                    ''
                );
            } else {
                IERC721(configs[i].nft).safeTransferFrom(from, to, ids[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Transfers ETH or ERC20 tokens to recepient
    /// @param to - token recepient
    /// @param amount - token amount
    function _pay(address to, uint256 amount) private {
        if (address(rewardToken) == address(0)) {
            // pay ether
            (bool success, ) = payable(to).call{value: amount}('');
            if (!success) revert PaymentFailure();
        } else {
            // transfer ERC20
            rewardToken.safeTransfer(to, amount);
        }
    }

    /// @notice Receives ETH or ERC20 tokens from account
    /// @param from - token holder
    /// @param amount - token amount
    function _accept(address from, uint256 amount) private {
        if (address(rewardToken) == address(0)) {
            // pay ether
            if (msg.value < amount) revert ValueTooLow('amount');
        } else {
            // transfer ERC20
            rewardToken.safeTransferFrom(from, address(this), amount);
        }
    }

    /// @notice Removes stake from active list
    /// @param id - stake id
    function _deactivateStake(uint256 id, address stakeOwner) private {
        activeIdsByUser[stakeOwner].remove(id);
        activeStakeIds.remove(id);
    }
}
