// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./LogosTypes.sol";

interface ILogosTraits {
    function charactersByID(uint8) external view returns (L.CharacterInfo memory);
    function shapesPrimaryByID(uint8) external view returns (L.ShapeInfo memory);
    function shapesSecondaryByID(uint8) external view returns (L.ShapeInfo memory);
    function colorPalettesByID(uint16) external view returns (L.ColorPalette memory);
}

interface ERC721 {
    function ownerOf(uint256) external view returns (address);
}

contract LogosCrafter is Ownable {
    bool public locked;
    bool public paused;
    ERC721 public logosContract;
    ILogosTraits public traitsContract;

    struct Hash {
        bool taken;
        uint16 tokenID;
    }

    mapping (uint256 => L.Logo) public _logosByTokenID;
    mapping (bytes32 => Hash) public _characterHashes;
    mapping (bytes32 => Hash) public _shapeHashes;

    event TokenUpdated(uint256 tokenID, L.Logo logo, bool isFirstUpdate);

    constructor(address logosContractAddress, address traitsContactAddress) Ownable() {
        logosContract = ERC721(logosContractAddress);
        traitsContract = ILogosTraits(traitsContactAddress);
    }

    function lock(string memory ack) external onlyOwner {
        require(keccak256(abi.encodePacked(ack)) == keccak256(abi.encodePacked("This action is permanent")), "Incorrect ack");
        locked = true;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function logosByTokenID(uint256 tokenID) external view returns (L.Logo memory) {
        L.Logo memory logo = _logosByTokenID[tokenID];

        check(tokenID, logo);
    
        return _logosByTokenID[tokenID];
    }

    function update(uint256 tokenID, L.Logo memory logo) public {
        _update(tokenID, logo, false);
    }

    function updateAndSkipChecks(uint256 tokenID, L.Logo memory logo) public {
        _update(tokenID, logo, true);
    }

    function check(uint256 tokenID, L.Logo memory logo) public view {
        L.CharacterInfo memory character = traitsContract.charactersByID(logo.characterSelections.characterID);
        L.ShapeInfo memory primaryShape = traitsContract.shapesPrimaryByID(logo.shapeSelections.primaryShape);
        L.ShapeInfo memory secondaryShape = traitsContract.shapesSecondaryByID(logo.shapeSelections.secondaryShape);
        L.ColorPalette memory colorPalette = traitsContract.colorPalettesByID(logo.colorPalette);

        require(character.enabled, "Character not enabled");
        require(primaryShape.enabled, "Primary shape not enabled");
        require(primaryShape.numVariants >= logo.shapeSelections.primaryShapeVariant, "Primary shape variant out of range");
        require(secondaryShape.enabled, "Secondary shape not enabled");
        require(secondaryShape.numVariants >= logo.shapeSelections.secondaryShapeVariant, "Secondary shape variant out of range");
        require(colorPalette.enabled, "Color palette not enabled");
        require(logo.characterSelections.slotSelections.length == character.slotOffsets.length, "Wrong number of slot selections");

        // check that no bonus traits were selected if not a Blitmap base
        if (tokenID >= 1700) {
            require(!character.bodies[logo.characterSelections.body].isBonus, "Bonus body selected");
            require(!character.heads[logo.characterSelections.head].isBonus, "Bonus head selected");
            require(!colorPalette.isBonus, "Bonus color palette selected");
        }

        uint256 slotSelectionLength = logo.characterSelections.slotSelections.length;
        for (uint8 i = 0; i < slotSelectionLength; i++) {
            // check that slot selection is in range
            uint256 lengthOfSlot;

            if (i < slotSelectionLength - 1) {
                lengthOfSlot = character.slotOffsets[i + 1] - character.slotOffsets[i];
            } else {
                lengthOfSlot = character.slotOptions.length - character.slotOffsets[i];
            }

            if (logo.characterSelections.slotSelections[i] >= lengthOfSlot) {
                revert("Slot selection out of range");
            }

            uint8 offset = character.slotOffsets[i] + logo.characterSelections.slotSelections[i];

            // Check that the selected trait is not empty
            require(bytes(character.slotOptions[offset].name).length > 0, "Empty trait selected");

            // check that no bonus traits were selected if not a Blitmap base
            if (tokenID >= 1700) {
                require(!character.slotOptions[offset].isBonus, "Bonus trait selected");
            }
        }
    }

    function _update(uint256 tokenID, L.Logo memory logo, bool skipExternalChecks) internal {
        require(!locked, "Locked");
        require(!paused, "Paused");
        require(logosContract.ownerOf(tokenID) == msg.sender, "Not owner of Logo");

        // external checks can be skipped to optimize gas usage, but validity checks (except for collisions) are lost
        if (!skipExternalChecks) {
            check(tokenID, logo);
        }

        bytes32 characterHash = keccak256(
            abi.encode(
                logo.characterSelections.characterID,
                logo.characterSelections.slotSelections
            )
        );

        bytes32 shapeHash = keccak256(
            abi.encode(
                logo.shapeSelections.primaryShape,
                logo.shapeSelections.primaryShapeVariant,
                logo.shapeSelections.secondaryShape,
                logo.shapeSelections.secondaryShapeVariant
            )
        );

        // character/shape hash must be unused or already owned by this token
        require(!_characterHashes[characterHash].taken || _characterHashes[characterHash].tokenID == tokenID, "Character combination already used");
        require(!_shapeHashes[shapeHash].taken || _shapeHashes[shapeHash].tokenID == tokenID, "Shape combination already used");

        // delete old hash if logo was enabled once already
        if (_logosByTokenID[tokenID].enabled) {
            bytes32 oldCharacterHash = keccak256(
                abi.encode(
                    _logosByTokenID[tokenID].characterSelections.characterID,
                    _logosByTokenID[tokenID].characterSelections.slotSelections
                )
            );

            bytes32 oldShapeHash = keccak256(
                abi.encode(
                    _logosByTokenID[tokenID].shapeSelections.primaryShape,
                    _logosByTokenID[tokenID].shapeSelections.primaryShapeVariant,
                    _logosByTokenID[tokenID].shapeSelections.secondaryShape,
                    _logosByTokenID[tokenID].shapeSelections.secondaryShapeVariant
                )
            );

            delete _characterHashes[oldCharacterHash];
            delete _shapeHashes[oldShapeHash];
        }

        _characterHashes[characterHash].taken = true;
        _characterHashes[characterHash].tokenID = uint16(tokenID);
        _shapeHashes[shapeHash].taken = true;
        _shapeHashes[shapeHash].tokenID = uint16(tokenID);

        logo.enabled = true;

        bool isFirstUpdate = !_logosByTokenID[tokenID].enabled;
        
        _logosByTokenID[tokenID] = logo;

        emit TokenUpdated(tokenID, logo, isFirstUpdate);
    }
}