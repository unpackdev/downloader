pragma solidity ^0.8.21;

   import "./ERC20.sol";

   contract ard is ERC20 {
       constructor() ERC20("Ard Van Token", "ARDV") {
           _mint(msg.sender, 1000000000 * 10 ** decimals());
       }
   }