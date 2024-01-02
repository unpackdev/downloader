//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./OwnableUpgradeable.sol";

/**
 * @title Onchain File Storage
 * @notice Introduces file handling to place utilities onchain
 * @author highlight.xyz
 */
abstract contract OnchainFileStorage is OwnableUpgradeable {
    /**
     * @notice File existence errors
     */
    error FileAlreadyRegistered();
    error FileNotRegistered();

    /**
     * @notice File storage
     * @dev File-scoped bytecode addresses (pointers) holding contents
     */
    mapping(bytes => address[]) private _fileStorage;

    /**
     * @notice File storage path names
     * @dev Store registered file names (all will be present as keys in `fileStorage`)
     */
    bytes[] private _files;

    /**
     * @notice Add a file via its name and associated storage bytecode addresses
     */
    function addFile(string calldata fileName, address[] calldata fileStorageAddresses) external onlyOwner {
        bytes memory _fileName = bytes(fileName);
        if (_fileStorage[_fileName].length != 0) {
            _revert(FileAlreadyRegistered.selector);
        }

        _files.push(_fileName);
        _fileStorage[_fileName] = fileStorageAddresses;
    }

    /**
     * @notice Remove a file from registered list of file names, and its associated storage bytecode addresses
     */
    function removeFile(string calldata fileName) external onlyOwner {
        bytes memory _fileName = bytes(fileName);
        if (_fileStorage[_fileName].length == 0) {
            _revert(FileNotRegistered.selector);
        }

        bytes[] memory oldFiles = _files;
        bytes[] memory newFiles = new bytes[](oldFiles.length - 1);
        uint256 fileIndexOffset = 0;
        uint256 oldFilesLength = oldFiles.length;

        for (uint256 i = 0; i < oldFilesLength; i++) {
            if (keccak256(oldFiles[i]) == keccak256(_fileName)) {
                fileIndexOffset = 1;
            } else {
                newFiles[i - fileIndexOffset] = oldFiles[i];
            }
        }

        _files = newFiles;
        delete _fileStorage[_fileName];
    }

    /**
     * @notice Return registered file names
     */
    function files() external view returns (string[] memory) {
        bytes[] memory fileNames = _files;
        string[] memory fileNamesHumanReadable = new string[](fileNames.length);

        for (uint256 i = 0; i < fileNames.length; i++) {
            fileNamesHumanReadable[i] = string(fileNames[i]);
        }

        return fileNamesHumanReadable;
    }

    /**
     * @notice Return storage bytecode addresses for a file
     */
    function fileStorage(string calldata fileName) external view returns (address[] memory) {
        bytes memory _fileName = bytes(fileName);
        if (_fileStorage[_fileName].length == 0) {
            _revert(FileNotRegistered.selector);
        }

        return _fileStorage[bytes(fileName)];
    }

    /**
     * @notice Return file contents
     */
    function fileContents(string calldata fileName) external view returns (string memory) {
        bytes memory _fileName = bytes(fileName);
        if (_fileStorage[_fileName].length == 0) {
            _revert(FileNotRegistered.selector);
        }

        address[] memory fileStorageAddresses = _fileStorage[bytes(fileName)];
        uint256 fileStorageAddressesLength = fileStorageAddresses.length;
        string memory contents = "";

        for (uint256 i = 0; i < fileStorageAddressesLength; i++) {
            contents = string(
                abi.encodePacked(
                    contents,
                    string(_readBytecode(fileStorageAddresses[i], 1, fileStorageAddresses[i].code.length - 1))
                )
            );
        }

        return contents;
    }

    /**
     * @notice Read bytecode at an address
     * @ author SOLMATE
     */
    function _readBytecode(address pointer, uint256 start, uint256 size) private view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure virtual {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}
