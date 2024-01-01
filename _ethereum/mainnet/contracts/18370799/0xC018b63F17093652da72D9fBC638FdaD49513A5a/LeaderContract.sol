// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Context.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./ILeaderContract.sol";

contract LeaderContract is ILeaderContract, Ownable {
    struct Share {
        uint256 initialDeposit;
        uint256 rewardIndex;
    }
    mapping(address => Share) public shares;
    mapping(address => uint256) public userClaimed;
    mapping(address => bool) public isLeader;
    IERC20 public rewardToken;
    uint256 public rewardIndex;
    uint256 private constant PRECISION = 1e10;
    uint256 public numberOfLeader;
    uint256 public totalReward;
    uint256 public totalClaimed;
    bool public initialized;

    function init(address _rewardToken) external {
        require(!initialized, "Alrealy initialized");
        rewardToken = IERC20(_rewardToken);
        initialized = true;
    }

    function setRewardToken(IERC20 token_) external onlyOwner {
        rewardToken = token_;
    }

    function addLeader(address[] memory _leaders) external onlyOwner {
        for (uint256 i; i < _leaders.length; i++) {
            if (!isLeader[_leaders[i]]) {
                isLeader[_leaders[i]] = true;
                Share memory share = shares[_leaders[i]];
                _payoutGainsUpdateShare(_leaders[i], share, 1);
                numberOfLeader++;
            }
        }
    }

    function removeLeader(address[] memory _leaders) public onlyOwner {
        for (uint256 i; i < _leaders.length; i++) {
            if (isLeader[_leaders[i]]) {
                isLeader[_leaders[i]] = false;
                Share memory share = shares[_leaders[i]];
                _payoutGainsUpdateShare(_msgSender(), share, 0);
                numberOfLeader--;
            }
        }
    }

    function claim() external {
        Share memory share = shares[_msgSender()];
        require(share.initialDeposit > 0, "Not leader");
        _payoutGainsUpdateShare(_msgSender(), share, share.initialDeposit);
    }

    function _payoutGainsUpdateShare(
        address who,
        Share memory share,
        uint newAmount
    ) private {
        uint gains;
        if (share.initialDeposit != 0)
            gains =
                (share.initialDeposit * (rewardIndex - share.rewardIndex)) /
                PRECISION;

        if (newAmount == 0) delete shares[who];
        else shares[who] = Share(newAmount, rewardIndex);

        if (gains > 0) {
            rewardToken.transfer(who, gains);
            totalClaimed = totalClaimed + gains;
            userClaimed[who] = userClaimed[who] + gains;
        }
    }

    function pending(address who) external view returns (uint) {
        Share memory share = shares[who];
        return
            (share.initialDeposit * (rewardIndex - share.rewardIndex)) /
            PRECISION;
    }

    function updateReward(uint256 _amount) external {
        require(
            _msgSender() == address(rewardToken),
            "Only accept token contract"
        );

        uint totalUser = numberOfLeader;

        if (_amount == 0 || totalUser == 0) return;

        uint gpus = (_amount * PRECISION) / totalUser;
        rewardIndex += gpus;
        totalReward += _amount;
    }
}
