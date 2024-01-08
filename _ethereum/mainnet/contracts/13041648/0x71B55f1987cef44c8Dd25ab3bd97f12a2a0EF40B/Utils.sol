// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SafeMath.sol";

library Utils {
  using SafeMath for uint256;
    function hashString(string memory domainName)
      internal
      pure
      returns (bytes32) {
      return keccak256(abi.encode(domainName));
    }
    function calculatePercentage(uint256 amount,
                                 uint256 percentagePoints,
                                 uint256 maxPercentagePoints)
      internal
      pure
      returns (uint256){  
      return amount.mul(percentagePoints).div(maxPercentagePoints);
    }

    function percentageCentsMax()
        internal
        pure
        returns (uint256){
        return 10000;
    }

    function calculatePercentageCents(uint256 amount,
                                      uint256 percentagePoints)
        internal
        pure
        returns (uint256){
        return calculatePercentage(amount, percentagePoints, percentageCentsMax());
    }
    
}
