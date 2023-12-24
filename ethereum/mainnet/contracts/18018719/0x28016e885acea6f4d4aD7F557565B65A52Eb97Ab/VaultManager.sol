// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./IVaultFactory.sol";
import "./IVault.sol";
import "./IStETH.sol";

// Stateless contracts for executing vault interactions. Used by external contracts, UIs and looper admins.
contract VaultManager is Ownable {

    IVaultFactory public immutable factory;

    constructor(address _factory) {
        factory = IVaultFactory(_factory);
    }

    function depositAndMintWithETH(uint _mintAmount) external payable {
        IStETH stETH = IStETH(address(factory.collateral()));
        uint before = factory.collateral().balanceOf(address(this));
        if (msg.value > 0) {
            stETH.submit{value: msg.value}(address(0));
        }
        uint actualDepositedAmount = factory.collateral().balanceOf(address(this)) - before;
        _depositAndMint(actualDepositedAmount, _mintAmount);
    }

    function depositAndMint(uint _depositAmount, uint _mintAmount) external {
        uint before = factory.collateral().balanceOf(address(this));
        factory.collateral().transferFrom(msg.sender, address(this), _depositAmount);
        uint actualDepositedAmount = factory.collateral().balanceOf(address(this)) - before;
        _depositAndMint(actualDepositedAmount, _mintAmount);
    }

    function _depositAndMint(uint _depositAmount, uint _mintAmount) internal {
        IVault vault = IVault(factory.getVault(msg.sender));
        require(address(vault) != address(0), "vault not exist");
        if (_depositAmount > 0) {
            factory.collateral().approve(address(vault), _depositAmount);
            vault.deposit(_depositAmount);
        }
        uint available = vault.availableBalance();
        // Cap mint at available balance
        _mintAmount = _mintAmount > available ? available : _mintAmount;

        if (_mintAmount > 0) {
            vault.mint(_mintAmount);
        }
    }

    function burnAndWithdraw(uint _burnAmount, uint _withdrawAmount) external {
        IVault vault = IVault(factory.getVault(msg.sender));
        require(address(vault) != address(0), "vault not exist");
        if (_burnAmount > 0) {
            factory.token().transferFrom(msg.sender, address(this), _burnAmount);
            factory.token().approve(address(vault), _burnAmount);
            vault.burn(_burnAmount);
        }
        if (_withdrawAmount > 0) {
            vault.withdraw(_withdrawAmount);
        }
    }

    function redeem(uint _amount, IVault[] calldata vaults) external {
        uint vaultManagerCollateralBefore = factory.collateral().balanceOf(address(this));
        factory.token().transferFrom(msg.sender, address(this), _amount);
        for (uint i=0; i<vaults.length; i++) {
            uint amountToRedeem = _amount > vaults[i].minted() ? vaults[i].minted() : _amount;

            // skip vaults with no minted tokens
            if (amountToRedeem > 0) {
                factory.token().approve(address(vaults[i]), amountToRedeem);
                vaults[i].redeem(amountToRedeem);
                _amount -= amountToRedeem;
            }

            if (_amount == 0) break;
        }
        // caclulate amount of collateral redeemed and transfer to msg.sender
        uint redeemed = factory.collateral().balanceOf(address(this)) - vaultManagerCollateralBefore;
        factory.collateral().transfer(msg.sender, redeemed);

        require(_amount == 0, "VaultManager: insufficient vault balance to redeem");
    }

    // Manager should not have any balances, allow rescuing of accidental transfers
    function rescue(address _token, address _recipient) external onlyOwner {
        uint _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_recipient, _balance);
    }
}
