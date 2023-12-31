pragma solidity 0.8.19;

abstract contract StabilityFeeTreasuryLike {
    function systemCoin() external view virtual returns (address);

    function pullFunds(address, address, uint) external virtual;
}

abstract contract OracleLike {
    function read() external view virtual returns (uint256);
}

abstract contract BaseFeeIncentive {
    StabilityFeeTreasuryLike public immutable treasury; // The stability fee treasury
    address public immutable coin; // The system coin
    OracleLike public ethOracle; // eth oracle
    OracleLike public coinOracle; // coin oracle
    uint256 public fixedReward; // The fixed reward sent by the treasury to a fee receiver (wad)
    uint256 public callDelay; // delay between incentivized calls (seconds)
    uint256 public lastCallMade; // last time a call to target was made (UNIX timestamp)

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, address addr);
    event ModifyParameters(bytes32 parameter, uint256 val);
    event RewardCaller(address indexed finalFeeReceiver, uint256 fixedReward);
    event FailRewardCaller(
        bytes revertReason,
        address feeReceiver,
        uint256 amount
    );

    // --- Auth ---
    mapping(address => uint256) public authorizedAccounts;

    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }

    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }

    /**
     * @notice Checks whether msg.sender can call an authed function
     **/
    modifier isAuthorized() {
        require(
            authorizedAccounts[msg.sender] == 1,
            "StabilityFeeTreasury/account-not-authorized"
        );
        _;
    }

    // --- Constructor ---
    constructor(
        address treasury_,
        uint256 reward_,
        uint256 delay_,
        address coinOracle_,
        address ethOracle_
    ) {
        require(treasury_ != address(0), "invalid-treasury");
        require(reward_ != 0, "invalid-reward");
        require(coinOracle_ != address(0), "invalid-coin-oracle");
        require(ethOracle_ != address(0), "invalid-eth-oracle");

        authorizedAccounts[msg.sender] = 1;

        treasury = StabilityFeeTreasuryLike(treasury_);
        fixedReward = reward_;
        callDelay = delay_;
        coin = StabilityFeeTreasuryLike(treasury_).systemCoin();
        coinOracle = OracleLike(coinOracle_);
        ethOracle = OracleLike(ethOracle_);

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("fixedReward", reward_);
        emit ModifyParameters("callDelay", delay_);
        emit ModifyParameters("coinOracle", coinOracle_);
        emit ModifyParameters("ethOracle", ethOracle_);
    }

    // -- Admin --
    function modifyParameters(
        bytes32 parameter,
        uint256 val
    ) public isAuthorized virtual {
        if (parameter == "fixedReward") fixedReward = val;
        else if (parameter == "callDelay") callDelay = val;
        else revert("invalid-param");
        emit ModifyParameters(parameter, val);
    }

    function modifyParameters(
        bytes32 parameter,
        address val
    ) external isAuthorized {
        require(val != address(0), "invalid-data");
        if (parameter == "coinOracle") coinOracle = OracleLike(val);
        else if (parameter == "ethOracle") ethOracle = OracleLike(val);
        else revert("invalid-param");
        emit ModifyParameters(parameter, val);
    }

    modifier payRewards() {
        uint256 gas = gasleft();
        _;

        if (block.timestamp >= lastCallMade + callDelay) {
            gas = gas - gasleft();
            uint256 coinCost = (gas * block.basefee * ethOracle.read()) /
                coinOracle.read();

            try treasury.pullFunds(msg.sender, coin, coinCost + fixedReward) {
                emit RewardCaller(msg.sender, coinCost + fixedReward);
            } catch (bytes memory revertReason) {
                emit FailRewardCaller(
                    revertReason,
                    msg.sender,
                    coinCost + fixedReward
                );
            }
        }

        emit log(gas);

        lastCallMade = block.timestamp;
    }

    event log(uint);
}

// @notice: Unobtrusive incentives for any call on a TAI like system.
// @dev: Assumes an allowance from the stability fee treasury, all oracles return quotes with 18 decimal places.
contract BasefeeIncentiveCallBundler is BaseFeeIncentive {
    // wen immutable arrays? (https://github.com/ethereum/solidity/issues/12587) ==> if you're reading this please go there and support.
    address public immutable target0; // target of first call
    address public immutable target1; // target of second call
    bytes32 public immutable callData0; // calldata of the first incentivized call
    bytes32 public immutable callData1; // calldata of the second incentivized call

    // --- Constructor ---
    constructor(
        address treasury_,
        address[2] memory targets_,
        bytes32[2] memory callDatas_,
        uint256 reward_,
        uint256 delay_,
        address coinOracle_,
        address ethOracle_
    ) BaseFeeIncentive(treasury_, reward_, delay_, coinOracle_, ethOracle_) {
        require(targets_[0] != address(0), "invalid-target");
        require(targets_[1] != address(0), "invalid-target");
        require(callDatas_[0] != bytes32(0), "invalid-call-data");
        require(callDatas_[1] != bytes32(0), "invalid-call-data");

        target0 = targets_[0];
        target1 = targets_[1];
        callData0 = callDatas_[0];
        callData1 = callDatas_[1];
    }

    // @dev Calls are made through the fallback function, meaning any call to this contract will do
    fallback() external payRewards {
        (bool success, ) = target0.call(abi.encode(callData0));
        require(success, "call-failed");
        (success, ) = target1.call(abi.encode(callData0));
        require(success, "call-failed");
    }
}