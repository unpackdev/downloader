import "./IERC20.sol";

interface IInfinityProtocol is IERC20 {
    function burn(uint amount) external returns (bool);
}