// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";

interface IStrategy {
    
    // function unsalvagableTokens(address tokens) external view returns (bool);
    
    // function governance() external view returns (address);
    // function controller() external view returns (address);
    function getUnderlying() external view returns (address);
    function getBundle() external view returns (address);

    function withdrawAllToBundle() external;
    function withdrawToBundle(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;
    function depositArbCheck() external view returns(bool);
}
