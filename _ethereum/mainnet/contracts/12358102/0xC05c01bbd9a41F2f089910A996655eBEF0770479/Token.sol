pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicense

import "./ERC20.sol";
import "./Ownable.sol";

// import "./ERC20.sol";
// import "./Ownable.sol";


contract Token is ERC20, Ownable {
   bool private _publicMintingAllowed = true;
   mapping(uint256 => address) private _mintedAtMint;

   uint256 constant COMMISSION = 100 * (10 ** 18);
   // == 100

   constructor(
      string memory _name,
      string memory _symbol,
      uint256 initialSupply
   ) public ERC20(_name, _symbol) {
      _mint(msg.sender, initialSupply);
   }

   function hasMinted(uint256 timestamp) public view returns (address) {
      return _mintedAtMint[timestamp / 30 days];
   }

   function untilNextMint() public view returns (uint256) {
      return ((block.timestamp / 30 days) + 1) * 30 days;
   }

   function setPublicMinting(bool enabled) public onlyOwner {
      _publicMintingAllowed = enabled;
   }

   function hasPublicMinting() public view returns (bool) {
      return _publicMintingAllowed;
   }

   function distribute(address[] memory recipients, uint256 amount) public {
      require (recipients.length * amount <= balanceOf(_msgSender()), "not enough");
      for (uint j = 0; j < recipients.length; j++) {
         _transfer(_msgSender(), recipients[j], amount);
      }
   }

   function timedMint(uint256 newAmount) public {
      // can only be minted once a month, max 10k tokens
      require(_mintedAtMint[block.timestamp / 30 days] == address(0x0), "Too soon, wait 30 days");
      require(newAmount <= 2000 * (10 ** 18), "Max 2k");
      require(newAmount >= 1000 * (10 ** 18), "Min 1k");
      require(_publicMintingAllowed || owner() == msg.sender, "Public minting disabled");

      _mintedAtMint[block.timestamp / 30 days] = msg.sender;
      if (_publicMintingAllowed) {
         _mint(owner(), newAmount - COMMISSION);
         _mint(msg.sender, COMMISSION);
      } else {
         _mint(owner(), newAmount);
      }
   }
}
