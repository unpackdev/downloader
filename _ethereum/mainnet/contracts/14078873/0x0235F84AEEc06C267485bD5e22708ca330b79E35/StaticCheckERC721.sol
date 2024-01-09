/*

  << Static Check ERC721 contract >>

*/

import "./ArrayUtils.sol";

pragma solidity 0.7.5;

contract StaticCheckERC721 {
    function checkERC721Side(bytes memory data, address from, address to, uint256 tokenId)
        internal
        pure
    {
        require(ArrayUtils.arrayEq(data, abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, tokenId)));
    }

    function checkERC721SideForCollection(bytes memory data, address from, address to)
        internal
        pure
    {
        (uint256 tokenId) = abi.decode(ArrayUtils.arraySlice(data, 68, 32), (uint256));
        require(ArrayUtils.arrayEq(data, abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, tokenId)));
    }
}
