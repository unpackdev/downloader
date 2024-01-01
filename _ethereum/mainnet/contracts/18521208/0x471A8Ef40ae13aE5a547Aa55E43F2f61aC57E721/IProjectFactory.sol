import "./IERC20.sol";
import "./IMembership.sol";

interface IProjectFactory {
    function rewardToken() external view returns (IERC20);
    function coccToken() external view returns (IERC20);
    function membership() external view returns (IMembership);
    function owner() external view returns (address);
}