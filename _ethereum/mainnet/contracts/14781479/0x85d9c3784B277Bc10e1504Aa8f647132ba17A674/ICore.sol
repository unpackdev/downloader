// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "./RegistryEntities.sol";
import "./LibDerivative.sol";

interface ICore {
    function initialize(address _governor) external;

    function getProtocolParametersArgs() external view returns (RegistryEntities.ProtocolParametersArgs memory);

    function getProtocolAddresses() external view returns (RegistryEntities.ProtocolAddressesArgs memory);

    function getReservesVaultBalance(address _reseveRecipient, address _token) external view returns (uint256);

    function getDerivativePayouts(bytes32 _derivativeHash) external view returns (uint256[2] memory);

    function getP2pDerivativeVaultFunds(bytes32 _derivativeHash) external view returns (uint256);

    function isDerivativeCancelled(bytes32 _derivativeHash) external view returns (bool);

    function updateProtocolParametersArgs() external;

    function updateProtocolAddresses() external;

    function claimReserves(address _tokenAddress) external;

    function claimReserves(address _tokenAddress, uint256 _amount) external;

    function create(
        LibDerivative.Derivative calldata _derivative,
        uint256 _amount,
        address[2] calldata _positionsOwners
    ) external;

    function createAndMint(
        LibDerivative.Derivative calldata _derivative,
        uint256 _amount,
        address[2] calldata _positionsOwners,
        string calldata _derivativeAuthorCustomName
    ) external;

    function mint(
        uint256 _amount,
        address[2] calldata _positionsAddresses,
        address[2] calldata _positionsOwners
    ) external;

    function execute(address _positionAddress, uint256 _amount) external;

    function execute(
        address _positionOwner,
        address _positionAddress,
        uint256 _amount
    ) external;

    function execute(address[] calldata _positionsAddresses, uint256[] calldata _amounts) external;

    function execute(
        address _positionsOwner,
        address[] calldata _positionsAddresses,
        uint256[] calldata _amounts
    ) external;

    function redeem(address[2] calldata _positionsAddresses, uint256 _amount) external;

    function redeem(address[2][] calldata _positionsAddresses, uint256[] calldata _amounts) external;

    function cancel(address _positionAddress, uint256 _amount) external;

    function cancel(address[] calldata _positionsAddresses, uint256[] calldata _amounts) external;
}
