// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

import "./SafeERC20.sol";
import "./IUniverseVaultV3.sol";

interface IAccountInterface {

    function accountID(address contractAddress) external view returns (uint64);

}

interface IUniverseAddressResolver {

    function checkUniverseVault(address _vault) external view returns (bool);

}

contract UniverseAdapter {

    using SafeERC20 for IERC20;

    IAccountInterface private constant accountInterface = IAccountInterface(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);
    IUniverseAddressResolver private constant addressResolver = IUniverseAddressResolver(0x7466420dC366DF67b55daeDf19f8d37a346Fa7C8);

    /// @notice DSL Deposit In Universe Vault
    /// @param universeVault Universe Vault Address
    /// @param amount0 Token0 Amount to deposit in
    /// @param amount1 Token1 Amount to deposit in
    /// @return uToken0Amount Amount of uToken0 sent to Owner
    /// @return uToken1Amount Amount of uToken1 sent to Owner
    function depositProxy (
        address universeVault,
        uint256 amount0,
        uint256 amount1
    ) external returns(uint256 uToken0Amount, uint256 uToken1Amount){
        // For safety.
        require(addressResolver.checkUniverseVault(universeVault), 'Not Universe Vault!');
        // Check DSL
        require(accountInterface.accountID(msg.sender) != 0, "Invalid Address!");
        // Vault OBJ
        IUniverseVaultV3 vaultV3 = IUniverseVaultV3(universeVault);
        // Transfer Tokens
        IERC20 token;
        if(amount0 > 0){
            token = vaultV3.token0();
            token.safeTransferFrom(msg.sender, address(this), amount0);
            token.approve(universeVault, amount0);
        }
        if(amount1 > 0){
            token = vaultV3.token1();
            token.safeTransferFrom(msg.sender, address(this), amount1);
            token.approve(universeVault, amount1);
        }
        // Deposit in UniverseVault with Owner Address
        return vaultV3.deposit(amount0, amount1, msg.sender);
    }

}
