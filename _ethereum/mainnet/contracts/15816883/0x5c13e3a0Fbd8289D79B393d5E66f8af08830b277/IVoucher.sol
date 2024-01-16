// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IERC1155Upgradeable.sol";

interface IVoucher is IERC1155Upgradeable {
    event VoucherCreated(
        uint256 id,
        VoucherEffect effect,
        VoucherType vtype,
        uint256 discount,
        uint256 expiredAt,
        uint8 strlen
    );

    enum VoucherEffect {
        Register,
        Renewal,
        General
    }

    enum VoucherType {
        Discount,
        Deduct
    }

    struct VoucherInfo {
        VoucherEffect effect;
        VoucherType vtype;
        uint256 discount; // Discount or deduct(usd) amount
        bool isAll; // Whether all TLDs can be registered
        bool isPermanent;
        uint256 expiredAt;
        uint8 strlen; // 1,2,3,4,5...
    }

    function createVoucher(
        VoucherInfo memory info,
        address[] calldata registrars
    ) external;

    function voucherOf(uint256 id)
        external
        view
        returns (VoucherInfo memory voucher, address[] memory registrars);

    function checkout(
        uint256 id,
        VoucherEffect effect,
        address registrar,
        string memory domainName,
        address currency,
        uint256 price
    ) external view returns (uint256);

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}
