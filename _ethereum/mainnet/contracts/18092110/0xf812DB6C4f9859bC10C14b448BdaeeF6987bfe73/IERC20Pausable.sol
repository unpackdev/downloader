// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20Pausable {
    function paused() external view returns (bool);

    function unpause() external;

    function PAUSER_ROLE() external view returns (bytes32);

    function renounceRole(bytes32 role, address account) external;
}
