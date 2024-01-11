// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

// contract by:
//
//  ______   ______   ______  __  __   ______   ______   __  __   ______
// /\___  \ /\  ___\ /\  == \/\ \_\ \ /\  ___\ /\  == \ /\ \/\ \ /\  ___\
// \/_/  /__\ \  __\ \ \  _-/\ \  __ \\ \  __\ \ \  __< \ \ \_\ \\ \___  \
//   /\_____\\ \_____\\ \_\   \ \_\ \_\\ \_____\\ \_\ \_\\ \_____\\/\_____\
//   \/_____/ \/_____/ \/_/    \/_/\/_/ \/_____/ \/_/ /_/ \/_____/ \/_____/
//
// zepheruslabs.xyz
//
contract TRMGiveaway is ERC721, Ownable {
  using Strings for uint256;

  uint256 public constant maxSupply = 100;
  bool public isLocked;

  address airdropper;
  string baseURI;
  uint256 counter = 1;

  constructor(string memory _baseURI, address _airdropper)
    ERC721('Money2020 TRM Giveaway', 'M2020TRM')
  {
    baseURI = _baseURI;
    airdropper = _airdropper;
  }

  // Metadata
  function tokenURI(uint256 id) public view override returns (string memory) {
    return string(abi.encodePacked(baseURI, id.toString()));
  }

  function setBaseURI(string memory _baseURI) public onlyOwner isNotLocked {
    baseURI = _baseURI;
  }

  // end Metadata

  // Airdropper actions
  function airdropTo(address _to) external {
    require(counter <= maxSupply, 'exceeds max supply');
    require(msg.sender == airdropper, 'must be authorized airdropper');
    _mint(_to, counter);
    unchecked {
      counter++;
    }
  }

  function setAirdropper(address _airdropper) external onlyOwner isNotLocked {
    airdropper = _airdropper;
  }
  // end Airdropper actions

  // Locking
  function lock() external onlyOwner isNotLocked {
    isLocked = true;
    airdropper = address(0);
  }

  modifier isNotLocked() {
    require(!isLocked, 'contract has been locked');
    _;
  }

  // end Locking

  // Implement non-transferable token spec.
  function transferFrom(
    address,
    address,
    uint256
  ) public override {
    revert('token is non-transferable');
  }
}
