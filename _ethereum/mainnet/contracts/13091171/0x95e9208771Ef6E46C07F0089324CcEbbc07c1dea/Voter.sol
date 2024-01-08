// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

interface IMasterChef {
    function userInfo(uint256, address) external view returns (uint256, uint256);
}

contract DFXSnapshot {
    IMasterChef public constant CHEF = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);

    IERC20 public constant DFX_ETH_SUSHI_LP = IERC20(0xBE71372995E8e920E4E72a29a51463677A302E8d);
    IERC20 public constant DFX = IERC20(0x888888435FDe8e7d4c54cAb67f206e4199454c60);

    function decimals() external pure returns (uint8) {
        return uint8(18);
    }

    function name() external pure returns (string memory) {
        return "DFX Snapshot";
    }

    function symbol() external pure returns (string memory) {
        return "DFXS";
    }

    function totalSupply() external view returns (uint256) {
        return DFX.totalSupply();
    }

    function balanceOf(address _voter) public view returns (uint256) {
        // DFX/ETH is pool id 172
        (uint256 _stakedSlpAmount, ) = CHEF.userInfo(172, _voter);
        uint256 slpAmount = DFX_ETH_SUSHI_LP.balanceOf(_voter);
        uint256 bareAmount = DFX.balanceOf(_voter);

        uint256 votePower = getAmountFromSLP(_stakedSlpAmount) + getAmountFromSLP(slpAmount) + bareAmount;

        return votePower;
    }

    function getAmountFromSLP(uint256 _slpAmount) public view returns (uint256) {
        uint256 tokenAmount = DFX.balanceOf(address(DFX_ETH_SUSHI_LP));
        uint256 tokenSupply = DFX_ETH_SUSHI_LP.totalSupply();

        return _slpAmount * 1e18 / tokenSupply * tokenAmount / 1e18;
    }
}
