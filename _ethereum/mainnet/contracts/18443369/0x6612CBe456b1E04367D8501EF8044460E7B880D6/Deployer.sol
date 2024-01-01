pragma solidity ^0.8.18;

import "./MOSOnboarding.sol";

contract Deployer {
    MOSOnboarding public mosOnboarding;
    ShipStore public shipStoreContract;
    PillStore public pillStoreContract;
    AzimuthOwnerWrapper public azimuthOwnerWrapperContract;

    uint public shipStackId;
    uint public pillSetId;

    constructor(
        IERC721 _miladysContract,
        IERC721 _avatarContract,
        IAzimuth _azimuthContract,
        ISoulboundAccessories _soulboundAccessoriesContract,
        TGARegistry _tgaRegistry,
        TokenGatedAccount _tgaAccountImpl,

        uint _onboardingGasForwardAmount,

        // using an array to avoid StackTooDeep error.
        address[4] memory privilegedAddrs,
        // 0 - onboardingOwner
        // 1 - stackAndPillOwner
        // 2 - stackAndPillOperator
        // 3 - stackDepositor

        address payable _revenueRecipient,

        // using an array to avoid StackTooDeep error.
        uint[2] memory prices,
        // 0 - shipPrice
        // 1 - pillPrice

        string memory mosMetadataUrl
    )
    {
        azimuthOwnerWrapperContract = new AzimuthOwnerWrapper(_azimuthContract);

        shipStoreContract = new ShipStore(_azimuthContract);
        pillStoreContract = new PillStore();

        shipStackId = shipStoreContract.prepStack(address(this), address(this), privilegedAddrs[3], _revenueRecipient);
        pillSetId = pillStoreContract.prepPillSet(address(this), address(this), _revenueRecipient);

        mosOnboarding = new MOSOnboarding(
            _miladysContract,
            _avatarContract,
            azimuthOwnerWrapperContract,
            _soulboundAccessoriesContract,
            _tgaRegistry,
            _tgaAccountImpl,

            shipStoreContract,
            shipStackId,

            pillStoreContract,
            pillSetId,

            _onboardingGasForwardAmount
        );

        shipStoreContract.deployStack(shipStackId, prices[0], address(mosOnboarding));
        pillStoreContract.deployPillSet(pillSetId, prices[1], 0, address(0), "Milady OS", mosMetadataUrl);

        mosOnboarding.transferOwnership(privilegedAddrs[0]);

        shipStoreContract.setOperator(shipStackId, privilegedAddrs[2]);
        pillStoreContract.setOperator(shipStackId, privilegedAddrs[2]);

        shipStoreContract.setOwner(shipStackId, privilegedAddrs[1]);
        pillStoreContract.setOwner(pillSetId, privilegedAddrs[1]);
    }
}