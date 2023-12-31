// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./IEGMC.sol";

contract EGMCRewardsDistributor is Ownable {
    using SafeMath for uint;

    address public immutable token;
    address public immutable WETH;
    address public mine;
    uint public wethPercentage; // in bp
    uint public tokenPercentage; // in bp

    constructor (
        address _token,
        address _mine
    ) {
        token = _token;
        WETH = IEGMC(token).WETH();
        mine = _mine;

        wethPercentage = uint(2500).div(24);
        tokenPercentage = wethPercentage;
    }

    /** VIEW FUNCTIONS */

    function getAmounts() public view returns (uint goldRewards, uint silverRewards) {
        goldRewards = IERC20(WETH).balanceOf(address(this)).mul(wethPercentage).div(10000);
        silverRewards = IERC20(token).balanceOf(address(this)).mul(tokenPercentage).div(10000);
    }

    /** PUBLIC FUNCTIONS */

    function distribute() external returns (uint goldAmount, uint silverAmount) {
        require(_msgSender() == mine, "Only the mine can call this function");

        (goldAmount, silverAmount) = getAmounts();
        if (goldAmount > 0) {
            IERC20(WETH).transfer(mine, goldAmount);
        }

        if (silverAmount > 0) {
            IERC20(token).transfer(mine, silverAmount);
        }
    }

    /** RESTRICTED FUNCTIONS */

    function setMine(address _mine) external onlyOwner {
        mine = _mine;
    }

    function setPercentages(uint _wethPercentage, uint _tokenPercentage) external onlyOwner {
        wethPercentage = _wethPercentage.div(24);
        tokenPercentage = _tokenPercentage.div(24);
    }

    function recover(address _token) external onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}