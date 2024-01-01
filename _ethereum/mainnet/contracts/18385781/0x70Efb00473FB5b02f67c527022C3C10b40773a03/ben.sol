pragma solidity ^0.8.21;

   import "./ERC20.sol";

   contract ben is ERC20 {
       constructor() ERC20("Ben Big Ben", "BBB") {
           _mint(msg.sender, 1000000000 * 10 ** decimals());
       }
   }