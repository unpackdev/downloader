// SPDX-License-Identifier: MIT

//submitted for verification to Etherscan.io on 31/01/2022

// ░█████╗░███████╗██████╗░░█████╗░██████╗░██████╗░░█████╗░██╗██████╗░░██████╗
// ██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██║██╔══██╗██╔════╝
// ███████║█████╗░░██████╔╝██║░░██║██║░░██║██████╔╝██║░░██║██║██║░░██║╚█████╗░
// ██╔══██║██╔══╝░░██╔══██╗██║░░██║██║░░██║██╔══██╗██║░░██║██║██║░░██║░╚═══██╗
// ██║░░██║██║░░░░░██║░░██║╚█████╔╝██████╔╝██║░░██║╚█████╔╝██║██████╔╝██████╔╝
// ╚═╝░░╚═╝╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝╚═════╝░╚═════╝░

// ██████╗░██████╗░░█████╗░███╗░░██╗███████╗
// ██╔══██╗██╔══██╗██╔══██╗████╗░██║██╔════╝
// ██║░░██║██████╔╝██║░░██║██╔██╗██║█████╗░░
// ██║░░██║██╔══██╗██║░░██║██║╚████║██╔══╝░░
// ██████╔╝██║░░██║╚█████╔╝██║░╚███║███████╗
// ╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░╚══╝╚══════╝


// AFRODRONES 

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

interface AfroDroids {
  function balanceOf(address owner) external view returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index)
    external
    view
    returns (uint256);
}

contract AfroDrones is Ownable, ERC721A, ReentrancyGuard {
 

  address AFRODOIDSADDRESS = 0x77aA555c8a518b56A1Ed57B7b4b85Ee2AD479d06;
  mapping(uint256 => bool) public claimedTokens;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_
   
  ) ERC721A("Droids", "DROIDS",maxBatchSize_, collectionSize_) {}

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  // CLAIM FUNCTION

  function claimToken(uint256 quantity) public {
    require(
      totalSupply() + quantity <= collectionSize,
      "Not Enough left to claim."
    );
     AfroDroids prevContract = AfroDroids(AFRODOIDSADDRESS);
   
    require(
      prevContract.balanceOf(msg.sender) >= quantity,
      "Wallet does not contrain enough droids."
    );

    uint256 toBeClaimed = 0;
    uint256 token;

    for (
      uint256 index = 0;
      index < prevContract.balanceOf(msg.sender) && toBeClaimed < quantity;
      index++
    ) {
      token = prevContract.tokenOfOwnerByIndex(msg.sender, index);
      if (!claimedTokens[token] ) {
        // _safeMint(msg.sender, prevContract.tokenOfOwnerByIndex(msg.sender, index));
        toBeClaimed++;
        claimedTokens[token] = true;
      }
    }

    require(
      toBeClaimed == quantity,
      "You have exeeded the quantity that you can claim."
    );

    _safeMint(msg.sender, quantity);
  }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function availableClaims(address owner) public view returns (uint256)  {
    AfroDroids prevContract = AfroDroids(AFRODOIDSADDRESS);

    uint256 canBeClaimed = 0;
    uint256 token;

    for (
      uint256 index = 0;
      index < prevContract.balanceOf(owner);
      index++
    ) {
      token = prevContract.tokenOfOwnerByIndex(owner, index);
      if (!claimedTokens[token] ) {
        canBeClaimed++;
      }
    }
    return canBeClaimed;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{ value: address(this).balance }("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }

}

  
