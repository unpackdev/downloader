// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC20Votes.sol";
import "./SafeCast.sol";

import "./IBasePool.sol";
import "./ITimeLockPool.sol";

import "./AbstractRewards.sol";
import "./TokenSaver.sol";

abstract contract BasePool is
    ERC20Votes,
    AbstractRewards,
    IBasePool,
    TokenSaver
{
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    IERC20 public immutable depositToken;
    IERC20 public immutable rewardToken;

    event RewardsClaimed(
        address indexed _from,
        address indexed _receiver,
        uint256 _escrowedAmount
    );

    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken,
        address _rewardToken
    )
        ERC20Permit(_name)
        ERC20(_name, _symbol)
        AbstractRewards(balanceOf, totalSupply)
    {
        require(
            _depositToken != address(0),
            "BasePool.constructor: Deposit token must be set"
        );
        depositToken = IERC20(_depositToken);
        rewardToken = IERC20(_rewardToken);
    }

    function _mint(address _account, uint256 _amount)
        internal
        virtual
        override
    {
        super._mint(_account, _amount);
        _correctPoints(_account, -(_amount.toInt256()));
    }

    function _burn(address _account, uint256 _amount)
        internal
        virtual
        override
    {
        super._burn(_account, _amount);
        _correctPoints(_account, _amount.toInt256());
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal virtual override {
        super._transfer(_from, _to, _value);
        _correctPointsForTransfer(_from, _to, _value);
    }

    function distributeRewards(uint256 _amount) public virtual override {
        rewardToken.safeTransferFrom(_msgSender(), address(this), _amount);
        _distributeRewards(_amount);
    }

    function claimRewards(address _receiver) external {
        uint256 rewardAmount = _prepareCollect(_msgSender());

        if (rewardAmount > 1) {
            rewardToken.safeTransfer(_receiver, rewardAmount);
        }

        emit RewardsClaimed(_msgSender(), _receiver, rewardAmount);
    }
}
