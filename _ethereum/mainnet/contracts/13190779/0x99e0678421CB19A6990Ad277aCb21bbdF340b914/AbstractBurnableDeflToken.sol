// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./AbstractDeflationaryToken.sol";

abstract contract AbstractBurnableDeflToken is AbstractDeflationaryToken {
    uint256 public totalBurned;

    function burn(uint256 amount) external {
        require(balanceOf(_msgSender()) >= amount, 'Not enough tokens');
        totalBurned += amount;

        if(_isExcludedFromReward[_msgSender()] == 1) {
            _tOwned[_msgSender()] -= amount;
        }
        else {
            uint256 rate = _getRate();
            _rOwned[_msgSender()] -= amount * rate;
            _tIncludedInReward -= amount;
            _rIncludedInReward -= amount * rate;
        }
    }
}