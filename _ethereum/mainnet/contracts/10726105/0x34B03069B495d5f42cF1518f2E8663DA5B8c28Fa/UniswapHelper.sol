pragma solidity ^0.5.12;

interface IUniswapV2Factory {
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}

contract UniswapHelper {
    
    IUniswapV2Factory factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    
    function getAllPairs() external view returns (address[] memory pairs) {
        uint pairsLength = factory.allPairsLength();
        pairs = new address[](pairsLength);
        for (uint i = 0; i < pairsLength; i++) {
            pairs[i] = factory.allPairs(i);
        }
    }
    
    
}