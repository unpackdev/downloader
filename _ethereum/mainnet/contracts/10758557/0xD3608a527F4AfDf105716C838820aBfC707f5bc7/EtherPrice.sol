pragma solidity >=0.4.23 <0.5.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IMakerPriceFeed {
  function read() external view returns (bytes32);
}

contract EtherPrice {
    
    uint[22] public levelPrice;
    uint public regAmount;
    uint public ethPrice;
    
    function updateEtherPrices() public{
        
        ethPrice=getETHUSDPrice();
        levelPrice[1] = SafeMath.div(uint(5 *  10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[2] = SafeMath.div(uint(10 * 10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[3] = SafeMath.div(uint(20 * 10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[4] = SafeMath.div(uint(30 * 10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[5] = SafeMath.div(uint(40 * 10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[6] = SafeMath.div(uint(50 * 10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[7] = SafeMath.div(uint(75 * 10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[8] = SafeMath.div(uint(100 * 10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[9] = SafeMath.div(uint(125 * 10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[10] = SafeMath.div(uint(150* 10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[11] = SafeMath.div(uint(200* 10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[12] = SafeMath.div(uint(250* 10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[13] = SafeMath.div(uint(300* 10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[14] = SafeMath.div(uint(400* 10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[15] = SafeMath.div(uint(500* 10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[16] = SafeMath.div(uint(750* 10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[17] = SafeMath.div(uint(1000*10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[18] = SafeMath.div(uint(1250*10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[19] = SafeMath.div(uint(1500*10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[20] = SafeMath.div(uint(2000*10000000000000000000000),ethPrice)/10000 ether;
        levelPrice[21] = SafeMath.div(uint(3000*10000000000000000000000),ethPrice)/10000 ether;
        regAmount=2*levelPrice[1];
    }
    
  function getETHUSDPrice() public view returns (uint) {
    address ethUsdPriceFeed = 0x729D19f657BD0614b4985Cf1D82531c67569197B;
    return uint(
      IMakerPriceFeed(ethUsdPriceFeed).read()
    );
  }
  
  
}