// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import "./IVote.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeTransferLib.sol";

contract Vote is IVote, Ownable {
    uint256 constant _PRECISION = 1e18;
    uint256 private constant _PERCENTAGE = 10000;
    uint256 private constant _TOTAL_SUPPLY = 1e26; // 100,000,000 w/ 18 decimals
    address private immutable _token;

    uint256 public votingPeriod;
    uint256 public lastRevenue;

    SnapshotStruct _snapshot;
    VoteStruct _currentVote;
    GameStruct _currentGame;

    uint256[] public counter;

    TierStruct[] public tiers;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public tierOf;

    mapping(address => uint256) public gameShareOf;

    mapping(address => uint256) public lastActionOf;

    mapping(uint256 => GameStruct) public voteTimestampToGame;

    uint256 public redeemFee;
    address payable _protocolAddress;
    address _updateAddress;

    constructor(address _tokenAddress) noZeroAddress(_tokenAddress) {
        _initializeOwner(msg.sender);
        _token = _tokenAddress;
    }

    function castVote(uint8 _choice) external inSession {
        VoteStruct storage localVote = _currentVote;
        if (_choice > localVote.choices) revert NotAChoice(localVote.choices - 1);

        uint256 amount = _getTierAmount(msg.sender);
        amount += getReward(msg.sender);
        //slither-disable-next-line incorrect-equality
        if (amount == 0) return;

        counter[_choice] += 1;

        balanceOf[msg.sender] = 0;
        lastActionOf[msg.sender] = localVote.timestamp;
        emit VoteCasted(msg.sender, _choice);
        _currentGame.balanceBefore += amount;
        gameShareOf[msg.sender] = amount;
    }

    function claimShare() external inSession {
        uint256 amount = _getTierAmount(msg.sender);
        //slither-disable-next-line incorrect-equality
        if (amount == 0) return;

        uint256 toProtocol = amount * redeemFee / _PERCENTAGE;
        amount -= toProtocol;
        amount += getReward(msg.sender);

        balanceOf[msg.sender] = 0;
        gameShareOf[msg.sender] = 0;
        emit ShareClaimed(msg.sender, amount, toProtocol);
        SafeTransferLib.safeTransferETH(msg.sender, amount);
        SafeTransferLib.safeTransferETH(_protocolAddress, toProtocol);
    }

    function claimReward() external requireVoteNotActive requireGameNotActive {
        uint256 amount = getReward(msg.sender);
        if (amount == 0 && gameShareOf[msg.sender] == 0) revert NoReward();

        gameShareOf[msg.sender] = 0;
        emit RewardClaimed(msg.sender, amount);
        SafeTransferLib.safeTransferETH(msg.sender, amount);
    }

    function _getTierAmount(address _user) internal returns (uint256) {
        uint256 currentBalance = IERC20(_token).balanceOf(_user);

        int256 currentTier = _findTier(currentBalance);
        uint256 amount = balanceOf[_user];

        if (currentTier < 0) {
            balanceOf[_user] = 0;
            emit ForfeitShare(msg.sender, amount);
            SafeTransferLib.safeTransferETH(_protocolAddress, amount);
            return 0;
        }

        uint256 snapshotTier = tierOf[_user];
        uint256 currentTierUnsigned = uint256(currentTier);
        if (snapshotTier > currentTierUnsigned) {
            uint256 currentTierShare = _getTierRevenue(currentTierUnsigned) / _snapshot.usersByTier[currentTierUnsigned];
            uint256 snapshotTierShare = _getTierRevenue(snapshotTier) / _snapshot.usersByTier[snapshotTier];
            uint256 toProtocol = snapshotTierShare - currentTierShare;
            amount -= toProtocol;
            emit ForfeitSharePartial(msg.sender, amount, toProtocol);
            SafeTransferLib.safeTransferETH(_protocolAddress, toProtocol);
        }
        return amount;
    }

    function _getTierRevenue(uint256 _tier) internal view returns (uint256) {
        return _currentVote.balance * tiers[_tier].revenueShare / _PERCENTAGE;
    }

    /// @notice Starts a vote session
    /// @dev If vote is not already undergoing the contractOwner can start a vote session,
    /// we store number of choices, timestamp of action and set vote.active to true;
    /// function is set to payable to cut on gas costs
    /// @param _choices indicates the number of choices available for this vote sessions
    /// Note Emits a {VoteStarted} event
    function startVote(uint8 _choices) external payable onlyOwnerOrUpdate requireVoteNotActive {
        if (_choices < 2) revert NoChoices();
        _currentVote = VoteStruct(true, _choices, _snapshot.balance, block.timestamp);
        _currentGame = GameStruct(false, 0, 0, 0, 0);
        counter = new uint256[](_choices);

        emit VoteStarted(_choices);
    }

    function _getWinners() internal view returns (uint256[] memory) {
        uint256[] memory localCounter = counter;
        uint256 counterLength = localCounter.length;
        uint256 maxNumber = localCounter[0];
        uint256 count = 1;

        for (uint256 i = 1; i < counterLength; ++i) {
            if (localCounter[i] > maxNumber) {
                maxNumber = localCounter[i];
                count = 1;
            } else if (localCounter[i] == maxNumber) {
                ++count;
            }
        }

        uint256[] memory winners = new uint256[](count);
        count = 0;

        for (uint256 i; i < counterLength; ++i) {
            if (localCounter[i] == maxNumber) {
                winners[count] = i;
                count += 1;
            }
        }

        return winners;
    }

    function _findTier(uint256 balance) internal view returns (int256) {
        uint256 length = tiers.length;
        for (uint256 i; i < length; ++i) {
            if (balance < tiers[i].tokenAmount) {
                return (i == 0) ? -1 : int256(i) - 1;
            }
        }
        return int256(length) - 1;
    }

    function updateState(address[][] memory addressByTier) external payable onlyUpdate requireVoteNotActive {
        SnapshotStruct storage localSnapshot = _snapshot;
        if (localSnapshot.timestamp > _currentVote.timestamp) revert NoConsecutiveSnapshot();
        TierStruct[] memory localTiers = tiers;
        uint256 tiersLength = localTiers.length;
        if (addressByTier.length != tiersLength + 1) revert TierArrayLength(tiersLength + 1);
        delete _snapshot;
        uint256 toProtocol;

        // first array is reserved for addresses that do not respect any threshold requirement
        // we zero out the pending rewards for them and send them to protocol wallet
        uint256 zeroLength = addressByTier[0].length;
        for (uint256 i; i < zeroLength; ++i) {
            toProtocol += balanceOf[addressByTier[0][i]];
            balanceOf[addressByTier[0][i]] = 0;
        }
        SafeTransferLib.safeTransferETH(_protocolAddress, toProtocol);

        uint256 inputLength = addressByTier.length;
        _snapshot = SnapshotStruct(new uint256[](tiersLength), lastRevenue, block.timestamp);

        for (uint256 l = 1; l < inputLength; ++l) {
            uint256 tier = l - 1;
            uint256 tierLength = addressByTier[l].length;
            localSnapshot.usersByTier[tier] = tierLength;
            uint256 individualShare = (lastRevenue * localTiers[tier].revenueShare / _PERCENTAGE) / tierLength;

            // Update the state for each user
            for (uint256 i; i < tierLength; ++i) {
                tierOf[addressByTier[l][i]] = tier;
                balanceOf[addressByTier[l][i]] += individualShare;
            }
        }
        lastRevenue = 0;
        // maybe emit event?
    }

    function startGame() external payable onlyOwnerOrUpdate requireGameNotActive {
        VoteStruct storage localVote = _currentVote;
        GameStruct storage localGame = _currentGame;
        if (block.timestamp < localVote.timestamp + votingPeriod) revert OutOfBounds();
        if (!localVote.active) revert VoteNotActive();

        uint256[] memory winners = _getWinners();
        localVote.active = false;
        localGame.active = true;
        localGame.withdrawTimestamp = block.timestamp;
        emit VoteEnded(owner(), winners, localGame.balanceBefore);
        SafeTransferLib.safeTransferETH(owner(), localGame.balanceBefore);
    }

    function endGame() external payable onlyOwner requireGameActive requireVoteNotActive {
        GameStruct storage localGame = _currentGame;
        localGame.active = false;
        localGame.balanceAfter = msg.value;
        localGame.depositTimestamp = block.timestamp;

        voteTimestampToGame[_currentVote.timestamp] = localGame;
        emit GameEnded(msg.value);
    }

    function getReward(address _address) public view returns (uint256) {
        uint256 share = gameShareOf[_address];
        if (share == 0) return 0;
        GameStruct storage localGame = voteTimestampToGame[lastActionOf[_address]];
        uint256 multiplier = _getMultiplier(localGame.balanceAfter, localGame.balanceBefore);
        return share * multiplier / _PRECISION;
    }

    function _getMultiplier(uint256 _newBalance, uint256 _oldBalance) internal pure returns (uint256) {
        return (_newBalance * _PRECISION) / _oldBalance;
    }

    function setTiers(TierStruct[] calldata _tiers) external payable onlyOwner tiersSafe(_tiers) {
        delete tiers;
        uint256 length = _tiers.length;
        for (uint256 i; i < length; ++i) {
            tiers.push(_tiers[i]);
        }

        emit TiersSet(_tiers);
    }

    function setPeriod(uint256 _period) external payable onlyOwner requireVoteNotActive {
        votingPeriod = _period;
        emit VotingPeriodSet(_period);
    }

    function setProtocolAddress(address _address) external payable onlyOwner noZeroAddress(_address) {
        _protocolAddress = payable(_address);
        emit ProtocolAddressSet(_address);
    }

    function setUpdateAddress(address _address) external payable onlyOwner noZeroAddress(_address) {
        _updateAddress = _address;
        emit UpdateAddressSet(_address);
    }

    /// @notice Sets fee for early redeem, values from 0.01 (1) to 100.00 (10000)
    /// @param _fee new fee amount, a percentage expressed in uint256 with 2 decimals
    function setRedeemFee(uint256 _fee) external payable onlyOwner {
        if (_fee > _PERCENTAGE) revert FeeOverflow();
        redeemFee = _fee;
        emit RedeemFeeSet(_fee);
    }

    function renounceOwnership() public payable override onlyOwner {
        revert NoRenounce();
    }

    receive() external payable {
        lastRevenue += msg.value;
    }

    // redeem emergency function;

    function currentVote() external view returns (VoteStruct memory) {
        return _currentVote;
    }

    function currentGame() external view returns (GameStruct memory) {
        return _currentGame;
    }

    function snapshot() external view returns (SnapshotStruct memory) {
        return _snapshot;
    }

    function getUsersByTier() external view returns (uint256[] memory) {
        return _snapshot.usersByTier;
    }

    modifier inSession() {
        VoteStruct storage localVote = _currentVote;
        if (block.timestamp < localVote.timestamp || block.timestamp > localVote.timestamp + votingPeriod) {
            revert OutOfBounds();
        }

        if (balanceOf[msg.sender] == 0) revert NoReward();

        _;
    }

    modifier tiersSafe(TierStruct[] memory _tiers) {
        uint256 length = _tiers.length;
        if (length == 0) revert NoTiers();
        uint256 tokenTotal;
        uint256 revenueTotal;
        uint256 supply = _TOTAL_SUPPLY;
        for (uint256 i; i < length; ++i) {
            tokenTotal += _tiers[i].tokenAmount;
            revenueTotal += _tiers[i].revenueShare;

            if (tokenTotal > supply) revert TokenTierOverflow();
            if (revenueTotal > 10_000) revert ShareTierOverflow();
        }

        _;
    }

    modifier noZeroAddress(address _address) {
        if (_address == address(0)) revert ZeroAddress();
        _;
    }

    modifier requireVoteNotActive() {
        if (_currentVote.active) revert VoteActive();
        _;
    }

    modifier requireGameActive() {
        if (!_currentGame.active) revert GameNotActive();
        _;
    }

    modifier requireGameNotActive() {
        if (_currentGame.active) revert GameActive();
        _;
    }

    modifier onlyUpdate() {
        if (msg.sender != _updateAddress) revert OnlyUpdate();
        _;
    }

    modifier onlyOwnerOrUpdate() {
        if (msg.sender != owner() && msg.sender != _updateAddress) revert NotOwnerOrUpdate();
        _;
    }
}
