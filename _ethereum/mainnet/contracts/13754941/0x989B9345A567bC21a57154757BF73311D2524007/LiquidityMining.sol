// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./OwnableUpgradeable.sol";
import "./EnumerableSet.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IERC1155.sol";
import "./ERC1155Receiver.sol";

import "./IPolicyBook.sol";
import "./IContractsRegistry.sol";
import "./ILiquidityMining.sol";
import "./IPolicyBookRegistry.sol";

import "./AbstractDependant.sol";

import "./Globals.sol";

contract LiquidityMining is
    ILiquidityMining,
    OwnableUpgradeable,
    ERC1155Receiver,
    AbstractDependant
{
    using Math for uint256;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    address[] public leaderboard;
    address[] public topUsers;

    EnumerableSet.AddressSet internal allUsers;
    EnumerableSet.AddressSet internal teamsArr;

    uint256 public override startLiquidityMiningTime;

    uint256 public constant PLATINUM_NFT_ID = 1;
    uint256 public constant GOLD_NFT_ID = 2;
    uint256 public constant SILVER_NFT_ID = 3;
    uint256 public constant BRONZE_NFT_ID = 4;

    uint256 public constant TOP_1_REWARD = 150000 * DECIMALS18;
    uint256 public constant TOP_2_5_REWARD = 50000 * DECIMALS18;
    uint256 public constant TOP_6_10_REWARD = 20000 * DECIMALS18;
    uint256 public constant MAX_MONTH_TO_GET_REWARD = 5;

    uint256 public constant MAX_GROUP_LEADERS_SIZE = 10;
    uint256 public constant MAX_LEADERBOARD_SIZE = 10;
    uint256 public constant MAX_TOP_USERS_SIZE = 5;
    uint256 public constant LM_DURATION = 2 weeks;

    uint256 public constant FIRST_MAX_SLASHING_FEE = 50 * PRECISION;
    uint256 public constant SECOND_MAX_SLASHING_FEE = 99 * PRECISION;
    uint256 public constant SECOND_SLASHING_DURATION = 10 minutes;

    uint256 public constant ONE_MONTH = 30 days;

    IERC20 public bmiToken;
    IERC1155 public liquidityMiningNFT;
    IPolicyBookRegistry public policyBookRegistry;

    // Referral link => team info
    mapping(address => TeamInfo) public teamInfos;

    // User addr => Info
    mapping(address => UserTeamInfo) public usersTeamInfo;

    mapping(string => bool) public existingNames;

    // Referral link => members
    mapping(address => EnumerableSet.AddressSet) private teamsMembers;

    event TeamCreated(address _referralLink, string _name);
    event TeamDeleted(address _referralLink, string _name);
    event MemberAdded(address _referralLink, address _newMember, uint256 _membersNumber);
    event TeamInvested(address _referralLink, address _stblInvestor, uint256 _tokensAmount);
    event LeaderboardUpdated(uint256 _index, address _prevLink, address _newReferralLink);
    event TopUsersUpdated(uint256 _index, address _prevAddr, address _newAddr);
    event RewardSent(address _referralLink, address _address, uint256 _reward);
    event NFTSent(address _address, uint256 _nftIndex);

    function __LiquidityMining_init() external initializer {
        __Ownable_init();
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        bmiToken = IERC20(_contractsRegistry.getBMIContract());
        liquidityMiningNFT = IERC1155(_contractsRegistry.getBMIUtilityNFTContract());
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
    }

    function startLiquidityMining() external onlyOwner {
        require(startLiquidityMiningTime == 0, "LM: start liquidity mining is already set");

        startLiquidityMiningTime = block.timestamp;
    }

    function getTopTeams() external view override returns (TeamDetails[] memory teams) {
        uint256 leaderboradSize = leaderboard.length;

        teams = new TeamDetails[](leaderboradSize);

        for (uint256 i = 0; i < leaderboradSize; i++) {
            teams[i] = _getTeamDetails(leaderboard[i]);
        }
    }

    function getTopUsers() external view override returns (UserInfo[] memory users) {
        uint256 topUsersSize = topUsers.length;

        users = new UserInfo[](topUsersSize);

        for (uint256 i = 0; i < topUsersSize; i++) {
            address _currentUserAddr = topUsers[i];

            users[i] = UserInfo(
                _currentUserAddr,
                teamInfos[usersTeamInfo[_currentUserAddr].teamAddr].name,
                usersTeamInfo[_currentUserAddr].stakedAmount,
                checkMainNFTReward(_currentUserAddr),
                checkPlatinumNFTReward(_currentUserAddr)
            );
        }
    }

    function getAllTeamsLength() external view override returns (uint256) {
        return teamsArr.length();
    }

    function getAllTeamsDetails(uint256 _offset, uint256 _limit)
        external
        view
        override
        returns (TeamDetails[] memory _teamDetailsArr)
    {
        uint256 _to = (_offset.add(_limit)).min(teamsArr.length()).max(_offset);

        _teamDetailsArr = new TeamDetails[](_to - _offset);

        for (uint256 i = _offset; i < _to; i++) {
            _teamDetailsArr[i - _offset] = _getTeamDetails(teamsArr.at(i));
        }
    }

    function getMyTeamsLength() external view override returns (uint256) {
        return teamsMembers[usersTeamInfo[msg.sender].teamAddr].length();
    }

    function getMyTeamMembers(uint256 _offset, uint256 _limit)
        external
        view
        override
        returns (address[] memory _teamMembers, uint256[] memory _memberStakedAmount)
    {
        EnumerableSet.AddressSet storage _members =
            teamsMembers[usersTeamInfo[msg.sender].teamAddr];

        uint256 _to = (_offset.add(_limit)).min(_members.length()).max(_offset);
        uint256 _size = _to - _offset;

        _teamMembers = new address[](_size);
        _memberStakedAmount = new uint256[](_size);

        for (uint256 i = _offset; i < _to; i++) {
            address _currentMember = _members.at(i);
            _teamMembers[i - _offset] = _currentMember;
            _memberStakedAmount[i - _offset] = usersTeamInfo[_currentMember].stakedAmount;
        }
    }

    function getAllUsersLength() external view override returns (uint256) {
        return allUsers.length();
    }

    function getAllUsersInfo(uint256 _offset, uint256 _limit)
        external
        view
        override
        returns (UserInfo[] memory _userInfos)
    {
        uint256 _to = (_offset.add(_limit)).min(allUsers.length()).max(_offset);

        _userInfos = new UserInfo[](_to - _offset);

        for (uint256 i = _offset; i < _to; i++) {
            address _currentUserAddr = allUsers.at(i);

            _userInfos[i - _offset] = UserInfo(
                _currentUserAddr,
                teamInfos[usersTeamInfo[_currentUserAddr].teamAddr].name,
                usersTeamInfo[_currentUserAddr].stakedAmount,
                checkMainNFTReward(_currentUserAddr),
                checkPlatinumNFTReward(_currentUserAddr)
            );
        }
    }

    function getMyTeamInfo() external view override returns (MyTeamInfo memory _myTeamInfo) {
        UserTeamInfo storage userTeamInfo = usersTeamInfo[msg.sender];

        _myTeamInfo.teamDetails = _getTeamDetails(userTeamInfo.teamAddr);
        _myTeamInfo.myStakedAmount = userTeamInfo.stakedAmount;
        _myTeamInfo.teamPlace = _getIndexInTheLeaderboard(_myTeamInfo.teamDetails.referralLink);
    }

    function _getTeamDetails(address _teamAddr)
        internal
        view
        returns (TeamDetails memory _teamDetails)
    {
        _teamDetails = TeamDetails(
            teamInfos[_teamAddr].name,
            _teamAddr,
            teamsMembers[_teamAddr].length(),
            teamInfos[_teamAddr].totalAmount,
            _getTeamReward(_getIndexInTheLeaderboard(_teamAddr))
        );
    }

    function getRewardsInfo(address user)
        external
        view
        override
        returns (UserRewardsInfo memory userRewardInfo)
    {
        if (!isLMEnded()) {
            return userRewardInfo; // empty
        }

        userRewardInfo.teamName = teamInfos[usersTeamInfo[user].teamAddr].name;

        userRewardInfo.totalBMIReward = getTotalUserBMIReward(user);
        userRewardInfo.availableBMIReward = checkAvailableBMIReward(user);

        uint256 elapsedSeconds = block.timestamp.sub(getEndLMTime());
        uint256 elapsedMonths = elapsedSeconds.div(ONE_MONTH).add(1);

        userRewardInfo.incomingPeriods = MAX_MONTH_TO_GET_REWARD > elapsedMonths
            ? MAX_MONTH_TO_GET_REWARD - elapsedMonths
            : 0;

        userRewardInfo.timeToNextDistribution = userRewardInfo.incomingPeriods > 0
            ? ONE_MONTH - elapsedSeconds.mod(ONE_MONTH)
            : 0;

        userRewardInfo.claimedBMI = usersTeamInfo[user]
            .countOfRewardedMonth
            .mul(userRewardInfo.totalBMIReward)
            .div(MAX_MONTH_TO_GET_REWARD);

        userRewardInfo.mainNFTAvailability = checkMainNFTReward(user);
        userRewardInfo.platinumNFTAvailability = checkPlatinumNFTReward(user);

        userRewardInfo.claimedNFTs = usersTeamInfo[user].isNFTDistributed;
    }

    function createTeam(string calldata _teamName) external override {
        require(isLMLasting(), "LM: LME didn't start or finished");
        require(
            bytes(_teamName).length != 0 && bytes(_teamName).length <= 50,
            "LM: Team name is too long/short"
        );
        require(
            usersTeamInfo[msg.sender].teamAddr == address(0),
            "LM: The user is already in the team"
        );
        require(!existingNames[_teamName], "LM: Team name already exists");

        teamInfos[msg.sender].name = _teamName;
        usersTeamInfo[msg.sender].teamAddr = msg.sender;

        teamsArr.add(msg.sender);
        teamsMembers[msg.sender].add(msg.sender);
        existingNames[_teamName] = true;

        allUsers.add(msg.sender);

        emit TeamCreated(msg.sender, _teamName);
    }

    function deleteTeam() external override {
        require(teamsMembers[msg.sender].length() == 1, "LM: Unable to delete a team");
        require(usersTeamInfo[msg.sender].stakedAmount == 0, "LM: Unable to remove a team");

        string memory _teamName = teamInfos[msg.sender].name;

        teamsArr.remove(msg.sender);
        delete usersTeamInfo[msg.sender];
        delete teamsMembers[msg.sender];
        delete teamInfos[msg.sender].name;
        delete existingNames[_teamName];

        allUsers.remove(msg.sender);

        emit TeamDeleted(msg.sender, _teamName);
    }

    function joinTheTeam(address _referralLink) external override {
        require(_referralLink != address(0), "LM: Invalid referral link");
        require(teamsArr.contains(_referralLink), "LM: There is no such team");
        require(
            usersTeamInfo[msg.sender].teamAddr == address(0),
            "LM: The user is already in the team"
        );

        teamsMembers[_referralLink].add(msg.sender);

        usersTeamInfo[msg.sender].teamAddr = _referralLink;

        allUsers.add(msg.sender);

        emit MemberAdded(_referralLink, msg.sender, teamsMembers[_referralLink].length());
    }

    function getSlashingPercentage() public view override returns (uint256) {
        uint256 endLMTime = getEndLMTime();

        if (block.timestamp + SECOND_SLASHING_DURATION < endLMTime) {
            uint256 elapsed = block.timestamp.sub(startLiquidityMiningTime);
            uint256 feePerSecond =
                FIRST_MAX_SLASHING_FEE.div(LM_DURATION.sub(SECOND_SLASHING_DURATION));

            return elapsed.mul(feePerSecond);
        } else {
            uint256 elapsed = block.timestamp.sub(endLMTime.sub(SECOND_SLASHING_DURATION));
            uint256 feePerSecond =
                SECOND_MAX_SLASHING_FEE.sub(FIRST_MAX_SLASHING_FEE).div(SECOND_SLASHING_DURATION);

            return
                Math.min(
                    elapsed.mul(feePerSecond).add(FIRST_MAX_SLASHING_FEE),
                    SECOND_MAX_SLASHING_FEE
                );
        }
    }

    function investSTBL(uint256 _tokensAmount, address _policyBookAddr) external override {
        require(_tokensAmount > 0, "LM: Tokens amount is zero");
        require(isLMLasting(), "LM: LME didn't start or finished");
        require(
            policyBookRegistry.isPolicyBook(_policyBookAddr),
            "LM: Can't invest to not a PolicyBook"
        );

        address _userTeamAddr = usersTeamInfo[msg.sender].teamAddr;
        uint256 _userStakedAmount = usersTeamInfo[msg.sender].stakedAmount;

        require(_userTeamAddr != address(0), "LM: User is without a team");

        uint256 _finalTokensAmount =
            _tokensAmount.sub(_tokensAmount.mul(getSlashingPercentage()).div(PERCENTAGE_100));

        require(_finalTokensAmount > 0, "LM: Final tokens amount is zero");

        teamInfos[_userTeamAddr].totalAmount = teamInfos[_userTeamAddr].totalAmount.add(
            _finalTokensAmount
        );

        usersTeamInfo[msg.sender].stakedAmount = _userStakedAmount.add(_finalTokensAmount);

        _updateTopUsers();
        _updateLeaderboard(_userTeamAddr);
        _updateGroupLeaders(_userTeamAddr);

        emit TeamInvested(_userTeamAddr, msg.sender, _finalTokensAmount);

        IPolicyBook(_policyBookAddr).addLiquidityFor(msg.sender, _tokensAmount);
    }

    function distributeNFT() external override {
        require(isLMEnded(), "LM: LME didn't start or still going");

        UserTeamInfo storage _userTeamInfo = usersTeamInfo[msg.sender];

        require(!_userTeamInfo.isNFTDistributed, "LM: NFT is already distributed");

        _userTeamInfo.isNFTDistributed = true;

        uint256 _indexInTheTeam = _getIndexInTheGroupLeaders(msg.sender);

        if (
            _indexInTheTeam != MAX_GROUP_LEADERS_SIZE &&
            _getIndexInTheLeaderboard(_userTeamInfo.teamAddr) != MAX_LEADERBOARD_SIZE
        ) {
            _sendMainNFT(_indexInTheTeam, msg.sender);
        }

        _sendPlatinumNFT(msg.sender);
    }

    function checkPlatinumNFTReward(address _userAddr) public view override returns (uint256) {
        if (isLMEnded() && _getIndexInTopUsers(_userAddr) != MAX_TOP_USERS_SIZE) {
            return PLATINUM_NFT_ID;
        }

        return 0;
    }

    function checkMainNFTReward(address _userAddr) public view override returns (uint256) {
        uint256 placeInsideTeam = _getIndexInTheGroupLeaders(_userAddr);

        if (
            isLMEnded() &&
            placeInsideTeam != MAX_GROUP_LEADERS_SIZE &&
            _getIndexInTheLeaderboard(usersTeamInfo[_userAddr].teamAddr) != MAX_LEADERBOARD_SIZE
        ) {
            return _getMainNFTReward(placeInsideTeam);
        }

        return 0;
    }

    function distributeBMIReward() external override {
        require(isLMEnded(), "LM: LME didn't start or still going");

        address _teamAddr = usersTeamInfo[msg.sender].teamAddr;
        uint256 _userReward = checkAvailableBMIReward(msg.sender);

        if (_userReward == 0) {
            revert("LM: No BMI reward available");
        }

        bmiToken.transfer(msg.sender, _userReward);
        emit RewardSent(_teamAddr, msg.sender, _userReward);

        usersTeamInfo[msg.sender].countOfRewardedMonth += _getAvailableMonthForReward(msg.sender);
    }

    function getTotalUserBMIReward(address _userAddr) public view override returns (uint256) {
        if (!isLMEnded()) {
            return 0;
        }

        address _teamAddr = usersTeamInfo[_userAddr].teamAddr;
        uint256 _staked = usersTeamInfo[_userAddr].stakedAmount;
        uint256 _currentGroupIndex = _getIndexInTheLeaderboard(_teamAddr);

        if (_currentGroupIndex == MAX_LEADERBOARD_SIZE || _staked == 0) {
            return 0;
        }

        uint256 _userRewardPercent =
            _calculatePercentage(_staked, teamInfos[_teamAddr].totalAmount);
        uint256 _userReward =
            _getTeamReward(_currentGroupIndex).mul(_userRewardPercent).div(PERCENTAGE_100);

        return _userReward;
    }

    function checkAvailableBMIReward(address _userAddr) public view override returns (uint256) {
        uint256 _availableMonthCount = _getAvailableMonthForReward(_userAddr);

        if (_availableMonthCount == 0) {
            return 0;
        }

        return
            getTotalUserBMIReward(_userAddr).mul(_availableMonthCount).div(
                MAX_MONTH_TO_GET_REWARD
            );
    }

    function isLMLasting() public view override returns (bool) {
        return startLiquidityMiningTime != 0 && getEndLMTime() >= block.timestamp;
    }

    function isLMEnded() public view override returns (bool) {
        return startLiquidityMiningTime != 0 && getEndLMTime() < block.timestamp;
    }

    function getEndLMTime() public view override returns (uint256) {
        return startLiquidityMiningTime.add(LM_DURATION);
    }

    function _getMainNFTReward(uint256 place) internal view returns (uint256) {
        if (!isLMEnded() || place == MAX_GROUP_LEADERS_SIZE) {
            return 0;
        }

        if (place == 0) {
            return GOLD_NFT_ID;
        } else if (place < 4) {
            return SILVER_NFT_ID;
        } else {
            return BRONZE_NFT_ID;
        }
    }

    /// @dev NFT indices have to change when external ERC1155 is used
    function _sendMainNFT(uint256 _index, address _userAddr) internal {
        uint256 _nftIndex = _getMainNFTReward(_index);

        liquidityMiningNFT.safeTransferFrom(address(this), _userAddr, _nftIndex, 1, "");

        emit NFTSent(_userAddr, _nftIndex);
    }

    function _sendPlatinumNFT(address _userAddr) internal {
        uint256 _topUsersLength = topUsers.length;

        for (uint256 i = 0; i < _topUsersLength; i++) {
            if (_userAddr == topUsers[i]) {
                liquidityMiningNFT.safeTransferFrom(
                    address(this),
                    _userAddr,
                    PLATINUM_NFT_ID,
                    1,
                    ""
                );
                emit NFTSent(_userAddr, PLATINUM_NFT_ID);

                break;
            }
        }
    }

    function _calculatePercentage(uint256 _part, uint256 _amount) internal pure returns (uint256) {
        if (_amount == 0) {
            return 0;
        }

        return _part.mul(PERCENTAGE_100).div(_amount);
    }

    function _getTeamReward(uint256 place) internal view returns (uint256) {
        if (!isLMEnded() || place == MAX_LEADERBOARD_SIZE) {
            return 0;
        }

        if (place == 0) {
            return TOP_1_REWARD;
        } else if (place > 0 && place < 5) {
            return TOP_2_5_REWARD;
        } else {
            return TOP_6_10_REWARD;
        }
    }

    function _getAvailableMonthForReward(address _userAddr) internal view returns (uint256) {
        return
            Math
                .min(
                (block.timestamp.sub(getEndLMTime())).div(ONE_MONTH).add(1),
                MAX_MONTH_TO_GET_REWARD
            )
                .sub(usersTeamInfo[_userAddr].countOfRewardedMonth);
    }

    function _getIndexInTopUsers(address _userAddr) internal view returns (uint256) {
        uint256 _topUsersLength = topUsers.length;

        for (uint256 i = 0; i < _topUsersLength; i++) {
            if (_userAddr == topUsers[i]) {
                return i;
            }
        }

        return MAX_TOP_USERS_SIZE;
    }

    function _getIndexInTheGroupLeaders(address _userAddr) internal view returns (uint256) {
        address _referralLink = usersTeamInfo[_userAddr].teamAddr;
        uint256 _size = teamInfos[_referralLink].teamLeaders.length;

        for (uint256 i = 0; i < _size; i++) {
            if (_userAddr == teamInfos[_referralLink].teamLeaders[i]) {
                return i;
            }
        }

        return MAX_GROUP_LEADERS_SIZE;
    }

    function _getIndexInTheLeaderboard(address _referralLink) internal view returns (uint256) {
        uint256 _leaderBoardLength = leaderboard.length;

        for (uint256 i = 0; i < _leaderBoardLength; i++) {
            if (_referralLink == leaderboard[i]) {
                return i;
            }
        }

        return MAX_LEADERBOARD_SIZE;
    }

    function _updateLeaderboard(address _referralLink) internal {
        uint256 _leaderBoardLength = leaderboard.length;

        if (_leaderBoardLength == 0) {
            leaderboard.push(_referralLink);
            emit LeaderboardUpdated(0, address(0), _referralLink);
            return;
        }

        uint256 _currentGroupIndex = _getIndexInTheLeaderboard(_referralLink);

        if (_currentGroupIndex == MAX_LEADERBOARD_SIZE) {
            _currentGroupIndex = _leaderBoardLength++;
            leaderboard.push(_referralLink);
        }

        if (_currentGroupIndex == 0) {
            return;
        }

        address[] memory _addresses = leaderboard;
        uint256 _currentIndex = _currentGroupIndex - 1;
        uint256 _currentTeamAmount = teamInfos[_referralLink].totalAmount;

        if (_currentTeamAmount > teamInfos[_addresses[_currentIndex]].totalAmount) {
            while (_currentTeamAmount > teamInfos[_addresses[_currentIndex]].totalAmount) {
                address _tmpLink = _addresses[_currentIndex];
                _addresses[_currentIndex] = _referralLink;
                _addresses[_currentIndex + 1] = _tmpLink;

                if (_currentIndex == 0) {
                    break;
                }

                _currentIndex--;
            }

            leaderboard = _addresses;

            emit LeaderboardUpdated(_currentIndex, _addresses[_currentIndex + 1], _referralLink);
        }

        if (_leaderBoardLength > MAX_LEADERBOARD_SIZE) {
            leaderboard.pop();
        }
    }

    function _updateTopUsers() internal {
        uint256 _topUsersLength = topUsers.length;

        if (_topUsersLength == 0) {
            topUsers.push(msg.sender);
            emit TopUsersUpdated(0, address(0), msg.sender);
            return;
        }

        uint256 _currentIndex = _getIndexInTopUsers(msg.sender);

        if (_currentIndex == MAX_TOP_USERS_SIZE) {
            _currentIndex = _topUsersLength++;
            topUsers.push(msg.sender);
        }

        if (_currentIndex == 0) {
            return;
        }

        address[] memory _addresses = topUsers;
        uint256 _tmpIndex = _currentIndex - 1;
        uint256 _currentUserAmount = usersTeamInfo[msg.sender].stakedAmount;

        if (_currentUserAmount > usersTeamInfo[_addresses[_tmpIndex]].stakedAmount) {
            while (_currentUserAmount > usersTeamInfo[_addresses[_tmpIndex]].stakedAmount) {
                address _tmpAddr = _addresses[_tmpIndex];
                _addresses[_tmpIndex] = msg.sender;
                _addresses[_tmpIndex + 1] = _tmpAddr;

                if (_tmpIndex == 0) {
                    break;
                }

                _tmpIndex--;
            }

            topUsers = _addresses;

            emit TopUsersUpdated(_tmpIndex, _addresses[_tmpIndex + 1], msg.sender);
        }

        if (_topUsersLength > MAX_TOP_USERS_SIZE) {
            topUsers.pop();
        }
    }

    function _updateGroupLeaders(address _referralLink) internal {
        uint256 _groupLeadersSize = teamInfos[_referralLink].teamLeaders.length;

        if (_groupLeadersSize == 0) {
            teamInfos[_referralLink].teamLeaders.push(msg.sender);
            return;
        }

        uint256 _currentIndex = _getIndexInTheGroupLeaders(msg.sender);

        if (_currentIndex == MAX_GROUP_LEADERS_SIZE) {
            _currentIndex = _groupLeadersSize++;
            teamInfos[_referralLink].teamLeaders.push(msg.sender);
        }

        if (_currentIndex == 0) {
            return;
        }

        address[] memory _addresses = teamInfos[_referralLink].teamLeaders;
        uint256 _tmpIndex = _currentIndex - 1;
        uint256 _currentUserAmount = usersTeamInfo[msg.sender].stakedAmount;

        if (_currentUserAmount > usersTeamInfo[_addresses[_tmpIndex]].stakedAmount) {
            while (_currentUserAmount > usersTeamInfo[_addresses[_tmpIndex]].stakedAmount) {
                address _tmpAddr = _addresses[_tmpIndex];
                _addresses[_tmpIndex] = msg.sender;
                _addresses[_tmpIndex + 1] = _tmpAddr;

                if (_tmpIndex == 0) {
                    break;
                }

                _tmpIndex--;
            }

            teamInfos[_referralLink].teamLeaders = _addresses;
        }

        if (_groupLeadersSize > MAX_GROUP_LEADERS_SIZE) {
            teamInfos[_referralLink].teamLeaders.pop();
        }
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return 0xbc197c81;
    }
}
