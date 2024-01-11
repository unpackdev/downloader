// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./IERC165.sol";

interface WhitelistInterface is IERC165 {
    function addMember(address _newAccount) external;

    function removeMember(address _accountToRemove) external;

    function turnOffWhitelistMode() external;

    function setMaxMembers(uint256 _newThreshold) external;

    function isWhitelisted(address _who) external view returns (bool);
}
