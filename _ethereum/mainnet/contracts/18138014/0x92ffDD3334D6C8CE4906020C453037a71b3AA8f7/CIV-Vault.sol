// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title  Civ Vault
 * @author Ren / Frank
 */

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./FixedPoint.sol";
import "./ICivFund.sol";
import "./CIV-VaultGetter.sol";
import "./CIV-VaultFactory.sol";

contract CIVVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for ICivFundRT;
    using FixedPoint for *;

    /// @notice All Fees Base Amount
    uint public constant feeBase = 10_000;
    /// @notice Safety Factor to avoid out of Gas in loops
    uint public gasBuffer;
    /// @notice Number of strategies
    uint public strategiesCounter;
    /// @notice vault getter contract
    ICivVaultGetter public vaultGetter;
    /// @notice share factory contract
    CIVFundShareFactory public fundShareFactory;
    /// @notice mapping with info on each strategy
    mapping(uint => StrategyInfo) private _strategyInfo;
    /// @notice structure with epoch info
    mapping(uint => mapping(uint => EpochInfo)) private _epochInfo;
    /// @notice Info of each user that enters the fund
    mapping(uint => mapping(address => UserInfo)) private _userInfo;
    /// @notice Counter for the epochs of each strategy
    mapping(uint => uint) private _epochCounter;
    /// @notice Each Strategies epoch informations per address
    mapping(uint => mapping(address => mapping(uint => UserInfoEpoch)))
        private _userInfoEpoch;
    /// @notice Mapping of depositors on a particular epoch
    mapping(uint => mapping(uint => mapping(uint => address)))
        private _depositors;
    /// @notice Mapping of guarantee locks on a strategy for each user
    mapping(uint => mapping(address => mapping(uint => GuaranteeInfo)))
        private _userGuaranteeLock; // Index of the depositor in the depositors mapping

    ////////////////// EVENTS //////////////////

    /// @notice Event emitted when user deposit fund to our vault or vault deposit fund to strategy
    event Deposit(
        address indexed user,
        address receiver,
        uint indexed id,
        uint amount
    );
    /// @notice Event emitted when user request withdraw fund from our vault or vault withdraw fund to user
    event Withdraw(address indexed user, uint indexed id, uint amount);
    /// @notice Event emitted when owner sets new fee
    event SetFee(
        uint id,
        uint oldFee,
        uint newFee,
        uint oldDuration,
        uint newDuration
    );
    /// @notice Event emitted when owner sets new guarantee fee
    event SetGuaranteeFee(uint oldFee, uint newFee);
    /// @notice Event emitted when owner sets new gas buffer
    event SetGasBuffer(uint gasBuffer, uint newGasBuffer);
    /// @notice Event emitted when owner sets new deposit duration
    event SetEpochDuration(uint id, uint oldDuration, uint newDuration);
    /// @notice Event emitted when owner sets new guarantee token lock time
    event SetGuaranteeLockTime(uint id, uint oldLocktime, uint newLockTime);
    /// @notice Event emitted when owner sets new treasury addresses
    event SetWithdrawAddress(
        uint id,
        address[] oldAddress,
        address[] newAddress
    );
    /// @notice Event emitted when owner sets new invest address
    event SetInvestAddress(uint id, address oldAddress, address newAddress);
    /// @notice Event emitted when send fee to our treasury
    event SendFeeWithOwner(uint id, address treasuryAddress, uint feeAmount);
    /// @notice Event emitted when owner update new VPS
    event UpdateVPS(uint id, uint lastEpoch, uint VPS);
    /// @notice Event emitted when owner paused deposit
    event SetPaused(uint id, bool paused);
    /// @notice Event emitted when owner set new Max & Min Deposit Amount
    event SetLimits(
        uint id,
        uint oldMaxAmount,
        uint newMaxAmount,
        uint oldMinAmount,
        uint newMinAmount,
        uint oldMaxUsers,
        uint newMaxUsers
    );
    /// @notice Event emitted when user cancel pending deposit from vault
    event CancelDeposit(address user, uint id, uint amount);
    /// @notice Event emitted when user cancel withdraw request from vault
    event CancelWithdraw(address user, uint id, uint amount);
    /// @notice Event emitted when Uniswap Token Price Updated
    event Update(uint id, uint index);
    /// @notice Event emitted when user claim guarantee token
    event ClaimGuarantee(uint id, address user, uint guaranteeAmount);
    /// @notice Event emitted when user claim Asset token for each epoch
    event ClaimWithdrawedToken(
        uint id,
        address user,
        uint epoch,
        uint assetAmount
    );
    /// @notice Event emitted when user claim Asset token
    event WithdrawedToken(uint id, address user, uint assetAmount);
    /// @notice Event emitted when owner adds new strategy
    event AddStrategy(
        uint indexed id,
        uint indexed fee,
        uint maxDeposit,
        uint minDeposit,
        bool paused,
        address[] withdrawAddress,
        address assetToken,
        address guaranteeToken,
        uint lockPeriod,
        uint feeDuration
    );
    /// @notice Event emitted when strategy is initialized
    event InitializeStrategy(uint indexed id);

    ////////////////// ERROR CODES //////////////////
    /*
    ERR_V.1 = "Strategy does not exist";
    ERR_V.2 = "Deposit paused";
    ERR_V.3 = "Treasury Address Length must be 2";
    ERR_V.4 = "Burn failed";
    ERR_V.5 = "Guarantee Token address cannot be null address";
    ERR_V.6 = "First Treasury address cannot be null address";
    ERR_V.7 = "Second Treasury address cannot be null address";
    ERR_V.8 = "Minting failed";
    ERR_V.9 = "Strategy already initialized";
    ERR_V.10 = "No epochs exist";
    ERR_V.11 = "Wait for the previos epoch to settle before requesting withdraw";
    ERR_V.12 = "Insufficient contract balance";
    ERR_V.13 = "Not enough amount to withdraw";
    ERR_V.14 = "Strategy address cannot be null address";
    ERR_V.15 = "Enable withdraw for previous epoch";
    ERR_V.16 = "Distribute all shares for previous epoch";
    ERR_V.17 = "Epoch does not exist";
    ERR_V.18 = "Epoch not yet expired";
    ERR_V.19 = "No funds available to withdraw";
    ERR_V.20 = "Amount can't be 0";
    ERR_V.21 = "Insufficient User balance";
    ERR_V.22 = "No more users are allowed";
    ERR_V.23 = "Deposit amount exceeds epoch limit";
    ERR_V.24 = "Epoch expired";
    ERR_V.25 = "Current balance not enough";
    ERR_V.26 = "Not enough total withdrawals";
    ERR_V.27 = "VPS not yet updated";
    ERR_V.28 = "Already started distribution";
    ERR_V.29 = "Not yet distributed";
    ERR_V.30 = "Already distributed";
    ERR_V.31 = "Fee duration not yet passed";
    ERR_V.32 = "Vault balance is not enough to pay fees";
    ERR_V.33 = "Transfer Failed";
    ERR_V.34 = "Withdraw Token cannot be deposit token";
    ERR_V.35 = "No pending Fees to distribute";
    ERR_V.36 = "Nothing to claim";
    ERR_V.37 = "Wait for rebalancing to complete";
    */

    ////////////////// MODIFIER //////////////////

    modifier checkStrategyExistence(uint _id) {
        require(strategiesCounter > _id, "ERR_V.1");
        _;
    }

    modifier checkEpochExistence(uint _id) {
        require(_epochCounter[_id] > 0, "ERR_V.10");
        _;
    }

    ////////////////// CONSTRUCTOR //////////////////

    constructor() {
        CivVaultGetter getterContract = new CivVaultGetter(address(this));
        fundShareFactory = new CIVFundShareFactory();
        vaultGetter = ICivVaultGetter(address(getterContract));
    }

    ////////////////// INITIALIZATION //////////////////

    /// @notice Add new strategy to our vault
    /// @dev Only Owner can call this function
    /// @param addStrategyParam Parameters for new strategy
    function addStrategy(
        AddStrategyParam memory addStrategyParam
    ) external virtual nonReentrant onlyOwner {
        require(addStrategyParam._withdrawAddresses.length == 2, "ERR_V.3");
        require(
            address(addStrategyParam._guaranteeToken) != address(0),
            "ERR_V.5"
        );
        require(
            addStrategyParam._withdrawAddresses[0] != address(0),
            "ERR_V.6"
        );
        require(
            addStrategyParam._withdrawAddresses[1] != address(0),
            "ERR_V.7"
        );
        /// deploy new CIVFundShare contract
        CIVFundShare fundRepresentToken = fundShareFactory.createCIVFundShare();

        _strategyInfo[strategiesCounter] = StrategyInfo({
            assetToken: addStrategyParam._assetToken,
            fundRepresentToken: ICivFundRT(address(fundRepresentToken)),
            guaranteeToken: addStrategyParam._guaranteeToken,
            fee: addStrategyParam._fee,
            guaranteeFee: addStrategyParam._guaranteeFee,
            withdrawAddress: addStrategyParam._withdrawAddresses,
            investAddress: addStrategyParam._investAddress,
            initialized: false,
            pendingFees: 0,
            maxDeposit: addStrategyParam._maxDeposit,
            maxUsers: addStrategyParam._maxUsers,
            minDeposit: addStrategyParam._minAmount,
            paused: addStrategyParam._paused,
            epochDuration: addStrategyParam._epochDuration,
            lockPeriod: addStrategyParam._lockPeriod,
            feeDuration: addStrategyParam._feeDuration,
            lastFeeDistribution: 0,
            lastProcessedEpoch: 0,
            watermark: 0
        });

        uint id = strategiesCounter;
        strategiesCounter++;
        vaultGetter.addUniPair(
            id,
            address(addStrategyParam._assetToken),
            address(addStrategyParam._guaranteeToken)
        );
        emit AddStrategy(
            id,
            addStrategyParam._fee,
            addStrategyParam._maxDeposit,
            addStrategyParam._minAmount,
            addStrategyParam._paused,
            addStrategyParam._withdrawAddresses,
            address(addStrategyParam._assetToken),
            address(addStrategyParam._guaranteeToken),
            addStrategyParam._lockPeriod,
            addStrategyParam._feeDuration
        );
    }

    /// @notice Delayed strategy start
    /// @dev Only Owner can call this function
    /// @param _id strategy id
    function initializeStrategy(
        uint _id
    ) external onlyOwner checkStrategyExistence(_id) {
        require(!_strategyInfo[_id].initialized, "ERR_V.9");

        _strategyInfo[_id].initialized = true;
        vaultGetter.addTimeOracle(_id, _strategyInfo[_id].epochDuration);

        _epochInfo[_id][_epochCounter[_id]] = EpochInfo({
            totDepositors: 0,
            totDepositedAssets: 0,
            totWithdrawnShares: 0,
            VPS: 0,
            newShares: 0,
            currentWithdrawAssets: 0,
            epochStartTime: block.timestamp,
            lastDepositorProcessed: 0,
            duration: _strategyInfo[_id].epochDuration
        });

        _epochCounter[_id]++;
        emit InitializeStrategy(_id);
    }

    ////////////////// SETTER //////////////////

    /// @notice Sets new fee and new collecting fee duration
    /// @dev Only Owner can call this function
    /// @param _id Strategy Id
    /// @param _newFee New Fee Percent
    /// @param _newDuration New Collecting Fee Duration
    function setFee(
        uint _id,
        uint _newFee,
        uint _newDuration
    ) external onlyOwner checkStrategyExistence(_id) {
        emit SetFee(
            _id,
            _strategyInfo[_id].fee,
            _newFee,
            _strategyInfo[_id].feeDuration,
            _newDuration
        );
        _strategyInfo[_id].fee = _newFee;
        _strategyInfo[_id].feeDuration = _newDuration;
    }

    /// @notice Sets new Strategy guarantee token lock time and guarantee fee
    /// @dev Only Owner can call this function
    /// @param _id Strategy Id
    /// @param _lockTime New Guarantee token lock time
    /// @param _newFee new guarantee fee amount
    function setStrategyGuarantee(
        uint _id,
        uint _lockTime,
        uint _newFee
    ) external onlyOwner checkStrategyExistence(_id) {
        emit SetGuaranteeLockTime(
            _id,
            _strategyInfo[_id].lockPeriod,
            _lockTime
        );
        emit SetGuaranteeFee(_strategyInfo[_id].guaranteeFee, _newFee);
        _strategyInfo[_id].lockPeriod = _lockTime;
        _strategyInfo[_id].guaranteeFee = _newFee;
    }

    /// @notice Sets new deposit fund from vault to strategy duration
    /// @dev Only Owner can call this function
    /// @param _id Strategy Id
    /// @param _newDuration New Duration for Deposit fund from vault to strategy
    function setEpochDuration(
        uint _id,
        uint _newDuration
    ) external onlyOwner checkStrategyExistence(_id) {
        emit SetEpochDuration(
            _id,
            _strategyInfo[_id].epochDuration,
            _newDuration
        );
        vaultGetter.setEpochDuration(_id, _newDuration);
        _strategyInfo[_id].epochDuration = _newDuration;
    }

    /// @notice Sets new treasury addresses to keep fee
    /// @dev Only Owner can call this function
    /// @param _id Strategy Id
    /// @param _newAddress Address list to keep fee
    function setWithdrawAddress(
        uint _id,
        address[] memory _newAddress
    ) external onlyOwner checkStrategyExistence(_id) {
        require(_newAddress.length == 2, "ERR_V.3");
        require(_newAddress[0] != address(0), "ERR_V.6");
        require(_newAddress[1] != address(0), "ERR_V.7");
        emit SetWithdrawAddress(
            _id,
            _strategyInfo[_id].withdrawAddress,
            _newAddress
        );
        _strategyInfo[_id].withdrawAddress = _newAddress;
    }

    /// @notice Sets new treasury addresses to keep fee
    /// @dev Only Owner can call this function
    /// @param _id Strategy Id
    /// @param _newAddress Address list to keep fee
    function setInvestAddress(
        uint _id,
        address _newAddress
    ) external onlyOwner checkStrategyExistence(_id) {
        require(_newAddress != address(0), "ERR_V.14");
        emit SetInvestAddress(
            _id,
            _strategyInfo[_id].investAddress,
            _newAddress
        );
        _strategyInfo[_id].investAddress = _newAddress;
    }

    /// @notice Set Pause of Unpause for deposit to vault
    /// @dev Only Owner can change this status
    /// @param _id Strategy Id
    /// @param _paused paused or unpaused for deposit
    function setPaused(
        uint _id,
        bool _paused
    ) external onlyOwner checkStrategyExistence(_id) {
        emit SetPaused(_id, _paused);
        _strategyInfo[_id].paused = _paused;
    }

    /// @notice Set limits on a given strategy
    /// @dev Only Owner can change this status
    /// @param _id Strategy Id
    /// @param _newMaxDeposit New Max Deposit Amount
    /// @param _newMinDeposit New Min Deposit Amount
    /// @param _newMaxUsers New Max User Count
    function setEpochLimits(
        uint _id,
        uint _newMaxDeposit,
        uint _newMinDeposit,
        uint _newMaxUsers
    ) external onlyOwner checkStrategyExistence(_id) {
        emit SetLimits(
            _id,
            _strategyInfo[_id].maxDeposit,
            _newMaxDeposit,
            _strategyInfo[_id].minDeposit,
            _newMinDeposit,
            _strategyInfo[_id].maxUsers,
            _newMaxUsers
        );
        _strategyInfo[_id].maxDeposit = _newMaxDeposit;
        _strategyInfo[_id].minDeposit = _newMinDeposit;
        _strategyInfo[_id].maxUsers = _newMaxUsers;
    }

    /// @notice Sets new gas buffer
    /// @dev Only Owner can call this function
    /// @param _gasBuffer new gas buffer amount
    function setGasBuffer(uint _gasBuffer) external onlyOwner {
        emit SetGasBuffer(gasBuffer, _gasBuffer);
        gasBuffer = _gasBuffer;
    }

    ////////////////// GETTER //////////////////

    /**
     * @dev Fetches the strategy information for a given strategy _id.
     * @param _id The ID of the strategy to fetch the information for.
     * @return strategy The StrategyInfo struct associated with the provided _id.
     */
    function getStrategyInfo(
        uint _id
    )
        external
        view
        checkStrategyExistence(_id)
        returns (StrategyInfo memory strategy)
    {
        strategy = _strategyInfo[_id];
    }

    /**
     * @dev Fetches the epoch information for a given strategy _id.
     * @param _id The ID of the strategy to fetch the information for.
     * @param _index The index of the epoch to fetch the information for.
     * @return epoch The EpochInfo struct associated with the provided _id and _index.
     */
    function getEpochInfo(
        uint _id,
        uint _index
    )
        external
        view
        checkStrategyExistence(_id)
        checkEpochExistence(_id)
        returns (EpochInfo memory epoch)
    {
        epoch = _epochInfo[_id][_index];
    }

    /**
     * @dev Fetches the current epoch number for a given strategy _id.
     * The current epoch is determined as the last index of the epochInfo mapping for the strategy.
     * @param _id The _id of the strategy to fetch the current epoch for.
     * @return The current epoch number for the given strategy _id.
     */
    function getCurrentEpoch(
        uint _id
    )
        public
        view
        checkStrategyExistence(_id)
        checkEpochExistence(_id)
        returns (uint)
    {
        return _epochCounter[_id] - 1;
    }

    /**
     * @dev Fetches the user information for a given strategy _id.
     * @param _id The _id of the strategy to fetch the information for.
     * @param _user The address of the user to fetch the information for.
     * @return user The UserInfo struct associated with the provided _id and _user.
     */
    function getUserInfo(
        uint _id,
        address _user
    ) external view checkStrategyExistence(_id) returns (UserInfo memory user) {
        user = _userInfo[_id][_user];
    }

    /**
     * @dev Fetches the user information for a given strategy _id.
     * @param _id The _id of the strategy to fetch the information for.
     * @param _epoch The starting index to fetch the information for.
     * @return users An array of addresses of unique depositors.
     */
    function getDepositors(
        uint _id,
        uint _epoch
    )
        external
        view
        checkStrategyExistence(_id)
        returns (address[] memory users)
    {  
        // Initialize the return array with the size equal to the range between the start and end indices
        users = new address[](_epochInfo[_id][_epoch].totDepositors);

        // Loop through the mapping to populate the return array
        for (uint i = 0; i < _epochInfo[_id][_epoch].totDepositors; i++) {
            users[i] = _depositors[_id][_epoch][i];
        }
    }

    /**
     * @dev Fetches the deposit parameters for a given strategy _id.
     * @param _id The _id of the strategy to fetch the information for.
     * @param _user The address of the user to fetch the information for.
     * @param _index The index of the deposit to fetch the information for.
     * @return userEpochStruct The UserInfoEpoch struct associated with the provided _id, _user and _index.
     */
    function getUserInfoEpoch(
        uint _id,
        address _user,
        uint _index
    )
        external
        view
        checkStrategyExistence(_id)
        returns (UserInfoEpoch memory userEpochStruct)
    {
        userEpochStruct = _userInfoEpoch[_id][_user][_index];
    }

    /**
     * @dev Fetches the guarantee parameters for an user for a certain index.
     * @param _id The _id of the strategy to fetch the information for.
     * @param _user The address of the user to fetch the information for.
     * @param _index The index of the user guarantee lock to fetch the information for.
     * @return userGuarantee The UserInfoEpoch struct associated with the provided id, _user and _index.
     */
    function getGuaranteeInfo(
        uint _id,
        address _user,
        uint _index
    )
        external
        view
        checkStrategyExistence(_id)
        returns (GuaranteeInfo memory userGuarantee)
    {
        userGuarantee = _userGuaranteeLock[_id][_user][_index];
    }

    ////////////////// UPDATE //////////////////

    /**
     * @dev Updates the current epoch information for the specified strategy
     * @param _id The Strategy _id
     * @return currentEpoch The _id of the current epoch
     *
     * This function checks if the current epoch's duration has been met or exceeded.
     * If true, it initializes a new epoch with its starting time as the current block timestamp.
     * If false, no action is taken.
     *
     * Requirements:
     * - The strategy must be initialized.
     * - The current block timestamp must be equal to or greater than the start
     *   time of the current epoch plus the epoch's duration.
     */
    function updateEpoch(
        uint _id
    ) private checkEpochExistence(_id) returns (uint) {
        uint currentEpoch = getCurrentEpoch(_id);

        if (
            block.timestamp >=
            _epochInfo[_id][currentEpoch].epochStartTime +
                _epochInfo[_id][currentEpoch].duration
        ) {
            require(_epochInfo[_id][currentEpoch].VPS > 0, "ERR_V.37");

            _epochInfo[_id][_epochCounter[_id]] = EpochInfo({
                totDepositors: 0,
                totDepositedAssets: 0,
                totWithdrawnShares: 0,
                VPS: 0,
                newShares: 0,
                currentWithdrawAssets: 0,
                epochStartTime: vaultGetter.getCurrentPeriod(_id),
                lastDepositorProcessed: 0,
                duration: _strategyInfo[_id].epochDuration
            });

            _epochCounter[_id]++;
        }

        return getCurrentEpoch(_id);
    }

    /// @notice Calculate fees to the treasury address and save it in the strategy mapping and returns adjusted VPS
    /**
     * @dev Internal function
     */
    /// @param _id Strategy _id
    /// @param _newVPS new Net Asset Value
    /// @return adjustedVPS The new VPS after fees have been deducted
    function calculateFees(
        uint _id,
        uint _newVPS
    ) private returns (uint adjustedVPS) {
        StrategyInfo storage strategy = _strategyInfo[_id];

        uint sharesMultiplier = 10 ** strategy.fundRepresentToken.decimals();
        uint totalSupplyShares = strategy.fundRepresentToken.totalSupply();
        uint actualFee = 0;
        adjustedVPS = _newVPS;

        if (strategy.watermark < _newVPS) {
            actualFee =
                ((_newVPS - strategy.watermark) *
                    strategy.fee *
                    totalSupplyShares) /
                feeBase /
                sharesMultiplier;
            if (actualFee > 0) {
                strategy.watermark = _newVPS;
                strategy.lastFeeDistribution = block.timestamp;
                strategy.pendingFees += actualFee;

                // Calculate adjusted VPS based on the actual fee
                uint adjustedTotalValue = (_newVPS * totalSupplyShares) /
                    sharesMultiplier -
                    actualFee;
                adjustedVPS =
                    (adjustedTotalValue * sharesMultiplier) 
                    / totalSupplyShares;
            }
        }
    }

    /**
     * @dev Processes the fund associated with a particular strategy, handling deposits,
     * minting, and burning of shares.
     * @param _id The Strategy _id
     * @param _newVPS New value per share (VPS) expressed in decimals (same as assetToken)
     * - must be greater than 0
     *
     * This function performs the following actions:
     * 1. Retrieves the current epoch and strategy info;
     * 2. Calculate the new shares and current withdrawal based on new VPS;
     * 3. Mints or burns shares depending on the new shares and total withdrawals.
     * 4. Handles deposits and withdrawals by transferring the Asset tokens.
     *
     * Requirements:
     * - `_newVPS` must be greater than 0.
     * - The necessary amount of Asset tokens must be present in the contract for deposits if required.
     * - The necessary amount of Asset tokens must be present in the investAddress for withdrawals if required.
     */
    function processFund(uint _id, uint _newVPS) private {
        require(_newVPS > 0, "ERR_V.35");

        // Step 1
        EpochInfo storage epoch = _epochInfo[_id][
            _strategyInfo[_id].lastProcessedEpoch
        ];
        StrategyInfo memory strategy = _strategyInfo[_id];

        uint sharesMultiplier = 10 ** strategy.fundRepresentToken.decimals();

        // Step 2
        uint newShares = (epoch.totDepositedAssets * sharesMultiplier) /
            _newVPS;
        uint currentWithdrawAssets = (_newVPS * epoch.totWithdrawnShares) /
            sharesMultiplier;

        epoch.newShares = newShares;
        epoch.currentWithdrawAssets = currentWithdrawAssets;

        // Step 3
        if (newShares > epoch.totWithdrawnShares) {
            uint sharesToMint = newShares - epoch.totWithdrawnShares;
            bool success = strategy.fundRepresentToken.mint(sharesToMint);
            require(success, "ERR_V.8");
        } else {
            uint offSetShares = epoch.totWithdrawnShares - newShares;
            if (offSetShares > 0) {
                bool success = strategy.fundRepresentToken.burn(offSetShares);
                require(success, "ERR_V.4");
            }
        }

        // Step 4
        if (epoch.totDepositedAssets >= currentWithdrawAssets) {
            uint netDeposits = epoch.totDepositedAssets - currentWithdrawAssets;
            if (netDeposits > 0) {
                require(
                    strategy.assetToken.balanceOf(address(this)) >= netDeposits,
                    "ERR_V.12"
                );
                strategy.assetToken.safeTransfer(
                    strategy.investAddress,
                    netDeposits
                );
                emit Deposit(
                    address(this),
                    strategy.investAddress,
                    _id,
                    netDeposits
                );
            }
        } else {
            uint offSet = currentWithdrawAssets - epoch.totDepositedAssets;
            require(
                strategy.assetToken.balanceOf(strategy.investAddress) >= offSet,
                "ERR_V.13"
            );
            strategy.assetToken.safeTransferFrom(
                strategy.investAddress,
                address(this),
                offSet
            );
        }
    }

    /// @notice Sets new VPS of the strategy.
    /**
     * @dev Only Owner can call this function.
     *      Owner must transfer fund to our vault before calling this function
     */
    /// @param _id Strategy _id
    /// @param _newVPS New VPS value
    function rebalancing(
        uint _id,
        uint _newVPS
    ) external nonReentrant onlyOwner checkStrategyExistence(_id) {
        StrategyInfo storage strategy = _strategyInfo[_id];
        require(strategy.investAddress != address(0), "ERR_V.14");

        if (strategy.lastProcessedEpoch == 0) {
            EpochInfo storage initEpoch = _epochInfo[_id][0];
            if (initEpoch.VPS > 0) {
                require(
                    initEpoch.lastDepositorProcessed == initEpoch.totDepositors,
                    "ERR_V.16"
                );
                require(_epochCounter[_id] > 1, "ERR_V.17");
                strategy.lastProcessedEpoch++;
                EpochInfo storage newEpoch = _epochInfo[_id][1];
                require(
                    block.timestamp >=
                        newEpoch.epochStartTime + newEpoch.duration,
                    "ERR_V.18"
                );
                _newVPS = calculateFees(_id, _newVPS);
                newEpoch.VPS = _newVPS;
            } else {
                require(
                    block.timestamp >=
                        initEpoch.epochStartTime + initEpoch.duration,
                    "ERR_V.18"
                );
                strategy.watermark = _newVPS;
                initEpoch.VPS = _newVPS;
            }
        } else {
            require(
                _epochInfo[_id][strategy.lastProcessedEpoch]
                    .lastDepositorProcessed ==
                    _epochInfo[_id][strategy.lastProcessedEpoch].totDepositors,
                "ERR_V.16"
            );
            strategy.lastProcessedEpoch++;
            require(
                _epochCounter[_id] > strategy.lastProcessedEpoch,
                "ERR_V.17"
            );
            EpochInfo storage subsequentEpoch = _epochInfo[_id][
                strategy.lastProcessedEpoch
            ];
            require(
                block.timestamp >=
                    subsequentEpoch.epochStartTime + subsequentEpoch.duration,
                "ERR_V.18"
            );
            _newVPS = calculateFees(_id, _newVPS);
            subsequentEpoch.VPS = _newVPS;
        }

        processFund(_id, _newVPS);

        emit UpdateVPS(_id, strategy.lastProcessedEpoch, _newVPS);
    }

    ////////////////// MAIN //////////////////

    /// @notice Claim withdrawed token epochs
    /// @param _id Strategy _id
    function claimGuaranteeToken(
        uint _id
    )
        external
        nonReentrant
        checkStrategyExistence(_id)
        checkEpochExistence(_id)
    {
        StrategyInfo memory strategy = _strategyInfo[_id];
        UserInfo storage user = _userInfo[_id][_msgSender()];

        uint endIndex = user.numberOfLocks;
        uint startingIndexFinal = user.startingIndexGuarantee;
        uint actualGuarantee;
        for (uint i = user.startingIndexGuarantee; i < endIndex; i++) {
            if (
                block.timestamp <
                _userGuaranteeLock[_id][_msgSender()][i].lockStartTime +
                    strategy.lockPeriod
            ) {
                break;
            }
            actualGuarantee += _userGuaranteeLock[_id][_msgSender()][i]
                .lockAmount;
            startingIndexFinal = i + 1;
        }
        require(actualGuarantee > 0, "ERR_V.19");
        user.startingIndexGuarantee = startingIndexFinal;
        strategy.guaranteeToken.safeTransfer(_msgSender(), actualGuarantee);
        emit ClaimGuarantee(_id, _msgSender(), actualGuarantee);
    }

    /// @notice Users Deposit tokens to our vault
    /**
     * @dev Anyone can call this function if strategy is not paused.
     *      Users must approve deposit token before calling this function
     *      We mint represent token to users so that we can calculate each users deposit amount outside
     */
    /// @param _id Strategy _id
    /// @param _amount Token Amount to deposit
    function deposit(
        uint _id,
        uint _amount
    ) external nonReentrant checkStrategyExistence(_id) {
        require(_strategyInfo[_id].paused == false, "ERR_V.2");
        StrategyInfo storage strategy = _strategyInfo[_id];
        require(_amount > strategy.minDeposit, "ERR_V.20");
        require(
            strategy.assetToken.balanceOf(_msgSender()) >= _amount,
            "ERR_V.21"
        );
        uint curEpoch = updateEpoch(_id);
        UserInfoEpoch storage userEpoch = _userInfoEpoch[_id][_msgSender()][
            curEpoch
        ];
        EpochInfo storage epoch = _epochInfo[_id][curEpoch];
        UserInfo storage user = _userInfo[_id][_msgSender()];

        require(
            epoch.totDepositedAssets + _amount <= strategy.maxDeposit,
            "ERR_V.23"
        );

        // Transfer guarantee token to the vault.
        vaultGetter.updateAll(_id);
        uint guaranteeAmount = (vaultGetter.getPrice(_id, _amount) *
            strategy.guaranteeFee) / feeBase;
        strategy.guaranteeToken.safeTransferFrom(
            _msgSender(),
            address(this),
            guaranteeAmount
        );

        GuaranteeInfo storage guaranteeInfo = _userGuaranteeLock[_id][
            _msgSender()
        ][user.numberOfLocks];
        if (userEpoch.epochGuaranteeIndex == 0)
            userEpoch.epochGuaranteeIndex = user.numberOfLocks;
        user.numberOfLocks++;
        guaranteeInfo.lockStartTime = block.timestamp;
        guaranteeInfo.lockAmount = guaranteeAmount;

        if (!userEpoch.hasDeposited) {
            require(epoch.totDepositors + 1 <= strategy.maxUsers, "ERR_V.22");
            _depositors[_id][curEpoch][epoch.totDepositors] = _msgSender();
            userEpoch.depositIndex = epoch.totDepositors;
            epoch.totDepositors++;
            userEpoch.hasDeposited = true;
        }

        epoch.totDepositedAssets += _amount;
        strategy.assetToken.safeTransferFrom(
            _msgSender(),
            address(this),
            _amount
        );
        userEpoch.depositInfo += _amount;
        emit Deposit(_msgSender(), address(this), _id, _amount);
    }

    /// @notice Immediately withdraw current pending deposit amount
    /// @param _id Strategy _id
    function cancelDeposit(
        uint _id
    )
        external
        nonReentrant
        checkStrategyExistence(_id)
        checkEpochExistence(_id)
    {
        StrategyInfo storage strategy = _strategyInfo[_id];
        uint curEpoch = getCurrentEpoch(_id);
        EpochInfo storage epoch = _epochInfo[_id][curEpoch];
        require(
            block.timestamp < epoch.epochStartTime + epoch.duration,
            "ERR_V.24"
        );
        UserInfoEpoch storage userEpoch = _userInfoEpoch[_id][_msgSender()][
            curEpoch
        ];
        uint amount = userEpoch.depositInfo;
        require(amount > 0, "ERR_V.20");
        userEpoch.depositInfo = 0;
        epoch.totDepositedAssets -= amount;
        strategy.assetToken.safeTransfer(_msgSender(), amount);

        UserInfo storage user = _userInfo[_id][_msgSender()];
        // Guarantee refund logic start //

        uint actualGuarantee;
        uint iterations;
        for (
            uint i = userEpoch.epochGuaranteeIndex;
            i < user.numberOfLocks;
            i++
        ) {
            actualGuarantee += _userGuaranteeLock[_id][_msgSender()][i]
                .lockAmount;
            iterations++;
        }
        user.numberOfLocks -= iterations;
        strategy.guaranteeToken.safeTransfer(_msgSender(), actualGuarantee);
        // Guarantee refund logic end //
        if (_depositors[_id][curEpoch][epoch.totDepositors] == _depositors[_id][curEpoch][userEpoch.depositIndex]) {
            _depositors[_id][curEpoch][epoch.totDepositors] = address(0);
        } else {
            address replaceAddress = _depositors[_id][curEpoch][epoch.totDepositors];
            _depositors[_id][curEpoch][epoch.totDepositors] = address(0);
            _depositors[_id][curEpoch][userEpoch.depositIndex] = replaceAddress;
            _userInfoEpoch[_id][replaceAddress][curEpoch].depositIndex = userEpoch
            .depositIndex;
        }
        userEpoch.depositIndex = 0;
        epoch.totDepositors--;
        userEpoch.hasDeposited = false;

        emit CancelDeposit(_msgSender(), _id, amount);
    }

    /// @notice Sends Withdraw Request to vault
    /**
     * @dev Withdraw amount user shares from vault
     */
    /// @param _id Strategy _id
    function withdraw(
        uint _id,
        uint _amount
    )
        external
        nonReentrant
        checkStrategyExistence(_id)
        checkEpochExistence(_id)
    {
        uint sharesBalance = _strategyInfo[_id].fundRepresentToken.balanceOf(
            _msgSender()
        );
        require(sharesBalance >= _amount, "ERR_V.25");
        uint curEpoch = updateEpoch(_id);
        UserInfoEpoch storage userEpoch = _userInfoEpoch[_id][_msgSender()][
            curEpoch
        ];
        UserInfo storage user = _userInfo[_id][_msgSender()];
        if (user.lastEpoch > 0 && userEpoch.withdrawInfo == 0)
            _claimWithdrawedTokens(_id, user.lastEpoch, _msgSender());

        _epochInfo[_id][curEpoch].totWithdrawnShares += _amount;
        userEpoch.withdrawInfo += _amount;
        if (user.lastEpoch != curEpoch) user.lastEpoch = curEpoch;
        _strategyInfo[_id].fundRepresentToken.safeTransferFrom(
            _msgSender(),
            address(this),
            _amount
        );
        emit Withdraw(_msgSender(), _id, _amount);
    }

    /// @notice Immediately withdraw current pending shares amount
    /// @param _id Strategy _id
    function cancelWithdraw(
        uint _id
    )
        external
        nonReentrant
        checkStrategyExistence(_id)
        checkEpochExistence(_id)
    {
        StrategyInfo storage strategy = _strategyInfo[_id];
        uint curEpoch = getCurrentEpoch(_id);
        EpochInfo storage epoch = _epochInfo[_id][curEpoch];
        require(
            block.timestamp < epoch.epochStartTime + epoch.duration,
            "ERR_V.24"
        );
        UserInfoEpoch storage userEpoch = _userInfoEpoch[_id][_msgSender()][
            curEpoch
        ];
        UserInfo storage user = _userInfo[_id][_msgSender()];
        uint amount = userEpoch.withdrawInfo;
        require(amount > 0, "ERR_V.20");
        userEpoch.withdrawInfo = 0;
        user.lastEpoch = 0;
        require(epoch.totWithdrawnShares >= amount, "ERR_V.26");
        epoch.totWithdrawnShares -= amount;
        strategy.fundRepresentToken.safeTransfer(_msgSender(), amount);

        emit CancelWithdraw(_msgSender(), _id, amount);
    }

    /// @notice Internal get withdraw tokens from vault for user
    /**
     * @dev Withdraw user funds from vault
     */
    /// @param _id Strategy _id
    /// @param _user Strategy _id
    function _claimWithdrawedTokens(
        uint _id,
        uint _lastEpoch,
        address _user
    ) internal {
        EpochInfo storage epoch = _epochInfo[_id][_lastEpoch];

        uint withdrawInfo = _userInfoEpoch[_id][_user][_lastEpoch].withdrawInfo;
        uint availableToClaim;
        if (withdrawInfo > 0) {
            uint dueWithdraw = (withdrawInfo * epoch.currentWithdrawAssets) /
                epoch.totWithdrawnShares;

            availableToClaim += dueWithdraw;
            emit ClaimWithdrawedToken(_id, _user, _lastEpoch, dueWithdraw);
        }
        if (availableToClaim > 0)
            _strategyInfo[_id].assetToken.safeTransfer(_user, availableToClaim);
        emit WithdrawedToken(_id, _user, availableToClaim);
    }

    /// @notice Get withdraw tokens from vault
    /**
     * @dev Withdraw my fund from vault
     */
    /// @param _id Strategy _id
    function claimWithdrawedTokens(
        uint _id
    ) external nonReentrant checkStrategyExistence(_id) {
        UserInfo storage user = _userInfo[_id][_msgSender()];
        uint lastEpoch = user.lastEpoch;
        require(lastEpoch > 0, "ERR_V.36");
        _claimWithdrawedTokens(_id, lastEpoch, _msgSender());
        user.lastEpoch = 0;
    }

    /// @notice Distribute shares to the epoch depositors
    /**
     * @dev Only Owner can call this function if deposit duration is passed.
     *      Owner must setPaused(false)
     */
    /// @param _id Strategy _id
    function processDeposits(
        uint _id
    ) external nonReentrant onlyOwner checkStrategyExistence(_id) {
        StrategyInfo memory strategy = _strategyInfo[_id];
        EpochInfo memory epoch = _epochInfo[_id][strategy.lastProcessedEpoch];
        require(epoch.VPS > 0, "ERR_V.27");
        require(epoch.lastDepositorProcessed == 0, "ERR_V.28");
        if (epoch.totDepositedAssets == 0) {
            return;
        }

        distributeShares(_id);
    }

    /**
     * @dev Continues the process of distributing shares for a specific strategy, if possible.
     * This function is only callable by the contract owner.
     * @param _id The _id of the strategy for which to continue distributing shares.
     */
    function continueDistributingShares(
        uint _id
    ) external nonReentrant onlyOwner checkStrategyExistence(_id) {
        // Check if there's anything to distribute
        EpochInfo memory epoch = _epochInfo[_id][
            _strategyInfo[_id].lastProcessedEpoch
        ];
        require(epoch.VPS > 0, "ERR_V.27");
        require(epoch.lastDepositorProcessed != 0, "ERR_V.29");
        require(epoch.lastDepositorProcessed < epoch.totDepositors, "ERR_V.30");
        distributeShares(_id);
    }

    /**
     * @dev Distributes the newly minted shares among the depositors of a specific strategy.
     * The function processes depositors until it runs out of gas.
     * @param _id The _id of the strategy for which to distribute shares.
     */
    function distributeShares(uint _id) internal {
        EpochInfo storage epoch = _epochInfo[_id][
            _strategyInfo[_id].lastProcessedEpoch
        ];
        uint i = epoch.lastDepositorProcessed;
        uint sharesToDistribute = epoch.newShares;

        while (i < epoch.totDepositors && gasleft() > gasBuffer) {
            address investor = _depositors[_id][_strategyInfo[_id].lastProcessedEpoch][i];
            uint depositInfo = _userInfoEpoch[_id][investor][
                _strategyInfo[_id].lastProcessedEpoch
            ].depositInfo;
            uint dueShares = (sharesToDistribute * depositInfo) /
                epoch.totDepositedAssets;

            if (dueShares > 0) {
                // Transfer the shares
                _strategyInfo[_id].fundRepresentToken.safeTransfer(
                    investor,
                    dueShares
                );
            }

            i++;
        }

        epoch.lastDepositorProcessed = i;
    }

    /**
     * @notice Distribute pending fees to the treasury addresses
     * @dev Internal function
     */
    /// @param _id Strategy _id
    function sendPendingFees(
        uint _id
    ) external nonReentrant onlyOwner checkStrategyExistence(_id) {
        StrategyInfo storage strategy = _strategyInfo[_id];

        require(
            block.timestamp >=
                strategy.lastFeeDistribution + strategy.feeDuration,
            "ERR_V.31"
        );

        uint pendingFees = strategy.pendingFees;
        require(pendingFees > 0, "ERR_V.35");
        require(
            strategy.assetToken.balanceOf(address(this)) >= pendingFees,
            "ERR_V.32"
        );
        strategy.pendingFees = 0;

        address addr0 = strategy.withdrawAddress[0];
        address addr1 = strategy.withdrawAddress[1];
        emit SendFeeWithOwner(_id, addr0, pendingFees / 2);
        emit SendFeeWithOwner(_id, addr1, pendingFees / 2);
        strategy.assetToken.safeTransfer(addr0, pendingFees / 2);
        strategy.assetToken.safeTransfer(addr1, pendingFees / 2);
    }

    /// @notice Withdraw ERC-20 Token to the owner
    /**
     * @dev Only Owner can call this function
     */
    /// @param _tokenContract ERC-20 Token address
    function withdrawERC20(IERC20 _tokenContract) external onlyOwner {
        for (uint i = 0; i < strategiesCounter; i++) {
            require(
                _strategyInfo[i].guaranteeToken != _tokenContract,
                "ERR_V.34"
            );
            require(_strategyInfo[i].assetToken != _tokenContract, "ERR_V.34");
        }
        _tokenContract.safeTransfer(
            _msgSender(),
            _tokenContract.balanceOf(address(this))
        );
    }
}
