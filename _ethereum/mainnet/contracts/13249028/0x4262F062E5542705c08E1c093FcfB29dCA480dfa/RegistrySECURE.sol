// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC721Burnable.sol";

contract RegistrySECURE is ERC721Burnable {
    mapping (address => bool) internal approvedMinters;

    struct Record {
        string value;
        bool destroyed;
    }

    event NewRecord(uint256 indexed tokenId, string key);

    // Mapping tokenId to record key/name to record structure
    mapping (uint256 => mapping (string => Record)) internal records;

    event NewDomain(uint256 indexed tokenId, string domain, bytes32 indexed hash);

    constructor(address initialController) ERC721(".secure", "INF") public {
        approvedMinters[initialController] = true;

        _setBaseURI("secure");
    }

    // Minting Permissioning - Start

    modifier onlyApprovedMinter() {
        require(approvedMinters[msg.sender]);
        _;
    }

    function isApprovedMinter(address account) external view returns (bool) {
        return approvedMinters[account];
    }

    function approveMinter(address account) external onlyApprovedMinter {
        approvedMinters[account] = true;
    }

    function renounceMintingApproval() external {
        approvedMinters[msg.sender] = false;
    }

    // Minting Permissioning - END

    // Minting SLD - Start

    function mintSLD(address to, string memory label) external onlyApprovedMinter returns (uint256) {
        require(bytes(label).length != 0);

        bytes memory domain = abi.encodePacked(label, '.', baseURI());
        uint256 tokenId = uint256(keccak256(domain));

        require(!_exists(tokenId));

        _mint(to, tokenId);
        _setTokenURI(tokenId, label);

        emit NewDomain(tokenId, string(domain), keccak256(domain));

        return tokenId;
    }

    // Minting SLD - Stop

    // Record managment - Start
    function setRecord(uint256 tokenId, string memory key, string memory value) external {
        require(_exists(tokenId));
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not owner nor approved");

        Record memory record;

        record.value = value;
        record.destroyed = false;

        records[tokenId][key] = record;
        
        emit NewRecord(tokenId, key);
    }

    function destroyRecord(uint256 tokenId, string memory key) external {
        require(_exists(tokenId));
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not owner nor approved");

        records[tokenId][key].destroyed = true;
    }

    function getRecordByKey(uint256 tokenId, string memory key) external view returns(string memory){
        require(_exists(tokenId));

        return (records[tokenId][key].value);
    }

    function isRecordDestroyed(uint256 tokenId, string memory key) external view returns(bool) {
        require(_exists(tokenId));

        return (records[tokenId][key].destroyed);
    }
    // Record managment - Stop

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
}