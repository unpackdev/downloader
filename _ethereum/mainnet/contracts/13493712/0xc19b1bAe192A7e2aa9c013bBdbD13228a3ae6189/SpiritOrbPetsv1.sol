// SPDX-License-Identifier: MIT
//
// Spirit Orb Pets v1 Pets Contract
// Developed by:  Heartfelt Games LLC
//
// Version 1 - the "child form" of the Spirit Orb Pets.  These are the
// base-level NFTs that are able to be interacted with via approved external
// contracts.  Over time, they will level up and award CARE tokens through
// interactions, eventually leading to their evolution into v2 Spirit Orb Pets.
//

pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

interface ISpiritOrbPetsv0 is IERC721, IERC721Enumerable {

}

contract SpiritOrbPetsv1 is ERC721Enumerable, Ownable {

    string _baseTokenURI;
    uint256 private _price = 0.07 ether;
    bool public _paused = true;
    ISpiritOrbPetsv0 public SOPv0;

    // Contracts allowed to change pet variables
    // i.e. Pet Care contract
    address[] public _approvedContracts;

    // Whitelist variables
    bool public _whitelistPaused = true;
    mapping(uint256 => bool) private _claimedMintList;

    // Maximum amount of Pets in existance.
    uint256 public constant MAX_PET_SUPPLY = 7777;

    // Maximum pet level for v1 pets
    uint8 public constant MAX_PET_LEVEL = 30; // about 1 month of natural play

    // Events
    event Minted(address sender, uint256 numberOfPets);

    struct Pet {
      uint16 id; // max possible is 65535, but will only to go 7777
      uint8 level; // max possble is 255, but will only go to 30
      bool active;
      uint64 cdPlay; // uint64 in case people want to play past 2038?
      uint64 cdFeed; // sorry humans of year 2,147,485,547 AD...
      uint64 cdClean;
      uint64 cdTrain;
      uint64 cdDaycare;
    }

    // Separated from pet struct to decrease gas price on mint
    // Mapped to pet's id
    mapping(uint16 => string) public petName;

    // Mapping of all pet objects to their id
    mapping(uint16 => Pet) public pets;


    /**
    * @dev Get info on the pet's level and if the pet is currently active.
    * @dev Note that the level could be innacurate if read from here for purposes
    * @dev of front-end display. Try using a getTrueLevel() function like the one
    * @dev from the PetCare contract for the level the pet should have after level-down
    * @dev effects are applied.
    */
    function getPetInfo(uint16 id) external view returns (
        uint8 level,
        bool active
        ) {
      return (
        pets[id].level,
        pets[id].active
      );
    }

    function getPetCooldowns(uint16 id) external view returns (
        uint64 cdPlay,
        uint64 cdFeed,
        uint64 cdClean,
        uint64 cdTrain,
        uint64 cdDaycare
      ) {
      return (
      pets[id].cdPlay,
      pets[id].cdFeed,
      pets[id].cdClean,
      pets[id].cdTrain,
      pets[id].cdDaycare
      );
    }

    /**
    * @dev This adds new contracts to the list that is allowed to change pet data
    */
    function addApprovedContract(address addr) external onlyOwner {
      _approvedContracts.push(addr);
    }

    function removeApprovedContract(uint index) external onlyOwner {
      _approvedContracts[index] = _approvedContracts[_approvedContracts.length - 1];
      _approvedContracts.pop();
    }

    function getApprovedContractList() external view returns (address[] memory) {
      return _approvedContracts;
    }

    function isApproved(address addr) internal view returns (bool) {
      bool approved = false;
      for (uint i = 0; i < _approvedContracts.length; i++) {
        if (_approvedContracts[i] == addr) approved = true;
      }
      return approved;
    }

    /**
    * @dev Throws if called by any account other than the ones in the approved list.
    */
    modifier inApprovedContractList() {
      require(isApproved(msg.sender), "Sender must be from approved contract list.");
      _;
    }

    // setters for external contracts that are approved to interact with this contract

    function setPetName(uint16 id, string memory name) external inApprovedContractList {
      petName[id] = name;
    }

    function setPetLevel(uint16 id, uint8 level) external inApprovedContractList {
      pets[id].level = level;
    }

    function setPetActive(uint16 id, bool active) external inApprovedContractList {
      pets[id].active = active;
    }

    function setPetCdPlay(uint16 id, uint64 cdPlay) external inApprovedContractList {
      pets[id].cdPlay = cdPlay;
    }

    function setPetCdFeed(uint16 id, uint64 cdFeed) external inApprovedContractList {
      pets[id].cdFeed = cdFeed;
    }

    function setPetCdClean(uint16 id, uint64 cdClean) external inApprovedContractList {
      pets[id].cdClean = cdClean;
    }

    function setPetCdTrain(uint16 id, uint64 cdTrain) external inApprovedContractList {
      pets[id].cdTrain = cdTrain;
    }

    function setPetCdDaycare(uint16 id, uint64 cdDaycare) external inApprovedContractList {
      pets[id].cdDaycare = cdDaycare;
    }

    function getPausedState() external view returns (bool) {
      return _paused;
    }

    function getMaxPetLevel() external pure returns (uint8) {
      return MAX_PET_LEVEL;
    }

    constructor() ERC721("Spirit Orb Pets v1", "SOPV1") {

    }

    /*
    * @dev Creates a pet with default data
    */
    function createPet(uint16 id) internal {
      pets[id] = Pet(id, 1, false, 0, 0, 0, 0, 0);
    }

    /*
    * @dev Allows owners of v0 pets to mint one v1 pet per v0 pet they own
    * @dev during the whitelist period. If this privilege isn't used during
    * @dev this time, the slot is not saved for future minting.
    */
    function mintPetWhitelisted(uint256[] memory petIdsToClaimFor) public payable {
      uint256 supply = totalSupply();
      require(!_whitelistPaused, "Whitelisted pet adoption has not yet begun.");
      require(supply < MAX_PET_SUPPLY, "Adoption has already ended.");

      uint256 numberOfPets = 0;

      for (uint i = 0; i < petIdsToClaimFor.length; i++) {
        require(msg.sender == SOPv0.ownerOf(petIdsToClaimFor[i]), "You don't own this pet");
        require(!_claimedMintList[petIdsToClaimFor[i]], "You have already claimed a mint for this pet!");
        numberOfPets++;
        _claimedMintList[petIdsToClaimFor[i]] = true;
      }

      require(supply + numberOfPets <= MAX_PET_SUPPLY, "Exceeds maximum Pets available. Please try to adopt less Pets.");
      require(_price * numberOfPets == msg.value, "Amount of Ether sent is not correct.");

      // Mint the amount of provided Pets.
      for (uint i = 0; i < numberOfPets; i++) {
        _safeMint(msg.sender, supply + i);
        createPet(uint16(supply + i));
      }

      emit Minted(msg.sender, numberOfPets);
    }

    /**
    * @dev Checks to see if a v0 pet claim has been taken yet.  Returns true if it has been taken
    */
    function hasV0PetClaimedWhitelist(uint16 petNumber) public view returns (bool) {
      return _claimedMintList[petNumber];
    }

    function mintPet(uint256 numberOfPets) public payable {
      uint256 supply = totalSupply();
      require(!_paused, "Pet adoption has not yet begun.");
      require(supply < MAX_PET_SUPPLY, "Adoption has already ended.");
      require(numberOfPets > 0, "You cannot adopt 0 Pets.");
      require(numberOfPets <= 7, "You are not allowed to adopt this many Pets at once.");
      require(supply + numberOfPets <= MAX_PET_SUPPLY, "Exceeds maximum Pets available. Please try to adopt less Pets.");
      require(_price * numberOfPets == msg.value, "Amount of Ether sent is not correct.");

      // Mint the amount of provided Pets.
      for (uint i = 0; i < numberOfPets; i++) {
          _safeMint(msg.sender, supply + i);
          createPet(uint16(supply + i));
      }

      emit Minted(msg.sender, numberOfPets);
    }

    function walletOfOwner(address owner) public view returns(uint256[] memory) {
      uint256 tokenCount = balanceOf(owner);

      uint256[] memory tokensId = new uint256[](tokenCount);
      for(uint256 i; i < tokenCount; i++){
          tokensId[i] = tokenOfOwnerByIndex(owner, i);
      }
      return tokensId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
      _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
      return _price;
    }

    /**
    * @dev This is permanent and one-way so contract owner can't disallow activation of pets
    */
    function unpauseMint() external onlyOwner {
      _paused = false;
    }

    function unpauseWhiteList() external onlyOwner {
      _whitelistPaused = false;
    }

    /**
    * @dev Withdraw ETH to the contract owner's wallet
    */
    function withdraw() external onlyOwner {
      uint balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    }

    /**
    * @dev Reserves the first 50 pets for giveaways and those who helped the project
    */
    function reserveGiveaway() public onlyOwner {
      uint currentSupply = totalSupply();
      require(currentSupply < 50, "Already reserved the first pets.");

      for (uint i = 0; i < 50; i++) {
          _safeMint(owner(), currentSupply + i);
          createPet(uint16(currentSupply + i));
      }
    }

    function setSOPV0Contract(address sopv0Address) external onlyOwner {
      SOPv0 = ISpiritOrbPetsv0(sopv0Address);
    }

    /**
    * @dev Returns a list of tokens that are owned by owner.
    * @dev NEVER call this function inside of the smart contract itself
    * @dev because it is expensive.  Only return this from web3 calls
    */
    function tokensOfOwner(address owner) external view returns(uint256[] memory) {
      uint256 tokenCount = balanceOf(owner);

      if (tokenCount == 0) {
        return new uint256[](0);
      } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 totalPets = totalSupply();
        uint256 resultIndex = 0;

        for (uint256 petId = 0; petId <= totalPets - 1; petId++) {
          if (ownerOf(petId) == owner) {
            result[resultIndex] = petId;
            resultIndex++;
          }
        }

        return result;
      }
    }

}
