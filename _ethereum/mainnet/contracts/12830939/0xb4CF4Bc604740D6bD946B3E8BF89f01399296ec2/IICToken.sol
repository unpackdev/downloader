// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IICToken {
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    function mint(uint64 term_, uint256 amount_, uint64[] calldata maturities_, uint32[] calldata percentages_,
        string memory originalInvestor_) external returns (uint256, uint256);

    function claim(uint256 tokenId, uint256 amount)  external ;
    function claimAll(uint256 tokenId)  external ;
    function claimableAmount(uint256 tokenId_) external view returns(uint256);

    function recharge(uint256 tokenId_, uint256 amount_) external;
}