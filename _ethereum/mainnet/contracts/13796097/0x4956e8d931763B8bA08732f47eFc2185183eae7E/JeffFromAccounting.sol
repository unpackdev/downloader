// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Context.sol";

contract JeffFromAccounting is Context {
    mapping(address => Project) internal projects;
    mapping(address => uint256) public balanceOf;

    struct Project {
        address[] team;
        uint256[] splits;
    }

    function getProjectTeam(address _projectAddress) public view returns (address[] memory _team) {
        return projects[_projectAddress].team;
    }
    
    function getProjectSplits(address _projectAddress) public view returns (uint256[] memory _team) {
        return projects[_projectAddress].splits;
    }
    
    function newProject(address _contract, address[] calldata _team, uint[] calldata _splits) external {
        projects[_contract] = Project(_team, _splits);
    }

    function withdrawBalance(uint256 _amount) external {
        require(
            balanceOf[_msgSender()] >= _amount,
            "This value is more than available to withdraw."
        );

        balanceOf[_msgSender()] -= _amount;
        (bool success, ) = payable(_msgSender()).call{value: _amount}("");
        require(success, "Withdraw failed.");
    }

    function tallySplits(Project memory _project) internal {
        uint256 each;
         for (uint256 i; i < _project.splits.length; i++) {
             each = (((msg.value * _project.splits[i]) / 100));
             balanceOf[_project.team[i]] += each;
         }
    }

    receive() external payable {
        Project memory _project = projects[_msgSender()];
        require(_project.splits.length != 0, "Project must exist.");
        tallySplits(_project);
    }
}