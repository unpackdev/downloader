// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


import "./Ownable.sol";

/*
interface MoonBoyzContract {

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}
*/
contract MoonPassContract {
    function ownerOf(uint) external view returns(address){}
    function balanceOf(address) external view returns(uint){}
    function safeTransferFrom(address, address, uint256) public {}
    function totalSupply() external view returns (uint){}
    function isApprovedForAll(address owner, address operator) external view returns (bool) {}
}
contract MoonBoyzContract {
    function ownerOf(uint) external view returns(address){}
    function balanceOf(address) external view returns(uint){}
    function safeTransferFrom(address, address, uint256) public {}
    function totalSupply() external view returns (uint){}
    function isApprovedForAll(address owner, address operator) external view returns (bool) {}
}

contract MoonShop is Ownable {

    struct SpecialTraitsInfos {
    uint256 id;
    string name;
    string category;
    uint256 moonpassNeeded;
    }


    mapping(uint256 => SpecialTraitsInfos) public specialTraitsById;

    mapping(uint256 => uint256) public itemsBought; // TokenId => ItemId

    event itemBought(uint indexed _tokenID, uint indexed _itemBought);


    MoonPassContract private moonPassContract;
    MoonBoyzContract private moonBoyzContract;
    address deadZone = address(0x000000000000000000000000000000000000dEaD);


    constructor(address _moonPassContract, address _moonBoyzContract ) {
        //MOON PASS CONTRACT - 0x9ba658650884fb36f3423d1ce2ee6d2a51361a99
        moonBoyzContract = MoonBoyzContract(_moonBoyzContract);
        moonPassContract = MoonPassContract(_moonPassContract);


        specialTraitsById[1] = SpecialTraitsInfos(1, "Crystals", "Ear", 1);
        specialTraitsById[2] = SpecialTraitsInfos(2, "Elf", "Ear", 1);
        specialTraitsById[3] = SpecialTraitsInfos(3, "Gundoom", "Ear", 1);
        specialTraitsById[4] = SpecialTraitsInfos(4, "Mustard", "Ear", 1);
        specialTraitsById[5] = SpecialTraitsInfos(5, "Punk", "Ear", 1);
        specialTraitsById[6] = SpecialTraitsInfos(6, "Upgrade 3000", "Ear", 1);
        specialTraitsById[7] = SpecialTraitsInfos(7, "Dimension Pockets", "Pocket", 5);
        specialTraitsById[8] = SpecialTraitsInfos(8, "Optical Pockets", "Pocket", 5);
        specialTraitsById[9] = SpecialTraitsInfos(9, "Useful Pockets", "Pocket", 5);
        specialTraitsById[10] = SpecialTraitsInfos(10, "Dimension Pack", "Backpack", 10);
        specialTraitsById[11] = SpecialTraitsInfos(11, "Blackhole", "Background", 2);
        specialTraitsById[12] = SpecialTraitsInfos(12, "Doppler", "Background", 2);
        specialTraitsById[13] = SpecialTraitsInfos(13, "Hexapod", "Background", 2);
        specialTraitsById[14] = SpecialTraitsInfos(14, "Light Speed", "Background", 2);
        specialTraitsById[15] = SpecialTraitsInfos(15, "Mind", "Background", 2);
        specialTraitsById[16] = SpecialTraitsInfos(16, "Prophecy", "Background", 2);
        specialTraitsById[17] = SpecialTraitsInfos(17, "Repere", "Background", 2);
        specialTraitsById[18] = SpecialTraitsInfos(18, "Stars", "Background", 2);
        specialTraitsById[19] = SpecialTraitsInfos(19, "Tabasko", "Background", 2);
        specialTraitsById[20] = SpecialTraitsInfos(20, "The Way", "Background", 2);


    }




  function TraitIdAtIndex(uint index) public view returns(uint256){
    return specialTraitsById[index].id ;
  }

  function MoonpassNeeededAtIndex(uint index) public view returns(uint256){
    return specialTraitsById[index].moonpassNeeded ;
  }

  function TraitNameAtIndex(uint index) public view returns(string memory){
    return specialTraitsById[index].name ;
  }

  function TraitCategoryAtIndex(uint index) public view returns(string memory){
    return specialTraitsById[index].category ;
  }




  function BuyItemWithMoonPass(uint _itemId, uint[] memory _moonPassIds, uint _moonBoyzTokenId) public {

    require(_moonPassIds.length <= MoonpassNeeededAtIndex(_moonBoyzTokenId), "not enough moonpass");
    require(moonPassContract.balanceOf(msg.sender) >= MoonpassNeeededAtIndex(_moonBoyzTokenId), "not enough moonpass");
    require(verifyOwnershipOfAll(_moonPassIds, msg.sender), "Not owner of All _moonPassIds");
      require(moonPassContract.isApprovedForAll(msg.sender, address(this)), "Moonpass is not approved For All");

      require(moonBoyzContract.ownerOf(_moonBoyzTokenId) == msg.sender, "Sender does not own this moonboyz");
      require(TraitIdAtIndex(_itemId) == _itemId, "This item does not exist");
      require(itemsBought[_moonBoyzTokenId] < 1, "An Item is already purchased For This MoonBoyz");

        for(uint i = 0; i < _moonPassIds.length; i++){
            moonPassContract.safeTransferFrom(msg.sender, deadZone, _moonPassIds[i]);
        }
        itemsBought[_moonBoyzTokenId] = _itemId;
        emit itemBought(_moonBoyzTokenId, _itemId);

  }


    function verifyOwnershipOfAll(uint[] memory _moonPassIds, address _owner) public view returns(bool){
            
        for(uint i = 0; i < _moonPassIds.length; i++){
         
            if(moonPassContract.ownerOf(_moonPassIds[i]) != _owner){
                return false;
            }

        }
        return true;

    }


    function modifyItem(uint _itemId, string memory _name, string memory _category, uint _moonpassNeeded) public onlyOwner{
    specialTraitsById[_itemId] = SpecialTraitsInfos(1, _name, _category, _moonpassNeeded);
    }

 
 
}