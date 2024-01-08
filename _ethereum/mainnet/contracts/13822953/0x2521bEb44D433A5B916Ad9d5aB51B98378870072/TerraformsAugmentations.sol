// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract TerraformsAugmentations is Ownable {
    struct Augmentation {
        string name;
        AugmentationVersion[] versions;
    }

    struct AugmentationVersion {
        uint versionNumber;
        address contractAddress;
        string contractABI;
    }

    uint public numberOfAugmentations;
    mapping(uint => Augmentation) augmentations;

    /// @notice Adds an augmentation for the Terraforms contract
    /// @param name The name of the augmentation
    function addAugmentation(string memory name) public onlyOwner {
        numberOfAugmentations += 1;
        Augmentation storage a = augmentations[numberOfAugmentations];
        a.name = name;
    }

    /// @notice Adds an augmentation for the Terraforms contract
    /// @dev If ABI is unchanged from last version, no new ABI will be uploaded
    /// @param augmentationId The id number of the augmentation
    /// @param contractAddress The address of the augmentation contract
    /// @param contractABI The augmentation contract's ABI
    function addAugmentationVersion(
        uint augmentationId, 
        address contractAddress, 
        string memory contractABI
    )
        public
        onlyOwner
    {
        require(augmentationId > 0, "Numbering begins at 1");
        require(
            augmentationId <= numberOfAugmentations, 
            "Augmentation does not exist"
        );
        Augmentation storage a = augmentations[augmentationId];
        a.versions.push(
            AugmentationVersion(
                a.versions.length + 1,
                contractAddress,
                contractABI
            )
        );
    }

    /// @notice Lists all augmentations
    /// @return result The list of augmentations
    function listAugmentations() 
        public 
        view 
        returns (Augmentation[] memory result) 
    {
        result = new Augmentation[](numberOfAugmentations);
        for (uint i; i < numberOfAugmentations; i++){
            result[i] = augmentations[i + 1];
        }
    }

    /// @notice Gets an augmentation version
    /// @param augmentationId The id number of the augmentation
    /// @param version The desired version number 
    /// @return result The requested version
    function getAugmentationVersion(uint augmentationId, uint version) 
        public 
        view
        returns (AugmentationVersion memory)
    {
        require(augmentationId > 0 && version > 0, "Numbering begins at 1");
        require(
            augmentationId <= numberOfAugmentations, 
            "Augmentation does not exist"
        );

        require(
            version <= augmentations[augmentationId].versions.length,
            "Version does not exist"
        );

        return augmentations[augmentationId].versions[version - 1];
    }
}