// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface Token {
  function balanceOf(address account) external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address); 
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function decimals() external view returns (uint8);
}

interface IUniswapV2Factory {
    function allPairsLength() external view returns (uint);
    function allPairs(uint) external view returns (address);
}

contract boostedFinal {
  /* Fallback function, don't accept any ETH */
    receive() external payable {
        revert("Not accept");
    }

    IUniswapV2Factory public factory;
    constructor(address _factoryAddress) {
    factory = IUniswapV2Factory(_factoryAddress);
    }

    // Address Functions
    function multipleEtherBalances(address[] memory users) public view returns (uint[] memory) {
            uint[] memory etherBalances = new uint[](users.length);

            for (uint i = 0; i < users.length; i++) {
                etherBalances[i] = users[i].balance;
            }

            return etherBalances;
    }
    function tokenBalance(address user, address token) public view returns (uint) {
        // check if token is actually a contract
        uint256 tokenCode;
        assembly { tokenCode := extcodesize(token) } // contract code size
    
        // is it a contract and does it implement balanceOf 
        if (tokenCode > 0) {  
        try Token(token).balanceOf(user) returns (uint balance) {
            return balance;
        } catch {
            return 0;
        }
        } else {
        return 0;
        }
    }

    struct TokenInfo {
        address tokenAddress;
        string name;
        string symbol;
        uint8 decimals;
    }
    struct pairElement {
        uint index;
        address pairAdress;
        address token0;
        string token0Name;
        string token0Symbol;
        uint token0Decimals;
        address token1;
        string token1Name;
        string token1Symbol;
        uint token1Decimals;
        
    }
    struct FullInfo {
        TokenInfo token0Info;
        uint reserve0;
        TokenInfo token1Info;
        uint reserve1;
    }

    struct ReserveData {
      uint reserve0;
      uint reserve1;
      address pairAdress;
    }
    function getReservesRangeIndexs(uint startIndex, uint endIndex) public view returns (ReserveData[] memory) {
        require(startIndex <= endIndex && endIndex < factory.allPairsLength(), "Invalid indices provided");
        uint rangeLength = endIndex - startIndex + 1;
        ReserveData[] memory reserves = new ReserveData[](rangeLength);
        for (uint i = startIndex; i <= endIndex; i++) {
            address pairAddress = factory.allPairs(i);
            (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();
            reserves[i - startIndex] = ReserveData(uint(reserve0), uint(reserve1),pairAddress);
        }

        return reserves;
    }
    function balancesTokensPerAdresss(address[] memory users, address[] memory tokens) external view returns (uint[] memory) {
        uint[] memory addrBalances = new uint[](tokens.length * users.length);
        for(uint i = 0; i < users.length; i++) {
            for (uint j = 0; j < tokens.length; j++) {
                uint addrIdx = j + tokens.length * i;              
                if (tokens[j] != address(0)) { 
                uint balance = tokenBalance(users[i], tokens[j]);
                //uint tokenDecimals = Token(tokens[j]).decimals();
                addrBalances[addrIdx] = balance; /// (10 ** tokenDecimals);
                } else {
                addrBalances[addrIdx] = users[i].balance; // ETH balance    
                }
            }  
        }
          
        return addrBalances;
    }
    function getReservesArrayIndexes(uint[] memory indexes) public view returns (ReserveData[] memory) {
        ReserveData[] memory reserves = new ReserveData[](indexes.length);

        for (uint j = 0; j < indexes.length; j++) {
            uint i = indexes[j];
            address pairAddress = factory.allPairs(i); // Suponiendo que 'factory' esté definido en algún lugar
            (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();
            reserves[j] = ReserveData(uint(reserve0), uint(reserve1), pairAddress);
        }

        return reserves;
    }
}