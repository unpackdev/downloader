// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICryptoFoxesOrigins.sol";
import "./ICryptoFoxesCalculationOrigin.sol";
import "./CryptoFoxesUtility.sol";
import "./SafeMath.sol";

// @author: miinded.com

contract CryptoFoxesCalculationOrigin is ICryptoFoxesCalculationOrigin, CryptoFoxesUtility{
    using SafeMath for uint256;
    uint256 public constant baseRateOrigins = 6 * 10**18;

    function calculationRewards(address _contract, uint256[] memory _tokenIds, uint256 _currentTimestamp) public override view returns(uint256){
        uint256 _currentTime = ICryptoFoxesOrigins(_contract)._currentTime(_currentTimestamp);
        uint256 totalSeconds = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            totalSeconds = totalSeconds.add( _currentTime.sub(ICryptoFoxesOrigins(_contract).getStackingToken(_tokenIds [i])));
        }

        return baseRateOrigins.mul(totalSeconds).div(86400);
    }
    function claimRewards(address _contract, uint256[] memory _tokenIds, address _owner) public override isFoxContract {
        require(!isPaused(), "Contract paused");

        uint256 reward = calculationRewards(_contract, _tokenIds, block.timestamp);
        _addRewards(_owner, reward);
        _withdrawRewards(_owner);
    }
}
