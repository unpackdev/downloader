// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SpiritOrbPetsv0 is ERC721Enumerable, Ownable {

    string _baseTokenURI;
    uint256 private _price = 0.01 ether;
    bool public _paused = true;

    // Maximum amount of Pets in existance.
    uint256 public constant MAX_PET_SUPPLY = 777;

    // Events
    event Minted(address sender, uint256 numberOfPets);

    constructor() ERC721("Spirit Orb Pets v0", "SOPV0") {
      _paused = true;
    }

    /**
    * @dev Mints [numberOfPets] Pets
    */
    function mintPet(uint256 numberOfPets) public payable {
      uint256 supply = totalSupply();
      require(!_paused, "Pet adoption has not yet begun.");
      require(supply < MAX_PET_SUPPLY, "Adoption has already ended.");
      require(numberOfPets > 0, "You cannot adopt 0 Pets.");
      require(numberOfPets <= 3, "You are not allowed to adopt this many Pets at once.");
      require(supply + numberOfPets <= MAX_PET_SUPPLY, "Exceeds maximum Pets available. Please try to adopt less Pets.");
      require(_price * numberOfPets == msg.value, "Amount of Ether sent is not correct.");

      // Mint the amount of provided Pets.
      for (uint i = 0; i < numberOfPets; i++) {
          _safeMint(msg.sender, supply + i);
      }

      emit Minted(msg.sender, numberOfPets);
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
      uint256 tokenCount = balanceOf(_owner);

      uint256[] memory tokensId = new uint256[](tokenCount);
      for(uint256 i; i < tokenCount; i++){
          tokensId[i] = tokenOfOwnerByIndex(_owner, i);
      }
      return tokensId;
    }

    // If everything is minted this will be irrelevant.
    // This is only in case ETH decides to do a x10 before minting or
    // something crazy like that. Would only do this if the community
    // agreed as well.
    function setPrice(uint256 _newPrice) public onlyOwner {
      _price = _newPrice;
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

    function setPause(bool val) public onlyOwner {
      _paused = val;
    }

    function withdraw() external onlyOwner {
      uint balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    }

    /**
    * @dev Reserves the first 10 pets for giveaways and for those you helped the project
    */
    function reserveGiveaway() public onlyOwner {
      uint currentSupply = totalSupply();
      require(currentSupply < 10, "Already reserved the first pets.");
      // Reserved for people who helped this project and giveaways
      for (uint i = 0; i < 10; i++) {
          _safeMint(owner(), currentSupply + i);
      }
    }

    /**
    * @dev Returns a list of tokens that are owned by _owner.
    * @dev NEVER call this function inside of the smart contract itself
    * @dev because it is expensive.  Only return this from web3 calls
    */
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
      uint256 tokenCount = balanceOf(_owner);

      if (tokenCount == 0) {
        return new uint256[](0);
      } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 totalPets = totalSupply();
        uint256 resultIndex = 0;

        for (uint256 petId = 0; petId <= totalPets - 1; petId++) {
          if (ownerOf(petId) == _owner) {
            result[resultIndex] = petId;
            resultIndex++;
          }
        }

        return result;
      }
    }

}
