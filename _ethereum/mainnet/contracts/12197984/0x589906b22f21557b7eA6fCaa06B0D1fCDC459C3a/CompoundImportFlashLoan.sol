pragma solidity ^0.6.0;

import "./AdminAuth.sol";
import "./FlashLoanReceiverBase.sol";
import "./ProxyRegistryInterface.sol";
import "./CTokenInterface.sol";
import "./SafeERC20.sol";

/// @title Receives FL from Aave and imports the position to DSProxy
contract CompoundImportFlashLoan is FlashLoanReceiverBase, AdminAuth {
    using SafeERC20 for ERC20;

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER =
        ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address public constant COMPOUND_BORROW_PROXY = 0xb7EDC39bE76107e2Cc645f0f6a3D164f5e173Ee2;
    address public constant PULL_TOKENS_PROXY = 0x45431b79F783e0BF0fe7eF32D06A3e061780bfc4;

    // solhint-disable-next-line no-empty-blocks
    constructor() public FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER) {}

    /// @notice Called by Aave when sending back the FL amount
    /// @param _reserve The address of the borrowed token
    /// @param _amount Amount of FL tokens received
    /// @param _fee FL Aave fee
    /// @param _params The params that are sent from the original FL caller contract
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external override {
        (address cCollAddr, address cBorrowAddr, address proxy) =
            abi.decode(_params, (address, address, address));

        address user = DSProxyInterface(proxy).owner();
        uint256 usersCTokenBalance = CTokenInterface(cCollAddr).balanceOf(user);

        if (_reserve != EthAddressLib.ethAddress()) {
            // approve FL tokens so we can repay them
            ERC20(_reserve).safeApprove(cBorrowAddr, _amount);

            // repay compound debt on behalf of the user
            require(
                CTokenInterface(cBorrowAddr).repayBorrowBehalf(user, uint256(-1)) == 0,
                "Repay borrow behalf fail"
            );
        } else {
            CTokenInterface(cBorrowAddr).repayBorrowBehalf{value: _amount}(user); // reverts on fail
        }

        bytes memory depositProxyCallData = formatDSProxyPullTokensCall(cCollAddr, usersCTokenBalance);
        DSProxyInterface(proxy).execute(PULL_TOKENS_PROXY, depositProxyCallData);

        // borrow debt now on ds proxy
        bytes memory borrowProxyCallData =
            formatDSProxyBorrowCall(cCollAddr, cBorrowAddr, _reserve, (_amount + _fee));
        DSProxyInterface(proxy).execute(COMPOUND_BORROW_PROXY, borrowProxyCallData);

        // repay the loan with the money DSProxy sent back
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));
    }

    /// @notice Formats function data call to pull tokens to DSProxy
    /// @param _cTokenAddr CToken address of the collateral
    /// @param _amount Amount of cTokens to pull
    function formatDSProxyPullTokensCall(
        address _cTokenAddr,
        uint256 _amount
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSignature(
            "pullTokens(address,uint256)",
            _cTokenAddr,
            _amount
        );
    }

    /// @notice Formats function data call borrow through DSProxy
    /// @param _cCollToken CToken address of collateral
    /// @param _cBorrowToken CToken address we will borrow
    /// @param _borrowToken Token address we will borrow
    /// @param _amount Amount that will be borrowed
    function formatDSProxyBorrowCall(
        address _cCollToken,
        address _cBorrowToken,
        address _borrowToken,
        uint256 _amount
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSignature(
            "borrow(address,address,address,uint256)",
            _cCollToken,
            _cBorrowToken,
            _borrowToken,
            _amount
        );
    }
}
