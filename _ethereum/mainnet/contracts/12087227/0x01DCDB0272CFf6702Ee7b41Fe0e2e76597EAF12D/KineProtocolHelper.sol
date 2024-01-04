// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IKineOracle.sol";

contract KineProtocolHelper{
    function totalStakingValueByKTokens(address[] memory kTokenAddresses, address oracleAddress) external view returns (uint){
        IKineOracle kineOracle = IKineOracle(oracleAddress);
        uint totalStakingValue;

        for(uint i = 0; i < kTokenAddresses.length; i++){
            IERC20 kToken = IERC20(kTokenAddresses[i]);
            uint tmpTotalSupply = kToken.totalSupply();
            uint tmpPrice = kineOracle.getUnderlyingPrice(kTokenAddresses[i]);
            uint tmpValue = tmpPrice * tmpTotalSupply;
            totalStakingValue += tmpValue;
        }
        return totalStakingValue;
    }

    function stakingValueByKToken(address kTokenAddress, address oracleAddress) external view returns (uint){
        IKineOracle kineOracle = IKineOracle(oracleAddress);
        IERC20 kToken = IERC20(kTokenAddress);
        uint tmpTotalSupply = kToken.totalSupply();
        uint tmpPrice = kineOracle.getUnderlyingPrice(kTokenAddress);
        return tmpPrice * tmpTotalSupply;
    }
}