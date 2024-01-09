/*

  << Static Check ERC20 contract >>

*/

import "./ArrayUtils.sol";

pragma solidity 0.7.5;

contract StaticCheckERC20{
    function checkERC20Side(bytes memory data, address from, address to, uint256 amount)
        internal
        pure
    {
        require(ArrayUtils.arrayEq(data, abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount)));
    }

    function checkERC20SideWithOneFee(bytes memory data, address from, address to, address feeRecipient, uint256 amount, uint256 fee)
        internal
        pure
    {
        require(ArrayUtils.arrayEq(ArrayUtils.arraySlice(data, 356, 100), abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount)));
        require(ArrayUtils.arrayEq(ArrayUtils.arraySlice(data, 516, 100), abi.encodeWithSignature("transferFrom(address,address,uint256)", from, feeRecipient, fee)));
    }

    function checkERC20SideWithTwoFees(bytes memory data, address from, address to, address feeRecipient, address royaltyFeeRecipient, uint256 amount, uint256 fee, uint256 royaltyFee)
        internal
        pure
    {
        require(ArrayUtils.arrayEq(ArrayUtils.arraySlice(data, 452, 100), abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount)));
        require(ArrayUtils.arrayEq(ArrayUtils.arraySlice(data, 612, 100), abi.encodeWithSignature("transferFrom(address,address,uint256)", from, feeRecipient, fee)));
        require(ArrayUtils.arrayEq(ArrayUtils.arraySlice(data, 772, 100), abi.encodeWithSignature("transferFrom(address,address,uint256)", from, royaltyFeeRecipient, royaltyFee)));
    }
}
