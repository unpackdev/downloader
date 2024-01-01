// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

import "./AggregatorV3Interface.sol";

import "./SetHelper.sol";
import "./ArrayHelper.sol";
import "./TypeCaster.sol";
import "./DecimalsConverter.sol";

import "./IP2PSports.sol";

import "./Globals.sol";

contract P2PSports is IP2PSports, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SetHelper for EnumerableSet.AddressSet;
    using DecimalsConverter for *;
    using ArrayHelper for uint256[];
    using TypeCaster for *;

    address public backend;
    address public tokenSTMX;

    uint256 public startTime;
    uint256 public endTime;

    uint256 public maxAdminSharePercentage;
    uint256 public maxChallengersEachSide;

    uint256 public latestChallengeId;

    EnumerableSet.AddressSet internal _allTokens;
    EnumerableSet.AddressSet internal _oraclessTokens;
    EnumerableSet.AddressSet internal _allowedTokens;

    mapping(address => AggregatorV3Interface) internal _priceFeeds;

    mapping(uint256 => Challenge) internal _challenges;

    mapping(address => mapping(uint256 => UserBet)) internal _userChallengeBets;
    mapping(address => mapping(address => uint256)) internal _withdrawables;

    mapping(bool => AdminShareRule) internal _adminShareRules;
    mapping(address => uint256) internal _adminWithdrawables;

    modifier onlyBackend() {
        _onlyBackend();
        _;
    }

    constructor(
        address backend_,
        uint256 startTimestamp,
        uint256 endTimestamp,
        address stmx,
        address[] memory otherTokens,
        address[] memory otherPriceFeeds
    ) {
        startTime = startTimestamp;
        endTime = endTimestamp;

        backend = backend_;

        tokenSTMX = stmx;

        maxAdminSharePercentage = 20 * PRECISION;
        maxChallengersEachSide = 50;

        allowTokens(stmx.asSingletonArray(), [address(0)].asDynamic());
        allowTokens(otherTokens, otherPriceFeeds);
    }

    function createChallenge(address token, uint256 amount, uint8 decision) external payable {
        uint256 challengeId = ++latestChallengeId;

        require(
            _challengeStatus(challengeId) == ChallengeStatus.CanBeCreated,
            "Challenge creation not started"
        );

        if (token == address(0)) {
            amount = msg.value;
        } else {
            require(_allowedTokens.contains(token), "Token is not available for the challenge");
        }

        Challenge storage _challenge = _challenges[challengeId];

        _challenge.token = token;
        _challenge.status = ChallengeStatus.Betting;

        emit ChallengeCreated(challengeId, token, msg.sender);

        joinChallenge(challengeId, amount, decision);
    }

    function joinChallenge(uint256 challengeId, uint256 amount, uint8 decision) public payable {
        require(decision == 1 || decision == 2, "Decision should be 1 or 2");
        require(_challengeExists(challengeId), "Challenge doesn't exist");
        require(
            _challengeStatus(challengeId) == ChallengeStatus.Betting,
            "Challenge not in progress"
        );
        require(
            _userChallengeBets[msg.sender][challengeId].decision == 0,
            "You can only challenge once"
        );

        if (_challenges[challengeId].token == address(0)) {
            amount = msg.value;
        }

        _joinChallenge(challengeId, amount, decision);
    }

    function withdraw() external nonReentrant {
        uint256 allTokensLength = _allTokens.length();

        for (uint256 i = 0; i < allTokensLength; i++) {
            address token = _allTokens.at(i);
            uint256 amount = _withdrawables[msg.sender][token];

            _withdraw(token, msg.sender, amount);

            emit UserWithdrawn(token, amount, msg.sender);

            delete _withdrawables[msg.sender][token];
        }
    }

    function resolveChallenge(
        uint256 challengeId,
        uint8 finalOutcome
    ) external onlyBackend nonReentrant {
        require(finalOutcome > 0 && finalOutcome < 4, "Final outcome can only be 1, 2, or 3");
        require(_challengeExists(challengeId), "Challenge doesn't exist");
        require(
            _challengeStatus(challengeId) == ChallengeStatus.Awaiting,
            "Challenge not awaiting"
        );

        _challenges[challengeId].status = ChallengeStatus(finalOutcome + 4);

        emit ChallengeResolved(challengeId, finalOutcome);

        if (finalOutcome == 3) {
            _cancelBets(challengeId);
        } else {
            _calculateChallenge(challengeId, finalOutcome);
        }
    }

    function cancelChallenge(uint256 challengeId) external onlyBackend nonReentrant {
        require(_challengeExists(challengeId), "Challenge doesn't exist");
        require(
            _challengeStatus(challengeId) == ChallengeStatus.Awaiting ||
                _challengeStatus(challengeId) == ChallengeStatus.Betting,
            "Challenge not awaiting or betting"
        );

        _challenges[challengeId].status = ChallengeStatus.Canceled;

        emit ChallengeCanceled(challengeId);

        _cancelBets(challengeId);
    }

    function changeTimes(uint256 startTimestamp, uint256 endTimestamp) external onlyOwner {
        startTime = startTimestamp;
        endTime = endTimestamp;
    }

    function changeBackend(address backend_) external onlyOwner {
        backend = backend_;
    }

    function allowTokens(address[] memory tokens, address[] memory priceFeeds) public onlyOwner {
        require(tokens.length == priceFeeds.length, "Lengths differ");

        _allowedTokens.add(tokens);
        _allTokens.add(tokens);

        for (uint256 i = 0; i < tokens.length; i++) {
            if (priceFeeds[i] == address(0)) {
                _oraclessTokens.add(tokens[i]);
            } else {
                _priceFeeds[tokens[i]] = AggregatorV3Interface(priceFeeds[i]);
            }
        }
    }

    function restrictTokens(address[] calldata tokens) external onlyOwner {
        _allowedTokens.remove(tokens);
        _oraclessTokens.remove(tokens);

        for (uint256 i = 0; i < tokens.length; i++) {
            delete _priceFeeds[tokens[i]];
        }
    }

    function setAdminShareRules(
        uint256[] calldata thresholds,
        uint256[] calldata percentages,
        bool isSTMX
    ) external onlyOwner {
        require(
            thresholds.length > 0 && thresholds.length == percentages.length,
            "Lengths differ"
        );

        for (uint256 i = 0; i < thresholds.length - 1; i++) {
            require(thresholds[i] <= thresholds[i + 1], "Descending threshold");
            require(percentages[i] <= maxAdminSharePercentage, "Share is greater than 20%");
        }

        require(
            percentages[percentages.length - 1] <= maxAdminSharePercentage,
            "Share is greater than 20%"
        );

        _adminShareRules[isSTMX] = AdminShareRule({
            percentages: percentages,
            thresholds: thresholds
        });
    }

    function withdrawAdminShares(address to) external onlyOwner nonReentrant {
        uint256 allTokensLength = _allTokens.length();

        for (uint256 i = 0; i < allTokensLength; i++) {
            address token = _allTokens.at(i);
            uint256 amount = _adminWithdrawables[token];

            _withdraw(token, to, amount);

            emit AdminWithdrawn(token, amount);

            delete _adminWithdrawables[token];
        }
    }

    function getAllowedTokens() external view returns (address[] memory) {
        return _allowedTokens.values();
    }

    function getChallengeDetails(
        uint256 challengeId
    ) external view returns (Challenge memory challengeDetails) {
        challengeDetails = _challenges[challengeId];

        challengeDetails.status = _challengeStatus(challengeId);
    }

    function getUserBet(uint256 challengeId, address user) external view returns (UserBet memory) {
        return _userChallengeBets[user][challengeId];
    }

    function getUserWithdrawables(
        address user
    ) external view returns (address[] memory tokens, uint256[] memory amounts) {
        uint256 allTokensLength = _allTokens.length();

        tokens = new address[](allTokensLength);
        amounts = new uint256[](allTokensLength);

        for (uint256 i = 0; i < allTokensLength; i++) {
            tokens[i] = _allTokens.at(i);
            amounts[i] = _withdrawables[user][tokens[i]];
        }
    }

    function getAdminWithdrawables()
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        uint256 allTokensLength = _allTokens.length();

        tokens = new address[](allTokensLength);
        amounts = new uint256[](allTokensLength);

        for (uint256 i = 0; i < allTokensLength; i++) {
            tokens[i] = _allTokens.at(i);
            amounts[i] = _adminWithdrawables[tokens[i]];
        }
    }

    function _joinChallenge(
        uint256 challengeId,
        uint256 amount,
        uint8 decision
    ) internal nonReentrant {
        Challenge storage _challenge = _challenges[challengeId];
        address challengeToken = _challenge.token;

        uint256 adminShare = _calculateAdminShare(_challenge, amount);
        require(amount > adminShare, "amount <= admin share per challenge");

        if (challengeToken != address(0)) {
            IERC20(challengeToken).safeTransferFrom(msg.sender, address(this), amount);
        }

        _adminWithdrawables[challengeToken] += adminShare;
        amount -= adminShare;

        uint256 participants;

        if (decision == 1) {
            _challenge.usersFor.push(msg.sender);
            participants = _challenge.usersFor.length;

            _challenge.amountFor += amount;
        } else {
            _challenge.usersAgainst.push(msg.sender);
            participants = _challenge.usersAgainst.length;

            _challenge.amountAgainst += amount;
        }

        require(participants <= maxChallengersEachSide, "Max challengers per side");

        _userChallengeBets[msg.sender][challengeId] = UserBet({
            amount: amount,
            decision: decision
        });

        emit ChallengeJoined(challengeId, amount, msg.sender);
        emit AdminReceived(challengeId, challengeToken, adminShare);
    }

    function _calculateChallenge(uint256 challengeId, uint8 finalOutcome) internal {
        Challenge storage _challenge = _challenges[challengeId];
        address challengeToken = _challenge.token;

        address[] storage usersWin = _challenge.usersFor;
        address[] storage usersLose = _challenge.usersAgainst;
        uint256 winAmount = _challenge.amountFor;
        uint256 loseAmount = _challenge.amountAgainst;

        if (finalOutcome == 2) {
            (usersWin, usersLose) = (usersLose, usersWin);
            (winAmount, loseAmount) = (loseAmount, winAmount);
        }

        uint256 usersWinLength = usersWin.length;
        uint256 usersLoseLength = usersLose.length;

        uint256[] memory winAmounts = new uint256[](usersWinLength);

        for (uint256 i = 0; i < usersWinLength; i++) {
            address user = usersWin[i];
            UserBet storage bet = _userChallengeBets[user][challengeId];

            uint256 userWinAmount = bet.amount + ((loseAmount * bet.amount) / winAmount);

            winAmounts[i] = userWinAmount;
            _withdrawables[user][challengeToken] += userWinAmount;
        }

        uint256[] memory loseAmounts = new uint256[](usersLoseLength);

        for (uint256 i = 0; i < usersLoseLength; i++) {
            loseAmounts[i] = _userChallengeBets[usersLose[i]][challengeId].amount;
        }

        emit ChallengeFundsMoved(challengeId, usersWin, winAmounts, usersLose, loseAmounts);
    }

    function _cancelBets(uint256 challengeId) internal {
        Challenge storage _challenge = _challenges[challengeId];
        address challengeToken = _challenge.token;

        uint256 usersForLength = _challenge.usersFor.length;
        uint256 usersAgainstLength = _challenge.usersAgainst.length;

        address[] memory users = new address[](usersForLength + usersAgainstLength);
        uint256[] memory amounts = new uint256[](usersForLength + usersAgainstLength);

        for (uint256 i = 0; i < usersForLength; i++) {
            address user = _challenge.usersFor[i];

            users[i] = user;
            amounts[i] = _userChallengeBets[user][challengeId].amount;

            _withdrawables[user][challengeToken] += amounts[i];
        }

        for (uint256 i = 0; i < usersAgainstLength; i++) {
            address user = _challenge.usersAgainst[i];
            uint256 index = i + usersForLength;

            users[index] = user;
            amounts[index] = _userChallengeBets[user][challengeId].amount;

            _withdrawables[user][challengeToken] += amounts[index];
        }

        emit ChallengeFundsMoved(challengeId, users, amounts, new address[](0), new uint256[](0));
    }

    function _withdraw(address token, address to, uint256 amount) internal {
        if (token == address(0)) {
            (bool ok, ) = to.call{value: amount}("");
            require(ok, "Failed to send ETH");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    function _calculateAdminShare(
        Challenge storage _challenge,
        uint256 amount
    ) internal view returns (uint256) {
        address token = _challenge.token;
        uint256 valueAmount = (_getValue(token) * amount) /
            10 ** (token == address(0) ? 18 : token.decimals());

        AdminShareRule storage rule = _adminShareRules[token == tokenSTMX];

        uint256 index = rule.thresholds.upperBound(valueAmount);

        if (index == 0) {
            return 0;
        }

        return (amount * rule.percentages[index - 1]) / PERCENTAGE_100;
    }

    function _getValue(address token) internal view returns (uint256) {
        int256 value;
        uint256 updatedAt;

        if (_oraclessTokens.contains(token)) {
            value = 10 ** 8;
        } else {
            (, value, , updatedAt, ) = _priceFeeds[token].latestRoundData();

            require(value > 0 && updatedAt >= block.timestamp - 1 days, "Oracle malfunction");
        }

        return uint256(value);
    }

    function _challengeExists(uint256 challengeId) internal view returns (bool) {
        return challengeId > 0 && challengeId <= latestChallengeId;
    }

    function _challengeStatus(uint256 challengeId) internal view returns (ChallengeStatus) {
        ChallengeStatus status = _challenges[challengeId].status;

        if (block.timestamp < startTime) {
            return ChallengeStatus.None;
        }

        if (
            status == ChallengeStatus.Canceled ||
            status == ChallengeStatus.ResolvedFor ||
            status == ChallengeStatus.ResolvedAgainst ||
            status == ChallengeStatus.ResolvedDraw
        ) {
            return status;
        }

        if (block.timestamp > endTime) {
            return ChallengeStatus.Awaiting;
        }

        if (status == ChallengeStatus.Betting) {
            return status;
        }

        return ChallengeStatus.CanBeCreated;
    }

    function _onlyBackend() internal view {
        require(msg.sender == backend, "Not a backend");
    }
}
