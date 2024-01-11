// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./AnonymiceLibrary.sol";
import "./IAnonymiceBreeding.sol";
import "./RedactedLibrary.sol";
import "./Interfaces.sol";

contract BreedingDescriptorProxy is Ownable {
    address public breedingDescriptorAddress;
    address public dnaChipDescriptorAddress;
    address public dnaChipAddress;
    address public breedingAddress;

    function setAddresses(
        address _breedingDescriptorAddress,
        address _dnaChipDescriptorAddress,
        address _dnaChipAddress,
        address _breedingAddress
    ) external onlyOwner {
        breedingDescriptorAddress = _breedingDescriptorAddress;
        dnaChipDescriptorAddress = _dnaChipDescriptorAddress;
        dnaChipAddress = _dnaChipAddress;
        breedingAddress = _breedingAddress;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        uint256 evolutionPodId = IDNAChip(dnaChipAddress).breedingIdToEvolutionPod(_tokenId);
        if (evolutionPodId > 0) {
            if (IAnonymiceBreeding(breedingAddress)._tokenToRevealed(_tokenId)) {
                return IDescriptor(dnaChipDescriptorAddress).tokenBreedingURI(evolutionPodId, _tokenId);
            }
            return IDescriptor(dnaChipDescriptorAddress).tokenIncubatorURI(_tokenId);
        }
        return IDescriptor(breedingDescriptorAddress).tokenURI(_tokenId);
    }
}
