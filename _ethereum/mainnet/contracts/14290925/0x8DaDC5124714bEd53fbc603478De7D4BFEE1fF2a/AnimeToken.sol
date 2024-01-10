// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

import "./IAnimeToken.sol";
import "./ERC20.sol";
import "./AccessControl.sol";

contract AnimeToken is IAnimeToken, ERC20, AccessControl {
    bytes32 public constant override MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("AnimeToken", "ANX") {
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _setupRole(MINTER_ROLE, _msgSender());
    }

    function mint(address _account, uint256 _amount) public override {
      require(
          hasRole(MINTER_ROLE, _msgSender()),
          "must have minter role to mint"
      );
      _mint(_account, _amount);
    }
}

