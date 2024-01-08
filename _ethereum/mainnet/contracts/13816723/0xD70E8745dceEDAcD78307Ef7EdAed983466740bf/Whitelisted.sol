//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

/// @dev Interface describing the required method for a whitelistable project
interface IWhitelistable {

    /// @dev Returns the number of tokens in the owner's account.
    function balanceOf(address owner) external view returns (uint256 balance);
}

/// @title Contract for Whitelisting 100% on-chain projects
/// @dev Since this contract is public, other projects may wish to rely on this list
contract Whitelisted is Ownable {

    /// Holds the list of IWhitelistable (e.g. ERC-721) projects in which ownership affords whitelisting
    IWhitelistable[] private _approvedProjects;

    /// Deploys a new Whitelisted contract with approved projects
    /// @param projects The list of contracts to add to the approved list
    constructor(address[] memory projects) {
        for (uint256 index = 0; index < projects.length; index++) {
            _approvedProjects.push(IWhitelistable(projects[index]));
        }
    }

    /// Adds additional projects to the approved list
    /// @dev Providing valid contract address that implement `balanceOf()` is the responsibility of the caller
    /// @param projects The list of contracts to add to the approved list
    function addApprovedProjects(address[] calldata projects) external onlyOwner {
        for (uint256 index = 0; index < projects.length; index++) {
            _approvedProjects.push(IWhitelistable(projects[index]));
        }
    }

    /// Returns the approved projects whitelisted by this contract
    function getApprovedProjects() external view returns (IWhitelistable[] memory) {
        return _approvedProjects;
    }

    /// Removes an approved project whitelisted by this contract
    /// @param project The address to remove from the list
    function removeApprovedProject(address project) external onlyOwner {
        uint256 length = _approvedProjects.length;
        for (uint256 index = 0; index < length; index++) {
            if (address(_approvedProjects[index]) == project) {
                if (index < length-1) {
                    _approvedProjects[index] = _approvedProjects[length-1];
                }
                _approvedProjects.pop();
                return;
            }
        }
    }

    /// Returns whether the owning address is eligible for whitelisting due to ownership in one of the approved projects
    /// @param owner The owning address to check
    /// @return True if the address at owner owns a token in one of the approved projects
    function isWhitelisted(address owner) external view returns (bool) {
        uint256 projects = _approvedProjects.length;
        for (uint256 index = 0; index < projects; index++) {
            IWhitelistable project = _approvedProjects[index];
            if (project.balanceOf(owner) > 0) {
                return true;
            }
        }
        return false;
    }
}
