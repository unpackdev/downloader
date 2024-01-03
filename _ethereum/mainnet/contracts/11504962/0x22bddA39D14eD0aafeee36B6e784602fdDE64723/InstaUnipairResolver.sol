pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface UnipairInterface {
    function balanceOf(address) external view returns (uint);
    function totalSupply() external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract Resolver {
    struct UnipairInfo {
        address token0;
        address token1;
        uint reserve0;
        uint reserve1;
        uint totalSupply;
    }

    function getUnipairInfo(
        address owner,
        address[] memory lpTknAddress
    ) public view returns (uint[] memory, UnipairInfo[] memory) {
        uint _length = lpTknAddress.length;

        uint[] memory tokensBal = new uint[](_length);
        UnipairInfo[] memory unipair = new UnipairInfo[](_length);

        address wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        for (uint i = 0; i < _length; i++) {
            UnipairInterface lp = UnipairInterface(lpTknAddress[i]);

            tokensBal[i] = lp.balanceOf(owner);

            address tkn0 = lp.token0() == wethAddr ? ethAddr : lp.token0();
            address tkn1 = lp.token1() == wethAddr ? ethAddr : lp.token1();

            (uint112 res0, uint112 res1, ) = lp.getReserves();
            uint supply = lp.totalSupply();

            unipair[i] = UnipairInfo({
                token0: tkn0,
                token1: tkn1,
                reserve0: res0,
                reserve1: res1,
                totalSupply: supply
            });
        }

        return (tokensBal, unipair);
    }
}

contract InstaUnipairResolver is Resolver {

    string public constant name = "Unipair-Resolver-v1";

}