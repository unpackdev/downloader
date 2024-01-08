// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IMirrorOpenSaleV0Events {
    event RegisteredSale(
        bytes32 h,
        address indexed token,
        uint256 startTokenId,
        uint256 endTokenId,
        address indexed operator,
        address indexed recipient,
        uint256 price,
        bool open,
        uint256 feePercentage
    );

    event Purchase(
        bytes32 h,
        address indexed token,
        uint256 tokenId,
        address indexed buyer,
        address indexed recipient
    );

    event Withdraw(
        bytes32 h,
        uint256 amount,
        uint256 fee,
        address indexed recipient
    );

    event OpenSale(bytes32 h);

    event CloseSale(bytes32 h);
}

interface IMirrorOpenSaleV0 {
    struct Sale {
        bool registered;
        bool open;
        uint256 sold;
        address operator;
    }

    struct SaleConfig {
        address token;
        uint256 startTokenId;
        uint256 endTokenId;
        address operator;
        address recipient;
        uint256 price;
        bool open;
        uint256 feePercentage;
    }

    function treasuryConfig() external returns (address);

    function feeRegistry() external returns (address);

    function tributaryRegistry() external returns (address);

    function sale(bytes32 h) external view returns (Sale memory);

    function register(SaleConfig calldata saleConfig_) external;

    function close(SaleConfig calldata saleConfig_) external;

    function open(SaleConfig calldata saleConfig_) external;

    function purchase(SaleConfig calldata saleConfig_, address recipient)
        external
        payable;
}
