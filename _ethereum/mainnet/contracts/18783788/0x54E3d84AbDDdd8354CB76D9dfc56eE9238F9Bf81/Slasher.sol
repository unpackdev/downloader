// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.19;

import "./Utils.sol";
import "./Initializable.sol";
import "./IEpochsManager.sol";
import "./IPRegistry.sol";
import "./ISlasher.sol";
// TODO: replace with interface from dao-v2 repository once stable
import "./IRegistrationManager.sol";

error NotHub(address hub);
error NotSupportedNetworkId(bytes4 originNetworkId);
error InvalidEpoch(uint16 epoch, uint16 expectedEpoch);

contract Slasher is ISlasher, Initializable {
    address public pRegistry;
    address public epochsManager;
    address public registrationManager;
    uint256 public stakingSentinelAmountToSlash;

    function initialize(
        address epochsManager_,
        address pRegistry_,
        address registrationManager_,
        uint256 stakingSentinelAmountToSlash_
    ) public initializer {
        epochsManager = epochsManager_;
        pRegistry = pRegistry_;
        stakingSentinelAmountToSlash = stakingSentinelAmountToSlash_;
        registrationManager = registrationManager_;
    }

    function receiveUserData(
        bytes4 originNetworkId,
        string calldata originAccount,
        bytes calldata userData
    ) external override {
        uint16 currentEpoch = IEpochsManager(epochsManager).currentEpoch();
        address originAccountAddress = Utils.hexStringToAddress(originAccount);

        if (!IPRegistry(pRegistry).isNetworkIdSupported(originNetworkId)) revert NotSupportedNetworkId(originNetworkId);

        address registeredHub = IPRegistry(pRegistry).getHubByNetworkId(originNetworkId);
        if (originAccountAddress != registeredHub) revert NotHub(originAccountAddress);

        (uint16 epoch, address actor, address challenger, uint256 slashTimestamp) = abi.decode(
            userData,
            (uint16, address, address, uint64)
        );

        if (epoch != currentEpoch) revert InvalidEpoch(epoch, currentEpoch);

        IRegistrationManager.Registration memory registration = IRegistrationManager(registrationManager)
            .registrationOf(actor);

        // See file `Constants.sol` in dao-v2-contracts:
        //
        // bytes1 public constant REGISTRATION_SENTINEL_STAKING = 0x01;
        //
        // Borrowing sentinels have nothing at stake, so the slashing
        // quantity will be zero
        uint256 amountToSlash = registration.kind == 0x01 ? stakingSentinelAmountToSlash : 0;
        IRegistrationManager(registrationManager).slash(actor, amountToSlash, challenger, slashTimestamp);
    }
}
