pragma solidity >=0.5.0 <0.7.0;
import "./ERC20Detailed.sol";
import "./SafeMath.sol";

contract HexUtils
{
    using SafeMath for uint256;

    function fromHex(bytes memory ss) 
        public 
        pure 
        returns(bytes memory) 
    {
        require(ss.length%2 == 0); // length must be even
        bytes memory r = new bytes(ss.length/2);
        for (uint i = 0; i < ss.length/2; ++i) {
            r[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 + fromHexChar(uint8(ss[2*i+1])));
            }
        return r;
    }
    
    function fromHexChar(uint8 c) 
        public 
        pure 
        returns(uint8) 
    {
        if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
            return c - uint8(bytes1('0'));
        }
        if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
            return 10 + c - uint8(bytes1('a'));
        }
        if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
            return 10 + c - uint8(bytes1('A'));
        }
    }

    function toDecimals(address tokenAddress, uint256 tokenCount)
        public
        view
        returns (uint256)
    {
        uint8 decimals = ERC20Detailed(tokenAddress).decimals();
        if(decimals < 18) {
            return tokenCount.mul(10 ** uint256(18 - decimals));
        } else if (decimals > 18) {
            return tokenCount.div(10 ** uint256(decimals - 18));
        } else {
            return tokenCount;
        }
    }

    function fromDecimals(address tokenAddress, uint256 tokenCount)
        public
        view
        returns (uint256)
    {
        uint8 decimals = ERC20Detailed(tokenAddress).decimals();
        if(decimals < 18)
        {
            return tokenCount.div(10 ** uint256(18 - decimals));
        } else if (decimals > 18) 
        {
            return tokenCount.mul(10 ** uint256(decimals - 18));
        } else 
        {
            return tokenCount;
        }
    }


}