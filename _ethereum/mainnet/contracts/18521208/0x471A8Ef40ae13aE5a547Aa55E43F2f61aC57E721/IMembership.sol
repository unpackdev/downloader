import "./IERC721.sol";

interface IMembership is IERC721 {
    function deposit(uint256 id, address token, uint256 value) external;
    function approveERC20tokens(uint256 id, address token, address operator, uint256 value) external;
    function transferFromERC20(uint256 id, address token, address to, uint256 value) external;
}