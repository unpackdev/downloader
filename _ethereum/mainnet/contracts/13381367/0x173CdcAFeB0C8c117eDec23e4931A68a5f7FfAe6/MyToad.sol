// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC1155.sol";

contract MyToad is ERC1155 {
  constructor() ERC1155("https://ipfs.io/ipfs/QmTkw7ySiWXr4fY1qwLdAjdRLptc4TMBN4ewxUZLBWizba") { 
    _mint(msg.sender, 1, 2500, "");
  }
}