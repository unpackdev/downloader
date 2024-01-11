//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./IERC721A.sol";

interface IGen2 is IERC721A {    
    function getLevel(uint256 id) external view returns (uint256);
    function mutateLevel(uint256 id, uint256 exp) external;
}
