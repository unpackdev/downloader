// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./IERC721Upgradeable.sol";

interface IDegenopolyNode is IERC721Upgradeable {
    function color() external view returns (string memory);

    function rewardPerSec() external view returns (uint256);

    function purchasePrice() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function mint(address to) external;

    function burn(uint256 tokenId) external;

    function syncReward(address _account) external;

    function claimReward(address _account) external returns (uint256 pending);

    function claimableReward(
        address _account
    ) external view returns (uint256 pending);
}
