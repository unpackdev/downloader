// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Ownable.sol";

import "./IERC20.sol";

import "./Tube.sol";
import "./SpaceShips.sol";

contract NFTCashback is Ownable {
    // model => cashback amount
    mapping(uint256 => uint256) private _approvedModels;
    // tokenId => bool
    mapping(uint256 => uint256) private _redeemed;

    uint256 public baseAmount = 15 * 1e18;

    SpaceShips public nft;
    Tube public tube;
    IERC20 public must;

    uint256 public mythicMultiplier = 100;
    uint256 public rareMultiplier  = 20;
    uint256 public uncommonMultiplier = 5;
    uint256 public commonMultiplier = 1;

    uint256 private constant MYTHIC_SUPPLY = 3;
    uint256 private constant RARE_SUPPLY = 10;
    uint256 private constant UNCOMMON_SUPPLY = 100;


    constructor(address owner, address _nft, address _tube, address _must) public {
      nft = SpaceShips(_nft);
      tube = Tube(_tube);
      must = IERC20(_must);

      transferOwnership(owner);
    }

    function amount(uint256 tokenId) public view returns (uint256) {
      uint256 model = tokenId / nft.ID_TO_MODEL();
      if (_approvedModels[model] == 0 || _redeemed[tokenId] != 0) {
        return 0;
      }
      uint256 supply = nft.supply(model);
      uint256 finalAmount = baseAmount;
      if (supply <= MYTHIC_SUPPLY) {
        finalAmount = finalAmount * mythicMultiplier;
      } else if (supply <= RARE_SUPPLY) {
        finalAmount = finalAmount * rareMultiplier;
      } else if (supply <= UNCOMMON_SUPPLY) {
        finalAmount = finalAmount * uncommonMultiplier;
      } else {
        finalAmount = finalAmount * commonMultiplier;
      }
      return finalAmount;
    }

    function cashback(uint256 tokenId) external {
        require(
            nft.ownerOf(tokenId) == msg.sender,
            "NFTCashback: sender is not owner"
        );

        uint256 cashbackAmount = amount(tokenId);
        require(
            cashbackAmount > 0,
            "NFTCashback: no cashback for this token"
        );

        _redeemed[tokenId] = 1;

        must.approve(address(tube), cashbackAmount);

        // this will fail if the contract doesn't hold enough must
        tube.enterFor(msg.sender, cashbackAmount);
    }

    function setBaseAmount(uint256 newAmount) external onlyOwner {
        baseAmount = newAmount;
    }

    function setCommonMultiplier(uint256 multiplier) external onlyOwner {
      commonMultiplier = multiplier;
    }

    function setUncommonMultiplier(uint256 multiplier) external onlyOwner {
      uncommonMultiplier = multiplier;
    }

    function setRareMultiplier(uint256 multiplier) external onlyOwner {
      rareMultiplier = multiplier;
    }

    function setMythicMultiplier(uint256 multiplier) external onlyOwner {
      mythicMultiplier = multiplier;
    }

    function allowSpaceships(uint256[] calldata models) external onlyOwner {
        uint256 length = models.length;
        for (uint256 i = 0; i < length; i++) {
          _approvedModels[models[i]] = 1;
        }
    }

    function withdraw() external onlyOwner {
      uint256 balance = must.balanceOf(address(this));
      must.transfer(msg.sender, balance);
    }
}
