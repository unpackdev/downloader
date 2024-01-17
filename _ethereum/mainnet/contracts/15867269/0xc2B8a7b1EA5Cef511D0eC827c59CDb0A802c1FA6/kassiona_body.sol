// SPDX-License-Identifier: MIT

//   _  __             _                    
//  | |/ /__ _ ___ ___(_) ___  _ __   __ _  
//  | ' // _` / __/ __| |/ _ \| '_ \ / _` | 
//  | . \ (_| \__ \__ \ | (_) | | | | (_| | 
//  |_|\_\__,_|___/___/_|\___/|_| |_|\__,_| 



pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";

contract KassionaBody is ERC721Enumerable,ERC721Burnable, Ownable {

    enum Rarity { Legendary,Epic,Rare,Common }
    enum Property { Ubinooa,Kiwanna,Busterra }

    uint256 public constant maxTokenSupply = 7779;
    uint256 public constant legedarySupplyPerProperty = 3;
    uint256 public constant epicSupplyPerProperty = 130;
    uint256 public constant rareSupplyPerProperty = 700;
    uint256 public constant commonSupplyPerProperty = 1760;

    address public admin; 

    string private _baseURIextended;

    // variable for weighted fisher–yates shuffle algorithm
    mapping(Rarity => mapping(uint => uint)) private _availableTokensOfRarity;
    mapping(Rarity =>uint) private _remainSupplyOfRarity;
    mapping(Rarity =>uint[]) private _randomWeight;
    mapping(Rarity =>uint[]) private _randomWeightSum;
    mapping(Rarity =>uint) private _randomWeightTotal;

    constructor() ERC721("BoovsBODY", "KABB") {
        _remainSupplyOfRarity[Rarity.Legendary] = 9;
        _remainSupplyOfRarity[Rarity.Epic] = 390;
        _remainSupplyOfRarity[Rarity.Rare] = 2100;
        _remainSupplyOfRarity[Rarity.Common] = 5280;

        _randomWeight[Rarity.Legendary] = [20,10,5,1];
        _randomWeight[Rarity.Epic] = [15,8,4,1];
        _randomWeight[Rarity.Rare] = [8,4,2,1];
        _randomWeight[Rarity.Common] = [1,1,1,1];

        _randomWeightSum[Rarity.Legendary] = [_randomWeight[Rarity.Legendary][0]*legedarySupplyPerProperty*3,_randomWeight[Rarity.Legendary][1]*epicSupplyPerProperty*3,_randomWeight[Rarity.Legendary][2]*rareSupplyPerProperty*3,_randomWeight[Rarity.Legendary][3]*commonSupplyPerProperty*3];
        _randomWeightSum[Rarity.Epic] = [_randomWeight[Rarity.Epic][0]*legedarySupplyPerProperty*3,_randomWeight[Rarity.Epic][1]*epicSupplyPerProperty*3,_randomWeight[Rarity.Epic][2]*rareSupplyPerProperty*3,_randomWeight[Rarity.Epic][3]*commonSupplyPerProperty*3];
        _randomWeightSum[Rarity.Rare] = [_randomWeight[Rarity.Rare][0]*legedarySupplyPerProperty*3,_randomWeight[Rarity.Rare][1]*epicSupplyPerProperty*3,_randomWeight[Rarity.Rare][2]*rareSupplyPerProperty*3,_randomWeight[Rarity.Rare][3]*commonSupplyPerProperty*3];
        _randomWeightSum[Rarity.Common] = [_randomWeight[Rarity.Common][0]*legedarySupplyPerProperty*3,_randomWeight[Rarity.Common][1]*epicSupplyPerProperty*3,_randomWeight[Rarity.Common][2]*rareSupplyPerProperty*3,_randomWeight[Rarity.Common][3]*commonSupplyPerProperty*3];
        
        _randomWeightTotal[Rarity.Legendary] = _randomWeightSum[Rarity.Legendary][0]+_randomWeightSum[Rarity.Legendary][1]+_randomWeightSum[Rarity.Legendary][2]+_randomWeightSum[Rarity.Legendary][3];
        _randomWeightTotal[Rarity.Epic] = _randomWeightSum[Rarity.Epic][0]+_randomWeightSum[Rarity.Epic][1]+_randomWeightSum[Rarity.Epic][2]+_randomWeightSum[Rarity.Epic][3];
        _randomWeightTotal[Rarity.Rare] = _randomWeightSum[Rarity.Rare][0]+_randomWeightSum[Rarity.Rare][1]+_randomWeightSum[Rarity.Rare][2]+_randomWeightSum[Rarity.Rare][3];
        _randomWeightTotal[Rarity.Common] = _randomWeightSum[Rarity.Common][0]+_randomWeightSum[Rarity.Common][1]+_randomWeightSum[Rarity.Common][2]+_randomWeightSum[Rarity.Common][3];
    }

    function ownerMint(uint256 tokenId) external onlyOwner {
        _safeMint(_msgSender(),tokenId);

        Rarity rarity = _tokenRarity(tokenId);
        _remainSupplyOfRarity[rarity] -= 1;
        uint256 lastValInArray = _availableTokensOfRarity[rarity][_remainSupplyOfRarity[rarity]];
        for(uint i=0;i<4;i++) {
            _randomWeightSum[Rarity(i)][uint(rarity)] -= _randomWeight[Rarity(i)][uint(rarity)];
            _randomWeightTotal[Rarity(i)] -= _randomWeight[Rarity(i)][uint(rarity)];
        }
        if (lastValInArray == 0) {
                _availableTokensOfRarity[rarity][_getRarityIndexByTokenId(tokenId)] = _remainSupplyOfRarity[rarity];
            } else {
                _availableTokensOfRarity[rarity][_getRarityIndexByTokenId(tokenId)] = lastValInArray;
            }
    }

    function mint(address addr,uint8 rarity) external {
        require(_msgSender() == admin || _msgSender() == owner(),"only admin or owner can mint");
        require(totalSupply() + 1 <= maxTokenSupply, "Cannot exceed total supply");
        _safeMint(addr,_getRandomTokenToMint(Rarity(rarity)));
    }

    function setAdmin(address admin_) external onlyOwner{
        admin = admin_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function isApprovedForAll(address account, address operator) public override(ERC721,IERC721) view returns (bool) {
        if (operator == admin) {
            return true;
        }

        return super.isApprovedForAll(account, operator);
    }

    function tokenProperty(uint256 tokenId) external pure returns (uint8){
        if(tokenId>=1 && tokenId<=2593) {
            return uint8(Property.Ubinooa);
        }else if(tokenId<=5186){
            return uint8(Property.Kiwanna);
        }else{
            return uint8(Property.Busterra);
        }
    }

    function tokenRarity(uint256 tokenId) external pure returns (uint8){
        uint256 propertyIndex = (tokenId-1)%2593 + 1;
        if(propertyIndex>=1 && propertyIndex<=3) {
            return uint8(Rarity.Legendary);
        }else if(propertyIndex<=133){
            return uint8(Rarity.Epic);
        }else if(propertyIndex<=833){
            return uint8(Rarity.Rare);
        }else{
            return uint8(Rarity.Common);
        }
    }

    function _tokenRarity(uint256 tokenId) internal  pure returns (Rarity){
        uint256 propertyIndex = (tokenId-1)%2593 + 1;
        if(propertyIndex>=1 && propertyIndex<=3) {
            return Rarity.Legendary;
        }else if(propertyIndex<=133){
            return Rarity.Epic;
        }else if(propertyIndex<=833){
            return Rarity.Rare;
        }else{
            return Rarity.Common;
        }
    }

    function tokenURIsOfOwner(address owner) public view  returns (string[] memory) {
        uint balance = balanceOf(owner); 
        string[] memory ret = new string[](balance);
        for(uint i=0;i<balance;i++) {
            ret[i] = tokenURI(tokenOfOwnerByIndex(owner, i));
        }
        return ret;
    }

    function tokenIdsOfOwner(address owner) public view  returns (uint256[] memory) {
        uint balance = balanceOf(owner); 
        uint256[] memory ret = new uint256[](balance);
        for(uint i=0;i<balance;i++) {
            ret[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ret;
    }

    function _random(uint256 nonce) private view returns (uint256){
        return uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,nonce)));
    }


    // weighted fisher–yates shuffle algorithm
    function _getRandomTokenToMint(Rarity rarity) private returns (uint256) {
        uint256 rd = _random(_randomWeightTotal[rarity])%_randomWeightTotal[rarity];
        Rarity randomRarity;

        for(uint i=0;i<4;i++) {
            if(rd<_randomWeightSum[rarity][i]) {
                randomRarity = Rarity(i);
                break;
            }else{
                rd -= _randomWeightSum[rarity][i];
            }
        }

        uint256 indexToUse = _random(_remainSupplyOfRarity[randomRarity])%_remainSupplyOfRarity[randomRarity];

        _remainSupplyOfRarity[randomRarity] -= 1;
        for(uint i=0;i<4;i++) {
            _randomWeightSum[Rarity(i)][uint(randomRarity)] -= _randomWeight[Rarity(i)][uint(randomRarity)];
            _randomWeightTotal[Rarity(i)] -= _randomWeight[Rarity(i)][uint(randomRarity)];
        }

        uint256 valAtIndex = _availableTokensOfRarity[randomRarity][indexToUse];
        if(valAtIndex==0) {
            valAtIndex = indexToUse;
        }

        uint256 lastIndex = _remainSupplyOfRarity[randomRarity];

        if(indexToUse!=lastIndex) {
            uint256 lastValInArray = _availableTokensOfRarity[randomRarity][lastIndex];
            if (lastValInArray == 0) {
                _availableTokensOfRarity[randomRarity][indexToUse] = lastIndex;
            } else {
                _availableTokensOfRarity[randomRarity][indexToUse] = lastValInArray;
            }
        }

        return _getTokenIdByRarityIndex(randomRarity,valAtIndex);
    }

    function _getTokenIdByRarityIndex(Rarity rarity,uint256 index) internal pure returns (uint256) {
        if(rarity == Rarity.Legendary) {
            return index%3+(index/3)*2593+1;
        }else if(rarity == Rarity.Epic) {
            return index%130+3+(index/130)*2593+1;
        }else if(rarity == Rarity.Rare) {
            return index%700+133+(index/700)*2593+1;
        }else{
            return index%1760+833+(index/1760)*2593+1;
        }
    }

    function _getRarityIndexByTokenId(uint256 tokenId) internal pure returns (uint256) {
        Rarity rarity = _tokenRarity(tokenId);
        if(rarity == Rarity.Legendary) {
            return (tokenId-1)/2593*3+(tokenId-1)%2593;
        }else if(rarity == Rarity.Epic) {
            return (tokenId-1)/2593*130+(tokenId-1)%2593-3;
        }else if(rarity == Rarity.Rare) {
            return (tokenId-1)/2593*700+(tokenId-1)%2593-133;
        }else{
            return (tokenId-1)/2593*1760+(tokenId-1)%2593-833;
        }
    }
}