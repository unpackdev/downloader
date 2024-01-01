pragma solidity ^0.8.21;

   import "./ERC20.sol";

   contract reg is ERC20 {
       constructor() ERC20("REGENT", "REG") {
           _mint(msg.sender, 1000000000 * 10 ** decimals());
       }
   }