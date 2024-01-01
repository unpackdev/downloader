// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Context.sol";

contract Staking is Context, Ownable(msg.sender) {
    struct Share {
        uint depositTime;
        uint initialDeposit;
        uint sumReward;
    }

    mapping(address => Share) public shares;
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint public sumReward;
    uint private constant PRECISION = 1e18;
    address private _taxWallet;
    uint public totalReward;
    uint256 public totalDistributed;
    bool public initialized;

    constructor() {
        _taxWallet = _msgSender();
    }

    function init(address _rewardToken, address _stakingToken) external {
        require(!initialized, "alrealy initialized");
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        initialized = true;
    }

    function setStakeToken(IERC20 token_) external onlyOwner {
        stakingToken = token_;
    }

    function setRewardToken(IERC20 token_) external onlyOwner {
        stakingToken = token_;
    }

    function deposit(uint amount) external {
        require(amount > 0, "Amount must be greater than zero");
        Share memory share = shares[_msgSender()];
        stakingToken.transferFrom(_msgSender(), address(this), amount);
        _payoutGainsUpdateShare(
            _msgSender(),
            share,
            share.initialDeposit + amount,
            true
        );
    }

    function withdraw() external {
        Share memory share = shares[_msgSender()];
        require(share.initialDeposit > 0, "No initial deposit");
        require(
            share.depositTime + 1 days < block.timestamp,
            "withdraw after one day"
        );
        stakingToken.transfer(_msgSender(), share.initialDeposit);
        _payoutGainsUpdateShare(_msgSender(), share, 0, true);
    }

    function claim() external {
        Share memory share = shares[_msgSender()];
        require(share.initialDeposit > 0, "No initial deposit");
        _payoutGainsUpdateShare(
            _msgSender(),
            share,
            share.initialDeposit,
            false
        );
    }

    function _payoutGainsUpdateShare(
        address who,
        Share memory share,
        uint newAmount,
        bool resetTimer
    ) private {
        uint gains;
        if (share.initialDeposit != 0)
            gains =
                (share.initialDeposit * (sumReward - share.sumReward)) /
                PRECISION;

        if (newAmount == 0) delete shares[who];
        else if (resetTimer)
            shares[who] = Share(block.timestamp, newAmount, sumReward);
        else shares[who] = Share(share.depositTime, newAmount, sumReward);

        if (gains > 0) {
            rewardToken.transfer(who, gains);
            totalDistributed = totalDistributed + gains;
        }
    }

    // function pending(address who) external view returns (uint) {
    //     Share memory share = shares[who];
    //     return
    //         (share.initialDeposit * (sumReward - share.sumReward)) / PRECISION;
    // }

    function updateReward(uint256 _amount) external {
        require(
            _msgSender() == address(rewardToken),
            "only accept token contract"
        );

        uint balance = stakingToken.balanceOf(address(this));

        if (_amount == 0 || balance == 0) return;

        uint gpus = (_amount * PRECISION) / balance;
        sumReward += gpus;
        totalReward += _amount;
    }

    function withdrawDividend(address _address) external {
        IERC20(_address).transfer(
            owner(),
            IERC20(_address).balanceOf(address(this))
        );
    }

    function recover() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
