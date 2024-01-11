// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Ownable.sol";

import "./IThePixelsInc.sol";
import "./IThePixelsMetadataProvider.sol";
import "./IThePixelsIncExtensionStorageV2.sol";

contract ThePixelsIncMetadataURLProviderV4 is
    IThePixelsMetadataProvider,
    Ownable
{
    using Strings for uint256;

    struct Snapshot {
        string url;
        string description;
    }

    Snapshot[] public snapshots;
    string public baseURL;
    address public immutable pixelsAddress;
    address public extensionStorageAddress;

    constructor(address _pixelsAddress, address _extensionStorageAddress) {
        pixelsAddress = _pixelsAddress;
        extensionStorageAddress = _extensionStorageAddress;
    }

    // OWNER CONTROLS

    function setExtensionStorageAddress(address _extensionStorageAddress)
        external
        onlyOwner
    {
        extensionStorageAddress = _extensionStorageAddress;
    }

    function addSnapshot(string memory _url, string memory _description)
        external
        onlyOwner
    {
        snapshots.push(Snapshot(_url, _description));
    }

    function setSnapshot(
        uint256 id,
        string memory _url,
        string memory _description
    ) external onlyOwner {
        snapshots[id] = (Snapshot(_url, _description));
    }

    function setBaseURL(string memory _baseURL) external onlyOwner {
        baseURL = _baseURL;
    }

    // PUBLIC

    function getMetadata(
        uint256 tokenId,
        uint256 dna,
        uint256 extensionV1
    ) public view override returns (string memory) {
        uint256 extensionV2 = IThePixelsIncExtensionStorageV2(
            extensionStorageAddress
        ).pixelExtensions(tokenId);

        string memory fullDNA = _fullDNA(dna, extensionV1, extensionV2);
        return
            string(
                abi.encodePacked(
                    baseURL,
                    "/",
                    tokenId.toString(),
                    "?dna=",
                    fullDNA
                )
            );
    }

    function fullDNAOfToken(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint256 dna = IThePixelsInc(pixelsAddress).pixelDNAs(tokenId);
        uint256 extensionV1 = IThePixelsInc(pixelsAddress).pixelDNAExtensions(
            tokenId
        );
        uint256 extensionV2 = IThePixelsIncExtensionStorageV2(
            extensionStorageAddress
        ).pixelExtensions(tokenId);

        return _fullDNA(dna, extensionV1, extensionV2);
    }

    // INTERNAL

    function _fullDNA(
        uint256 _dna,
        uint256 _extensionV1,
        uint256 _extensionV2
    ) internal pure returns (string memory) {
        if (_extensionV1 == 0 && _extensionV2 == 0) {
            return _dna.toString();
        }
        string memory _extension = _fixedExtension(_extensionV1, _extensionV2);
        return string(abi.encodePacked(_dna.toString(), "_", _extension));
    }

    function _fixedExtension(uint256 _extensionV1, uint256 _extensionV2)
        internal
        pure
        returns (string memory)
    {
        if (_extensionV2 > 0) {
            return
                string(
                    abi.encodePacked(
                        _extensionV1.toString(),
                        _extensionV2.toString()
                    )
                );
        } else if (_extensionV1 == 0) {
            return "";
        }

        return _extensionV1.toString();
    }
}
