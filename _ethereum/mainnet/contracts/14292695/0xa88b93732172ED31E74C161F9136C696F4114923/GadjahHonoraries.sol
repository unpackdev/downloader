//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract GadjahSocietyHonoraries is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI = "";
    string public baseExtension = ".json";

    constructor() ERC721A("Gadjah Society Honoraries", "GDJH-HONOR", 20) {}

    function mint(uint256 _mintAmount) public onlyOwner {
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
