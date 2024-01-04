pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

// proof of concept for keeping score based on different contracts that can add to it with right role

interface IERC20 {
    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function totalSupply() external view returns (uint256);
}

interface IMasterChef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    function userInfo(uint256 _poolId, address _user)
        external
        view
        returns (IMasterChef.UserInfo memory);
}

contract GetVotes {
    using SafeMath for uint256;
    IERC20 public muse = IERC20(0xB6Ca7399B4F9CA56FC27cBfF44F4d2e4Eef1fc81);
    IERC20 public uniLp = IERC20(0x20d2C17d1928EF4290BF17F922a10eAa2770BF43);
    IMasterChef public masterChef = IMasterChef(0x8aFc8Ade73393728d548d8Ca4Fd7Bde76C354f28);

    function getVotes(address _user) public view returns (uint256) {
        uint256 userMuseBalance = muse.balanceOf(_user);
        // lp tokens from user on masterchef
        uint256 userLpTokens = masterChef.userInfo(0, _user).amount;
        //total supply of of muse in lp
        uint256 museInLpPool = muse.balanceOf(address(uniLp));
        //total supply of lp tokens
        uint256 lpTokensTotalSupply = uniLp.totalSupply();
        // do calc for uniswap
        uint256 museFromStake = museInLpPool.div(lpTokensTotalSupply).mul(userLpTokens);
        return (userMuseBalance.add(museFromStake).div(1 ether));
    }
}
