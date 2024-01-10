// SPDX-License-Identifier: MIT

// Contract by pr0xy.io

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract ZiPoap is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public gallery;

    mapping(uint => uint) public tokenEvent;
    mapping(uint => address) public attendees;
    mapping(uint => bytes32) public merkleroot;
    mapping(uint => mapping(address => bool)) public denylist;

    constructor() ERC721('ZiPoap', 'ZOAP') {}

    function _baseURI() internal view virtual override returns (string memory) {
        return gallery;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        uint eventId = tokenEvent[tokenId];
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, eventId.toString())) : "";
    }

    function setGallery(string calldata _gallery) external onlyOwner {
        gallery = _gallery;
    }

    function setMerkleRoot(uint _eventId, bytes32 _merkleroot) external onlyOwner {
        merkleroot[_eventId] = _merkleroot;
    }

    function isAttendee(uint _eventId, address _wallet) external view returns (bool) {
        return denylist[_eventId][_wallet];
    }

    function validate(uint _tokenId) external view returns (bool) {
        return ownerOf(_tokenId) == attendees[_tokenId];
    }

    function mint(bytes32[] calldata _merkleProof, uint _eventId) external {
        uint supply = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(tx.origin == msg.sender, 'Contracts Denied.');
        require(!denylist[_eventId][msg.sender], 'Token Claimed.');
        require(MerkleProof.verify(_merkleProof, merkleroot[_eventId], leaf), 'Proof Invalid.');

        _safeMint(msg.sender, supply);

        tokenEvent[supply] = _eventId;
        attendees[supply] = msg.sender;
        denylist[_eventId][msg.sender] = true;
    }
}
