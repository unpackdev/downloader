pragma solidity 0.6.6;

interface IRealityCards {

    function collectRentAllTokens() external;

}

contract rentCollector {
    IRealityCards rc1 = IRealityCards(0x148Bb64E8910422E74f79feF1A2E830BDe0BB938);
    IRealityCards rc2 = IRealityCards(0x196c61A463e82fCEa84F38D1aFF1bCF1F83214eC);
    IRealityCards rc3 = IRealityCards(0xc61ba76c37Dd5a1b9A076f8eD909f12155739DeC);
    
    function collectRentAllTokensAllMarkets() public 
    {
        rc1.collectRentAllTokens();
        rc2.collectRentAllTokens();
        rc3.collectRentAllTokens();
    }
}
