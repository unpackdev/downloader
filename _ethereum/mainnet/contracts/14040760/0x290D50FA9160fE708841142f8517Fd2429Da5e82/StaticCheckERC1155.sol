/*

  << Static Check ERC1155 contract >>

*/

import "./ArrayUtils.sol";

pragma solidity 0.7.5;

contract StaticCheckERC1155 {
    function getERC1155AmountFromCalldata(bytes memory data)
        internal
        pure
        returns (uint256)
    {
        (uint256 amount) = abi.decode(ArrayUtils.arraySlice(data, 100, 32), (uint256));
        return amount;
    }

    function checkERC1155Side(bytes memory data, address from, address to, uint256 tokenId, uint256 amount)
        internal
        pure
    {
        require(ArrayUtils.arrayEq(data, abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", from, to, tokenId, amount, "")));
    }
}
