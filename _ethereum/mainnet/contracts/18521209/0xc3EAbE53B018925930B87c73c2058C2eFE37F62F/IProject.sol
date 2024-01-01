import "./IERC20.sol";
import "./IMembership.sol";

interface IProject {
    function initialize(string memory _title, string memory name, string memory symbol, string memory _description, string memory _image, string memory _projectLink, uint256 _termOfInvestment, uint256 _apy) external;
}