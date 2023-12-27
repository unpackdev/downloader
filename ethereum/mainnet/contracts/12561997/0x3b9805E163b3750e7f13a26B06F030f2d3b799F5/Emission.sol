// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0;

import "./Math.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeCast.sol";
import "./IEmission.sol";

contract Emission is IEmission, Ownable, ReentrancyGuard {
    using SafeCast for uint;
    using SafeERC20 for IERC20;

    address public token;
    address public stakingToken;

    uint constant INITIAL_QUANTITY = 10000;
    
    uint public override distributedPerBlock;
    uint public lastWithdrawalBlock;

    constructor(address _token, address _stakingToken, uint _distributedPerBlock) {
        require(_token != address(0), "Emission: ZERO");
        token = _token;
        stakingToken = _stakingToken;
        distributedPerBlock = _distributedPerBlock;
        lastWithdrawalBlock = block.number;
    }

    function setDistribution(uint _distributedPerBlock) external override onlyOwner {
        _withdraw();
        distributedPerBlock = _distributedPerBlock;
    }

    function withdraw() external override nonReentrant {
        _withdraw();
    }

    function withdrawable() external view override returns (uint) {
        uint balance = IERC20(token).balanceOf(address(this));
        if (balance == 0 || IERC20(stakingToken).totalSupply() <= INITIAL_QUANTITY) {
            return 0;
        }
        uint blocksPassed = block.number - lastWithdrawalBlock;
        return Math.min(balance, blocksPassed * distributedPerBlock);
    }

    function _withdraw() private {
        uint balance = IERC20(token).balanceOf(address(this));
        if (balance == 0 || IERC20(stakingToken).totalSupply() <= INITIAL_QUANTITY) {
            lastWithdrawalBlock = block.number; // increment last withdrawal time when there is no funds to reduce time delta
            return;
        }
        uint blocksPassed = block.number - lastWithdrawalBlock;
        if (blocksPassed == 0) {
            return;
        }
        uint amount = Math.min(balance, blocksPassed * distributedPerBlock);
        lastWithdrawalBlock = block.number;
        IERC20(token).safeTransfer(stakingToken, amount);
    }
}