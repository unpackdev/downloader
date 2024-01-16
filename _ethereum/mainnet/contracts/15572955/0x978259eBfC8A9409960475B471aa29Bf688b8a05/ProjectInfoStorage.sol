// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./AccessControlEnumerable.sol";
import "./ProjectInfo.sol";

contract ProjectInfoStorage is AccessControlEnumerable {
    bytes32 public constant ADD_ROLE = keccak256("ADD_ROLE");

    event AddProject(bytes32 indexed index);

    mapping(bytes32 => ProjectInfo) projects;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(ADD_ROLE, _msgSender());
    }

    function addProject(bytes32 index, ProjectInfo memory projectInfo)
        external
    {
        require(
            hasRole(ADD_ROLE, _msgSender()),
            "must have add role to add project"
        );
        projects[index] = projectInfo;

        emit AddProject(index);
    }

    function getProjectInfo(bytes32 index)
        external
        view
        returns (ProjectInfo memory)
    {
        return projects[index];
    }
}
