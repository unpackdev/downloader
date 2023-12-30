pragma solidity ^0.4.26;

interface OrFeedInterface {
  function getExchangeRate ( string fromSymbol, string toSymbol, string venue, uint256 amount ) external view returns ( uint256 );
  function getTokenDecimalCount ( address tokenAddress ) external view returns ( uint256 );
  function getTokenAddress ( string symbol ) external view returns ( address );
  function getSynthBytes32 ( string symbol ) external view returns ( bytes32 );
  function getForexAddress ( string symbol ) external view returns ( address );
}

contract Test {
    
    
    
    constructor() public {
        
    }
    
    function getExchangeRate(uint amount) view external returns (uint256){
        OrFeedInterface orfeed= OrFeedInterface(0x8316B082621CFedAB95bf4a44a1d4B64a6ffc336);
        uint price = orfeed.getExchangeRate("ETH", "DAI", "UNISWAPBYSYMBOLV2", 100000000000000);
    
    } 
}