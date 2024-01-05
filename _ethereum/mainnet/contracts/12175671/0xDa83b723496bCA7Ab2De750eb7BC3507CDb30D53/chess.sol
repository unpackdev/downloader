// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./AccessControl.sol";
import "./istones.sol";

contract TheCryptoChessToken is ERC721, AccessControl, Ownable {
    
    using Strings for uint256;

    // contains sha256(concat(sha256(image1), sha256(video1), sha256(image2), sha256(video2), ...)),
    // sorted by a token index
    uint256 public constant PROVENANCE_RECORD = 0xa14b984970f833d58ec93a68fcb0bfe2478eaef1e01feb82c89fa4b54f0311e8;
    
    bytes32 public constant META_UPDATER = keccak256("META_UPDATER");
    
    uint256 public constant MAX_SUPPLY = 32;
    uint256 public constant WHITE_MINERALS_MASK = 0x0F;
    uint256 public constant BLACK_MINERALS_MASK = 0xF0;
    uint256 public constant TOTAL_SIZES_MASK = 0xFF;
    
    uint256 public constant WHITE_GROUP_START = 0;
    uint256 public constant BLACK_GROUP_START = 16;

    mapping (uint256 => string) private _nftNames;
    mapping (string => bool) private _ntfReservedNames;

    string private _metadataUri;
    address private _theCryptoStonesAddress;

    event NameSet (uint256 indexed tokenId, string name);

    constructor () ERC721("TheCryptoChess", "CHESS") {
        address msgSender = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, msgSender);
        _setupRole(META_UPDATER, msgSender);
    }

    // we update metadata to set new names, i.e. the token images & videos are always the same (see PROVENANCE_RECORD)
    function setMetadataURI(string calldata baseURI) public {
        address msgSender = _msgSender();
        require(hasRole(META_UPDATER, msgSender));

        _metadataUri = baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(bytes(_metadataUri).length > 0, "Unknown token URI");
        
        return string(abi.encodePacked(_metadataUri, tokenId.toString()));
    }
    
    function setParentAddress(address parent) public onlyOwner {
        require(_theCryptoStonesAddress == address(0), "The TCS address is set already");
        
        _theCryptoStonesAddress = parent;
    }
    
    function extract() public onlyOwner {
        uint256 currentBalance = address(this).balance;

        address payable dest = payable(_msgSender());
        dest.transfer(currentBalance);
    }
    
    // get name of an item
    function getTokenName(uint256 tokenId) public view returns (string memory) {
        return _nftNames[tokenId];
    }
    
    // check whether the name is valid and available
    function isNameAvailable(string calldata name) public view returns (bool) {
        if (!validateName(name)) return false;
        
        string memory lowerCaseName = toLower(name);
        if (_ntfReservedNames[lowerCaseName]) return false;
        
        return true;
    }

    // set name to an item
    function setTokenName(uint256 tokenId, string calldata name) public {
        address msgSender = _msgSender();

        address owner = ERC721.ownerOf(tokenId); // internal owner
        require(owner == msgSender, "Only owner can name an item");

        string memory oldName = _nftNames[tokenId];
        require(bytes(oldName).length == 0, "Name has been set already");

        require(validateName(name), "Name is invalid");

        string memory lowerCaseName = toLower(name);
        require(!_ntfReservedNames[lowerCaseName], "Name has been taken already");
        
        _nftNames[tokenId] = name;
        _ntfReservedNames[lowerCaseName] = true;
        
        emit NameSet(tokenId, name);
    }

    // get id of a token to be collected based on collected stones
    function getCollectedTokenId(uint256[] calldata tokenIds, address owner) public view returns (uint256) {
        require(_theCryptoStonesAddress != address(0), "Parent contract is unknown");
        Stone[] memory stones = ICryptoStones(_theCryptoStonesAddress).getStonesProps(tokenIds);

        require(stones.length > 0, "Invalid number of stones");

        uint256 sizesCollected = 0;
        uint256 currentMineral = stones[0].mineral;
        uint256 currentCutting = stones[0].cutting;

        for (uint i = 0; i < stones.length; ++i) {
            Stone memory stone = stones[i];

            require(owner == address(0) || stone.owner == owner, "Invalid owner");
            require(stone.cutting == currentCutting, "Cutting should be the same");
            require(stone.mineral == currentMineral, "Mineral should be the same");

            sizesCollected |= (1 << stone.size);
        }

        require(sizesCollected == TOTAL_SIZES_MASK, "You have to collect all sizes");

        if ((1 << currentMineral) & WHITE_MINERALS_MASK != 0) {
            if (!_exists(WHITE_GROUP_START + currentCutting)) {
                return WHITE_GROUP_START + currentCutting; // we can collect it
            }
        }
        if ((1 << currentMineral) & BLACK_MINERALS_MASK != 0) {
            if (!_exists(BLACK_GROUP_START + currentCutting)) {
                return BLACK_GROUP_START + currentCutting; // we can collect it
            }
        }

        revert("The item has been collected already");
    }

    // claims a token based on collected stones
    function claimCollectedToken(uint256[] calldata tokenIds) public {
        address msgSender = _msgSender();

        uint256 itemIdToCollect = getCollectedTokenId(tokenIds, msgSender);

        require(itemIdToCollect < MAX_SUPPLY, "Invalid item");

        _safeMint(msgSender, itemIdToCollect); // it checks whether a token exists
    }

    function toLower(string memory str) public pure returns (string memory) {
        bytes memory byteStr = bytes(str);
        bytes memory resultStr = new bytes(byteStr.length);

        for (uint i = 0; i < byteStr.length; ++i) {
            if ((uint8(byteStr[i]) >= 65) && (uint8(byteStr[i]) <= 90)) { // uppercase
                resultStr[i] = bytes1(uint8(byteStr[i]) + 32);
            } else {
                resultStr[i] = byteStr[i];
            }
        }

        return string(resultStr);
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
