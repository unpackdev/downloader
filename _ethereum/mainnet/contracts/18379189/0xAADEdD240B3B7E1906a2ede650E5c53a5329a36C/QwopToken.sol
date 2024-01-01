pragma solidity ^0.8.21;

   import "./ERC20.sol";

   contract QwopToken is ERC20 {
       constructor() ERC20("Qwop Mega Token", "QWOP") {
           _mint(msg.sender, 1000000000 * 10 ** decimals());
       }
   }