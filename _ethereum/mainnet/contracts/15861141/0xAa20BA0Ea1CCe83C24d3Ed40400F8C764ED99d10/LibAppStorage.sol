// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./LibDiamond.sol";
import "./LibMeta.sol";

struct NftCommon {
    uint256 tokenId;
    string name;
    address owner;
}

struct AppStorage {
    uint256 maxNftCount;
    uint256 maxNftSalePerUser;
    uint256 nftSalePrice;
    string name;
    string symbol;
    bytes32 whitelistMerkleRoot;
    uint256 whitelistSalePrice;
    mapping(address => bool) whitelistClaimed;

    bool whitelistIsActive;
    bool saleIsActive;
    bool freeMintEnabled;

    mapping(uint256 => NftCommon) nfts;
    mapping(address => uint256[]) ownerTokenIds;
    mapping(address => mapping(uint256 => uint256)) ownerTokenIdIndexes;
    mapping(uint256 => address) approved;
    mapping(address => mapping(address => bool)) operators;
    mapping(string => bool) nftNamesUsed;

    mapping(address => bool) gameManagers;

    uint256 tokenIdsCount;

    string baseURI;
    string cloneBoxURI;
}

library LibAppStorage {
    function diamondStorage() internal pure returns(AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier onlyNftOwner(uint256 _tokenId) {
        require(LibMeta.msgSender() == s.nfts[_tokenId].owner, "LibAppStorage: Only nft owner can call this function");
        _;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyGameManager() {
        require(s.gameManagers[LibMeta.msgSender()], "LibAppStorage: Only game manager can call this function");
        _;
    }
}
