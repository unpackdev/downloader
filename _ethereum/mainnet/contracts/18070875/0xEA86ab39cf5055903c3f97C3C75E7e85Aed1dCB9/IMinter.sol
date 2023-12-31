// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "./IERC165.sol";

interface IMinter is IERC165 {
    function renounceMinterRights() external;
}
