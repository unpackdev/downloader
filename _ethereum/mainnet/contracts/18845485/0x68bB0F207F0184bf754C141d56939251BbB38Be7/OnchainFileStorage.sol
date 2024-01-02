//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Bytecode.sol";
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

        // @author of the following section: @xaltgeist (0x16cc845d144a283d1b0687fbac8b0601cc47a6c3 on Ethereum mainnet)
        // edited with HL FS -like variable names
        uint256 size;
        uint ptr = 0x20;
        address currentChunk;
        unchecked {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                contents := mload(0x40)
            }

            for (uint i = 0; i < fileStorageAddressesLength; i++) {
                currentChunk = fileStorageAddresses[i];
                size = Bytecode.codeSize(currentChunk) - 1;

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    extcodecopy(currentChunk, add(contents, ptr), 1, size)
                }
                ptr += size;
            }

            // solhint-disable-next-line no-inline-assembly
            assembly {
                // allocate output byte array - this could also be done without assembly
                // by using o_code = new bytes(size)
                // new "memory end" including padding
                mstore(0x40, add(contents, and(add(ptr, 0x1f), not(0x1f))))
                // store length in memory
                mstore(contents, sub(ptr, 0x20))
            }
        }
        return contents;
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
