// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./BoringMath.sol";
import "./BoringERC20.sol";
import "./IBentoBoxV1.sol";

interface IYearnVault {
    function deposit(uint256 amount, address recipient) external returns (uint256 shares);
}

contract YearnLiquidityMigrationHelper {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;

    // Local variables
    IBentoBoxV1 public immutable bentoBox;

    constructor(IBentoBoxV1 bentoBox_) public {
        bentoBox = bentoBox_;
    }

    function migrate(
        IERC20 token,
        IYearnVault vault,
        uint256 amount,
        address recipient
    ) external {
        token.approve(address(vault), amount);
        uint256 shares = vault.deposit(amount, address(bentoBox));
        bentoBox.deposit(token, address(bentoBox), recipient, shares, 0);
    }
}
