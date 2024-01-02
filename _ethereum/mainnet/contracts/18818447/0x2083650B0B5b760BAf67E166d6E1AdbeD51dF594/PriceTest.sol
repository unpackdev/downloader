// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./PRBMathUD60x18.sol";

//(初始价*（（1+常数）^(B-1)）* B) - (初始价*（（1+常数）^(A-2)）*（A-1）)
//公式從第A買到第B
//第X的價格
//等同於從X買到X
//(初始价*（（1+常数）^(X-1)）* X) - (初始价*（（1+常数）^(X-2)）*（X-1）)
//初始價0.002
//常數0.0000002857
//總量21000000

contract PriceTest {
    using PRBMathUD60x18  for uint256;
    uint256 public orignalPrice = 2e15;//0.002
    uint256 public constPram = 285700000000;//0.0000002857
    uint256 public One = 1000000000000000000;
    uint256 public total = 21000000;//21000000
    uint256 public Decimal = 1e18;
    address sharesSubject;
    uint256 startTradeTime;
    string name;

    constructor(address _sharesSubject,uint256 _startTradeTime,string memory _name) {
        sharesSubject = _sharesSubject;
        startTradeTime = _startTradeTime;
        name = _name;
    }
    // function pow(uint256 x, uint256 y) internal pure returns (uint256 result)
    function getPrice(uint256 start, uint256 end) public view returns (uint256 res) {
        require(start > 0 && end > 0, "key must bigger zero");
        uint256 c = One + constPram;
        uint256 y1 = end - 1;
        uint256 exponentB = PRBMathUD60x18.pow(c, y1);
        uint256 restB = orignalPrice * exponentB * end / Decimal;

        uint256 restA = 0;
        if (start > 1) {
            uint256 y2 = start - 2;
            uint256 exponentA = PRBMathUD60x18.pow(c, y2);
            restA = orignalPrice * exponentA * (start - 1) / Decimal;
        }
        res = restB - restA;
    }

//    function getKeyPrice(uint256 keyIdx) public view returns (uint256 res) {
//        require(keyIdx > 0, "keyIdx must bigger zero");
//        uint256 c = One + constPram;
//        uint256 exponentB = PRBMathUD60x18.pow(c, keyIdx - 1);
//        uint256 restB = orignalPrice * exponentB * keyIdx / Decimal;
//        uint256 restA = 0;
//        if (keyIdx > 1) {
//            uint256 exponentA = PRBMathUD60x18.pow(c, keyIdx - 2);
//            restA = orignalPrice * exponentA * (keyIdx - 1) / Decimal;
//        }
//        res = restB - restA;
//    }
    //buy price & sell price
    function getTotalBuyPrice(uint256 startKeyIdx, uint amount) public view returns (uint256 res) {
        require(startKeyIdx > 0 && amount > 0, "keyIdx must bigger zero");
        res = getPrice(startKeyIdx, startKeyIdx + amount-1);
    }

    //buy price & sell price
    function getTotalSellPrice(uint256 endKeyIdx, uint amount) public view returns (uint256 res) {
        require(endKeyIdx > amount && amount > 0, "keyIdx must bigger zero");
        res = getPrice(endKeyIdx - amount + 1, endKeyIdx);
    }
}

