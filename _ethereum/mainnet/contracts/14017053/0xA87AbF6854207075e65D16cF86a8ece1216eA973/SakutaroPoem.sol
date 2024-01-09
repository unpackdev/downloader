// SPDX-License-Identifier: MIT
//
//  _____         _            _
// /  ___|       | |          | |
// \ `--.   __ _ | | __ _   _ | |_   __ _  _ __   ___
//  `--. \ / _` || |/ /| | | || __| / _` || '__| / _ \
// /\__/ /| (_| ||   < | |_| || |_ | (_| || |   | (_) |
// \____/  \__,_||_|\_\ \__,_| \__| \__,_||_|    \___/
//
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Counters.sol";
import "./MerkleProof.sol";
import "./Base64.sol";

contract SakutaroPoem is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bytes32 markeRoot = bytes32(0xcd6af4a55c0a60ea2164e19db484a1da7c1fdd8210559e39181f057da1d8a42e);
    mapping(uint256 => string) public poemTitles;
    mapping(uint256 => string) public poemBodies;

    uint256 public constant maxElements = 39;
    uint256 public constant secondarySaleRoyalty = 10_00000; // 10.0%
    uint256 public constant modulo = 100_00000; // precision 100.00000%

    address public royaltyReceiver;
    uint256 private seed;

    constructor() ERC721("Sakurato Poem", "SAKU") {
        royaltyReceiver = msg.sender;
        seed = block.timestamp;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function mint(
        address to,
        uint256 id,
        string calldata poemTitle,
        string calldata poemBody,
        bytes32[] memory markleProof
    ) public {
        require(_tokenIdCounter.current() < maxElements, "Mint would exceed max supply of NFTs");
        require(_tokenIdCounter.current() == id, "Must add poem data for yours");
        addPoem(id, poemTitle, poemBody, markleProof);
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        uint256 id;
        if (_tokenIdCounter.current() < maxElements) {
            id = tokenId - 1;
        } else {
            id = (uint160(ownerOf[tokenId]) + seed) % uint256(maxElements);
        }

        string[11] memory parts;
        parts[0] = '<svg width="400" height="400" viewBox="0, 0, 410, 410" xmlns="http://www.w3.org/2000/svg">';
        parts[1] = '<defs><linearGradient id="grad1" x1="0%" y1="50%" ><stop offset="0%" stop-color="#0f2350" ><animate id="a1" attributeName="stop-color" values="#0f2350; #6a5acd" begin="0; a2.end" dur="3s" /><animate id="a2" attributeName="stop-color" values="#6a5acd; #0f2350" begin="a1.end" dur="3s" /></stop><stop offset="100%" stop-color="#6a5acd" ><animate id="a3" attributeName="stop-color" values="#6a5acd; #0f2350" begin="0; a4.end" dur="3s" /><animate id="a4" attributeName="stop-color" values="#0f2350; #6a5acd" begin="a3.end" dur="3s" /></stop></linearGradient></defs>';
        parts[2] = '<style type="text/css">p {font-family: serif; color: white;}</style>';
        parts[3] = '<rect width="400" height="400" fill="url(#grad1)" />';
        parts[4] = '<foreignObject x="25" y="15" width="350" height="370"><p class="shadow" xmlns="http://www.w3.org/1999/xhtml">';
        parts[5] = poemTitles[id];
        parts[6] = '</p><p xmlns="http://www.w3.org/1999/xhtml">';
        parts[7] = poemBodies[id];
        parts[8] = '</p><p style="padding-top: 1em" xmlns="http://www.w3.org/1999/xhtml">';
        parts[9] = unicode"― 萩原 朔太郎";
        parts[10] = "</p></foreignObject></svg>";

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9], parts[10]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
          "{",
          '"name": "', poemTitles[id], '",',
          '"description": "Thirty-nine poems from Sakutaro Hagiwara\'s late self-selected collection \\"Shukumei\\" have been inscribed on Blockchain as full-onchain NFTs. The content of this NFT changes depending on the owner.",',
          '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '",',
          '"license": "CC-BY 4.0",',
          '"creator": "Ara"',
          "}"
        ))));
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    function addPoem(
        uint256 id,
        string calldata poemTitle,
        string calldata poemBody,
        bytes32[] memory markleProof
    ) public {
        bytes32 leaf = keccak256(abi.encodePacked(poemTitle, poemBody));
        require(MerkleProof.verify(markleProof, markeRoot, leaf), "poem not match");
        poemTitles[id] = poemTitle;
        poemBodies[id] = poemBody;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override(ERC721) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == 0x2a55205a; // ERC165 Interface ID for ERC2981
    }

    // ERC-2981
    function royaltyInfo(
        uint256, /* _tokenId */
        uint256 _value
    ) external view returns (address _receiver, uint256 _royaltyAmount) {
        _receiver = royaltyReceiver;
        _royaltyAmount = (_value / modulo) * secondarySaleRoyalty;
    }
}
