//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721Enumerable.sol";
import "./Strings.sol";

//import "./UsingHexagons.sol";

contract DemoNFT is
    ERC721Enumerable // /* UsingHexagons*/
{
    using Strings for uint256;

    struct Info {
        string hair;
    }

    mapping(uint256 => Info) public tokenInfo;
    string public baseURI;

    constructor() ERC721("Demo NFT", "DNFT") {} //UsingHexagons() {}

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "DemoNFT: URI query for nonexistent token");

        Info storage info = tokenInfo[_tokenId];

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), "/", info.hair)) : "";
    }

    function mint() external {
        uint256 tokenId = totalSupply();
        tokenInfo[tokenId] = Info("blonde");
        _mint(msg.sender, tokenId);
    }

    function setBaseURI(string calldata _baseURI) external {
        //onlyOwner {
        baseURI = _baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setHairFor(string calldata _hair, uint256 _tokenId) external {
        //onlyOwner{
        tokenInfo[_tokenId].hair = _hair;
    }

    function getInfoOf(uint256 _tokenId) public view returns (Info memory) {
        return tokenInfo[_tokenId];
    }

    /*function _onNotification(
        uint256 _protocolId,
        address _owner,
        bytes calldata _data
    ) internal override {}*/
}
