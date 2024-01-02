// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC20Votes.sol";
import "./ERC20Permit.sol";
import "./SafeCast.sol";

import "./IBasePool.sol";
import "./IAiFiStaking.sol";

import "./AbstractRewards.sol";
import "./Token.sol";

abstract contract BasePool is ERC20Votes, ERC20Permit, AbstractRewards, IBasePool, Token {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;
    address public pair;

    IERC20 public immutable token;

    event RewardsClaimed(address indexed _from, address indexed _receiver, uint256 _rewardAmount);
    event Compound(address _from, uint256 _compound);

    constructor(
        string memory _name,
        string memory _symbol,
        address _token
    ) ERC20Permit(_name) ERC20(_name, _symbol) AbstractRewards(balanceOf, totalSupply) {
        require(_token != address(0), "BasePool.constructor: Deposit token must be set");
        token = IERC20(_token);
    }

    function _update(address _from, address _to, uint256 _amount) internal override(ERC20,ERC20Votes) {
        if(_from != address(0) && _to != address(0) && pair == address(0)) {
            require(false, "NON_TRANSFERRABLE");

        } else {
            super._update(_from, _to, _amount);
            _correctPointsForTransfer(_from, _to, _amount);
        }
    }

    function nonces(address owner) public view virtual override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    function distributeAiFi(uint256 _amount) external override {
        token.safeTransferFrom(_msgSender(), address(this), _amount);
        _distributeAiFi(_amount);
    }

    function claimRewards(address _receiver) external {
        uint256 rewardAmount = _prepareCollect(_msgSender());

        // ignore dust
        if(rewardAmount > 1) {
            token.safeTransfer(_receiver, rewardAmount);
        }
        emit RewardsClaimed(_msgSender(), _receiver, rewardAmount);
    }

    function compound() external {
        uint256 currentReward = _prepareCollect(_msgSender());

        // ignore dust
        if(currentReward > 1) {
            IAiFiStaking(address(this)).depositAiFi(_msgSender(), currentReward);
        }
        emit Compound(_msgSender(), currentReward);
    }

    function setPair(address _pair) external onlyGovManager {
        require(_pair != address(0), "zero address");

        pair = _pair;
    }

}