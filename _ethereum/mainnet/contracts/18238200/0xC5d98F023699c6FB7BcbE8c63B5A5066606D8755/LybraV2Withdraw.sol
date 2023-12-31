// commit a240b5339a90f4c765f04f2704512c7558bb45aa
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

interface ILybraVault {
    function burn(address onBehalfOf, uint256 amount) external;

    function withdraw(address onBehalfOf, uint256 amount) external;

    function getBorrowedOf(address user) external view returns (uint256);

    function depositedAsset(address user) external view returns (uint256);
}

interface IERC20 {
    function approve(address to, uint256 amount) external;
}

contract LybraV2Withdraw {
    bytes32 public constant NAME = "LybraV2Withdraw";
    uint256 public constant VERSION = 1;

    ILybraVault public constant stETHvault = ILybraVault(0xa980d4c0C2E48d305b582AA439a3575e3de06f0E);
    ILybraVault public constant rETHvault = ILybraVault(0x090B2787D6798000710a8e821EC6111d254bb958);
    ILybraVault public constant wstETHvault = ILybraVault(0x5e28B5858DA2C6fb4E449D69EEb5B82e271c45Ce);
    ILybraVault public constant wbETHvault = ILybraVault(0xB72dA4A9866B0993b9a7d842E5060716F74BF262);

    IERC20 public constant peUSD = IERC20(0xD585aaafA2B58b1CD75092B51ade9Fa4Ce52F247);

    function withdraw(address vault) external {
        require(vault == address(stETHvault) || vault == address(rETHvault) || vault == address(wstETHvault) || vault == address(wbETHvault), "LybraV2Withdraw: vault not supported");
        if (vault == address(stETHvault)) {
            handleEUSDRepayAndWithdraw();
        } else {
            handlePEUSDRepayAndWithdraw(vault);
        }
    }

    function handlePEUSDRepayAndWithdraw(address vault) internal {
        ILybraVault actualVault = ILybraVault(vault);
        uint256 peUSD_amount;
        uint256 collateral;
        peUSD.approve(address(actualVault), 2 ** 256 - 1);
        (peUSD_amount, collateral) = getUserBorrowAndCollateral(actualVault);
        burnAndRepayVault(actualVault, peUSD_amount, collateral);
        peUSD.approve(address(actualVault), 0);
    }

    function handleEUSDRepayAndWithdraw() internal {
        (uint256 eUSD_amount, uint256 collateral_amount) = getUserBorrowAndCollateral(stETHvault);
        burnAndRepayVault(stETHvault, eUSD_amount, collateral_amount);
    }

    function getUserBorrowAndCollateral(
        ILybraVault vault
    ) internal view returns (uint256 borrowed, uint256 collateral) {
        borrowed = vault.getBorrowedOf(address(this));

        collateral = vault.depositedAsset(address(this));
    }

    function burnAndRepayVault(ILybraVault vault, uint256 borrowed, uint256 collateral) internal {
        if (borrowed > 0) {
            vault.burn(address(this), borrowed);
        }
        if (collateral > 1) {
            vault.withdraw(address(this), collateral - 1);
        }
    }
}
