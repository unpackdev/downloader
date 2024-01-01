// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract ApiensNewEra is ERC721, Ownable {
    using Strings for uint256;

    string public uriPrefix = "https://apiensmorph.s3.amazonaws.com/json/";
    string public uriSuffix = ".json";
    uint256 public maxMintAmountPerTx;

    constructor() ERC721("ApiensNewEra", "APIENS") Ownable(msg.sender) {
        setMaxMintAmountPerTx(20);
    }

    modifier mintCompliance(uint256[] memory _tokenIds) {
        require(_tokenIds.length > 0, "No token IDs provided");
        require(
            _tokenIds.length <= maxMintAmountPerTx,
            "Exceeds max mint amount per transaction"
        );
        _;
    }

    function mintForAddress(
        uint256[] memory _tokenIds,
        address _receiver
    ) public mintCompliance(_tokenIds) onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _ownerOf(_tokenIds[i]) == address(0),
                "Token ID already exists"
            );
            _safeMint(_receiver, _tokenIds[i]);
        }
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _ownerOf(_tokenId) != address(0),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setMaxMintAmountPerTx(
        uint256 _maxMintAmountPerTx
    ) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
