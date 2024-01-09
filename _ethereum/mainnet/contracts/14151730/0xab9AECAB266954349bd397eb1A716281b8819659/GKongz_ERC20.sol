// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

interface iGuardianKongz {
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
    function balanceOf(address account) external view returns (uint256);
}

contract GuardianKongzToken is ERC20, Ownable {
    address private GuardianKongz = 0x5E90bB26A930038d7c139cA6a39CB1b5dA8e5f60;

    uint256 public productIndex = 1;

    bool claimPaused = true;

    uint256 constant private GEN_LEG_BASE = 50 ether;
    uint256 constant private GEN_BASE = 30 ether;
    uint256 constant private LEG_BASE = 10 ether;
    uint256 constant private ORI_BASE = 2 ether;

    uint256 private START_TIME = 1643673600; // GMT: Tuesday, 1 February 2022 00:00:00

    mapping(uint256 => uint256) public lastClaim;
    mapping(uint256 => bool) public isLegendary;

      struct Products {
        string name;
        uint256 price;
        uint256 quantity;
        uint256 limit;
    }

    mapping(uint256 => Products) public shopProducts;
    mapping(address => mapping(uint256 => uint256)) public userInventory;

    constructor() ERC20("gkongz", "GKONGZ") {}

    function getBaseRate(uint256 _id) private view returns (uint256) {
        if(_id > 0 && _id < 223) {
            if(isLegendary[_id]) {
                return GEN_LEG_BASE;
            }
            return GEN_BASE;
        }
        if(isLegendary[_id]){
            return LEG_BASE;
        }
        return ORI_BASE;
    }

    function getClaimableRewards(uint256[] memory _id) public view returns (uint256) {
        uint256 rewards = 0;
        uint256 baseRate;

        for (uint256 i = 0; i < _id.length; i++) {
            uint256 id = _id[i];
            baseRate = getBaseRate(id);
            rewards = rewards + (baseRate * (block.timestamp - (lastClaim[id] > START_TIME ? lastClaim[id] : START_TIME)) / 86400);
        }
        return rewards;
    }

    function claimReward() external {
        require(!claimPaused, "Claiming reward has been paused");

        uint256[] memory KongzId = iGuardianKongz(GuardianKongz).walletOfOwner(msg.sender);

        uint256 claimAmount = getClaimableRewards(KongzId);
        _mint(msg.sender, claimAmount);

        for (uint256 j = 0; j < KongzId.length; j++) {
            lastClaim[KongzId[j]] = block.timestamp;
        }
    }

    function flipReward() external onlyOwner {
        claimPaused = !claimPaused;
    }

    function setLegendary(uint256[] memory _tokenId) external onlyOwner {
        for (uint256 i = 0; i < _tokenId.length; i++){
            isLegendary[_tokenId[i]] = true;
        }
    }

    function buy(uint256 _index, uint256 _qty) external {
        uint256 NFTOwned = iGuardianKongz(GuardianKongz).balanceOf(msg.sender);
        uint256 TokenOwned = balanceOf(msg.sender);
        
        require(NFTOwned > 0, "NFT, Not eligible");
        require(TokenOwned > 0, "Token, Not eligible");
        require(TokenOwned >= shopProducts[_index].price, "Insufficient $GKongz!");
        require(shopProducts[_index].quantity >= _qty, "No stock!");
        require(userInventory[msg.sender][_index] + _qty <= shopProducts[_index].limit, "Over limit");

        _burn(msg.sender, shopProducts[_index].price * _qty);
        shopProducts[_index].quantity -= _qty;
        userInventory[msg.sender][_index] += _qty;
    }

    function addNewProduct(string memory _name, uint256 _price, uint256 _quantity, uint256 _limit) external onlyOwner {
        shopProducts[productIndex].name = _name;
        shopProducts[productIndex].price = _price;
        shopProducts[productIndex].quantity = _quantity;
        shopProducts[productIndex].limit = _limit;
        productIndex++;
    }
}