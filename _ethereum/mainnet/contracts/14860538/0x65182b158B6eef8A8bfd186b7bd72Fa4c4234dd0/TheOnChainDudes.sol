// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract TheOnChainDudes is Ownable {
    string[] public scriptChunks;
    bool public isLocked;

    function addScriptChunks(string[] memory chunks) public onlyOwner {
        require(!isLocked, "Script is locked!");
        for (uint256 i; i < chunks.length; i++) {
            scriptChunks.push(chunks[i]);
        }
    }

    function lockScript() public onlyOwner {
        isLocked = true;
    }

    // PUBLIC

    function getScriptChunkLength() public view returns (uint256) {
        return scriptChunks.length;
    }

    function getScriptChunk(uint256 _chunkIndex, uint256 _chunkSize)
        public
        view
        returns (string memory, bool)
    {
        string memory script;
        uint256 beginIndex = _chunkIndex * _chunkSize;
        uint256 endIndex = (_chunkIndex + 1) * _chunkSize;
        for (uint256 i = beginIndex; i < endIndex; i++) {
            if (i < scriptChunks.length) {
                script = string(abi.encodePacked(script, scriptChunks[i]));
                if (i == scriptChunks.length - 1) {
                    return (script, false);
                }
            }
        }
        return (script, true);
    }
}
