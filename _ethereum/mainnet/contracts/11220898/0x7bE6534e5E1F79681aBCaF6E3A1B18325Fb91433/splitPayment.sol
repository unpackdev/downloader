pragma solidity 0.4.18;

contract splitPayment {
   address development = 0xaf3Aad6626E5F2cb13fD65D24EF95292d20A727E;
   address initialmktg = 0x2975CAD72eff6a3F3d7cC62c0a027638D4fb2b92;
   uint percentageDevelopment = 94;
   uint percentageInitialmktg = 6;

  function() payable {
    development.transfer(msg.value * percentageDevelopment / 100);
    initialmktg.transfer(msg.value * percentageInitialmktg / 100);
  }
}