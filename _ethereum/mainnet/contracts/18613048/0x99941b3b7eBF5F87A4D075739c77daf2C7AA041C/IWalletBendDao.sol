// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IWallet.sol";

interface IWalletBendDao is IWallet {
    function repayBendDaoLoan(
        address collection,
        uint256 tokenId,
        uint256 amount,
        address currency
    ) external;
}
