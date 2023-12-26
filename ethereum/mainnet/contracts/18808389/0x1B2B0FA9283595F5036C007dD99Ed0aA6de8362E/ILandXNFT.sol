// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ILandXNFT {
    function tillableArea(uint256 id) external view returns (uint256);

    function cropShare(uint256 id) external view returns (uint256);

    function crop(uint256 id) external view returns (string memory);

    function validatorFee(uint256 id) external view returns (uint256);

    function validator(uint256 id) external view returns (address);

    function initialOwner(uint256 id) external view returns (address);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}