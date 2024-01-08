// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC20.sol";

contract WavepoolToken is ERC20 {
  constructor() ERC20('Wavepool Token', 'WAP') {
    _mint(msg.sender, 30000000000 * 10**decimals());
  }
}