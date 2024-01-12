// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./LibDiamond.sol";

import "./IERC721A.sol";
import "./IAttribute.sol";
import "./IMetadata.sol";
import "./ISVG.sol";
import "./IDiamondFactory.sol";
import "./IERC721Enumerable.sol";
import "./IERC3156FlashLender.sol";
import "./IClaim.sol";
import "./ITokenPrice.sol";
import "./IFees.sol";
import "./IBitGem.sol";
import "./IMultiPart.sol";
import "./ITokenSale.sol";
import "./ITokenMetadataFactory.sol";
import "./IRandomness.sol";

/* solhint-disable indent */
/* solhint-disable no-inline-assembly */
/* solhint-disable mark-callable-contracts */

struct SaltStorage {
    uint256 salt;
}

struct AppStorage {
    DiamondFactoryContract factory;
    mapping(address => SaltStorage) salts;
    mapping(address => ERC721AContract) erc721Contracts;
    mapping(address => AttributeContract) attributes;
    mapping(address => MetadataContract) metadata;
    mapping(address => ERC721EnumerableContract) enumerations;
    mapping(address => VariablePriceContract) variablePrices;
    mapping(address => MultiPartContract) multiParts;
    mapping(uint256 => TokenSaleContract) tokenSales;
    uint256[] tokenSaleKeys;
    mapping(uint256 => TokenMetadataFactoryContract) tokenMetadataFactories;
    RandomnessContract randomness;
}

library LibAppStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.erc721a.app.storage");

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

contract Modifiers {
    function s() internal pure returns (AppStorage storage ds) {
        return LibAppStorage.diamondStorage();
    }

    modifier onlyOwner() {
        require(LibDiamond.contractOwner() == msg.sender || address(this) == msg.sender,
            "not authorized to call function");
        _;
    }
}
