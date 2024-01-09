pragma solidity ^0.8.0;
/**
 * @title MegaToads contract
 * @dev Extends ERC721Enumerable Non-Fungible Token Standard basic implementation
 */

 /**
 *  SPDX-License-Identifier: UNLICENSED
 */

/*
   _____                    ___________               .___
  /     \   ____   _________\__    ___/________     __| _/______
 /  \ /  \_/ __ \ / ___\__  \ |    | /  _ \__  \   / __ |/  ___/
/    Y    \  ___// /_/  > __ \|    |(  <_> ) __ \_/ /_/ |\___ \ 
\____|__  /\___  >___  (____  /____| \____(____  /\____ /____  >
        \/     \/_____/     \/                 \/      \/    \/ 

 */

import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";

interface IfrogV2 {
    function ownerOf(uint tokenId) external view returns (address);
    function anim(uint tokenId) external view returns (uint);
    function getTrait(uint frogTokenId, uint traitType) external view returns (uint8);
    function burnForToads(uint frogTokenId) external;
}

interface IVoltV2 {
	function balanceOf(address user) external returns(uint);
    function spend(address user, uint256 amount) external;
    function mint(address to, uint256 amount) external;
}

contract MegaToadsV2 is ERC721EnumerableUpgradeable, OwnableUpgradeable{

    uint256 public constant MAX_TOADS = 1000;
    uint256 public constant NUM_TRAITS = 6;
    uint256 public constant MAX_SUPERS = 20;

    bool public saleIsActive;
    IfrogV2 public Frog;
    IVoltV2 public VOLTAGE;
    
    uint256 public numSupers;
    uint8[NUM_TRAITS][MAX_TOADS] internal toadTraits;
    string internal baseURI;

    /**
    * Frankenstein some thicc
    */
    function mintToad(uint[] memory frogIds, uint[] memory frogIndicesToUseForTraits) public {
        require(frogIds.length == 3, "Requires 3 frogs");
        require(frogIndicesToUseForTraits.length == 5, "Requires 5 frogs to use for traits.");
        require(saleIsActive, "Sale must be active to mint toad");
        require(totalSupply() + 1 <= MAX_TOADS, "Purchase would exceed max supply of toads");
        uint toadAnim = 0;
        for(uint i = 0; i < 5; i++){
            toadTraits[totalSupply()][i] = Frog.getTrait(frogIds[frogIndicesToUseForTraits[i]], i);
        }
        for(uint i = 0; i < 3; i++){
            uint frogAnim = Frog.anim(frogIds[i]);
            require(Frog.ownerOf(frogIds[i]) == msg.sender, "You do not own every frog");
            require(frogAnim > 0, "Not every frog has Melvin's Blessing");
            Frog.burnForToads(frogIds[i]);
            toadAnim += frogAnim - 1;
        }
        toadTraits[totalSupply()][5] = uint8(toadAnim);
        VOLTAGE.spend(msg.sender, (1000 + totalSupply() * 9) * (10 ** 18));
        _safeMint(msg.sender, totalSupply());
    }

    function getTraits(uint tokenId) public view returns (uint, uint, uint, uint, uint, uint) {
        require(_exists(tokenId), "ERC721Metadata: Trait query for nonexistent token");

        return (toadTraits[tokenId][0], 
            toadTraits[tokenId][1], 
            toadTraits[tokenId][2], 
            toadTraits[tokenId][3], 
            toadTraits[tokenId][4], 
            toadTraits[tokenId][5]
            );
    }

    function _setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function startSale() external onlyOwner {
        require(saleIsActive == false, "Sale is already started");
        saleIsActive = true;
    }

    function pauseSale() external onlyOwner {
        require(saleIsActive == true, "Sale is already paused");
        saleIsActive = false;
    }

    function setFrog(address FrogAddy) external onlyOwner {
		Frog = IfrogV2(FrogAddy);
	}

    function setVoltage(address VOLTaddy) external onlyOwner {
		VOLTAGE = IVoltV2(VOLTaddy);
	}

    function mintSupers(uint numOfSupers) external onlyOwner {
        numSupers += numOfSupers;
        for(uint j = 0; j < numOfSupers; j++){
            for(uint i = 0; i < 6; i++){
                toadTraits[totalSupply()][i] = uint8(100 + j);
            }
            _safeMint(owner(), totalSupply());
        }
    }

    function initialize() initializer public {
        __ERC721_init("MegaToads", "MT");
        __ERC721Enumerable_init();
        __Ownable_init();

        saleIsActive = false;
        VOLTAGE = IVoltV2(0xfFbF315f70E458e49229654DeA4cE192d26f9b25);
        Frog = IfrogV2(0xd668A2E001f3385B8BBC5a8682AC3C0D83C19122);
        _setBaseURI("https://api.supducks.com/megatoads/metadata/");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function updateToads(uint[] calldata tokenIds, uint[] calldata traitIds, uint8[] calldata traits) external onlyOwner {
        require(tokenIds.length == traitIds.length && tokenIds.length == traits.length, "invalid args");
        for(uint i = 0; i < tokenIds.length; i++){
            toadTraits[tokenIds[i]][traitIds[i]] = traits[i];
        }
    }
}
