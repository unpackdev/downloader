// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./VaccineSelling.sol";
import "./IERC721.sol";

abstract contract VaccineApply is VaccineSelling {
    uint8[] _vaccinesStrength = [0, 25, 50, 100];
    uint8[] _vaccinesProbability = [0, 25, 50, 100];
    
    event VaccineApplied(uint256 vaccineId, uint256 porkId, uint8 vaccinationProgress);
    
    address pork1984Address;
    mapping(uint256 => uint8) _vaccinationProgress;
    uint8 constant maxVaccinationProgress = 100;
    
    constructor(address _pork1984Address) {
        pork1984Address = _pork1984Address;
    }
    
    function getMaxVaccinationProgress() public pure returns(uint8) {
        return maxVaccinationProgress;
    }
    
    function isFullyVaccinated(uint256 porkId) public view returns(bool) {
        return _vaccinationProgress[porkId] == maxVaccinationProgress;
    }
    
    function vaccinationProgress(uint256 porkId) public view returns(uint8) {
        return _vaccinationProgress[porkId];
    }
    
    function mutatePork(uint256 vaccineId, uint256 porkId) public {
        _burn(msg.sender, vaccineId, 1);
        
        IERC721 pork1984 = IERC721(pork1984Address);
        require(pork1984.ownerOf(porkId) == msg.sender);
        
        _mutatePorkWithChance(vaccineId, porkId, _vaccinesProbability[vaccineId]);
    }
    
    function _mutatePorkWithChance(uint256 vaccineId, uint256 porkId, uint8 chanceOfMutation) private {
        require(!isFullyVaccinated(porkId), "This pork has already become a mutant");
        
        uint8 randomNumber = uint8(_getRandomInteger(porkId) % 100);
        
        if (randomNumber >= chanceOfMutation) {
            _stackVaccineOnPork(porkId, vaccineId);
        } else {
            _mutatePork(porkId);
        }
        
        emit VaccineApplied(vaccineId, porkId, _vaccinationProgress[porkId]);
    }
    
    function _mutatePork(uint256 porkId) private {
        _vaccinationProgress[porkId] = maxVaccinationProgress;  // become fully vaccinated
    }
    
    function _stackVaccineOnPork(uint256 porkId, uint256 vaccineId) private {
        _vaccinationProgress[porkId] += _vaccinesStrength[vaccineId];
        if (_vaccinationProgress[porkId] > maxVaccinationProgress) {
            _vaccinationProgress[porkId] = maxVaccinationProgress;  // become fully vaccinated
        }
    }
}