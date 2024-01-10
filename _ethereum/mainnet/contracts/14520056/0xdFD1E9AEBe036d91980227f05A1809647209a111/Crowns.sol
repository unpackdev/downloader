pragma solidity 0.6.7;

import "./CrownsToken.sol";

/// @dev Nft Rush and Leaderboard contracts both are with Crowns.
/// So, making Crowns available for both Contracts by moving it to another contract.
///
/// @author Medet Ahmetson
contract Crowns {
    CrownsToken public crowns;

   function setCrowns(address _crowns) internal {
        require(_crowns != address(0), "Crowns can't be zero address");
       	crowns = CrownsToken(_crowns);
   }
}
