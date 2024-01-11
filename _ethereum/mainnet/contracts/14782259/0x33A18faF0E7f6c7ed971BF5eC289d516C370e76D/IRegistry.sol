// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;
import "./RegistryEntities.sol";

interface IRegistry {
    function initialize(address _governor) external;

    function setProtocolAddresses(
        address _opiumProxyFactory,
        address _core,
        address _oracleAggregator,
        address _syntheticAggregator,
        address _tokenSpender
    ) external;

    function setNoDataCancellationPeriod(uint32 _noDataCancellationPeriod) external;

    function addToWhitelist(address _whitelisted) external;

    function removeFromWhitelist(address _whitelisted) external;

    function setProtocolExecutionReserveClaimer(address _protocolExecutionReserveClaimer) external;

    function setProtocolRedemptionReserveClaimer(address _protocolRedemptionReserveClaimer) external;

    function setProtocolExecutionReservePart(uint32 _protocolExecutionReservePart) external;

    function setDerivativeAuthorExecutionFeeCap(uint32 _derivativeAuthorExecutionFeeCap) external;

    function setProtocolRedemptionReservePart(uint32 _protocolRedemptionReservePart) external;

    function setDerivativeAuthorRedemptionReservePart(uint32 _derivativeAuthorRedemptionReservePart) external;

    function pause() external;

    function pauseProtocolPositionCreation() external;

    function pauseProtocolPositionMinting() external;

    function pauseProtocolPositionRedemption() external;

    function pauseProtocolPositionExecution() external;

    function pauseProtocolPositionCancellation() external;

    function pauseProtocolReserveClaim() external;

    function unpause() external;

    function getProtocolParameters() external view returns (RegistryEntities.ProtocolParametersArgs memory);

    function getProtocolAddresses() external view returns (RegistryEntities.ProtocolAddressesArgs memory);

    function isRegistryManager(address _address) external view returns (bool);

    function isCoreConfigurationUpdater(address _address) external view returns (bool);

    function getCore() external view returns (address);

    function isCoreSpenderWhitelisted(address _address) external view returns (bool);

    function isProtocolPaused() external view returns (bool);

    function isProtocolPositionCreationPaused() external view returns (bool);

    function isProtocolPositionMintingPaused() external view returns (bool);

    function isProtocolPositionRedemptionPaused() external view returns (bool);

    function isProtocolPositionExecutionPaused() external view returns (bool);

    function isProtocolPositionCancellationPaused() external view returns (bool);

    function isProtocolReserveClaimPaused() external view returns (bool);
}
