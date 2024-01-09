/*

  << Static Check ETH contract >>

*/
import "./SafeMath.sol";
import "./ArrayUtils.sol";

pragma solidity 0.7.5;

contract StaticCheckETH {
    function checkETHSideWithOffset(address to, uint256 value, uint price, bytes memory data) internal pure {
        require(value > 0 && value == price, "checkETHSideWithOffset: Price must be same and greater than 0");
        address[] memory addrs = new address[](1);
        addrs[0] = to;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = price;
        require(ArrayUtils.arrayEq(ArrayUtils.arraySlice(data, 132, 196), abi.encodeWithSignature("transferETH(address[],uint256[])", addrs, amounts)));
    }

    function checkETHSideOneFeeWithOffset(address to, address feeRecipient, uint256 value, uint price, uint fee, bytes memory data) internal pure {
        require(value > 0 && value == SafeMath.add(price, fee), "checkETHSideOneFeeWithOffset: Price must be same and greater than 0");
        address[] memory addrs = new address[](2);
        addrs[0] = to;
        addrs[1] = feeRecipient;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = price;
        amounts[1] = fee;
        require(ArrayUtils.arrayEq(ArrayUtils.arraySlice(data, 132, 260), abi.encodeWithSignature("transferETH(address[],uint256[])", addrs, amounts)));
    }

    function checkETHSideTwoFeesWithOffset(address to, address feeRecipient, address royaltyFeeRecipient, uint256 value, uint price, uint fee, uint royaltyFee, bytes memory data) internal pure {
        require(value > 0 && value == SafeMath.add(SafeMath.add(price, fee), royaltyFee), "checkETHSideTwoFeesWithOffset: Price must be same and greater than 0");
        address[] memory addrs = new address[](3);
        addrs[0] = to;
        addrs[1] = feeRecipient;
        addrs[2] = royaltyFeeRecipient;
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = price;
        amounts[1] = fee;
        amounts[2] = royaltyFee;
        require(ArrayUtils.arrayEq(ArrayUtils.arraySlice(data, 132, 324), abi.encodeWithSignature("transferETH(address[],uint256[])", addrs, amounts)));
    }
}
