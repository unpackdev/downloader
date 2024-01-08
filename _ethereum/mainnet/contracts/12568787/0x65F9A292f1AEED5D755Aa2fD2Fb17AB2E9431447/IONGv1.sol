import "./IERC20.sol";

interface IONGv1 is IERC20 {
    function burn(uint256 value) external;
}
