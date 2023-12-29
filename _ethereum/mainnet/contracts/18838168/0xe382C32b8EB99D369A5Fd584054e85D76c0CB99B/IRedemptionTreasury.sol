// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

interface IRedemptionTreasury {    
      /// @notice send redemption amount to user
    function transferRedemption(uint256 rnftid, address _token, address _to, uint256 _amount) external;
}
