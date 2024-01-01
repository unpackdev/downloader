pragma solidity ^0.8.21;

   import "./ERC20.sol";

   contract maxheaven is ERC20 {
       constructor() ERC20("Max Heaven Mega Token", "MHMT") {
           _mint(msg.sender, 7777777 * 10 ** decimals());
       }
   }