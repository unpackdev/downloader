// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./Ownable.sol";
import "./KumaleonGenArt.sol";

contract KumaleonGenArtManager is Ownable { 

    KumaleonGenArt public genart;
    
    constructor(address genart_) {
        genart = KumaleonGenArt(genart_);
    }

    function registerProjects(
        address payable[] memory _artistAddress,
        address payable[] memory _additionalPayee, 
        uint256[] memory _maxInvocations,
        uint256[] memory _additionalPayeePercentage,
        string[] memory _projectName,
        string[] memory _projectArtistName,
        string[] memory _newBaseURI,
        string[] memory _projectLicense,
        string[] memory _projectScriptJSON
    ) public onlyOwner { 
        for (uint256 i; i < _artistAddress.length; i++) { 
            registerProject(
                _artistAddress[i],
                _additionalPayee[i], 
                _maxInvocations[i],
                _additionalPayeePercentage[i],
                _projectName[i],
                _projectArtistName[i],
                _newBaseURI[i],
                _projectLicense[i],
                _projectScriptJSON[i]
            );
        }
    }

    function registerProject(
        address payable _artistAddress,
        address payable _additionalPayee, 
        uint256 _maxInvocations,
        uint256 _additionalPayeePercentage,
        string memory _projectName,
        string memory _projectArtistName,
        string memory _newBaseURI,
        string memory _projectLicense,
        string memory _projectScriptJSON
    ) public onlyOwner {
        uint256 projectId = genart.nextProjectId();
        genart.addProject(_projectName, _artistAddress, 0);
        genart.updateProjectArtistName(projectId, _projectArtistName);
        genart.updateProjectBaseURI(projectId, _newBaseURI);
        genart.updateProjectLicense(projectId, _projectLicense);
        genart.updateProjectMaxInvocations(projectId, _maxInvocations);
        genart.updateProjectScriptJSON(projectId, _projectScriptJSON);
        genart.updateProjectAdditionalPayeeInfo(projectId, _additionalPayee, _additionalPayeePercentage);
        genart.updateProjectSecondaryMarketRoyaltyPercentage(projectId, 10);
    }

   function updateProjectsDescription(string[] memory descriptions) public onlyOwner { 
       for (uint256 i; i < descriptions.length; i++) { 
           genart.updateProjectDescription(i, descriptions[i]);
       }
   }

    function toggleAllProjectIsLocked() public onlyOwner { 
        uint256 nextProjectId = genart.nextProjectId();
        for (uint256 i; i < nextProjectId; i++) { 
            genart.toggleProjectIsLocked(i);
        }
    }

    function toggleAllProjectIsActive() public onlyOwner { 
        uint256 nextProjectId = genart.nextProjectId();
        for (uint256 i; i < nextProjectId; i++) { 
            genart.toggleProjectIsActive(i);
        }
    }

    function toggleAllProjectIsPaused() public onlyOwner { 
        uint256 nextProjectId = genart.nextProjectId();
        for (uint256 i; i < nextProjectId; i++) { 
            genart.toggleProjectIsPaused(i);
        }
    }

}