//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./IFaction.sol";

interface IFactions {    
    function getFaction(uint256 id) external returns (IFaction);
}
