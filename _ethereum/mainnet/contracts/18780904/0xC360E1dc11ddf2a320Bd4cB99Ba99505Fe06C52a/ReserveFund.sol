// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// interfaces
import "./IReserveFund.sol";
// libraries
import "./Contracts.sol";
// mixins
import "./MixinAccessControl.sol";
import "./MixinAddressResolver.sol";
// utils
import "./Proxyable.sol";
import "./MixinWallet.sol";
// storages
import "./ReserveFundStorage.sol";

/**
 * @notice Implements managing of the reserve fund.
 *
 * This contract receives the fees from the lending market and uses them to cover to avoid the protocol insolvency.
 */
contract ReserveFund is
    IReserveFund,
    MixinAccessControl,
    MixinAddressResolver,
    MixinWallet,
    Proxyable
{
    receive() external payable {}

    /**
     * @notice Initializes the contract.
     * @dev Function is invoked by the proxy contract when the contract is added to the ProxyController.
     * @param _owner The address of the contract owner
     * @param _resolver The address of the Address Resolver contract
     * @param _nativeToken The address of wrapped token of native currency
     */
    function initialize(
        address _owner,
        address _resolver,
        address _nativeToken
    ) public initializer onlyProxy {
        Storage.slot().paused = false;

        registerAddressResolver(_resolver);
        MixinWallet._initialize(_owner, _nativeToken);
        MixinAccessControl._setupInitialRoles(_owner);
    }

    // @inheritdoc MixinAddressResolver
    function requiredContracts() public pure override returns (bytes32[] memory contracts) {
        contracts = new bytes32[](1);
        contracts[0] = Contracts.TOKEN_VAULT;
    }

    /**
     * @notice Gets if the reserve fund is paused.
     * @return The boolean if the reserve fund is paused
     */
    function isPaused() public view override returns (bool) {
        return Storage.slot().paused;
    }

    /**
     * @notice Pauses the reserve fund.
     */
    function pause() public override onlyOperator {
        Storage.slot().paused = true;
        emit Pause(msg.sender);
    }

    /**
     * @notice Unpauses the reserve fund.
     */
    function unpause() public override onlyOperator {
        Storage.slot().paused = false;
        emit Unpause(msg.sender);
    }

    /**
     * @dev Deposits funds by the caller into the token vault as reserve fund.
     * @param _ccy Currency name in bytes32
     * @param _amount Amount of funds to deposit
     */
    function deposit(bytes32 _ccy, uint256 _amount) external payable onlyOwner {
        _deposit(tokenVault(), _ccy, _amount);
    }

    /**
     * @dev Withdraw funds by the caller from the token vault.
     * @param _ccy Currency name in bytes32
     * @param _amount Amount of funds to deposit
     */
    function withdraw(bytes32 _ccy, uint256 _amount) external onlyOwner {
        _withdraw(tokenVault(), _ccy, _amount);
    }
}
