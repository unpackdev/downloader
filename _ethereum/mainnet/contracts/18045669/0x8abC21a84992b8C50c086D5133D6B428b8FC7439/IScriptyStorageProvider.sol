// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///////////////////////////////////////////////////////////
// ░██████╗░█████╗░██████╗░██╗██████╗░████████╗██╗░░░██╗ //
// ██╔════╝██╔══██╗██╔══██╗██║██╔══██╗╚══██╔══╝╚██╗░██╔╝ //
// ╚█████╗░██║░░╚═╝██████╔╝██║██████╔╝░░░██║░░░░╚████╔╝░ //
// ░╚═══██╗██║░░██╗██╔══██╗██║██╔═══╝░░░░██║░░░░░╚██╔╝░░ //
// ██████╔╝╚█████╔╝██║░░██║██║██║░░░░░░░░██║░░░░░░██║░░░ //
// ╚═════╝░░╚════╝░╚═╝░░╚═╝╚═╝╚═╝░░░░░░░░╚═╝░░░░░░╚═╝░░░ //
///////////////////////////////////////////////////////////

/**
 * @title IScriptyStorageProvider
 * @author @NiftyMike | @NFTCulture
 * @dev An interface wrapper for a ScriptStorage contract, when we only need to read data from it.
 * @dev Special thanks to @0xthedude and @xtremetom for providing this library.
 * See: https://github.com/intartnft/scripty.sol
 */
interface IScriptyStorageProvider {
    /**
     * @notice Get the full script
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param data - Arbitrary data. Not used by this contract.
     * @return script - Full script from merged chunks
     */
    function getScript(string memory name, bytes memory data) external view returns (bytes memory script);

    /**
     * @notice Get script's chunk pointer list
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @return pointers - List of pointers
     */
    function getScriptChunkPointers(string memory name) external view returns (address[] memory pointers);
}
