//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IHLFS {
    /**
     * @notice Get contents of a file on a HL FS
     */
    function fileContents(string calldata fileName) external view returns (string memory);
}
