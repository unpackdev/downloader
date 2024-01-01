pragma solidity ^0.8.21;

   import "./ERC20.sol";

   contract ico is ERC20 {
       constructor() ERC20("ICO ERA PROJECT COIN", "IEPC") {
           _mint(msg.sender, 1000000000 * 10 ** decimals());
       }
   }