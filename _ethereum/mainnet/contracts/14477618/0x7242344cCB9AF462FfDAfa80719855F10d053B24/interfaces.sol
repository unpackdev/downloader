//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface VaultInterface {
    function balanceOf(address account) external view returns (uint256);

    function getCurrentExchangePrice()
        external
        view
        returns (
            uint256 exchangePrice_,
            uint256 newRevenue_
        );
    
    struct BalVariables {
        uint wethVaultBal;
        uint wethDsaBal;
        uint stethVaultBal;
        uint stethDsaBal;
        uint totalBal;
    }

    function netAssets() external view returns (
        uint netCollateral_,
        uint netBorrow_,
        BalVariables memory balances_,
        uint netSupply_,
        uint netBal_
    );

    struct Ratios {
        uint16 maxLimit; // Above this withdrawals are not allowed
        uint16 minLimit; // After leverage the ratio should be below minLimit & above minLimitGap
        uint16 minLimitGap;
        // send borrow rate in 4 decimals from UI. In the smart contract it'll convert to 27 decimals which where is 100%
        uint128 maxBorrowRate; // maximum borrow rate above this leveraging should not happen
    }

    // maximum borrow rate. If above this limit then leverage won't happen
    function ratios() external view returns (Ratios memory);

    function vaultDsa() external view returns (address);

    function lastRevenueExchangePrice() external view returns (uint256);

    function revenueFee() external view returns (uint256);

    function revenue() external view returns (uint256);
}