// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ICorporation {
    struct Corporation {
        uint256 id;
        address owner;
        string name;
        string description;
        string image;
        string animation;
        bool active;
    }

    event CorporationCreated(Corporation);
    event CorporationDisbanded(Corporation);
    event MemberAdded(address);
    event MemberRemoved(address);

    /// @notice Function used to create a Corporation
    /// @dev Should be callable by anyone not part of a corporation
    function createCorporation(Corporation calldata corporation) external;

    function disbandCorporation(Corporation calldata corporation) external;

    function addOrRemoveMember(
        uint256 _corporationId,
        address _member
    ) external;
}
