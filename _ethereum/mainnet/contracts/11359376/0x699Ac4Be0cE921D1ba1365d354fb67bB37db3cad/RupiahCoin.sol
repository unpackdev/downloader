pragma solidity ^0.6.12;

import "./ERC20PresetMinterPauserUpgradeable.sol";

contract RupiahCoin is ERC20PresetMinterPauserUpgradeable {
  function initialize() initializer public {
    __ERC20PresetMinterPauser_init("Rupiah Coin", "IDRC");
  }
}
