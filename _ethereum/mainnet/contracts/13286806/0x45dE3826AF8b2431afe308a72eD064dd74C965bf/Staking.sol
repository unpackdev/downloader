// SPDX-License-Identifier: UNLICENSED

// Code by zipzinger and cmtzco
// DEFIBOYS
// defiboys.com

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./FxBaseRootTunnel.sol";

contract Staking is Ownable, FxBaseRootTunnel {
    IERC20 private _token;

    mapping(address => bool) public staked;
    mapping(address => uint256) public stakedAmount;

    event StakedTokens(address from);
    event UnstakedTokens(address from);
    event StakeTokenChange(IERC20 token);

    constructor(
        IERC20 token,
        address _checkpointManager,
        address _fxRoot
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        _token = token;
    }

    function setStakeToken(IERC20 token) external onlyOwner {
        _token = token;
        emit StakeTokenChange(_token);
    }

    function getStakeToken() external view returns (IERC20) {
        return _token;
    }

    function getStakedAmount(address _addr) external view returns (uint256) {
        return stakedAmount[_addr];
    }

    function stake(uint256 _amount) external {
        address from = msg.sender;
        require(
            _token.balanceOf(from) >= _amount,
            "You dont own that amount of tokens"
        );

        _token.transferFrom(from, address(this), _amount);

        if (!staked[from]) {
            staked[from] = true;
            stakedAmount[from] = _amount;
        } else {
            stakedAmount[from] = SafeMath.add(stakedAmount[from], _amount);
        }

        _sendMessageToChild(abi.encode(from, true, _amount));

        emit StakedTokens(from);
    }

    function unstake(uint256 _amount) external {
        address from = msg.sender;
        require(
            stakedAmount[from] >= _amount,
            "You dont own that amount of tokens"
        );

        stakedAmount[from] = SafeMath.sub(stakedAmount[from], _amount);
        _token.transfer(from, _amount);

        _sendMessageToChild(abi.encode(from, false, _amount));

        emit UnstakedTokens(from);
    }

    function _processMessageFromChild(bytes memory data) internal override {}

    function updateFxChildTunnel(address _fxChildTunnel) external onlyOwner {
        fxChildTunnel = _fxChildTunnel;
    }
}
