// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";

error NotEnoughValues();
error NoPriceAvailable();
error NoSupplyLeftForSelectedTraits();
error OutOfBoundPrices();

/// @title Contract for BillyBoys (NFT Project)
/// @notice You can use this contract for minting BillyBoys
contract BillyBoys is ERC721A, PaymentSplitter, Ownable {
    using Strings for uint256;
    
    struct Traits {
        uint16 idx;
        uint16 supply;
        bytes24 traitName; 
        uint256 price; 
    }

    struct Metadata {
        uint16 background; 
        uint16 skin;
        uint16 clothes;
        uint16 mouth;
        uint16 eyes;
        uint16 hair;
        uint16 accesories;
        uint16 earrings; 
    }

    //@notice mapping for layer + trait index to refer to a trait
    mapping (uint16 => Traits) public layers;
    //@notice mapping each token to their metadata onchain
    mapping (uint256 => Metadata) public tokenURIs;
    //@notice mapping for all minted billys 
    mapping (bytes32 => bool) public minted;

    //@notice max amount to be minted
    uint256 public constant publicSupply = 9800; // 10000 - 200 (gifts)
    uint256 public giftSupply = 200;
    //@notice Metadata URI 
    string public BASE_URI;
    //@notice Event for when a Billy is minted
    event BillyBoysMinted(uint256 tokenId, uint16[8] billyBoyTraits);

    constructor(
        Traits[] memory traitValues,
        address[] memory team,
        uint256[] memory shares,
        string memory _BASE_URI
        )  ERC721A("BillyBoys", "BOYS") PaymentSplitter(team, shares) {
        BASE_URI = _BASE_URI;
        for(uint i = 0; i < traitValues.length; i++) {
            layers[traitValues[i].idx] = traitValues[i];
        }
        _safeMint(msg.sender, 6);  
    }

    function create(
        uint16[8] calldata values
        ) external payable {
        //@notice Don't mint if over supply
        require(totalSupply() + 1 <= publicSupply, "MAX_SUPPLY");
        //@notice Fetch price for given traits and return price
        uint256 price = getPrice(values);
        //@notice Check user has sent enough ETH
        require(msg.value >= price, "NOT_ENOUGH_ETH");
        //@notice Check if previously minted
        require(!minted[keccak256(abi.encode(values))], "ALREADY_MINTED");
        //@notice Get the current tokenId to be minted
        uint256 currentIndex = totalSupply();
        unchecked { currentIndex += 1; }
        //@notice Set metadata of nft minted
        tokenURIs[currentIndex] = Metadata(values[0], values[1], values[2], values[3], values[4], values[5], values[6], values[7]);
        //@notice Set aleady minted for current id  
        minted[keccak256(abi.encode(values))] = true;
        //@notice Apply changes to state
        unchecked {
            layers[values[0]].supply -= 1;
            layers[values[1]].supply -= 1;
            layers[values[2]].supply -= 1;
            layers[values[3]].supply -= 1;
            layers[values[4]].supply -= 1;
            layers[values[5]].supply -= 1;
            layers[values[6]].supply -= 1;
            layers[values[7]].supply -= 1;
        }

        _safeMint(msg.sender, 1);
        emit BillyBoysMinted(currentIndex, values);

    }

    function reserve(Metadata[] memory giftOptions, bytes32[] memory giftHashes) external onlyOwner {
        require(giftOptions.length <= giftSupply, "GIFTS_MINTED");
        uint256 currentIndex = totalSupply();
        for(uint256 i = 0; i < giftOptions.length; i++) {
            ++currentIndex;
            tokenURIs[currentIndex] = giftOptions[i];
            minted[giftHashes[i]] = true;
        }
        giftSupply -= giftOptions.length;
        _safeMint(msg.sender, giftOptions.length);
    }

    function withdraw() external onlyOwner {
      for(uint i = 0; i < _payees.length; i++) {
        release(payable(_payees[i]));
      }
    }

    function setBaseURI(
        string memory base
        ) external onlyOwner {
        BASE_URI = base;
    }
    
    function getPrice(
        uint16[8] calldata values
        ) internal view returns (uint256) {
        if(values[0] < 10 && 
        values[1] < 20 && 
        values[2] < 30 && 
        values[3] < 40 && 
        values[4] < 50 && 
        values[5] < 60 && 
        values[6] < 70 && 
        values[7] < 80
        ) revert OutOfBoundPrices();

        Traits memory layerOne = layers[values[0]];
        Traits memory layerTwo = layers[values[1]];
        Traits memory layerThree = layers[values[2]];
        Traits memory layerFour = layers[values[3]];
        Traits memory layerFive = layers[values[4]];
        Traits memory layerSix = layers[values[5]];
        Traits memory layerSeven = layers[values[6]];
        Traits memory layerEight = layers[values[7]];
        
        if(layerOne.supply > 0 && layerTwo.supply > 0 && layerThree.supply > 0 && layerFour.supply > 0 && layerFive.supply > 0 && layerSix.supply > 0 && layerSeven.supply > 0 && layerEight.supply > 0) {
           return layerOne.price + layerTwo.price + layerThree.price + layerFour.price + layerFive.price + layerSix.price + layerSeven.price + layerEight.price;              
        }

        revert NoPriceAvailable();
    }

    function getMetdata(
        uint256 tokenId
        ) public view returns (string memory) {
        Metadata memory _metadata = tokenURIs[tokenId];
        return string(abi.encodePacked(
            bytes32ToString(layers[_metadata.background].traitName),
            "\n",
            bytes32ToString(layers[_metadata.skin].traitName),
            "\n",
            bytes32ToString(layers[_metadata.clothes].traitName),
            "\n",
            bytes32ToString(layers[_metadata.mouth].traitName),
            "\n",
            bytes32ToString(layers[_metadata.eyes].traitName),
            "\n",
            bytes32ToString(layers[_metadata.hair].traitName),
            "\n",
            bytes32ToString(layers[_metadata.accesories].traitName),
            "\n",
            bytes32ToString(layers[_metadata.earrings].traitName)
        ));
    }

    function tokenURI(
        uint256 tokenId
        ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: nonexistent");
        return string(abi.encodePacked(BASE_URI, tokenId.toString(), ".json"));
    }

    function bytes32ToString(
        bytes32 input
        ) internal pure returns (string memory) {
        return string(abi.encodePacked(input));
    }  
}


