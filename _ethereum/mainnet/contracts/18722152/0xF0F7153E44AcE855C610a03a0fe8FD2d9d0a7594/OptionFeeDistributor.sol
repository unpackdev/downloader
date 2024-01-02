pragma solidity 0.8.13;

import "./IERC20.sol";

contract OptionFeeDistributor {
    address public constant address1 =
        0x1530A9a40cF0a5afc6898128083Bc8334e2dF4E2;
    address public constant address2 =
        0x88A82Fa2AE25296a4cD11aB7f5393325c6167aF4;

    function distribute(IERC20 token, uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount));

        uint256 half = amount / 4;
        uint256 otherHalf = amount - half;

        require(token.transfer(address1, half));
        require(token.transfer(address2, otherHalf));
    }
}
