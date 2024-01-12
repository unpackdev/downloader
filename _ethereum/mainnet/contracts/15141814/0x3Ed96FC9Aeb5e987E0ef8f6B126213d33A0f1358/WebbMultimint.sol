// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./ERC1155.sol";

// @title WebbMultimint
// @author jamiedubs <https://jamiedubs.com>
// @desc by popular request, a contract to mint all 6 current images in a single txn
contract WebbMultimint is ERC1155TokenReceiver {
    IWebbNFT private webbNFT;

    constructor(address webbAddress) {
        webbNFT = IWebbNFT(webbAddress);
    }

    // it saves approx 2k gas to use arrays and `safeBatchTransferFrom`
    // rather than transferring each item individually with `safeTransferFrom`
    // more code, but we like saving gas <3
    // ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
    // │ Function Name            ┆ min             ┆ avg   ┆ median ┆ max    ┆ # calls │
    // ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
    // │ mintAllWithTransfer      ┆ 75093           ┆ 86245 ┆ 75093  ┆ 130853 ┆ 5       │
    // ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
    // │ mintAllWithBatchTransfer ┆ 73452           ┆ 73452 ┆ 73452  ┆ 73452  ┆ 5       │
    // ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
    function mintAll() public {
        uint256 maxID = webbNFT.maxID();
        uint256[] memory ids = new uint256[](maxID);
        uint256[] memory amounts = new uint256[](maxID);

        for (uint256 i = 0; i < maxID; i++) {
            uint256 id = i + 1;
            webbNFT.mint(id);

            ids[i] = id;
            amounts[i] = 1;
        }

        webbNFT.safeBatchTransferFrom(
            address(this),
            msg.sender,
            ids,
            amounts,
            ""
        );
    }
}

// prettier-ignore
interface IWebbNFT {
    function mint(uint256 id) external;
    function owner() external returns (address);
    function maxID() external returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}
