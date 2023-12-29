// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IBeacon.sol";
import "./ITerraforms.sol";
import "./ITerraformsCharacters.sol";
import "./ISatellite.sol";
import "./Types.sol";
import "./ToString.sol";

/// @author xaltgeist, with code direction and consultation from 113
/// @title A beacon for Terraforms parcels, version 2.0
contract TerraformsBeacon_v2_0 is
    IBeacon,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using ToString for uint256;

    enum ScriptComponent {
        Library,
        Font,
        Extra1,
        Body,
        UI,
        Extra2,
        LoopStart,
        LoopEnd
    }

    struct Broadcast {
        address satellite;
        uint256 duration;
    }

    struct CapturedSatelliteConnection {
        address satellite;
        uint256 timestamp;
    }

    struct AntennaModificationRecord {
        AntennaModification modification;
        address satellite;
        uint256 timestamp;
    }

    // Contract data
    string public version;
    uint256 public MAX_SUPPLY;
    ITerraforms terraforms;

    // Broadcast data
    Broadcast[] public broadcasts;
    uint256[] public broadcastOrder;
    uint256[8] public defaultScriptComponentIndices;

    // Parcel data
    mapping(uint256 => uint256) public placementToParcelId;
    mapping(uint256 => AntennaStatus) public parcelToAntennaStatus;
    mapping(uint256 => CapturedSatelliteConnection[])
        public parcelToCapturedSatelliteConnections;
    mapping(uint256 => uint256) public parcelToActiveSatelliteConnectionIndex;
    mapping(uint256 => AntennaModificationRecord[]) public parcelToAntennaMods;

    // Script data
    mapping(uint256 => string) public scriptLibraries;
    mapping(uint256 => string) public scriptFonts;
    mapping(uint256 => string) public scriptExtras1;
    mapping(uint256 => string) public scriptBodies;
    mapping(uint256 => string) public scriptUIs;
    mapping(uint256 => string) public scriptExtras2;
    mapping(uint256 => string) public scriptLoopStarts;
    mapping(uint256 => string) public scriptLoopEnds;
    uint public nScriptLibraries;
    uint public nScriptFonts;
    uint public nScriptExtras1;
    uint public nScriptBodies;
    uint public nScriptUIs;
    uint public nScriptExtras2;
    uint public nScriptLoopStarts;
    uint public nScriptLoopEnds;

    // Events
    event ParcelModified(uint256 tokenId, AntennaModification modification);
    event BroadcastAdded(address satellite, uint256 duration);
    event BroadcastRemoved(address satellite);
    event BroadcastModified(address satellite, uint256 duration);
    event BroadcastOrderModified(uint256[] order);
    event ScriptComponentModified(ScriptComponent componentType, uint256 index);

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * INITIALIZER
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _scriptLibrary,
        string memory _scriptBody,
        string memory _scriptUI,
        string memory _scriptLoopStart,
        string memory _scriptLoopEnd
    ) public initializer {
        __Ownable_init();
        version = "Version 2.0";
        terraforms = ITerraforms(0x4E1f41613c9084FdB9E34E11fAE9412427480e56); // Main (ERC721) contract
        MAX_SUPPLY = 11104;

        setScriptLibrary(0, _scriptLibrary);
        setScriptBody(0, _scriptBody);
        setScriptUI(0, _scriptUI);
        setScriptLoopStart(0, _scriptLoopStart);
        setScriptLoopEnd(0, _scriptLoopEnd);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * PUBLIC: WRITE FUNCTIONS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice Turns the antenna on for a parcel
    /// @param tokenId The parcel's token ID
    function turnAntennaOn(uint256 tokenId) public {
        require(terraforms.ownerOf(tokenId) == msg.sender, "Only owner");
        require(
            terraforms.tokenToStatus(tokenId) != Status.Terrain,
            "Cannot be terrain"
        );

        require(
            parcelToAntennaStatus[tokenId] != AntennaStatus.On,
            "Antenna already on"
        );

        if (parcelToAntennaMods[tokenId].length == 0) {
            placementToParcelId[terraforms.tokenToPlacement(tokenId)] = tokenId;
        }

        parcelToAntennaStatus[tokenId] = AntennaStatus.On;

        parcelToAntennaMods[tokenId].push(
            AntennaModificationRecord(
                AntennaModification.TurnedAntennaOn,
                address(0),
                block.timestamp
            )
        );

        emit ParcelModified(tokenId, AntennaModification.TurnedAntennaOn);
    }

    /// @notice Turns the antenna off for a parcel
    /// @param tokenId The parcel's token ID
    function turnAntennaOff(uint256 tokenId) public {
        require(terraforms.ownerOf(tokenId) == msg.sender, "Only owner");
        require(
            parcelToAntennaStatus[tokenId] != AntennaStatus.Off,
            "Antenna is off"
        );

        parcelToAntennaStatus[tokenId] = AntennaStatus.Off;

        parcelToAntennaMods[tokenId].push(
            AntennaModificationRecord(
                AntennaModification.TurnedAntennaOff,
                address(0),
                block.timestamp
            )
        );

        emit ParcelModified(tokenId, AntennaModification.TurnedAntennaOff);
    }

    /// @notice Saves a connection to the current satellite
    /// @param tokenId The parcel's token ID
    function saveConnectionToCurrentSatellite(uint256 tokenId) public {
        require(terraforms.ownerOf(tokenId) == msg.sender, "Only owner");
        require(
            parcelToAntennaStatus[tokenId] != AntennaStatus.Off,
            "Antenna is off"
        );

        int256 index = getCurrentBroadcastIndex();
        require(index >= 0, "No active satellite broadcasts");
        Broadcast memory b = broadcasts[uint256(index)];

        ISatellite(b.satellite).capture(tokenId);
        parcelToCapturedSatelliteConnections[tokenId].push(
            CapturedSatelliteConnection(b.satellite, block.timestamp)
        );

        parcelToAntennaMods[tokenId].push(
            AntennaModificationRecord(
                AntennaModification.CapturedSatelliteConnection,
                b.satellite,
                block.timestamp
            )
        );

        emit ParcelModified(
            tokenId,
            AntennaModification.TunedToCapturedSatelliteConnection
        );
        tuneToCapturedSatelliteConnection(
            tokenId,
            parcelToCapturedSatelliteConnections[tokenId].length - 1
        );
    }

    /// @notice Tunes a parcel's antenna to a captured broadcast
    /// @param tokenId The parcel's token ID
    /// @param index The index of the captured broadcast to tune to
    function tuneToCapturedSatelliteConnection(
        uint256 tokenId,
        uint256 index
    ) public {
        require(
            parcelToAntennaStatus[tokenId] != AntennaStatus.Off,
            "Antenna is off"
        );
        require(terraforms.ownerOf(tokenId) == msg.sender, "Only owner");
        require(
            index < parcelToCapturedSatelliteConnections[tokenId].length,
            "Out of range"
        );
        AntennaModificationRecord memory lastMod = getLastAntennaModification(
            tokenId
        );
        if (
            lastMod.modification ==
            AntennaModification.TunedToCapturedSatelliteConnection
        ) {
            require(
                lastMod.satellite !=
                    parcelToCapturedSatelliteConnections[tokenId][index]
                        .satellite,
                "Already connected to this satellite"
            );
        }

        parcelToActiveSatelliteConnectionIndex[tokenId] = index;
        parcelToAntennaStatus[tokenId] = AntennaStatus.ConnectedToSatellite;

        parcelToAntennaMods[tokenId].push(
            AntennaModificationRecord(
                AntennaModification.TunedToCapturedSatelliteConnection,
                parcelToCapturedSatelliteConnections[tokenId][index].satellite,
                block.timestamp
            )
        );

        emit ParcelModified(
            tokenId,
            AntennaModification.TunedToCapturedSatelliteConnection
        );
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * PUBLIC: READ FUNCTIONS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice Gets the status of a parcel's antenna
    /// @param tokenId The parcel's token ID
    /// @return status The status of the parcel's antenna
    function getAntennaStatus(
        uint256 tokenId
    ) public view returns (AntennaStatus status) {
        require(tokenId <= MAX_SUPPLY);
        return parcelToAntennaStatus[tokenId];
    }

    /// @notice Gets the first antenna modification for a parcel
    /// @param tokenId The parcel's token ID
    /// @return modification The first antenna modification
    function getFirstAntennaModification(
        uint256 tokenId
    ) public view returns (AntennaModificationRecord memory) {
        AntennaModificationRecord[] storage mods = parcelToAntennaMods[tokenId];
        require(mods.length > 0, "No antenna modifications");
        return mods[0];
    }

    /// @notice Gets the last antenna modification for a parcel
    /// @param tokenId The parcel's token ID
    /// @return modification The last antenna modification
    function getLastAntennaModification(
        uint256 tokenId
    ) public view returns (AntennaModificationRecord memory) {
        AntennaModificationRecord[] storage mods = parcelToAntennaMods[tokenId];
        require(mods.length > 0, "No antenna modifications");
        return mods[mods.length - 1];
    }

    /// @notice Gets the antenna modification at a given index for a parcel
    /// @param tokenId The parcel's token ID
    /// @param index The index of the antenna modification
    /// @return modification The antenna modification
    function getAntennaModificationAtIndex(
        uint256 tokenId,
        uint256 index
    ) public view returns (AntennaModificationRecord memory) {
        AntennaModificationRecord[] storage mods = parcelToAntennaMods[tokenId];
        require(index < mods.length, "Index out of range");
        return mods[index];
    }

    /// @notice Gets the number of antenna modifications for a parcel
    /// @param tokenId The parcel's token ID
    /// @return The number of antenna modifications
    function getNumberOfAntennaModifications(
        uint256 tokenId
    ) public view returns (uint256) {
        AntennaModificationRecord[] storage mods = parcelToAntennaMods[tokenId];
        return mods.length;
    }

    /// @notice Gets the index of the current broadcast
    /// @return index The index of the current broadcast
    function getCurrentBroadcastIndex() public view returns (int256 index) {
        uint256 cycleDuration = getBroadcastCycleDuration();
        if (cycleDuration == 0) {
            return -1;
        }
        uint256 locationInCycle = block.timestamp % cycleDuration;
        uint256 aggregator;
        Broadcast memory b;

        for (uint256 i; i < broadcastOrder.length; i++) {
            if (broadcastOrder[i] < broadcasts.length) {
                b = broadcasts[broadcastOrder[i]];
                if (ISatellite(b.satellite).isBroadcasting()) {
                    aggregator += broadcasts[broadcastOrder[i]].duration;
                }
                if (locationInCycle < aggregator) {
                    return int256(broadcastOrder[i]);
                }
            }
        }
        return -1;
    }

    /// @notice Gets the duration of the current cycle
    /// @return result The duration of the current cycle
    function getBroadcastCycleDuration() public view returns (uint256 result) {
        for (uint256 i; i < broadcastOrder.length; i++) {
            if (
                broadcastOrder[i] < broadcasts.length &&
                ISatellite(broadcasts[broadcastOrder[i]].satellite)
                    .isBroadcasting()
            ) {
                result += broadcasts[broadcastOrder[i]].duration;
            }
        }
    }

    /// @notice Gets the default script
    /// @return script The default script (a JavaScript string)
    function getCoreScript(uint tokenId) public view returns (string memory) {
        return
            string.concat(
                assembleScriptVars(tokenId),
                getFont(defaultScriptComponentIndices[0]),
                scriptLibraries[defaultScriptComponentIndices[1]],
                scriptBodies[defaultScriptComponentIndices[2]],
                scriptUIs[defaultScriptComponentIndices[3]],
                scriptLoopStarts[defaultScriptComponentIndices[3]],
                "t.m1=dist(c,15.5,r,c)+airship*.05*SEED*.00045",
                scriptLoopEnds[defaultScriptComponentIndices[4]]
            );
    }

    /// @notice Gets the code for a parcel
    /// @param tokenId The parcel's token ID
    /// @return status The status of the parcel's antenna
    /// @return parcelCode The code for the parcel (a JavaScript string)
    function getParcelCode(
        uint256 tokenId
    ) public view returns (AntennaStatus status, string memory parcelCode) {
        status = parcelToAntennaStatus[tokenId];
        int256 index = getCurrentBroadcastIndex();
        if (status == AntennaStatus.Off) {
            parcelCode = getCoreScript(tokenId);
        } else if (status == AntennaStatus.ConnectedToSatellite) {
            CapturedSatelliteConnection
                memory c = parcelToCapturedSatelliteConnections[tokenId][
                    parcelToActiveSatelliteConnectionIndex[tokenId]
                ];

            parcelCode = ISatellite(c.satellite).getBroadcast(tokenId);
        } else if (index >= 0) {
            parcelCode = ISatellite(broadcasts[uint256(index)].satellite)
                .getBroadcast(tokenId);
        } else {
            parcelCode = getCoreScript(tokenId);
        }
    }

    /// @notice Gets the script for a parcel's placement
    /// @param placement The parcel's placement
    /// @return status The status of the parcel's antenna
    /// @return script The script for the parcel (a JavaScript string)
    function getParcelCodeFromPlacement(
        uint256 placement
    ) public view returns (AntennaStatus status, string memory script) {
        return getParcelCode(placementToParcelId[placement]);
    }

    function assembleScriptVars(
        uint tokenId
    ) public view returns (string memory vars) {
        uint atime;
        if (getNumberOfAntennaModifications(tokenId) > 0) {
            atime = getFirstAntennaModification(tokenId).timestamp;
        }
        return
            string.concat(
                "let ATIME=",
                atime.toString(),
                ";let TIME=",
                uint(block.timestamp).toString(),
                ";"
            );
    }

    /// @notice Gets the font for a parcel
    /// @param index The index of the font
    /// @return font The font for the parcel (wrapped base64 string)
    function getFont(uint256 index) public view returns (string memory font) {
        font = scriptFonts[index];
        if (keccak256(bytes(font)) == keccak256(bytes(""))) {
            font = ITerraformsCharacters(
                0xC9e417B7e67E387026161E50875D512f29630D7B
            ).font(0);
        }
        return
            string.concat(
                "let extraFont = `@font-face {font-family:'MathcastlesRemix-Extra';font-display:block;src:url(data:application/font-woff2;charset=utf-8;base64,",
                font,
                ") format('woff');}`; document.head.insertAdjacentHTML('beforeend', '<style>'+extraFont+'</style>');"
            );
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * PUBLIC: ADMINISTRATIVE
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice Adds a broadcast to the list of broadcasts
    /// @param satellite The satellite contract address
    /// @param duration The duration of the broadcast
    function addBroadcast(
        address satellite,
        uint256 duration
    ) public onlyOwner {
        broadcasts.push(Broadcast(satellite, duration));
        emit BroadcastAdded(satellite, duration);
    }

    /// @notice Removes the last broadcast from the list of broadcasts
    function removeLastBroadcast() public onlyOwner {
        require(broadcasts.length > 0, "No broadcasts");
        Broadcast memory b = broadcasts[broadcasts.length - 1];
        broadcasts.pop();
        emit BroadcastRemoved(b.satellite);
    }

    /// @notice Modifies a broadcast
    /// @param index The index of the broadcast to modify
    /// @param satellite The satellite contract address
    /// @param duration The duration of the broadcast
    function modifyBroadcast(
        uint256 index,
        address satellite,
        uint256 duration
    ) public onlyOwner {
        require(index < broadcasts.length, "Index out of range");

        Broadcast storage b = broadcasts[index];

        if (b.duration != duration) {
            b.duration = duration;
        }
        if (b.satellite != satellite) {
            b.satellite = satellite;
        }
        emit BroadcastModified(b.satellite, b.duration);
    }

    /// @notice Modifies the broadcast order
    /// @param order The new broadcast order
    function modifyBroadcastOrder(uint256[] calldata order) public onlyOwner {
        uint256 nBroadcasts = broadcasts.length;
        for (uint256 i; i < order.length; i++) {
            require(order[i] < nBroadcasts, "Index out of range");
        }
        broadcastOrder = order;
        emit BroadcastOrderModified(order);
    }

    /// @notice Sets a script library component
    /// @param index The index of the script library component
    /// @param scriptLibrary The script library component
    function setScriptLibrary(
        uint index,
        string memory scriptLibrary
    ) public onlyOwner {
        if (index == nScriptLibraries) {
            nScriptLibraries++;
        }
        scriptLibraries[index] = scriptLibrary;
        emit ScriptComponentModified(ScriptComponent.Library, index);
    }

    /// @notice Sets a script font component
    /// @param index The index of the script font component
    /// @param scriptFont The script font component
    function setScriptFont(
        uint index,
        string memory scriptFont
    ) public onlyOwner {
        if (index == nScriptFonts) {
            nScriptFonts++;
        }
        scriptFonts[index] = scriptFont;
        emit ScriptComponentModified(ScriptComponent.Font, index);
    }

    /// @notice Sets a script extra1 component
    /// @param index The index of the script extra1 component
    /// @param scriptExtra1 The script extra1 component
    function setScriptExtra1(
        uint index,
        string memory scriptExtra1
    ) public onlyOwner {
        if (index == nScriptExtras1) {
            nScriptExtras1++;
        }
        scriptExtras1[index] = scriptExtra1;
        emit ScriptComponentModified(ScriptComponent.Extra1, index);
    }

    /// @notice Sets a script body component
    /// @param index The index of the script body component
    /// @param scriptBody The script body component
    function setScriptBody(
        uint index,
        string memory scriptBody
    ) public onlyOwner {
        if (index == nScriptBodies) {
            nScriptBodies++;
        }
        scriptBodies[index] = scriptBody;
        emit ScriptComponentModified(ScriptComponent.Body, index);
    }

    /// @notice Sets a script UI component
    /// @param index The index of the script UI component
    /// @param scriptUI The script UI component
    function setScriptUI(uint index, string memory scriptUI) public onlyOwner {
        if (index == nScriptUIs) {
            nScriptUIs++;
        }
        scriptUIs[index] = scriptUI;
        emit ScriptComponentModified(ScriptComponent.UI, index);
    }

    /// @notice Sets a script extra2 component
    /// @param index The index of the script extra2 component
    /// @param scriptExtra2 The script extra2 component
    function setScriptExtra2(
        uint index,
        string memory scriptExtra2
    ) public onlyOwner {
        if (index == nScriptExtras2) {
            nScriptExtras2++;
        }
        scriptExtras2[index] = scriptExtra2;
        emit ScriptComponentModified(ScriptComponent.Extra2, index);
    }

    /// @notice Sets a script loop start component
    /// @param index The index of the script loop start component
    /// @param scriptLoopStart The script loop start component
    function setScriptLoopStart(
        uint index,
        string memory scriptLoopStart
    ) public onlyOwner {
        if (index == nScriptLoopStarts) {
            nScriptLoopStarts++;
        }
        scriptLoopStarts[index] = scriptLoopStart;
        emit ScriptComponentModified(ScriptComponent.LoopStart, index);
    }

    /// @notice Sets a script loop end component
    /// @param index The index of the script loop end component
    /// @param scriptLoopEnd The script loop end component
    function setScriptLoopEnd(
        uint index,
        string memory scriptLoopEnd
    ) public onlyOwner {
        if (index == nScriptLoopEnds) {
            nScriptLoopEnds++;
        }
        scriptLoopEnds[index] = scriptLoopEnd;
        emit ScriptComponentModified(ScriptComponent.LoopEnd, index);
    }

    /// @notice Sets the default script component indices
    /// @param indices The default script component indices
    /// @dev The indices are in the following order: library, font, extra1, body, UI, extra2, loopStart, loopEnd
    function setDefaultScriptComponentIndices(
        uint256[8] memory indices
    ) public onlyOwner {
        defaultScriptComponentIndices = indices;
    }
}
