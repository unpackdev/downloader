// SPDX-License-Identifier: MIT
//
// Spirit Orb Pets v0 PFP NFT
// Developed by:  Heartfelt Games LLC
//
// This is a PFP NFT that can be bought with Care Tokens.
// The PFP represents the same v0 pet that minted it so the
// owner can proudly display their v0 pet as their PFP.
//
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./Counters.sol";
import "./Ownable.sol";

interface ISpiritOrbPetsv0 is IERC721, IERC721Enumerable {

}

interface ICareToken is IERC20 {
  function burn(address sender, uint256 paymentAmount) external;
}

contract SpiritOrbPetsv0Pfp is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    ISpiritOrbPetsv0 public SOPv0;
    ICareToken public CareToken;

    string _baseTokenURI;
    uint256 private _price; // price in Care tokens
    bool public _paused;

    // Maximum amount of Pets in existance.
    uint256 public constant MAX_PET_SUPPLY = 777;

    // Events
    event Minted(address sender, uint256 numberOfPets);

    constructor() ERC721("Spirit Orb Pets v0 PFP", "SOPV0PFP") {
      _paused = true;
      _price = 250 ether; // price in whole Care tokens
    }

    function claim(uint256 tokenId) external {
        require(!_paused, "Minting is currently paused.");
        require(msg.sender == SOPv0.ownerOf(tokenId), "You don't own this pet");
        require(!_exists(tokenId), "v0 baby claimed already");

        _safeMint(msg.sender, tokenId);
        _tokenSupply.increment();

        // take CARE tokens from owner
        // ERC20 will revert if there aren't enough tokens in wallet
        CareToken.burn(msg.sender, _price);

        emit Minted(msg.sender, 1);
    }

    function claimMultiple(uint256[] memory tokenIds) external {
        require(!_paused, "Minting is currently paused.");

        uint256 numberOfPets = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            require(msg.sender == SOPv0.ownerOf(tokenIds[i]), "You don't own this pet");
            require(!_exists(tokenIds[i]), "v0 baby claimed already");
            numberOfPets++;
            _safeMint(msg.sender, tokenIds[i]);
            _tokenSupply.increment();
        }

        // take CARE tokens from owner
        // Token must be approved from the CARE token's address by the owner
        CareToken.burn(msg.sender, _price * numberOfPets);

        emit Minted(msg.sender, numberOfPets);
    }

    function totalSupply() public view returns (uint256) {
      return _tokenSupply.current();
    }

    /**
    * @dev Checks to see if a v0 pet claim has been taken yet.  Returns true if it has been taken
    */
    function hasV0PetClaimedWhitelist(uint256 tokenId) public view returns (bool) {
      return _exists(tokenId);
    }

    // Set new Care token price
    function setPrice(uint256 _newPrice) public onlyOwner {
      _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
      _baseTokenURI = baseURI;
    }

    function setPause(bool val) public onlyOwner {
      _paused = val;
    }

    // This withdraws Ether in case someone sends ETH to the contract for some reason
    function withdraw() external onlyOwner {
      uint balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    }

    function setCareToken(address careTokenAddress) external onlyOwner {
      CareToken = ICareToken(careTokenAddress);
    }

    function setSOPV0Contract(address sopv0Address) external onlyOwner {
      SOPv0 = ISpiritOrbPetsv0(sopv0Address);
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
        uint256 totalPets = MAX_PET_SUPPLY;
        uint256 resultIndex = 0;

        for (uint256 petId = 0; petId <= totalPets - 1; petId++) {
          if (_exists(petId)) {
            if (ownerOf(petId) == _owner) {
              result[resultIndex] = petId;
              resultIndex++;
            }
          }
        }

        return result;
      }
    }

}
