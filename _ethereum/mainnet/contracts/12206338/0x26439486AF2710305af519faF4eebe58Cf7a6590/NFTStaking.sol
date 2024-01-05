// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";

contract NFTStaking is Context, Ownable, ERC1155Holder {
    using SafeMath for uint256;

    IERC20 _rfdToken;
    IERC1155 _nftToken;

    uint256 vipTokenId = 1;

    struct STAKE {
        uint256 amount;
        uint256 _lastUpdatedAt;
    }

    mapping(address => STAKE) _stakeInfo;
    address[] _stakers;

    event Stake(address _staker, uint256 amount);
    event Unstake(address _staker, uint256 amount);
    event Withdraw(address _staker, uint256 amount);

    constructor(IERC20 _rfdAddr, IERC1155 _nftAddr) {
        _rfdToken = _rfdAddr;
        _nftToken = _nftAddr;
    }

    function totalRewards() public view returns (uint256) {
        return _rfdToken.balanceOf(address(this));
    }

    function isStakeHolder(address _account) public view returns (bool) {
        return _stakeInfo[_account].amount > 0;
    }

    function setNFTToken(IERC1155 _nftAddr) public onlyOwner {
        _nftToken = _nftAddr;
    }

    function setRFDToken(IERC20 _rfdAddr) public onlyOwner {
        _rfdToken = _rfdAddr;
    }

    function rewardOf(address _staker) public view returns (uint256) {
        STAKE memory _stakeDetail = _stakeInfo[_staker];

        uint256 _rewards = totalRewards();
        uint256 _singlePart =
            _stakeDetail.amount.mul(
                block.timestamp.sub(_stakeDetail._lastUpdatedAt)
            );

        uint256 _totalPart;

        for (uint256 i = 0; i < _stakers.length; i++) {
            STAKE memory _singleStake = _stakeInfo[_stakers[i]];

            _totalPart = _totalPart.add(
                _singleStake.amount.mul(
                    block.timestamp.sub(_singleStake._lastUpdatedAt)
                )
            );
        }

        if (_totalPart == 0) return 0;

        return _rewards.mul(_singlePart).div(_totalPart);
    }

    function stake(uint256 _amount) public {
        _nftToken.safeTransferFrom(
            _msgSender(),
            address(this),
            vipTokenId,
            _amount,
            ""
        );

        STAKE storage _stake = _stakeInfo[_msgSender()];

        if (_stake.amount > 0) {
            uint256 reward = rewardOf(_msgSender());
            _rfdToken.transfer(_msgSender(), reward);
            _stake.amount = _stake.amount.add(_amount);
            emit Withdraw(_msgSender(), reward);
        } else {
            _stake.amount = _amount;
            _stakers.push(_msgSender());
        }

        _stake._lastUpdatedAt = block.timestamp;

        emit Stake(_msgSender(), _amount);
    }

    function unstake() public {
        require(_stakeInfo[_msgSender()].amount > 0, "Not staking");

        STAKE storage _stake = _stakeInfo[_msgSender()];
        uint256 reward = rewardOf(_msgSender());
        uint256 _amount = _stake.amount;

        _rfdToken.transfer(_msgSender(), reward);
        _nftToken.safeTransferFrom(
            address(this),
            _msgSender(),
            vipTokenId,
            _stake.amount,
            ""
        );

        _stake.amount = 0;
        _stake._lastUpdatedAt = block.timestamp;

        for (uint256 i = 0; i < _stakers.length; i++) {
            if (_stakers[i] == _msgSender()) {
                _stakers[i] = _stakers[_stakers.length - 1];
                _stakers.pop();
                break;
            }
        }

        emit Unstake(_msgSender(), _amount);
    }

    function claimReward() public {
        uint256 reward = rewardOf(_msgSender());
        STAKE storage _stake = _stakeInfo[_msgSender()];

        _rfdToken.transfer(_msgSender(), reward);

        _stake._lastUpdatedAt = block.timestamp;

        emit Withdraw(_msgSender(), reward);
    }
}
