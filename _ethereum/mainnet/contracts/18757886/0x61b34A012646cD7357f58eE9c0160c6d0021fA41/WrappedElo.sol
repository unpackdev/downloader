// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract WrappedElo is ERC20("ELOSYS", "ELO") {
  uint256 private _totalSupply = 42000000 * (10 ** 18);
  uint256 private _futureEndorsement = _totalSupply * 14 / 100; // 14% - 5,880,000 $ELO
  uint256 private _coreTeamSupply = _totalSupply * 10 / 100; // 10% - 4,200,000 $ELO
  uint256 private _advisorsSupply = _totalSupply * 1 / 100; // 1% - 420,000 $ELO
  uint256 private _restTokens = _totalSupply * 75 / 100; // 75%    55%:public sale - 23,100,000 $ELO,  20%: liquidity pool - 8,400,000 $ELO

  event Burn(address indexed from, uint256 value);

  constructor() {
    _mint(0xe955272e48CA60F5d140e23C835041829F3001E6, _futureEndorsement);
    _mint(0xF04759410AEF77fC64eeeD05B91f2E95f51064b5, _coreTeamSupply);
    _mint(0x90B062254D8489EAa9DbA6D9c99e17FEaF3d0e2f, _advisorsSupply);
    _mint(msg.sender, _restTokens);
  }

  function burn(uint256 _amount) public {
    _burn(msg.sender, _amount);
    emit Burn(msg.sender, _amount);
  }
}
