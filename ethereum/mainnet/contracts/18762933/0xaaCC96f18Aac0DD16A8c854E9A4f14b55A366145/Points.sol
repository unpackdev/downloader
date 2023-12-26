// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./IPoints.sol";

contract Points is Ownable, ERC20, IPoints {
    struct TokenStake {
        uint128 amount;
        uint128 cumulativeRate;
    }

    uint128 public constant RATE_DENOMINATOR = 10 ** 18;

    bool internal _paused;

    address public authorizedBurner;

    /**
     * @inheritdoc IPoints
     */
    mapping(address => bool) public isWhitelisted;

    /**
     * @inheritdoc IPoints
     */
    address[] public tokenAt;

    // Stores the cumulative rate for each token up to the last timestamp
    mapping(address => uint128) internal cumulativeRates;

    // Stores the current rate for each token
    mapping(address => uint96) internal _rates;

    // Records the timestamp of the last transfer or rate change for each token
    mapping(address => uint32) internal timestamps;

    // User -> Token -> Amount
    mapping(address => mapping(address => TokenStake)) internal tokenStakes;

    // How much stake is required to reach each multiplier
    // Token -> Thresholds
    mapping(address => uint128[]) internal multiplierThresholds;

    // How much to scale the rate by at each multiplier
    // Token -> Scalars
    mapping(address => uint128[]) internal multiplierScalars;

    modifier checkPaused(address account) {
        if (_paused && !isWhitelisted[account]) {
            revert TransfersPaused();
        }
        _;
    }

    modifier preConvertPendingPoints(address account, address token) {
        // Do not want to modify timestamps[token] if token is not supported
        if (!tokenSupported(token)) {
            revert TokenNotSupported(token);
        }
        // Updating the cumulative rate for the token and the last timestamp
        cumulativeRates[token] += uint128(_rates[token]) * (uint32(block.timestamp) - timestamps[token]);
        timestamps[token] = uint32(block.timestamp);

        // Calculating the amount of points to mint to the account
        TokenStake storage tokenStake = tokenStakes[account][token];
        uint256 amountToMint =
            calculateMintAmount(token, tokenStake.amount, cumulativeRates[token] - tokenStake.cumulativeRate);
        _mint(account, amountToMint);
        emit PendingPointsConverted(account, token, amountToMint);

        // Updating the user's token stake
        tokenStake.cumulativeRate = cumulativeRates[token];
        _;
    }

    /**
     * @dev If `super.balanceOf()` already exceeds `threshold`, it will skip converting pending points
     */
    modifier preConvertAllPendingPoints(address account, uint256 threshold) {
        if (super.balanceOf(account) < threshold) {
            convertPendingPoints(account);
        }
        _;
    }

    function calculateMintAmount(address token, uint128 amount, uint128 cumulativeRateDiff)
        internal
        view
        returns (uint256 mintAmount)
    {
        mintAmount = (uint256(amount) * cumulativeRateDiff) / RATE_DENOMINATOR;

        uint256 thresholdIndex;
        for (thresholdIndex = 0; thresholdIndex < multiplierThresholds[token].length; thresholdIndex++) {
            if (amount < multiplierThresholds[token][thresholdIndex]) {
                break;
            }
        }
        // If not greater than any threshold, don't apply a multiplier. Otherwise use the last applicable scalar.
        if (thresholdIndex > 0) {
            mintAmount = (mintAmount * multiplierScalars[token][thresholdIndex - 1]) / RATE_DENOMINATOR;
        }
    }

    function convertPendingPoints(address account) public {
        uint256 totalAmountToMint;
        for (uint256 i = 0; i < tokenAt.length; i++) {
            address token = tokenAt[i];
            // Skip if the user has no stakes for the current token
            if (tokenStakes[account][token].amount == 0) {
                continue;
            }
            // Updating the cumulative rate for the token and the last timestamp
            cumulativeRates[token] += uint128(_rates[token]) * (uint32(block.timestamp) - timestamps[token]);
            timestamps[token] = uint32(block.timestamp);

            // Calculating the amount of points to mint to the account
            TokenStake storage tokenStake = tokenStakes[account][token];
            uint256 amountToMint =
                calculateMintAmount(token, tokenStake.amount, cumulativeRates[token] - tokenStake.cumulativeRate);
            emit PendingPointsConverted(account, token, amountToMint);
            totalAmountToMint += amountToMint;

            // Updating the user's token stake
            tokenStake.cumulativeRate = cumulativeRates[token];
        }
        // Minting the total amount of points to the account at the end if there are any
        if (totalAmountToMint > 0) {
            _mint(account, totalAmountToMint);
        }
    }

    function convertPendingPoints(address[] calldata accounts) public {
        for (uint256 i = 0; i < accounts.length; i++) {
            convertPendingPoints(accounts[i]);
        }
    }

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _paused = true;
    }

    /**
     * @inheritdoc IPoints
     */
    function paused() public view virtual returns (bool paused_) {
        paused_ = _paused;
    }

    /**
     * @inheritdoc IPoints
     */
    function setPaused(bool paused_) external onlyOwner {
        _paused = paused_;
        emit IsPaused(paused_);
    }

    /**
     * @inheritdoc IPoints
     */
    function setAuthorizedBurner(address authorizedBurner_) external onlyOwner {
        authorizedBurner = authorizedBurner_;
        emit AuthorizedBurnerUpdated(authorizedBurner_);
    }

    /**
     * @inheritdoc IPoints
     */
    function burn(address account, uint256 amount) external preConvertAllPendingPoints(account, amount) {
        if (msg.sender != authorizedBurner) {
            revert UnauthorizedBurner(msg.sender);
        }
        _burn(account, amount);
    }

    /**
     * @inheritdoc IPoints
     */
    function setAddressWhitelist(address account, bool status) external onlyOwner {
        isWhitelisted[account] = status;
        emit WhitelistUpdated(account, status);
    }

    /**
     * @dev Checks if token has been added. Does this by validating that the token has a timestamp.
     */
    function tokenSupported(address token) internal view returns (bool supported) {
        supported = timestamps[token] != 0;
    }

    function tokenCount() public view returns (uint256 count) {
        count = tokenAt.length;
    }

    /**
     * @inheritdoc IPoints
     */
    function setRates(address[] calldata tokens, uint96[] calldata rates) external onlyOwner {
        if (tokens.length != rates.length) {
            revert TokenRatesLengthsMismatched(tokens.length, rates.length);
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint96 newRate = rates[i];
            // Increase the cumulativeRate by r_{i-1} * t_{i-1}
            cumulativeRates[token] += uint128(block.timestamp - timestamps[token]) * _rates[token];
            _rates[token] = newRate;
            // If token not already supported, it needs to be added to the tokenAt array
            if (!tokenSupported(token)) {
                tokenAt.push(token);
            }
            timestamps[token] = uint32(block.timestamp);
            emit RateUpdated(token, newRate, uint32(block.timestamp));
        }
    }

    /**
     * @inheritdoc IPoints
     */
    function getRateInfo(address token) external view returns (uint96 rate, uint32 timestamp, uint128 cumulativeRate) {
        rate = _rates[token];
        timestamp = timestamps[token];
        cumulativeRate = cumulativeRates[token];
    }

    /**
     * @inheritdoc IPoints
     */
    function getMultipliers(address token)
        external
        view
        returns (uint128[] memory thresholds, uint128[] memory scalars)
    {
        thresholds = multiplierThresholds[token];
        scalars = multiplierScalars[token];
    }

    /**
     * @inheritdoc IPoints
     */
    function setMultipliers(address token, uint128[] calldata iterativeThresholds, uint128[] calldata iterativeScalars)
        external
        onlyOwner
    {
        if (iterativeThresholds.length != iterativeScalars.length) {
            revert MultiplierLengthsMismatched(iterativeThresholds.length, iterativeScalars.length);
        }

        // Calculating the resulting absolute thresholds and scalars
        uint128 runningThreshold;
        uint128 runningScalar = RATE_DENOMINATOR;
        multiplierThresholds[token] = new uint128[](iterativeThresholds.length);
        multiplierScalars[token] = new uint128[](iterativeThresholds.length);
        for (uint256 i = 0; i < iterativeThresholds.length; i++) {
            runningThreshold += iterativeThresholds[i];
            runningScalar += iterativeScalars[i];
            multiplierThresholds[token][i] = runningThreshold;
            multiplierScalars[token][i] = runningScalar;
        }
        emit MultipliersUpdated(token, multiplierThresholds[token], multiplierScalars[token]);
    }

    /**
     * @inheritdoc IPoints
     */
    function pendingBalanceOf(address account) public view returns (uint256 pendingBalance) {
        for (uint256 i = 0; i < tokenAt.length; i++) {
            address token = tokenAt[i];
            // Skip if the user has no stakes for the current token
            if (tokenStakes[account][token].amount == 0) {
                continue;
            }
            TokenStake memory tokenStake = tokenStakes[account][token];
            uint128 cumulativeRate =
                cumulativeRates[token] + uint128(block.timestamp - timestamps[token]) * _rates[token];
            pendingBalance += calculateMintAmount(token, tokenStake.amount, cumulativeRate - tokenStake.cumulativeRate);
        }
    }

    /**
     * @inheritdoc IERC20
     * @dev Overriding balanceOf to include pendingBalance
     */
    function balanceOf(address account) public view override(ERC20, IERC20) returns (uint256) {
        return super.balanceOf(account) + pendingBalanceOf(account);
    }

    /**
     * @dev Overriding _transfer to convert all pending points before transfers
     */
    function _transfer(address from, address to, uint256 amount)
        internal
        override
        checkPaused(from)
        preConvertAllPendingPoints(from, amount)
    {
        super._transfer(from, to, amount);
    }

    /**
     * @inheritdoc IPoints
     */
    function getTokenStake(address account, address token) external view override returns (uint128 amount) {
        amount = tokenStakes[account][token].amount;
    }

    function getTokenMultiplier(address account, address token) external view returns (uint256 rateScalar) {
        uint128 amount = tokenStakes[account][token].amount;

        rateScalar = RATE_DENOMINATOR;
        uint256 thresholdIndex;
        for (thresholdIndex = 0; thresholdIndex < multiplierThresholds[token].length; thresholdIndex++) {
            if (amount < multiplierThresholds[token][thresholdIndex]) {
                break;
            }
        }
        if (thresholdIndex > 0) {
            rateScalar = multiplierScalars[token][thresholdIndex - 1];
        }
    }
}
