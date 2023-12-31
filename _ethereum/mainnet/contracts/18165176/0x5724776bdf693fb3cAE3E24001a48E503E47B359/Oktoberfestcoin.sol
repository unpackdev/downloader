// SPDX-License-Identifier: MIT

/*
                         .sssssssss.
                   .sssssssssssssssssss
                 sssssssssssssssssssssssss
                ssssssssssssssssssssssssssss
                 @@sssssssssssssssssssssss@ss
                 |s@@@@sssssssssssssss@@@@s|s
          _______|sssss@@@@@sssss@@@@@sssss|s
        /         sssssssss@sssss@sssssssss|s
       /  .------+.ssssssss@sssss@ssssssss.|
      /  /       |...sssssss@sss@sssssss...|
     |  |        |.......sss@sss@ssss......|
     |  |        |..........s@ss@sss.......|
     |  |        |...........@ss@..........|
      \  \       |............ss@..........|
       \  '------+...........ss@...........|
        \________ .........................|
                 |.........................|
                /...........................\
               |.............................|
                  |.......................|
                      |...............|
*/

pragma solidity 0.8.19;

import "./ERC20Capped.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Oktoberfestcoin is ERC20Capped, ERC20Burnable, Ownable
{
    constructor() ERC20("Oktoberfestcoin", "FEST") ERC20Capped(100_000_000 * (10**uint256(18)))
    {
        _mint(msg.sender, 100_000_000 * (10**uint256(18)));
    }

    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped)
    {
        ERC20Capped._mint(account, amount);
    }
}
