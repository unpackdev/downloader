// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IBondPool {

    struct SlotDetail {
        address issuer;
        uint256 totalValue;
        uint64 effectiveTime;
        uint64 maturity;
        bool isIssuerRefunded;
        bool isValid;
    }

    event NewVoucher(address oldVoucher, address newVoucher);

    event CreateSlot(
        uint256 indexed slot,
        address indexed issuer,
        uint64 effectiveTime,
        uint64 maturity
    );

    event Mint(
        address indexed minter,
        uint256 indexed slot,
        uint256 value
    );

    event Refund(uint256 indexed slot, address sender, uint256 refundAmount);

    function mint(
        address minter_,
        uint256 slot_,
        uint256 mintValue_
    ) external;

    function claim(
        uint256 slot_,
        address to_,
        uint256 claimValue_
    ) external returns (uint256);

    function refund(uint256 slot_) external;

}
