pragma solidity >=0.6.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract MockStakedAave is ERC20 {
    using SafeMath for uint256;

    IERC20 aave;

    constructor(IERC20 _aave) public ERC20("stAAVE", "stAAVE") {
        aave = _aave;
    }

    function stake(address to, uint256 amount) external {
        aave.transferFrom(to, address(this), amount);
        super._mint(to, amount);
    }

    function redeem(address to, uint256 amount) external {
        super._burn(to, amount);
        aave.transfer(to, amount);
    }

    function cooldown() external {

    }

    // must transfer aave to this contract first
    function claimRewards(address to, uint256 amount) external {
        uint currentStakedBal = IERC20(address(this)).balanceOf(to);
        uint rewards = currentStakedBal.div(1000); // random fixed reward
        aave.transfer(to, rewards);
    }
}