// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./CharityPops.sol";

contract CharityPopsMinter is Ownable {
    using Strings for string;
    using SafeMath for uint256;

    address public nftAddress;

    uint256 public LOW_MAX = 200;
    uint256 public LOW_PRICE = 90000000000000000;
    uint256 public MID_MAX = 100;
    uint256 public MID_PRICE = 270000000000000000;
    uint256 public TOP_MAX = 50;
    uint256 public TOP_PRICE = 1000000000000000000;

    mapping(uint256 => uint256) public supplyCounters;

    // mapping follows system of Animal rescue (1, 6, 11), autism (2, 7, 12), breast cancer (3, 8, 13), environment (4, 9, 14), hunger (5, 10, 15)
    // 1, 2, 3, 4, 5 are each cheapest options
    // 6, 7, 8, 9, 10 are each mid options alphabetically
    // 11, 12, 13, 14, 15 are most expensive


    constructor(address _nftAddress) {
        nftAddress = _nftAddress;
    }

    function name() external pure returns (string memory) {
        return "Charity Pops";
    }

    function symbol() external pure returns (string memory) {
        return "CHP";
    }

    function mint(uint256 amount, address _toAddress, uint256 option_id) external payable {

        if (option_id <= 5) {
            require(LOW_PRICE.mul(amount) <= msg.value, "Ether value sent is not correct");
            require(supplyCounters[option_id] + amount <= LOW_MAX, "Minting would exceed available supply!");
        }
        else if (option_id <= 10) {
            require(MID_PRICE.mul(amount) <= msg.value, "Ether value sent is not correct");
            require(supplyCounters[option_id] + amount <= MID_MAX, "Minting would exceed available supply!");
        }
        else if (option_id <= 15) {
            require(TOP_PRICE.mul(amount) <= msg.value, "Ether value sent is not correct");
            require(supplyCounters[option_id] + amount <= TOP_MAX, "Minting would exceed available supply!");
        } else {
            require(option_id > 0 && option_id <= 15, "Option id should be 1-15!");
        }


        string memory token_bucket;

        // base https://storage.googleapis.com/charitypops/Cards/

        
        // https://storage.googleapis.com/charitypops/Cards/Animal%20rescue/french%20bulldog%20(%20GoodPop%20)/1-200/FrenchBulldogJSON1.json
        // https://storage.googleapis.com/charitypops/Cards/Animal%20rescue/Bear%20(%20GreatPop%20)/1-100/BearJSON1.json
        // https://storage.googleapis.com/charitypops/Cards/Animal%20rescue/Dolphin%20(%20ExtremePop%20)/1-50/DolphinJSON1.json

        // https://storage.googleapis.com/charitypops/Cards/Autism/Ring%20(%20GoodPop%20)/1-200/RingJSON1.json
        // https://storage.googleapis.com/charitypops/Cards/Autism/DodeCahedron%20(GreatPop%20)/1-100/DodecahedronJSON1.json
        // https://storage.googleapis.com/charitypops/Cards/Autism/Red%20reverb%20(%20ExtremePop%20)/1-50/RedReverbJSON1.json

        // https://storage.googleapis.com/charitypops/Cards/Breast%20Cancer/Pink%20Ribbon%20(%20GoodPop%20)/1-200/PinkRibbonJSON1.json
        // https://storage.googleapis.com/charitypops/Cards/Breast%20Cancer/Pink%20Heart%20(%20GreatPop)/1-100/PinkHeartJSON1.json
        // https://storage.googleapis.com/charitypops/Cards/Breast%20Cancer/special%20pink%20(%20ExtremePop%20)/Cards/SpecialPinkJSON1.json

        // https://storage.googleapis.com/charitypops/Cards/Environment/Earth%20(%20GoodPop%20)/from%201-200/EarthJSON1.json
        // https://storage.googleapis.com/charitypops/Cards/Environment/Tree%20on%20Earth%20(%20GreatPop%20)/1-100/TreeOnEarthJSON1.json
        // https://storage.googleapis.com/charitypops/Cards/Environment/Whale%20(%20ExtremePop%20)/1-50/WhaleJSON1.json

        // https://storage.googleapis.com/charitypops/Cards/Hunger/Avocado%20(%20GoodPop%20)/1-200/AvocadoJSON1.json
        // https://storage.googleapis.com/charitypops/Cards/Hunger/Strawberry%20(%20GreatPop%20)/1-100/StrawberryJSON1.json
        // https://storage.googleapis.com/charitypops/Cards/Hunger/Watermelon%20(%20ExtremePop%20)/1-50/WatermelonJSON1.json

        if (option_id == 1) {
            token_bucket = "Animal%20rescue/french%20bulldog%20(%20GoodPop%20)/1-200/FrenchBulldogJSON";
        } else if (option_id == 2) {
            token_bucket = "Autism/Ring%20(%20GoodPop%20)/1-200/RingJSON";
        } else if (option_id == 3) {
            token_bucket = "Breast%20Cancer/Pink%20Ribbon%20(%20GoodPop%20)/1-200/PinkRibbonJSON";
        } else if (option_id == 4) {
            token_bucket = "Environment/Earth%20(%20GoodPop%20)/from%201-200/EarthJSON";
        } else if (option_id == 5) {
            token_bucket = "Hunger/Avocado%20(%20GoodPop%20)/1-200/AvocadoJSON";
        } else if (option_id == 6) {
            token_bucket = "Animal%20rescue/Bear%20(%20GreatPop%20)/1-100/BearJSON";
        } else if (option_id == 7) {
            token_bucket = "Autism/DodeCahedron%20(GreatPop%20)/1-100/DodecahedronJSON";
        } else if (option_id == 8) {
            token_bucket = "Breast%20Cancer/Pink%20Heart%20(%20GreatPop)/1-100/PinkHeartJSON";
        } else if (option_id == 9) {
            token_bucket = "Environment/Tree%20on%20Earth%20(%20GreatPop%20)/1-100/TreeOnEarthJSON";
        } else if (option_id == 10) {
            token_bucket = "Hunger/Strawberry%20(%20GreatPop%20)/1-100/StrawberryJSON";
        } else if (option_id == 11) {
            token_bucket = "Animal%20rescue/Dolphin%20(%20ExtremePop%20)/1-50/DolphinJSON";
        } else if (option_id == 12) {
            token_bucket = "Autism/Red%20reverb%20(%20ExtremePop%20)/1-50/RedReverbJSON";
        } else if (option_id == 13) {
            token_bucket = "Breast%20Cancer/special%20pink%20(%20ExtremePop%20)/Cards/SpecialPinkJSON";
        } else if (option_id == 14) {
            token_bucket = "Environment/Whale%20(%20ExtremePop%20)/1-50/WhaleJSON";
        } else if (option_id == 15) {
            token_bucket = "Hunger/Watermelon%20(%20ExtremePop%20)/1-50/WatermelonJSON";
        }

        
        CharityPops charityPops = CharityPops(nftAddress);

        for (uint256 i = 0; i < amount; i++) {
            supplyCounters[option_id]++;
            charityPops.factoryMint(_toAddress, supplyCounters[option_id], token_bucket);
        }
    }

    function supplyOfOption(uint256 optionId) public view returns (uint256){
        return supplyCounters[optionId];
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        address wallet = 0xF3387b479FB6C3E27ABE685E5c1C51F4aA0C0624;
        payable(wallet).transfer(balance);
    }
}