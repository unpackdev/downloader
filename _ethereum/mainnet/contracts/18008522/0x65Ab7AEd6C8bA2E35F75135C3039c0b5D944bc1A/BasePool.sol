// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./SafeCast.sol";

import "./IBasePool.sol";
import "./IEthlinQStaking.sol";

import "./AbstractRewards.sol";
import "./TokenSaver.sol";

abstract contract BasePool is ERC20, AbstractRewards, IBasePool, TokenSaver {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    IERC20 public immutable depositToken;

    event RewardsClaimed(
        address indexed _from,
        address indexed _receiver,
        uint256 _rewards
    );

    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken
    ) ERC20(_name, _symbol) AbstractRewards(balanceOf, totalSupply) {
        require(
            _depositToken != address(0),
            "BasePool.constructor: Deposit token must be set"
        );
        depositToken = IERC20(_depositToken);
    }

    function _mint(
        address _account,
        uint256 _amount
    ) internal virtual override {
        super._mint(_account, _amount);
        _correctPoints(_account, -(_amount.toInt256()));
    }

    function _burn(
        address _account,
        uint256 _amount
    ) internal virtual override {
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

    function distributeRewards() external payable override {
        uint256 amount = msg.value;
        _distributeRewards(amount);
    }

    function claimRewards(address _receiver) external {
        uint256 rewardAmount = _prepareCollect(_msgSender());

        // ignore dust
        if (rewardAmount > 1) {
            (bool success, ) = payable(_receiver).call{value: rewardAmount}("");
            require(success, "Failed to send ETH to _receiver wallet");
        }

        emit RewardsClaimed(_msgSender(), _receiver, rewardAmount);
    }
}
