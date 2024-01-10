// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IGaugeController.sol";
interface IMinter {
    function insure_token()external view returns(address);
    function controller()external view returns(address);
    function minted(address user, address gauge) external view returns(uint256);
    function gauge_controller()external view returns(address);
}