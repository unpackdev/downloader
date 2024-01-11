// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./BoringMath.sol";
import "./VotiumInterfaces.sol";
import "./Ownable.sol";


abstract contract VotiumShare is Ownable {
    using BoringMath for uint256;
    using SafeERC20 for IERC20;
    // reward section
    struct Reward {
        uint256 rewardLeft;
        uint40 periodFinish;
        uint208 rewardRate;
        uint40 lastUpdateTime;
        uint208 rewardPerTokenStored;
    }

    // claim section
    struct ClaimParam {
        address token;
        uint256 index;
        uint256 amount;
        bytes32[]  merkleProof;
    }
    
    // earned reward section
    struct EarnedData {
        address token;
        uint256 amount;
    }

    // votium = https://etherscan.io/address/0x378ba9b73309be80bf4c2c027aad799766a7ed5a#writeContract

    IERC20[] public rewardTokens;

    mapping(IERC20 => Reward) public rewardData;

    mapping(IERC20 => uint256) public rewardIndex;

    uint256 public constant rewardsDuration = 86400 * 14;

    address public team;

    // user -> reward token -> amount
    mapping(address => mapping(IERC20 => uint256)) public userRewardPerTokenPaid;

    mapping(address => mapping(IERC20 => uint256)) public rewards;

    constructor() {
        team = msg.sender;
    }

    modifier updateReward(address _account) {
        for (uint i = 0; i < rewardTokens.length; i++) {
            IERC20 token = rewardTokens[i];
            rewardData[token].rewardPerTokenStored = _rewardPerToken(token).to208();
            rewardData[token].lastUpdateTime = _lastTimeRewardApplicable(rewardData[token].periodFinish).to40();
            if (_account != address(0)) {
                rewards[_account][token] = _earned(_account, token, _balanceOf(_account));
                userRewardPerTokenPaid[_account][token] = rewardData[token].rewardPerTokenStored;
            }
        }
        _;
    }

    function changeTeam(address _team) external onlyOwner {
        team = _team;
    }

    function syncRewards(IERC20[] memory _tokens) external {
        for(uint256 i = 0; i<_tokens.length; i++){
            IERC20 token = _tokens[i];
            require(approvedReward(token), "!approvedReward");
            uint256 increasedToken = token.balanceOf(address(this)) - rewardData[token].rewardLeft;
            _notifyReward(
                token,
                increasedToken * 8 / 10
            );

            rewardData[token].rewardLeft += increasedToken;
            token.transfer(team, increasedToken * 2 / 10);

            if(rewardIndex[token] == 0) {
                rewardTokens.push(token);
                rewardIndex[token] = rewardTokens.length;
            }
        }
    }
    
    // Address and claimable amount of all reward tokens for the given account
    function claimableAmount(address _account) external view returns(EarnedData[] memory userRewards) {
        userRewards = new EarnedData[](rewardTokens.length);
        for (uint256 i = 0; i < userRewards.length; i++) {
            IERC20 token = rewardTokens[i];
            userRewards[i].token = address(token);
            userRewards[i].amount = _earned(_account, token, _balanceOf(_account));
        }
        return userRewards;
    }


    function claim() external updateReward(msg.sender) {
        for (uint i; i < rewardTokens.length; i++) {
            IERC20 _rewardsToken = IERC20(rewardTokens[i]);
            uint256 reward = rewards[msg.sender][_rewardsToken];
            if (reward > 0) {
                rewards[msg.sender][_rewardsToken] = 0;
                rewardData[_rewardsToken].rewardLeft -= reward;
                _rewardsToken.safeTransfer(msg.sender, reward);
            }
        }
    }

    // --- internal functions ---

    function _notifyReward(IERC20 _rewardsToken, uint256 _reward) internal {
        Reward storage rdata = rewardData[_rewardsToken];

        if (block.timestamp >= rdata.periodFinish) {
            rdata.rewardRate = _reward.div(rewardsDuration).to208();
        } else {
            uint256 remaining = uint256(rdata.periodFinish).sub(block.timestamp);
            uint256 leftover = remaining.mul(rdata.rewardRate);
            rdata.rewardRate = _reward.add(leftover).div(rewardsDuration).to208();
        }

        rdata.lastUpdateTime = block.timestamp.to40();
        rdata.periodFinish = block.timestamp.add(rewardsDuration).to40();
    }

    function _rewardPerToken(IERC20 _rewardsToken) internal view returns(uint256) {
        if (_supply() == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        return
        uint256(rewardData[_rewardsToken].rewardPerTokenStored).add(
            _lastTimeRewardApplicable(rewardData[_rewardsToken].periodFinish).sub(
                rewardData[_rewardsToken].lastUpdateTime).mul(
                rewardData[_rewardsToken].rewardRate).mul(1e18).div(_supply())
        );

    }

    function _lastTimeRewardApplicable(uint256 _finishTime) internal view returns(uint256) {
        return Math.min(block.timestamp, _finishTime);
    }

    function _earned(
        address _user,
        IERC20 _rewardsToken,
        uint256 _balance
    ) internal view returns(uint256) {
        return _balance.mul(
            _rewardPerToken(_rewardsToken).sub(userRewardPerTokenPaid[_user][_rewardsToken])
        ).div(1e18).add(rewards[_user][_rewardsToken]);
    }

    // --- virtual internal functions ---
    function _balanceOf(address _user) internal view virtual returns(uint256);

    function _supply() internal view virtual returns(uint256);

    function approvedReward(IERC20 _token) public view virtual returns(bool);
}
