// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ITerraformsData.sol";
import "./ITerraforms.sol";
import "./ITerraformsHelpers.sol";
import "./ITerraformsTokenURI.sol";
import "./ITerraformsData_v0.sol";
import "./IPerlinNoise.sol";

/// @author xaltgeist, with code direction and consultation from 113
/// @title Token data for the Terraforms contract, version 2.0
/// @dev Terraforms data is generated on-demand; Terraforms are not stored
contract TerraformsData_v2_0 is
    ITerraformsData,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    string public version;

    // Interfaces
    ITerraforms terraforms;
    ITerraformsHelpers helpers;
    ITerraformsTokenURI TFTokenURI;
    IPerlinNoise perlinNoise;
    ITerraformsData_v0 dataV0;

    // Visualization info
    uint256 public MAX_SUPPLY;
    uint256 public TOKEN_DIMS;
    uint256 public SEED;
    int256 public STEP;
    int256[8] public topography;
    uint256[20] public levelDimensions;
    bool public isLocked;

    modifier notLocked() {
        require(isLocked == false, "Terraforms Data: Contract is locked");
        _;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * INITIALIZER
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _helpersAddress,
        address _tokenURIAddress
    ) public initializer {
        __Ownable_init();
        version = "Version 2.0";
        terraforms = ITerraforms(0x4E1f41613c9084FdB9E34E11fAE9412427480e56);
        perlinNoise = IPerlinNoise(0x53B811757fC725aB3556Bc00237D9bBcF2c0DfDE); // Generates terrain
        helpers = ITerraformsHelpers(_helpersAddress);
        TFTokenURI = ITerraformsTokenURI(_tokenURIAddress);
        dataV0 = ITerraformsData_v0(0xA5aFC9fE76a28fB12C60954Ed6e2e5f8ceF64Ff2); // Prior implementation of TerraformsData.sol
        MAX_SUPPLY = 11104;
        TOKEN_DIMS = 32;
        SEED = 10196;
        STEP = 6619;
        topography = [
            int256(18000),
            int256(12000),
            int256(4000),
            -4000,
            -12000,
            -20000,
            -22000,
            -26000
        ];
        levelDimensions = [
            4,
            8,
            8,
            16,
            16,
            24,
            24,
            24,
            16,
            32,
            32,
            16,
            48,
            48,
            24,
            24,
            16,
            8,
            8,
            4
        ];
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner notLocked {}

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * PUBLIC: TOKEN DATA
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice Returns a token's tokenURI
    /// @param tokenId The token ID
    /// @param status The token's status
    /// @param placement Placement of token on level/tile before rotation
    /// @param seed Seed used to rotate initial token placement
    /// @param decay Amount of decay affecting the superstructure
    /// @param canvas The canvas data of a (dreaming) token
    /// @return result A base64 encoded JSON string
    function tokenURI(
        uint256 tokenId,
        uint256 status,
        uint256 placement,
        uint256 seed,
        uint256 decay,
        uint256[] memory canvas
    ) public view returns (string memory result) {
        decay = helpers.structureDecay(block.timestamp); // Overwrite decay data
        return
            TFTokenURI.tokenURI(
                tokenId,
                status,
                placement,
                seed,
                decay,
                canvas
            );
    }

    /// @notice Returns an SVG of a token
    /// @param status The token's status
    /// @param placement Placement of token on level/tile before rotation
    /// @param seed Seed used to rotate initial token placement
    /// @param decay Amount of decay affecting the superstructure
    /// @param canvas The canvas data of a (dreaming) token
    /// @return A plaintext SVG string
    function tokenSVG(
        uint256 status,
        uint256 placement,
        uint256 seed,
        uint256 decay,
        uint256[] memory canvas
    ) public view returns (string memory) {
        decay = helpers.structureDecay(block.timestamp); // Overwrite decay data
        return TFTokenURI.tokenSVG(status, placement, seed, decay, canvas);
    }

    /// @notice Returns HTML with the token's SVG as plaintext
    /// @param status The token's status
    /// @param placement Placement of token on level/tile before rotation
    /// @param seed Seed used to rotate initial token placement
    /// @param decay Amount of decay affecting the superstructure
    /// @param canvas The canvas data of a (dreaming) token
    /// @return A plaintext HTML string
    function tokenHTML(
        uint256 status,
        uint256 placement,
        uint256 seed,
        uint256 decay,
        uint256[] memory canvas
    ) public view returns (string memory) {
        decay = helpers.structureDecay(block.timestamp); // Overwrite decay data
        return TFTokenURI.tokenHTML(status, placement, seed, decay, canvas);
    }

    /// @notice Returns the characters of a token
    /// @param status The token's status
    /// @param placement Placement of token on level/tile before rotation
    /// @param seed Seed used to rotate initial token placement
    /// @param decay Amount of decay affecting the superstructure
    /// @param canvas The canvas data of a (dreaming) token
    /// @return result A 2D array of characters (strings)
    function tokenCharacters(
        uint256 status,
        uint256 placement,
        uint256 seed,
        uint256 decay,
        uint256[] memory canvas
    ) public view returns (string[32][32] memory result) {
        decay = helpers.structureDecay(block.timestamp); // Overwrite decay data
        // Get the token's character set
        (string[9] memory chars, , , ) = dataV0.characterSet(placement, seed);

        // Get the token's heightmap (values correspond to character indices)
        uint256[32][32] memory indices = tokenHeightmapIndices(
            status,
            placement,
            seed,
            decay,
            canvas
        );

        // Translate the indices to characters. If the index is 9, it represents
        // the background, so we put a space instead
        for (uint256 y; y < TOKEN_DIMS; y++) {
            for (uint256 x; x < TOKEN_DIMS; x++) {
                result[y][x] = indices[y][x] < 9 ? chars[indices[y][x]] : " ";
            }
        }
    }

    /// @notice Returns a snapshot of an antenna
    /// @param tokenId The token ID
    /// @return result A string
    function antennaPhoto(
        uint256 tokenId
    ) public view returns (string memory result) {
        uint256 placement = terraforms.tokenToPlacement(tokenId);
        (string[9] memory chars, , , uint index) = characterSet(
            placement,
            SEED
        );
        // Biome 0 is a special case
        if (index == 0) {
            chars[0] = " ";
            chars[1] = " ";
        }
        (uint level, uint tile) = levelAndTile(placement, SEED);
        uint seed = helpers.calculateSeed(level, tile);
        uint[32][32] memory indices = TFTokenURI.antennaHeightmap(seed);
        string[32][32] memory heightmapChars = generateTokenCharacterArray(
            chars,
            indices
        );
        string[32] memory rows;
        for (uint i; i < 32; i++) {
            rows[i] = concatenateArrayOfStrings(heightmapChars[i]);
        }
        for (uint i; i < 32; i++) {
            result = concatenateArrayOfStrings(rows);
        }
    }

    /// @notice Concatenates an array of 32 strings
    /// @param arr An array of 32 strings
    /// @return result A string, terminated with a newline
    function concatenateArrayOfStrings(
        string[32] memory arr
    ) public pure returns (string memory result) {
        result = string.concat(
            arr[0],
            arr[1],
            arr[2],
            arr[3],
            arr[4],
            arr[5],
            arr[6],
            arr[7],
            arr[8],
            arr[9],
            arr[10],
            arr[11]
        );
        result = string.concat(
            result,
            arr[12],
            arr[13],
            arr[14],
            arr[15],
            arr[16],
            arr[17],
            arr[18],
            arr[19],
            arr[20],
            arr[21]
        );
        result = string.concat(
            result,
            arr[22],
            arr[23],
            arr[24],
            arr[25],
            arr[26],
            arr[27],
            arr[28],
            arr[29],
            arr[30],
            arr[31],
            "\n"
        );
    }

    /// @notice Returns a 2D array of characters (strings)
    /// @param chars An array of strings
    /// @param heightmap A 2D array of ints
    /// @return result A 2D array of characters (strings)
    function generateTokenCharacterArray(
        string[9] memory chars,
        uint[32][32] memory heightmap
    ) public view returns (string[32][32] memory result) {
        for (uint256 y; y < TOKEN_DIMS; y++) {
            for (uint256 x; x < TOKEN_DIMS; x++) {
                result[y][x] = heightmap[y][x] < 9
                    ? chars[heightmap[y][x]]
                    : " ";
            }
        }
    }

    /// @notice Returns the numbers used to create a token's topography
    /// @dev Values are positions in 3D space. Not applicable to dreaming tokens
    /// @param placement Placement of token on level/tile before rotation
    /// @param seed Value used to rotate initial token placement
    /// @param decay Amount of decay affecting the superstructure
    /// @return result A 2D array of ints
    function tokenTerrain(
        uint256 placement,
        uint256 seed,
        uint256 decay
    ) public view returns (int256[32][32] memory result) {
        decay = helpers.structureDecay(block.timestamp); // Overwrite decay data
        // The step is the increment in the noise space between each element
        // of the token
        int256 step = STEP;

        // If the structure has decayed for more than 100 years, the step sizes
        // become larger, causing the token surface to collapse inward
        if (decay > 100) {
            step += int256(decay - 99) * 100;
        }

        // Determine the level and tile on which the token is located
        (uint256 level, uint256 tile) = dataV0.levelAndTile(placement, seed);

        // Obtain the XYZ origin for the token
        int256 initX = dataV0.xOrigin(level, tile, seed);
        int256 yPos = dataV0.yOrigin(level, tile, seed);
        int256 zPos = zOrigin(level, tile, seed, decay, block.timestamp);
        int256 xPos;

        // Populate 2D array
        for (uint256 y; y < TOKEN_DIMS; y++) {
            xPos = initX; // Reset X for row alignment on each iteration
            for (uint256 x; x < TOKEN_DIMS; x++) {
                result[y][x] = perlinNoise.noise3d(xPos, yPos, zPos);
                xPos += step;
            }
            yPos += step;
        }

        return result;
    }

    /// @notice Returns a 2D array of indices into a char array
    /// @param status The token's status
    /// @param placement The placement of token on level/tile before rotation
    /// @param seed Value used to rotate initial token placement
    /// @param decay Amount of decay affecting the superstructure
    /// @param canvas The canvas data of a (dreaming) token
    /// @return result A 2D array of uints to index into a char array
    function tokenHeightmapIndices(
        uint256 status,
        uint256 placement,
        uint256 seed,
        uint256 decay,
        uint256[] memory canvas
    ) public view returns (uint256[32][32] memory result) {
        decay = helpers.structureDecay(block.timestamp); // Overwrite decay data
        Status s = Status(status);

        // If the token is in terrain mode, generate terrain
        if (s == Status.Terrain) {
            int256[32][32] memory values = tokenTerrain(placement, seed, decay);

            // Convert terrain values to heightmap indices
            for (uint256 y; y < TOKEN_DIMS; y++) {
                for (uint256 x; x < TOKEN_DIMS; x++) {
                    result[y][x] = heightmapIndexFromTerrainValue(values[y][x]);
                }
            }
        } else if (
            // If token is terraformed, draw it
            (s == Status.Terraformed || s == Status.OriginTerraformed) &&
            canvas.length == 16
        ) {
            uint256 digits;
            uint256 counter;
            // Iterate through canvas data
            for (uint256 rowPair; rowPair < 16; rowPair++) {
                // Canvas data is from left to right, so we need to reverse
                // the integers so we can isolate (modulo) the leftmost digits
                digits = helpers.reverseUint(canvas[rowPair]);
                for (uint256 digit; digit < 64; digit++) {
                    // Read 64 digits
                    result[counter / 32][counter % 32] = digits % 10;
                    digits = digits / 10; // Shift down one digit
                    counter += 1;
                }
            }
        }
        // Otherwise, the token is daydreaming, so we return an empty array
        return result;
    }

    /// @notice Returns the XYZ origins of a level in 3D space
    /// @param level The level of the superstructure
    /// @param tile The token's tile placement
    /// @param seed Value used to rotate initial token placement
    /// @param decay Amount of decay affecting the superstructure
    /// @param timestamp The time queried (structure floats and decays in time)
    /// @return Three ints representing the level's XYZ origins in 3D space
    function tileOrigin(
        uint256 level,
        uint256 tile,
        uint256 seed,
        uint256 decay,
        uint256 timestamp
    ) public view returns (int256, int256, int256) {
        decay = helpers.structureDecay(block.timestamp); // Overwrite decay data
        return (
            xOrigin(level, tile, seed),
            yOrigin(level, tile, seed),
            zOrigin(level, tile, seed, decay, timestamp)
        );
    }

    /// @notice Returns the x origin of a token in 3D space
    /// @param level The level of the superstructure
    /// @param tile The token's tile placement
    /// @param seed Value used to rotate initial token placement
    /// @return An int representing the tile's x origin in 3D space
    function xOrigin(
        uint256 level,
        uint256 tile,
        uint256 seed
    ) public view returns (int256) {
        return dataV0.xOrigin(level, tile, seed);
    }

    /// @notice Returns the y origin of a token in 3D space
    /// @param level The level of the superstructure
    /// @param tile The token's tile placement
    /// @param seed Value used to rotate initial token placement
    /// @return An int representing the tile's y origin in 3D space
    function yOrigin(
        uint256 level,
        uint256 tile,
        uint256 seed
    ) public view returns (int256) {
        return dataV0.yOrigin(level, tile, seed);
    }

    /// @notice Returns the z origin of a token in 3D space
    /// @param level The level of the superstructure
    /// @param tile The token's tile placement
    /// @param seed Value used to rotate initial token placement
    /// @param decay Amount of decay affecting the superstructure
    /// @param timestamp The time queried (structure floats and decays in time)
    /// @return An int representing the tile's z origin in 3D space
    function zOrigin(
        uint256 level,
        uint256 tile,
        uint256 seed,
        uint256 decay,
        uint256 timestamp
    ) public view returns (int256) {
        return helpers.zOrigin(level, tile, seed, decay, timestamp);
    }

    /// @notice Changes a token's elevation on a level according to its zone
    /// @param level The level of the superstructure
    /// @param tile The token's tile placement
    /// @param seed Value used to rotate initial token placement
    /// @return A signed integer in range +-4
    function tokenElevation(
        uint256 level,
        uint256 tile,
        uint256 seed
    ) public view returns (int256) {
        // Elevation is determined by the token's position on the level
        // Elevation ranges from 4 (for heightmap index 0) to -4 (index 8)
        return dataV0.tokenElevation(level, tile, seed);
    }

    /// @notice Returns a token's zone, including its name and color scheme
    /// @param placement The placement of token on level/tile before rotation
    /// @param seed Value used to rotate initial token placement
    /// @return An array of hexadecimal strings and a string
    function tokenZone(
        uint256 placement,
        uint256 seed
    ) public view returns (string[10] memory, string memory) {
        return dataV0.tokenZone(placement, seed);
    }

    /// @notice Returns a token's character set
    /// @param placement The placement of token on level/tile before rotation
    /// @param seed Value used to rotate initial token placement
    /// @return charset An array of strings
    /// @return font The index of the token's font
    /// @return fontsize The token's font size
    /// @return index The index of the character set in the storage array
    function characterSet(
        uint256 placement,
        uint256 seed
    )
        public
        view
        returns (
            string[9] memory charset,
            uint256 font,
            uint256 fontsize,
            uint256 index
        )
    {
        return dataV0.characterSet(placement, seed);
    }

    /// @notice Returns a token's biome code
    /// @param tokenId The token ID
    /// @return result The token's biome code
    function biomeCode(
        uint256 tokenId
    ) public view returns (string[9] memory result) {
        uint256 placement = terraforms.tokenToPlacement(tokenId);
        (result, , , ) = characterSet(placement, SEED);
    }

    /// @notice Returns a token's biome index
    /// @param tokenId The token ID
    /// @return result The index of the token's biome
    function biomeIndex(uint256 tokenId) public view returns (uint256 result) {
        uint256 placement = terraforms.tokenToPlacement(tokenId);
        (, , , result) = characterSet(placement, SEED);
    }

    /// @notice Returns a token's chroma trait
    /// @param tokenId The token ID
    /// @return result The name of the token's chroma
    function chroma(
        uint256 tokenId
    ) public view returns (string memory result) {
        uint256 placement = terraforms.tokenToPlacement(tokenId);
        AnimParams memory a = TFTokenURI.animationParameters(placement, SEED);
        if (a.activation == Activation.Plague) {
            return "Plague";
        } else if (a.duration == TFTokenURI.durations(0)) {
            return "Hyper";
        } else if (a.duration == TFTokenURI.durations(1)) {
            return "Pulse";
        } else {
            return "Flow";
        }
    }

    /// @notice Returns a token's resource level
    /// @param tokenId The token ID
    /// @return result The token's resource level
    function resourceLevel(uint256 tokenId) public view returns (uint256) {
        uint256 placement = terraforms.tokenToPlacement(tokenId);
        return dataV0.resourceLevel(placement, SEED);
    }

    /// @notice Returns a token's resource level
    /// @param placement The placement of token on level/tile before rotation
    /// @param seed Value used to rotate initial token placement
    /// @return result The token's resource level
    function resourceLevel(
        uint256 placement,
        uint256 seed
    ) public view returns (uint256) {
        return dataV0.resourceLevel(placement, seed);
    }

    /// @notice Determines a token's level and its position on the level
    /// @param placement The placement of token on level/tile before rotation
    /// @param seed Value used to rotate initial token placement
    /// @return level The token's level number
    /// @return tile The token's tile number
    function levelAndTile(
        uint256 placement,
        uint256 seed
    ) public view returns (uint256 level, uint256 tile) {
        return dataV0.levelAndTile(placement, seed);
    }

    /// @notice Returns the position on the z axis of a 2D level
    /// @dev Z offset cycles over a two year period
    /// @dev Intensity of the offset increases farther from center levels
    /// @param level The level of the superstructure
    /// @param decay Amount of decay affecting the superstructure
    /// @param timestamp The time queried (structure floats and decays in time)
    /// @return result An int representing the altitude of the level
    function zOscillation(
        uint256 level,
        uint256 decay,
        uint256 timestamp
    ) public view returns (int256 result) {
        return helpers.zOscillation(level, decay, timestamp);
    }

    /// @notice Converts a numeric value into an index into a char array
    /// @dev Converts terrain values into characters
    /// @param terrainValue An int from perlin noise
    /// @return An integer to index into a character array
    function heightmapIndexFromTerrainValue(
        int256 terrainValue
    ) public view returns (uint256) {
        // Iterate through the topography array until we find an elem less than
        // value
        for (uint256 i; i < 8; i++) {
            if (terrainValue > topography[i]) {
                return i;
            }
        }
        return 8; // if we fall through, return 8 (the lowest height value)
    }

    /// @notice Returns the name of the Terraforms resource
    function resourceName() public view returns (string memory) {
        return dataV0.resourceName();
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * PUBLIC: ADMINISTRATIVE
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice Locks the contract
    function lock() public onlyOwner notLocked {
        isLocked = true;
    }

    /// @notice Transfers the contract balance to the owner
    function withdraw() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success);
    }

    fallback() external payable {
        _delegate();
    }

    receive() external payable {
        _delegate();
    }

    function _delegate() internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                0xA5aFC9fE76a28fB12C60954Ed6e2e5f8ceF64Ff2,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
