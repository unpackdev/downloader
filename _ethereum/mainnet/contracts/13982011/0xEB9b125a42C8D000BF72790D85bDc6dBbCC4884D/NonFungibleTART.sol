// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Base64.sol";

contract NonFungibleTART is ERC721, Ownable {

    using Strings for uint256;

    string private _imageDirectoryCid;

    constructor(string memory imageDirectoryCid)
    ERC721("Non Fungible TART", "NFTART")
    Ownable()
    {
        _imageDirectoryCid = imageDirectoryCid;
    }

    function getTokenIdOf(address to) public pure returns (uint256) {
        return uint256(uint160(bytes20(to)));
    }

    function getTokenIdListOf(address[] memory toList) public pure returns (uint256[] memory) {
        uint256[] memory tokenIdList = new uint256[](toList.length);
        for (uint256 i; i < toList.length; i++) {
            tokenIdList[i] = getTokenIdOf(toList[i]);
        }

        return tokenIdList;
    }

    function mint(address to) public onlyOwner {
        _safeMint(to, getTokenIdOf(to));
    }

    function batchMint(address[] memory toList) public onlyOwner {
        for (uint256 i; i < toList.length; i++) {
            _safeMint(toList[i], getTokenIdOf(toList[i]));
        }
    }

    function updateImageDirectoryCid(string memory imageDirectoryCid) public onlyOwner {
        _imageDirectoryCid = imageDirectoryCid;
    }

    function generateMetadataJson(uint256 tokenId) public view returns (string memory) {
        string [10] memory parts;

        parts[0] = '{';
        parts[1] = '"name": "Non Fungible TART", ';
        parts[2] = '"description": "Thank you from TART!", ';
        parts[3] = '"image": "ipfs://';
        parts[4] = _imageDirectoryCid;
        parts[5] = '/';
        parts[6] = tokenId.toString();
        parts[7] = '.png", ';
        parts[8] = '"external_url": "https://tart.tokyo"';
        parts[9] = '}';

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7])
        );
        output = string(
            abi.encodePacked(
                output,
                parts[8],
                parts[9]
            )
        );

        return output;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory json = Base64.encode(
            bytes(generateMetadataJson(tokenId))
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
