// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ISolver {
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    function isSolver() external returns (bool);

    function depositAllowed(
        address product,
        address depositor,
        uint64 term,
        uint256 depositAmount,
        uint64[] calldata maturities
    ) external returns (uint256);

    function depositVerify(
        address product,
        address depositor,
        uint256 depositAmount,
        uint256 tokenId,
        uint64 term,
        uint64[] calldata maturities
    ) external returns (uint256);

    function withdrawAllowed(
        address product,
        address payee,
        uint256 withdrawAmount,
        uint256 tokenId,
        uint64 term,
        uint64 maturity
    ) external returns (uint256);

    function withdrawVerify(
        address product,
        address payee,
        uint256 withdrawAmount,
        uint256 tokenId,
        uint64 term,
        uint64 maturity
    ) external returns (uint256);

    function transferFromAllowed(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external returns (uint256);

    function transferFromVerify(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external returns (uint256);

    function mergeAllowed(
        address product,
        address owner,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external returns (uint256);

    function mergeVerify(
        address product,
        address owner,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external returns (uint256);

    function splitAllowed(
        address product,
        address owner,
        uint256 tokenId,
        uint256 newTokenId,
        uint256 amount
    ) external returns (uint256);

    function splitVerify(
        address product,
        address owner,
        uint256 tokenId,
        uint256 newTokenId,
        uint256 amount
    ) external returns (uint256);

    function needConvertUnsafeTransfer(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 units
    ) external view returns (bool);

    function needRejectUnsafeTransfer(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 units
    ) external view returns (bool);

    function publishFixedPriceAllowed(
        address icToken,
        uint256 tokenId,
        address seller,
        address currency,
        uint256 min,
        uint256 max,
        uint256 startTime,
        bool useAllowList,
        uint256 price
    ) external returns (uint256);

    function publishDecliningPriceAllowed(
        address icToken,
        uint256 tokenId,
        address seller,
        address currency,
        uint256 min,
        uint256 max,
        uint256 startTime,
        bool useAllowList,
        uint256 highest,
        uint256 lowest,
        uint256 duration,
        uint256 interval
    ) external returns (uint256);

    function publishVerify(
        address icToken,
        uint256 tokenId,
        address seller,
        address currency,
        uint256 saleId,
        uint256 units
    ) external;

    function buyAllowed(
        address icToken,
        uint256 tokenId,
        uint256 saleId,
        address buyer,
        address currency,
        uint256 buyAmount,
        uint256 buyUnits,
        uint256 price
    ) external returns (uint256);

    function buyVerify(
        address icToken,
        uint256 tokenId,
        uint256 saleId,
        address buyer,
        address seller,
        uint256 amount,
        uint256 units,
        uint256 price,
        uint256 fee
    ) external;

    function removeAllow(
        address icToken,
        uint256 tokenId,
        uint256 saleId,
        address seller
    ) external returns (uint256);
}
