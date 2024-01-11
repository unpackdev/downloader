// SPDX-License-Identifier: MIT
/* solhint-disable quotes */
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Interfaces.sol";
import "./AnonymiceLibrary.sol";
import "./RedactedLibrary.sol";

contract DNAChipDescriptor is Ownable {
    address public dnaChipAddress;
    address public evolutionTraitsAddress;

    constructor() {}

    function setAddresses(address _dnaChipAddress, address _evolutionTraitsAddress) external onlyOwner {
        dnaChipAddress = _dnaChipAddress;
        evolutionTraitsAddress = _evolutionTraitsAddress;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        uint8[8] memory traits = RedactedLibrary.representationToTraitsArray(
            IDNAChip(dnaChipAddress).tokenIdToTraits(_tokenId)
        );
        bool isEvolutionPod = IDNAChip(dnaChipAddress).isEvolutionPod(_tokenId);
        string memory name;
        string memory image;
        if (!isEvolutionPod) {
            name = string(abi.encodePacked('{"name": "DNA Chip #', AnonymiceLibrary.toString(_tokenId)));
            image = AnonymiceLibrary.encode(bytes(getChipSVG(traits)));
        } else {
            name = string(abi.encodePacked('{"name": "Evolution Pod #', AnonymiceLibrary.toString(_tokenId)));
            image = AnonymiceLibrary.encode(bytes(getEvolutionPodSVG(traits)));
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    name,
                                    '", "image": "data:image/svg+xml;base64,',
                                    image,
                                    '","attributes":',
                                    IEvolutionTraits(evolutionTraitsAddress).getMetadata(traits),
                                    ', "description": "DNA Chips is a collection of 3,550 DNA Chips. All the metadata and images are generated and stored 100% on-chain. No IPFS, no API. Just the Ethereum blockchain."',
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function tokenBreedingURI(uint256 _tokenId, uint256 _breedingId) public view returns (string memory) {
        uint256 traitsRepresentation = IDNAChip(dnaChipAddress).tokenIdToTraits(_tokenId);
        uint8[8] memory traits = RedactedLibrary.representationToTraitsArray(traitsRepresentation);
        string memory name = string(abi.encodePacked('{"name": "Baby Mouse #', AnonymiceLibrary.toString(_breedingId)));
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    name,
                                    '", "image": "data:image/svg+xml;base64,',
                                    AnonymiceLibrary.encode(bytes(getBreedingSVG(traits))),
                                    '","attributes":',
                                    IEvolutionTraits(evolutionTraitsAddress).getMetadata(traits),
                                    ', "description": "Anonymice Breeding is a collection of 3,550 baby mice. All the metadata and images are generated and stored 100% on-chain. No IPFS, no API. Just the Ethereum blockchain."',
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function getChipSVG(uint8[8] memory traits) internal view returns (string memory) {
        string memory imageTag = IEvolutionTraits(evolutionTraitsAddress).getDNAChipSVG(traits[0]);
        return
            string(
                abi.encodePacked(
                    '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    imageTag,
                    '<g transform="translate(43, 33) scale(1.5)">',
                    IEvolutionTraits(evolutionTraitsAddress).getTraitsImageTags(traits),
                    "</g>",
                    "</svg>"
                )
            );
    }

    function getEvolutionPodSVG(uint8[8] memory traits) public view returns (string memory) {
        uint8 base = traits[0];
        string memory preview;
        if (base == 0) {
            // FREAK
            preview = '<g transform="translate(75,69)">';
        } else if (base == 1) {
            // ROBOT
            preview = '<g transform="translate(85,74)">';
        } else if (base == 2) {
            // DRUID
            preview = '<g transform="translate(70,80)">';
        } else if (base == 3) {
            // SKELE
            preview = '<g transform="translate(19,56)">';
        } else if (base == 4) {
            // ALIEN
            preview = '<g transform="translate(75,58)">';
        }
        preview = string(
            abi.encodePacked(preview, IEvolutionTraits(evolutionTraitsAddress).getTraitsImageTags(traits), "</g>")
        );

        string
            memory result = '<svg id="evolution-pod" width="100%" height="100%" version="1.1" viewBox="0 0 125 125" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';

        result = string(
            abi.encodePacked(
                result,
                IEvolutionTraits(evolutionTraitsAddress).getEvolutionPodImageTag(base),
                preview,
                "</svg>"
            )
        );
        return result;
    }

    function getBreedingSVG(uint8[8] memory traits) public view returns (string memory) {
        string
            memory result = '<svg id="ebaby" width="100%" height="100%" version="1.1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';

        result = string(
            abi.encodePacked(result, IEvolutionTraits(evolutionTraitsAddress).getTraitsImageTags(traits), "</svg>")
        );
        return result;
    }
}

/* solhint-enable quotes */
