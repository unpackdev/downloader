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
import "./IThePixelsIncExtensionStorage.sol";

contract ThePixelsIncMetadataURLProviderV3 is
    IThePixelsMetadataProvider,
    Ownable
{
    using Strings for uint256;

    struct BaseURL {
        bool useDNA;
        string url;
        string description;
    }

    string public initialBaseURL;
    BaseURL[] public baseURLs;

    address public immutable pixelsAddress;
    address public extensionStorageAddress;

    constructor(address _pixelsAddress, address _extensionStorageAddress) {
        pixelsAddress = _pixelsAddress;
        extensionStorageAddress = _extensionStorageAddress;
    }

    // OWNER CONTROLS

    function setInitialBaseURL(string calldata _initialBaseURL)
        external
        onlyOwner
    {
        initialBaseURL = _initialBaseURL;
    }

    function setExtensionStorageAddress(address _extensionStorageAddress)
        external
        onlyOwner
    {
        extensionStorageAddress = _extensionStorageAddress;
    }

    function addBaseURL(
        bool _useDNA,
        string memory _url,
        string memory _description
    ) external onlyOwner {
        baseURLs.push(BaseURL(_useDNA, _url, _description));
    }

    function setBaseURL(
        uint256 id,
        bool _useDNA,
        string memory _url,
        string memory _description
    ) external onlyOwner {
        baseURLs[id] = (BaseURL(_useDNA, _url, _description));
    }

    // PUBLIC

    function getMetadata(
        uint256 tokenId,
        uint256 dna,
        uint256 extensionV1
    ) public view override returns (string memory) {
        uint256 extensionV2 = IThePixelsIncExtensionStorage(
            extensionStorageAddress
        ).pixelExtensions(tokenId);

        string memory fullDNA = _fullDNA(dna, extensionV1, extensionV2);
        BaseURL memory currentBaseURL = baseURLs[baseURLs.length - 1];

        if (extensionV1 > 0 || extensionV2 > 0) {
            if (currentBaseURL.useDNA) {
                return
                    string(abi.encodePacked(currentBaseURL.url, "/", fullDNA));
            } else {
                return
                    string(
                        abi.encodePacked(
                            currentBaseURL.url,
                            "/",
                            tokenId.toString()
                        )
                    );
            }
        } else {
            return string(abi.encodePacked(initialBaseURL, "/", fullDNA));
        }
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
        uint256 extensionV2 = IThePixelsIncExtensionStorage(
            extensionStorageAddress
        ).pixelExtensions(tokenId);

        return _fullDNA(dna, extensionV1, extensionV2);
    }

    function lastBaseURL() public view returns (string memory) {
        return baseURLs[baseURLs.length - 1].url;
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
        }else if (_extensionV1 == 0) {
            return "";
        }

        return _extensionV1.toString();
    }
}
