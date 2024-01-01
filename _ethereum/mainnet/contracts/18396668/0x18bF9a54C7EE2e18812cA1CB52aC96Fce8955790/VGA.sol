/**
 *Submitted for verification at Etherscan.io on 2023-10-20
*/

/*
   VegaFi2 - Algorithmic Reflexivity

                                                 ,/
                                                //
                                              ,//
                                  ___   /|   |//
                              `__/\_ --(/|___/-/
                           \|\_-\___ __-_`- /-/ \.
                          |\_-___,-\_____--/_)' ) \
                           \ -_ /     __ \( `( __`\|
                           `\__|      |\)\ ) /(/|
   ,._____.,            ',--//-|      \  |  '   /
  /     __. \,          / /,---|       \       /
 / /    _. \  \        `/`_/ _,'        |     |
|  | ( (  \   |      ,/\'__/'/          |     |
|  \  \`--, `_/_------______/           \(   )/
| | \  \_. \,                            \___/\
| |  \_   \  \                                 \
\ \    \_ \   \   /                             \
 \ \  \._  \__ \_|       |                       \
  \ \___  \      \       |                        \
   \__ \__ \  \_ |       \                         |
   |  \_____ \  ____      |                        |
   | \  \__ ---' .__\     |        |               |
   \  \__ ---   /   )     |        \              /
    \   \____/ / ()(      \          `---_       /|
     \__________/(,--__    \_________.    |    ./ |
       |     \ \  `---_\--,           \   \_,./   |
       |      \  \_ ` \    /`---_______-\   \\    /
        \      \.___,`|   /              \   \\   \
         \     |  \_ \|   \              (   |:    |
          \    \      \    |             /  / |    ;
           \    \      \    \          ( `_'   \  |
            \.   \      \.   \          `__/   |  |
              \   \       \.  \                |  |
               \   \        \  \               (  )
                \   |        \  |              |  |
                 |  \         \ \              I  `
                 ( __;        ( _;            ('-_';
                 |___\        \___:            \___:

   Telegram:  https://t.me/vegafiportal
   Twitter/X: https://twitter.com/VegaFiOfficial
   Website:   https://vegafi.io
   Docs:      https://docs.vegafi.io
*/

import "./IERC20.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract VGA {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "VegaFi2";
    string public symbol = "VGA2";
    uint8 public decimals = 18;

    address public owner;

    constructor () {
      owner = msg.sender;

      uint amount = 10_000_000 * (10 ** 18);
      balanceOf[msg.sender] += amount;
      totalSupply += amount;
      emit Transfer(address(0), msg.sender, amount);

    }

    function transfer(address recipient, uint amount) public returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) public returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) public {
        require(msg.sender == owner);
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    // Emergency
    function rescue(address token) public {
      require(msg.sender == owner);

      if (token == 0x0000000000000000000000000000000000000000) {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
      } else {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
      }
    }

}
