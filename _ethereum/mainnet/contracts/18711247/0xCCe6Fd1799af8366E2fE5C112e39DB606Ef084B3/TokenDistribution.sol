// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "./AccessControl.sol";
import "./WorkToken.sol";

/**
 * @title The Work X $WORK TokenDistribution contract
 * @author Daniel de Witte
 * @notice The contract used to distribute the $WORK tokens according to a vesting schedule.
 * @dev There are 3 rounds, with different vesting periods. The 3rd round has a direct unlock of 10%.
 **/
contract TokenDistribution is AccessControl {
    bytes32 public constant NFT_ROLE = keccak256("NFT_ROLE");
    bytes32 public constant INIT_ROLE = keccak256("INIT_ROLE");

    WorkToken public immutable workToken;

    uint256 constant ONE_E18 = 10 ** 18;
    uint256 constant ONE_E17 = 10 ** 17;

    uint64 public constant VESTING_PERIOD1 = 547.5 days;
    uint64 public constant VESTING_PERIOD2 = 365 days;
    uint64 public constant VESTING_PERIOD3 = 273.75 days;
    uint64 public constant VESTING_PERIOD3_DIRECT_UNLOCK = 27.375 days;
    uint128 public startTime;

    event ClaimTokens(address indexed beneficiary, uint256 amount);

    struct Balance {
        uint32 totalBought;
        uint32 bought1;
        uint32 bought2;
        uint32 bought3;
        uint128 totalClaimed;
    }
    mapping(address => Balance) public accountBalance;

    /**
     * @notice The constructor sets the startTime to a point in the future, this is when the distribution starts.
     * @dev A reference to the work token is made.
     **/
    constructor(address _tokenAddress, uint256 _startTime) {
        _startTime = uint256(uint128(_startTime));
        require(_startTime > block.timestamp, "TokenDistribution: The startTime must be in the future");
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        workToken = WorkToken(_tokenAddress);
        startTime = uint128(_startTime);
    }

    /****
     **** EXTERNAL WRITE
     ****/

    /**
     * @notice The claimTokens function claims the amount of tokens a user has vested given the time that has past since distribution start minus how much they have previously claimed.
     * @dev The WorkToken contract is used to mint the tokens directly towards the claimer.
     **/
    function claimTokens() external {
        require(block.timestamp >= startTime, "TokenDistribution: The distribution hasn't started yet");
        uint256 availableTokens = _claimableTokens(msg.sender);
        require(availableTokens > 0, "TokenDistribution: You don't have any tokens to claim");
        Balance storage _balance = accountBalance[msg.sender];
        _balance.totalClaimed += uint128(availableTokens);
        workToken.mint(msg.sender, availableTokens);
        emit ClaimTokens(msg.sender, availableTokens);
    }

    /****
     **** ONLY NFT_ROLE
     ****/

    function setTotalClaimed(address wallet, uint256 totalClaimed) external onlyRole(NFT_ROLE) {
        Balance storage _balance = accountBalance[wallet];
        require(_balance.totalClaimed == 0, "TokenDistribution: You have previously claimed tokens");
        require(
            totalClaimed <= _balance.totalBought * ONE_E18,
            "TokenDistribution: You can not claim more tokens than you bought"
        );
        _balance.totalClaimed = uint128(totalClaimed);
    }

    /****
     **** ONLY INIT_ROLE
     ****/

    /**
     * @notice The startDistribution function starts the distribution in the future, this can not be changed after the distribution has started.
     * @dev The WorkToken contract is used to mint the tokens directly towards the claimer.
     * @param _startTime The amount of tokens that will be minted.
     **/
    function startDistribution(uint256 _startTime) external onlyRole(INIT_ROLE) {
        _startTime = uint256(uint128(_startTime));
        require(startTime > block.timestamp, "TokenDistribution: The token distribution has already started");
        require(_startTime > block.timestamp, "TokenDistribution: The startTime must be in the future");
        startTime = uint128(_startTime);
    }

    /**
     * @notice The startDistribution function starts the distribution in the future, this can not be changed after the distribution has started.
     * @dev The WorkToken contract is used to mint the tokens directly towards the claimer.
     * @param wallet An array containing the wallets of the accounts that can vest.
     * @param amount1 An array containing the amount each accounts sourced from sale round 1.
     * @param amount2 An array containing the amount each accounts sourced from sale round 2.
     * @param amount3 An array containing the amount each accounts sourced from sale round 3.
     * @param totalClaimed An array containing the preclaimed amount for each accounts (the unvested tokens they staked into the NFT).
     **/
    function setWalletClaimable(
        address[] calldata wallet,
        uint32[] calldata amount1,
        uint32[] calldata amount2,
        uint32[] calldata amount3,
        uint32[] calldata totalClaimed
    ) external onlyRole(INIT_ROLE) {
        require(startTime > block.timestamp, "TokenDistribution: The token distribution has already started");
        for (uint256 w = 0; w < wallet.length; w++) {
            accountBalance[wallet[w]] = Balance(
                amount1[w] + amount2[w] + amount3[w],
                amount1[w],
                amount2[w],
                amount3[w],
                uint128(totalClaimed[w] * ONE_E18)
            );
        }
    }

    /****
     **** EXTERNAL VIEW
     ****/

    /**
     * @notice The claimableTokens function returns the claimable tokens for an account.
     * @param _account The account for which the claimable token amount will be returned.
     **/
    function claimableTokens(address _account) external view returns (uint256) {
        return _claimableTokens(_account);
    }

    /**
     * @notice The claimedTokens function returns the claimed tokens for an account.
     * @param _account The account for which the claimed token amount will be returned.
     **/
    function claimedTokens(address _account) external view returns (uint256) {
        return accountBalance[_account].totalClaimed;
    }

    /**
     * @notice The vestedTokens function returns the vested tokens for an account.
     * @param _account The account for which the vested token amount will be returned.
     **/
    function vestedTokens(address _account) external view returns (uint256) {
        return _vestedTokens(_account);
    }

    /**
     * @notice The balance function returns an aggregate of vesting and claiming data for an account.
     * @param _account The account for which the aggregated data will be returned.
     **/
    function balance(
        address _account
    ) external view returns (uint256 _totalBought, uint256 _totalClaimed, uint256 _claimable, uint256 _vested) {
        Balance memory _balance = accountBalance[_account];
        _totalBought = _balance.totalBought * ONE_E18;
        _totalClaimed = _balance.totalClaimed;
        _claimable = _claimableTokens(_account);
        _vested = _vestedTokens(_account);
    }

    /****
     **** PRIVATE VIEW
     ****/

    /**
     * @notice The _claimableTokens function calculates the amount of tokens that are claimable for an account.
     * @dev The amount of tokens that are claimable is the amount of vested tokens minus the amount of tokens that have already been claimed.
     * @param _account The account for which the claimable tokens are calculated.
     **/
    function _claimableTokens(address _account) private view returns (uint256 claimableAmount) {
        uint256 vestedAmount = _vestedTokens(_account);
        uint256 claimed = accountBalance[_account].totalClaimed;
        if (vestedAmount <= claimed) {
            claimableAmount = 0;
        } else {
            claimableAmount = vestedAmount - claimed;
        }
    }

    /**
     * @notice The _vestedTokens function calculates the amount of tokens that have been vested for an account.
     * @dev The amount of tokens that are vested is calculated by taking the amount of tokens that are bought in each round and multiplying it by the percentage of the vesting period that has passed.
     * @param _account The account for which the vested tokens are calculated.
     **/
    function _vestedTokens(address _account) private view returns (uint256 vestedAmount) {
        if (block.timestamp < startTime) return 0;
        Balance memory _balance = accountBalance[_account];
        uint256 timeElapsed = block.timestamp - startTime;

        if (timeElapsed >= VESTING_PERIOD1) {
            vestedAmount += _balance.bought1 * ONE_E18;
        } else {
            vestedAmount += (_balance.bought1 * timeElapsed * ONE_E18) / VESTING_PERIOD1;
        }
        if (timeElapsed >= VESTING_PERIOD2) {
            vestedAmount += _balance.bought2 * ONE_E18;
        } else {
            vestedAmount += (_balance.bought2 * timeElapsed * ONE_E18) / VESTING_PERIOD2;
        }
        if (timeElapsed >= VESTING_PERIOD3) {
            vestedAmount += _balance.bought3 * ONE_E18;
        } else {
            if (timeElapsed < VESTING_PERIOD3_DIRECT_UNLOCK) {
                vestedAmount += _balance.bought3 * ONE_E17;
            } else {
                vestedAmount += (_balance.bought3 * timeElapsed * ONE_E18) / VESTING_PERIOD3;
            }
        }
    }
}
