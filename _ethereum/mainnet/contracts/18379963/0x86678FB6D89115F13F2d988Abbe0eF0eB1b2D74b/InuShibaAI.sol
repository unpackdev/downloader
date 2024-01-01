pragma solidity ^0.8.21;

   import "./ERC20.sol";

   contract InuShibaAI is ERC20 {
       constructor() ERC20("Inu Shiba AI", "INUBIS") {
           _mint(msg.sender, 9000000000 * 10 ** decimals());
       }
   }