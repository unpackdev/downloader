// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "./SafeERC20.sol";
import "./IVault.sol";
import "./AdapterBase.sol";

// https://docs.yearn.finance/developers/yvaults-documentation/vault-interfaces#ivault
contract YvdaiAdapter is AdapterBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public governanceAccount;
    address public underlyingAssetAddress;
    address public programAddress;
    address public farmingPoolAddress;

    IVault private _yvdai;
    IERC20 private _underlyingAsset;

    constructor(
        address underlyingAssetAddress_,
        address programAddress_,
        address farmingPoolAddress_
    ) {
        require(
            underlyingAssetAddress_ != address(0),
            "YvdaiAdapter: underlying asset address is the zero address"
        );
        require(
            programAddress_ != address(0),
            "YvdaiAdapter: yvDai address is the zero address"
        );
        require(
            farmingPoolAddress_ != address(0),
            "YvdaiAdapter: farming pool address is the zero address"
        );

        governanceAccount = msg.sender;
        underlyingAssetAddress = underlyingAssetAddress_;
        programAddress = programAddress_;
        farmingPoolAddress = farmingPoolAddress_;

        _yvdai = IVault(programAddress);
        _underlyingAsset = IERC20(underlyingAssetAddress);
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "YvdaiAdapter: sender not authorized");
        _;
    }

    function getTotalWrappedTokenAmountCore()
        internal
        view
        override
        returns (uint256)
    {
        return _yvdai.balanceOf(address(this));
    }

    function getWrappedTokenPriceInUnderlyingCore()
        internal
        view
        override
        returns (uint256)
    {
        require(
            _yvdai.decimals() <= 18,
            "YvdaiAdapter: greater than 18 decimal places"
        );

        uint256 originalPrice = _yvdai.pricePerShare();
        uint256 scale = 18 - _yvdai.decimals();

        return originalPrice.mul(10**scale);
    }

    // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
    // The reentrancy check is in farming pool.
    function depositUnderlyingToken(uint256 amount)
        external
        override
        onlyBy(farmingPoolAddress)
        returns (uint256)
    {
        require(amount != 0, "YvdaiAdapter: can't add 0");

        _underlyingAsset.safeTransferFrom(msg.sender, address(this), amount);
        _underlyingAsset.safeApprove(programAddress, amount);
        uint256 receivedWrappedTokenQuantity =
            _yvdai.deposit(amount, address(this));

        // slither-disable-next-line reentrancy-events
        emit DepositUnderlyingToken(
            underlyingAssetAddress,
            programAddress,
            amount,
            receivedWrappedTokenQuantity,
            msg.sender,
            block.timestamp
        );

        return receivedWrappedTokenQuantity;
    }

    // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
    // The reentrancy check is in farming pool.
    function redeemWrappedToken(uint256 maxAmount)
        external
        override
        onlyBy(farmingPoolAddress)
        returns (uint256, uint256)
    {
        require(maxAmount != 0, "YvdaiAdapter: can't redeem 0");

        uint256 beforeBalance = _yvdai.balanceOf(address(this));
        // The default maxLoss is 1: https://github.com/yearn/yearn-vaults/blob/v0.3.0/contracts/Vault.vy#L860
        uint256 receivedUnderlyingTokenQuantity =
            _yvdai.withdraw(maxAmount, msg.sender, 1);
        uint256 afterBalance = _yvdai.balanceOf(address(this));

        uint256 actualAmount = beforeBalance.sub(afterBalance);
        // slither-disable-next-line reentrancy-events
        emit RedeemWrappedToken(
            underlyingAssetAddress,
            programAddress,
            maxAmount,
            actualAmount,
            receivedUnderlyingTokenQuantity,
            msg.sender,
            block.timestamp
        );

        return (actualAmount, receivedUnderlyingTokenQuantity);
    }

    function setGovernanceAccount(address newGovernanceAccount)
        external
        onlyBy(governanceAccount)
    {
        require(
            newGovernanceAccount != address(0),
            "YvdaiAdapter: new governance account is the zero address"
        );

        governanceAccount = newGovernanceAccount;
    }

    function setFarmingPoolAddress(address newFarmingPoolAddress)
        external
        onlyBy(governanceAccount)
    {
        require(
            newFarmingPoolAddress != address(0),
            "YvdaiAdapter: new farming pool address is the zero address"
        );

        farmingPoolAddress = newFarmingPoolAddress;
    }
}
