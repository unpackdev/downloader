// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./IHasSecondarySaleFees.sol";
import "./Bytes32.sol";
import "./IPFS.sol";
import "./LiteralStrings.sol";
import "./TrimStrings.sol";

contract Letters is ERC721, IHasSecondarySaleFees {
    using LiteralStrings for bytes;
    using Bytes32 for string;
    using IPFS for bytes;
    using IPFS for bytes32;
    using TrimStrings for bytes32;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    bytes32 private _currentProvenanceHash;

    mapping(uint256 => bytes32) public letterMemory;
    mapping(uint256 => address payable) public fromMemory;

    uint256 public lastTokenId;
    uint256[] public feeBps;

    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        uint256 _lastTokenId,
        uint256[] memory _feeBps
    ) ERC721(_name, _symbol) {
        require(bytes(_name).length < 32, "name too long");
        lastTokenId = _lastTokenId;
        feeBps = _feeBps;
        sendLetter(_owner, _name.toBytes32());
    }

    function LETTERS_PROVENANCE() public view returns (bytes32) {
        uint256 currentSupply = _tokenIdTracker.current();
        require(currentSupply > lastTokenId, "provenance not determined");
        return _currentProvenanceHash;
    }

    function owner() public view virtual returns (address) {
        return ownerOf(0);
    }

    function sendLetter(address _to, bytes32 _letter) public {
        uint256 tokenId = _tokenIdTracker.current();
        require(tokenId <= lastTokenId, "all letters have been sent");
        letterMemory[tokenId] = _letter;
        fromMemory[tokenId] = payable(msg.sender);
        _mint(_to, tokenId);
        _tokenIdTracker.increment();
        // this takes extra 50000 gas but it is required to get final provenance for large number of letters
        if (_currentProvenanceHash == "") {
            _currentProvenanceHash = getProvenance(tokenId);
        } else {
            _currentProvenanceHash = sha256(abi.encodePacked(_currentProvenanceHash, getProvenance(tokenId)));
        }
    }

    function getFeeBps(uint256 _tokenId) external view override returns (uint256[] memory) {
        require(_exists(_tokenId), "query for nonexistent token");
        return feeBps;
    }

    function getFeeRecipients(uint256 _tokenId) external view override returns (address payable[] memory) {
        require(_exists(_tokenId), "query for nonexistent token");
        address payable[] memory feeRecipients = new address payable[](2);
        feeRecipients[0] = payable(owner());
        feeRecipients[1] = payable(fromMemory[_tokenId]);
        return feeRecipients;
    }

    function getLetter(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "query for nonexistent token");
        return letterMemory[_tokenId].toString();
    }

    function getFrom(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "query for nonexistent token");
        return abi.encodePacked(fromMemory[_tokenId]).toLiteralString();
    }

    function getDescription(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "query for nonexistent token");
        return string(abi.encodePacked("just 32 bytes letter from ", getFrom(_tokenId)));
    }

    function getImageData(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "query for nonexistent token");
        return
            string(
                abi.encodePacked(
                    '<svg width=\\"600\\" height=\\"315\\" viewBox=\\"0 0 600 315\\" xmlns=\\"http://www.w3.org/2000/svg\\"><rect x=\\"0\\" y=\\"0\\" width=\\"600\\" height=\\"315\\" fill=\\"white\\" /><g><text x=\\"300\\" y=\\"157.5\\" text-anchor=\\"middle\\" dominant-baseline=\\"middle\\" font-family=\\"sans-serif\\" font-size=\\"24\\" fill=\\"#1F2937\\">',
                    getLetter(_tokenId),
                    "</text></g></svg>"
                )
            );
    }

    function getMetaData(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "query for nonexistent token");
        return
            string(
                abi.encodePacked(
                    '{"name":"',
                    getLetter(_tokenId),
                    '","description":"',
                    getDescription(_tokenId),
                    '","image_data":"',
                    getImageData(_tokenId),
                    '"}'
                )
            );
    }

    function getProvenance(uint256 _tokenId) public view returns (bytes32) {
        require(_exists(_tokenId), "query for nonexistent token");
        return sha256(abi.encodePacked(getMetaData(_tokenId)));
    }

    function getCid(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "query for nonexistent token");
        return
            string(
                abi.encodePacked(getMetaData(_tokenId)).toIpfsDigest().addSha256FunctionCodePrefixToDigest().toBase58()
            );
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "query for nonexistent token");
        return string(abi.encodePacked(getCid(_tokenId)).addIpfsBaseUrlPrefix());
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IHasSecondarySaleFees).interfaceId || super.supportsInterface(interfaceId);
    }
}
