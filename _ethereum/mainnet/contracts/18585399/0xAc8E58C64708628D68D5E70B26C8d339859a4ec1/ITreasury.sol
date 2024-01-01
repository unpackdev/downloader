// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.18;

interface TreasuryContract {
    function isAdmin(address account) external view returns (bool);

    function isEntrepreneur(address account) external view returns (bool);

    function isVolunteerAdmin(address _account) external view returns (bool);
}
