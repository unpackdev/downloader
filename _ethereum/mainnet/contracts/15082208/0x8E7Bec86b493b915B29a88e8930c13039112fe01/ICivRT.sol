import "./IERC20.sol";
import "./IAccessControl.sol";

interface ICivRT is IERC20, IAccessControl {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}
