pragma solidity ^0.8.0;
/**
 * @title SupDucks contract
 * @dev Extends ERC721Enumerable Non-Fungible Token Standard basic implementation
 */

 /**
 *  SPDX-License-Identifier: UNLICENSED
 */

/*
                       .-~-.
                     .'     '.
                    /         \
            .-~-.  :           ;
          .'     '.|           |
         /         \           :
        :           ; .-~""~-,/
        |           /`        `'.
        :          |             \
         \         |             /
          `.     .' \          .'
     Sup    `~~~`    '-.____.-'
 */

import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract SupDucks is ERC721EnumerableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 public constant duckPrice = 100000000000000000; //0.10 ETH
    uint256 public constant duckTriplePrice = 240000000000000000; //0.24 ETH
    uint256 public constant duckSquadPrice = 700000000000000000; //0.70 ETH

    uint256 public constant MAX_DUCKS = 10000;
    uint256 public constant PROMO_SPACE = 50;
    uint256 public constant NUM_TRAITS = 6;
    uint256 public constant NUM_SUPERS = 9;

    bool public saleIsActive;
    
    uint16[NUM_SUPERS + 1] internal superStock;
    uint16[][NUM_TRAITS] internal traitProbs; 
    uint8[][NUM_TRAITS] internal traitAliases;
    uint8[NUM_TRAITS][MAX_DUCKS + PROMO_SPACE] internal duckTraits;
    mapping (uint256 => string) internal IPFS_CIDs;
    string internal baseURI;
    uint256 internal numPromos;
    uint256 internal nonce;
    address internal splitterAddress;

    function initialize(
    uint16[] memory background_p, uint8[] memory background_a,
    uint16[] memory skin_p, uint8[] memory skin_a,
    uint16[] memory clothes_p, uint8[] memory clothes_a,
    uint16[] memory hats_p, uint8[] memory hats_a,
    uint16[] memory mouth_p, //uint8[] memory mouth_a,
    uint16[] memory eyes_p, uint8[] memory eyes_a) initializer public {
        __ERC721_init("SupDucks", "SD");
        __ERC721Enumerable_init();
        __Ownable_init();
        __ReentrancyGuard_init();

        /**
        * Some duck gene magic
        */
        traitProbs[0] = background_p;
        traitProbs[1] = skin_p;
        traitProbs[2] = clothes_p;
        traitProbs[3] = hats_p;
        traitProbs[4] = mouth_p;
        traitProbs[5] = eyes_p;
        traitAliases[0] = background_a;
        traitAliases[1] = skin_a;
        traitAliases[2] = clothes_a;
        traitAliases[3] = hats_a;
        traitAliases[4] = [
            1,  2,  3,  4, 5, 6, 7, 8,
            9, 10, 11, 12, 0, 0, 0, 0,
            1,  1,  2,  2, 3, 4, 5, 6,
            7,  8,  9
        ];
        traitAliases[5] = eyes_a;

        saleIsActive = false;
        nonce = 12;
        numPromos = 0;
        splitterAddress = 0xA18a2078D44C93867dB711ed80C0E2784BB3c8d3;
        superStock = [uint16(MAX_DUCKS - NUM_SUPERS), 1, 1, 1, 1, 1, 1, 1, 1, 1];
        _setBaseURI("ipfs://");
     }

    function pauseSale() public onlyOwner {
        require(saleIsActive == true, "sale is already paused");
        saleIsActive = false;
    }

    function startSale() public onlyOwner {
        require(saleIsActive == false, "sale is already started");
        saleIsActive = true;
    }

    /**
     * Lay some eggs
     */
    function artificialEggFertilization(uint numberOfTokens) public onlyOwner {
        _mintDuck(numberOfTokens, owner());
    }

    function mintPromo() public onlyOwner {
        _safeMint(owner(), totalSupply());
        createSuper(totalSupply() - 1, ++numPromos + NUM_SUPERS);
    }

    function _mintDuck(uint numberOfTokens, address sender) internal {
        for(uint i = 0; i < numberOfTokens; i++) {
            uint seed = uint(keccak256(abi.encodePacked(nonce, block.difficulty, block.timestamp, sender)));
            uint mintIndex = totalSupply();
            addTraits(seed, mintIndex);
            _safeMint(sender, mintIndex);
        }
    }

    /**
    * Mint some ducks
    */
    function mintDuck(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Duck");
        require(numberOfTokens <= 10, "Can only mint 10 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_DUCKS, "Purchase would exceed max supply of Ducks");
        require(duckPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        _mintDuck(numberOfTokens, msg.sender);
    }

    /** 
    * Discounted duck nests
    */
    function mintThreeDucks() public payable {
        require(saleIsActive, "Sale must be active to mint Duck");
        require(totalSupply().add(3) <= MAX_DUCKS, "Purchase would exceed max supply of Ducks");
        require(duckTriplePrice <= msg.value, "Ether value sent is not correct");

        _mintDuck(3, msg.sender);
    }

    function mintTenDucks() public payable {
        require(saleIsActive, "Sale must be active to mint Duck");
        require(totalSupply().add(10) <= MAX_DUCKS, "Purchase would exceed max supply of Ducks");
        require(duckSquadPrice <= msg.value, "Ether value sent is not correct");

        _mintDuck(10, msg.sender);
    }

    function getTraits(uint tokenId) public view returns (uint, uint, uint, uint, uint, uint){
        require(_exists(tokenId), "ERC721Metadata: Trait query for nonexistent token");
        require(bytes(IPFS_CIDs[tokenId]).length > 0 || _msgSender() == owner(), "Unauthorized");

        return (duckTraits[tokenId][0], 
            duckTraits[tokenId][1], 
            duckTraits[tokenId][2], 
            duckTraits[tokenId][3], 
            duckTraits[tokenId][4], 
            duckTraits[tokenId][5]
            );
    }

    function determineTrait(uint8 traitType, uint seed) internal view returns (uint8){
        uint8 i = uint8(uint(keccak256(abi.encodePacked(nonce, seed++))) % traitProbs[traitType].length);
        return uint(keccak256(abi.encodePacked(nonce, seed))) % 10000 <= uint(traitProbs[traitType][i]) ? i : traitAliases[traitType][i];
    }

    function addTraits(uint seed, uint tokenId) internal {
        for(uint8 i = 0; i < NUM_TRAITS; i++){            
            nonce++;
            duckTraits[tokenId][i] = determineTrait(i, seed);
        }

        /**
        * GOOD LUCK
        */
        checkForSuper(tokenId, seed);
    }

    function checkForSuper(uint tokenId, uint seed) internal {
        uint16 roll = uint16(seed % (MAX_DUCKS - totalSupply()));
        for(uint8 i = 0; i < NUM_SUPERS + 1; i++){
           if(roll < superStock[i]){
                superStock[i]--;
                if(i > 0){
                    createSuper(tokenId, i);
                }
                return;
            }
            roll -= superStock[i];
        }
        revert('duck pit');
    }


    function createSuper(uint tokenId, uint superId) internal {
        for(uint8 i = 0; i < NUM_TRAITS; i++){            
            duckTraits[tokenId][i] = uint8(99 + superId);
        }
    }

    function withdraw() public {
        uint balance = address(this).balance;
        payable(splitterAddress).transfer(balance);
    }

    function _setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setTokenCID(uint tokenId, string memory tokenCID) public onlyOwner{
        IPFS_CIDs[tokenId] = tokenCID;
    }

    function setTokenCIDs(uint[] memory tokenIds, string[] memory tokenCIDs) public onlyOwner{
        require(tokenIds.length <= 100, "Limit 100 tokenIds");
        for(uint i = 0; i < tokenIds.length; i++){
            IPFS_CIDs[tokenIds[i]] = tokenCIDs[i];
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(IPFS_CIDs[tokenId]).length > 0 ? string(abi.encodePacked(baseURI, IPFS_CIDs[tokenId])) : "ipfs://QmVXMMj5eBikicjViQLtqJDVVgupbFr3miFeo2pZmCX2kC";
    }
}
