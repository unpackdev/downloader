// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";

interface WolfPups {
    function mint(uint quantity, address receiver) external payable;
    function totalSupply() external returns (uint);
}

contract WolfBreed is Ownable {
    IERC20 _wolfpawn = IERC20(0xB1838B5059B6Ca3696bb9833c31Fdb4671191945);
    IERC721 _wolfgang = IERC721(0xC269bDD2975a3D5B23B315dD83B82FDfbf4Ac4d9);
    IERC721 _lunawolf = IERC721(0xc852675BB88c8E41341C20D98A18Dd0C1E5B9249);
    WolfPups _pups = WolfPups(0xE916AaEbC2b0f9566b463BaBe6Fb0270Ad9Ec395);
    
    mapping(uint => bool) public tokenIdToBreededWolf;
    mapping(uint => bool) public tokenIdToBreededLuna;
    uint public breedingFee = 2 ether;
    
    event BreedWolves(uint wolfTokenId, uint lunaTokenId, uint newPupId, address owner);
    
    function breed(uint wolfTokenId, uint lunaTokenId) public {
        require(!tokenIdToBreededLuna[lunaTokenId], "luna already breeded");
        require(!tokenIdToBreededWolf[wolfTokenId], "wolf already breeded");
        require(_lunawolf.ownerOf(lunaTokenId) == msg.sender, "caller does not have this luna");
        require(_wolfgang.ownerOf(wolfTokenId) == msg.sender, "caller does not have this wolf");
        
        tokenIdToBreededLuna[lunaTokenId] = true;
        tokenIdToBreededWolf[wolfTokenId] = true;
        
        _wolfpawn.transferFrom(msg.sender, address(this), breedingFee);
        
        uint pupId = _pups.totalSupply();
        _pups.mint(1, msg.sender);
        
        emit BreedWolves(wolfTokenId, lunaTokenId, pupId, msg.sender);
    }
    
    function setBreedingFee(uint newFee) external onlyOwner {
        breedingFee = newFee;
    }
}