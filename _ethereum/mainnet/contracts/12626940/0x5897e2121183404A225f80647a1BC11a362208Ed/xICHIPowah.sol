// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./SafeMath.sol";

interface IStake {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract xICHIPowah {
    using SafeMath for uint256;

    string public DESCRIPTION = "ICHIPowah Interperter for xICHI tokens";

    address public ICHIaddress = 0x903bEF1736CDdf2A537176cf3C64579C3867A881; //mainnet

    function getSupply(address instance) public view returns (uint256 ichi) {
        IStake stake = IStake(instance);
        IERC20 ichiToken = IERC20(ICHIaddress);

        ichi = ichiToken.balanceOf(address(stake));
    }

    function getPowah(address instance, address user) public view returns (uint256 ichi) {
        IStake stake = IStake(instance);
        IERC20 ichiToken = IERC20(ICHIaddress);

        uint256 xICHI_totalICHI = ichiToken.balanceOf(address(stake));
        uint256 xICHI_balance = stake.balanceOf(user);
        uint256 xICHI_total = stake.totalSupply();
    
        ichi = xICHI_totalICHI.mul(xICHI_balance).div(xICHI_total);
    }
}

