import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

interface IERC20 {
    function transfer(address receipient, uint256 amount)
        external
        returns (bool);

    function approve(address _spender, uint256 _amount) external;

    function balanceOf(address holder) external view returns (uint256);
}

contract StakerBase is OwnableUpgradeable  {
    function withdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {            
            IERC20(token).transfer(to, amount);
        }
    }
}
