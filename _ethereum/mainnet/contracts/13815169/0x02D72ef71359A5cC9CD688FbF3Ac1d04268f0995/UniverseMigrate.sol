// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeERC20.sol";
import "./IUniverseVault.sol";
import "./IERC20Detail.sol";


interface IUniverseAddressResolver {

    function checkUniverseVault(address _vault) external view returns (bool);

}

contract UniverseMigrate {

    using SafeERC20 for IERC20Detail;

    IUniverseAddressResolver private constant addressResolver = IUniverseAddressResolver(0x7466420dC366DF67b55daeDf19f8d37a346Fa7C8);

    function migrate(
        address _fromVault,
        address _fromToken0,
        address _fromToken1,
        address _toVault
    ) external {
        require(addressResolver.checkUniverseVault(_toVault) && addressResolver.checkUniverseVault(_fromVault), "not Official Vault!");
        IUniverseVault fv = IUniverseVault(_fromVault);
        IUniverseVault tv = IUniverseVault(_toVault);
        (uint256 amount0, uint256 amount1) = fv.getUserShares(msg.sender);
        if (amount0 > 0) {
            IERC20Detail(_fromToken0).safeTransferFrom(msg.sender, address(this), amount0);
        }
        if (amount1 > 0) {
            IERC20Detail(_fromToken1).safeTransferFrom(msg.sender, address(this), amount1);
        }
        // Withdraw From fromVault
        (amount0, amount1) = fv.withdraw(amount0, amount1);
        // Deposit In toVault
        if (amount0 > 0) {
            tv.token0().safeApprove(address(tv), amount0);
        }
        if (amount1 > 0) {
            tv.token1().safeApprove(address(tv), amount1);
        }
        tv.deposit(amount0, amount1, msg.sender);
        // Event
        emit Migrate(msg.sender, _fromVault, _toVault, amount0, amount1);

    }

    event Migrate(address indexed user, address from, address to, uint256 amount0, uint256 amount1);
}
