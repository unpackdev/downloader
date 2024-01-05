// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./AccessControl.sol";

contract StoneSymbolsToken is ERC721, AccessControl, Ownable {
    
    using Strings for uint256;
    
    // contains sha256(concat(sha256(image1), sha256(video1), sha256(image2), sha256(video2), ...)),
    // sorted by a token index
    uint256 public constant PROVENANCE_RECORD = 0xd5c67402a4304165360fc3d4a80b64164d77004b472bcb5d6b0f4c8268ff13f9;
    
    bytes32 public constant META_UPDATER = keccak256("META_UPDATER");
    
    uint256 public constant MAX_SUPPLY = 4;

    mapping (uint256 => string) private _nftNames;

    string private _metadataUri;

    event NameSet (uint256 indexed tokenId, string name);

    constructor () ERC721("StoneSymbols", "SSMB") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(META_UPDATER, msg.sender);

        for (uint i = 0; i < MAX_SUPPLY; ++i) {
            _mint(msg.sender, i);
        }
    }

    // we update metadata to set new names, i.e. the token images & videos are always the same (see PROVENANCE_RECORD)
    function setMetadataURI(string calldata baseURI) public {
        require(hasRole(META_UPDATER, msg.sender));

        _metadataUri = baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(bytes(_metadataUri).length > 0, "Unknown token URI");
        
        return string(abi.encodePacked(_metadataUri, tokenId.toString()));
    }
    
    function extract() public onlyOwner {
        uint256 currentBalance = address(this).balance;
        address payable dest = payable(msg.sender);
        dest.transfer(currentBalance);
    }
    
    // get name of an item
    function getTokenName(uint256 tokenId) public view returns (string memory) {
        return _nftNames[tokenId];
    }
    
    // set name of an item
    function setTokenName(uint256 tokenId, string calldata name) public {
        address owner = ERC721.ownerOf(tokenId); // internal owner
        require(owner == msg.sender, "Only owner can name an item");

        string memory oldName = _nftNames[tokenId];
        require(bytes(oldName).length == 0, "Name has been set already");

        require(validateName(name), "Name is invalid");

        _nftNames[tokenId] = name;
        
        emit NameSet(tokenId, name);
    }

    function validateName(string memory str) public pure returns (bool) {
        bytes memory byteStr = bytes(str);

        if (byteStr.length < 1 || byteStr.length > 30) return false;
        if (byteStr[0] == 0x20) return false;
        if (byteStr[byteStr.length - 1] == 0x20) return false;

        bytes1 lastCh = byteStr[0];

        for (uint i = 0; i < byteStr.length; ++i) {
            bytes1 ch = byteStr[i];

            if (ch == 0x20 && lastCh == 0x20) return false; // double space

            if (
                !(ch >= 0x30 && ch <= 0x39) && // 0-9
                !(ch >= 0x41 && ch <= 0x5A) && // A-Z
                !(ch >= 0x61 && ch <= 0x7A) && // a-z
                !(ch == 0x20) // space
            )
                return false;

            lastCh = ch;
        }

        return true;
    }
}
