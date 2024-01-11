// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

interface PayableFactoryERC1155Upgradeable is IERC165Upgradeable {
    function fixedPrice() external view returns (uint256);

    function buy(
        address _toAddress,
        uint256 _amount,
        bytes calldata _data
    ) external payable;

    function canMint(uint256 _amount) external view returns (bool);

    function balanceOf(address _fromAddress) external view returns (uint256);
}
