// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
import "./CommonImports.sol";
interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
    function getLiqAddBudget(uint256 amount) external view returns (uint256);
    function getCallerCut(uint256 amount) external view returns (uint256);
}