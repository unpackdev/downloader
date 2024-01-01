pragma solidity ^0.8.18;

import "./IERC721.sol";
import "./Ownable.sol";
import "./TBARegistry.sol";
import "./TokenGatedAccount.sol";
import "./Interfaces.sol";
import "./ShipStore.sol";
import "./PillStore.sol";
import "./AzimuthOwnerWrapper.sol";

/// @title MOSOnboarding
/// @notice This contract handles onboarding for miladys to the Milady OS system, along with Ship and Pill purchases.
/// @author Logan Brutsche
contract MOSOnboarding is Ownable {
    IERC721 public immutable miladysContract;
    IERC721 public immutable avatarContract;
    AzimuthOwnerWrapper public immutable azimuthOwnerWrapperContract;
    ISoulboundAccessories public immutable soulboundAccessoriesContract;
    TBARegistry public immutable tgaRegistry;
    TokenGatedAccount public immutable tgaAccountImpl;

    ShipStore public immutable shipStoreContract;
    uint public immutable shipStackId;
    
    PillStore public immutable pillStoreContract;
    uint public immutable mosPillSetId;

    uint public onboardingGasForwardAmount;
    
    /// @notice Constructor to initialize the MOSOnboarding contract.
    /// @param _miladysContract Address of the IERC721 contract for Miladys.
    /// @param _avatarContract Address of the IERC721 contract for Avatars.
    /// @param _azimuthOwnerWrapperContract Address of the contract azimuthOwnerWrapperContract.
    /// @param _soulboundAccessoriesContract Address of the SoulboundAccessories contract.
    /// @param _tgaRegistry Address of the TokenGatedAccount registry.
    /// @param _tgaAccountImpl Address of the TokenGatedAccount implementation.
    /// @param _shipStoreContract Address of the ShipStore contract.
    /// @param _shipStackId The stack ID for ships this contract mediates purchasing of.
    /// @param _pillStoreContract Address of the PillStore contract.
    /// @param _mosPillSetId The Pill Set ID for MOS this contract mediates purchasing of.
    /// @param _onboardingGasForwardAmount The amount of gas to capture and forward to a server that uploads crucial metadata.
    /// @dev sets msg.sender to owner.
    constructor(
        IERC721 _miladysContract,
        IERC721 _avatarContract,
        AzimuthOwnerWrapper _azimuthOwnerWrapperContract,
        ISoulboundAccessories _soulboundAccessoriesContract,
        TBARegistry _tgaRegistry,
        TokenGatedAccount _tgaAccountImpl,

        ShipStore _shipStoreContract,
        uint _shipStackId,

        PillStore _pillStoreContract,
        uint _mosPillSetId,

        uint _onboardingGasForwardAmount
    )
        Ownable(msg.sender)
    {
        miladysContract = _miladysContract;
        avatarContract = _avatarContract;
        azimuthOwnerWrapperContract = _azimuthOwnerWrapperContract;
        soulboundAccessoriesContract = _soulboundAccessoriesContract;
        tgaRegistry = _tgaRegistry;
        tgaAccountImpl = _tgaAccountImpl;

        shipStoreContract = _shipStoreContract;
        shipStackId = _shipStackId;

        pillStoreContract = _pillStoreContract;
        mosPillSetId = _mosPillSetId;

        onboardingGasForwardAmount = _onboardingGasForwardAmount;
    }

    /// @notice Sets the amount of gas to forward for onboarding.
    /// @param _amount The amount of gas to forward.
    /// @dev Only callable by the contract owner.
    function setOnboardingGasForwardAmount(uint _amount)
        external
        onlyOwner()
    {
        onboardingGasForwardAmount = _amount;
    }

    /// @notice Emitted when a mint request for Soulbound is made.
    /// @param miladyId The ID of the Milady involved in the Soulbound mint request.
    event SoulboundMintRequested(uint miladyId);
    
    /// @notice Handles internal logic for onboarding a Milady.
    /// @param miladyId The ID of the Milady to onboard.
    /// @dev Creates two TGAs - one for the miladyMaker contract, one for the avatar contract.
    /// @dev Forwards the gas forwarding amount to the miladyAuthority.
    /// @dev Emits a SoulboundMintRequested event, expected to be seen and actioned by the miladyAuthority server.
    function _requestMiladyOnboard(uint miladyId)
        internal
    {
        createTGA(address(miladysContract), miladyId);
        createTGA(address(avatarContract), miladyId);

        payable(soulboundAccessoriesContract.miladyAuthority()).transfer(onboardingGasForwardAmount);

        emit SoulboundMintRequested(miladyId);
    }

    /// @notice Purchases the app package for a given address.
    /// @param _recipientAddress The recipient's address.
    /// @param _shipPrice The price for the ship.
    /// @param _appPrice The price for the app.
    /// @dev Creates a TGA for the ship, puts the pill into that TGA, and creates a TGA for the pill.
    /// @return shipId The ID of the purchased ship.
    /// @return pillId The ID of the purchased pill.
    function _purchaseAppPackage(address _recipientAddress, uint _shipPrice, uint _appPrice)
        internal
        returns(uint32 shipId, uint pillId)
    {
        shipId = shipStoreContract.buyShip{value:_shipPrice}(shipStackId, _recipientAddress);
        address shipTgaAddress = createTGA(address(azimuthOwnerWrapperContract), shipId);

        Pill pillSetContract = pillStoreContract.getPillSetContract(mosPillSetId);
        pillId = pillStoreContract.mintPill{value:_appPrice}(mosPillSetId, shipTgaAddress);
        createTGA(address(pillSetContract), pillId);
    }

    /// @notice Event emitted when a package is bought.
    /// @param topLevelEOA The address that holds the Milady.
    /// @param miladyId The ID of the associated Milady.
    /// @param shipId The ID of the purchased ship.
    /// @param pillId The ID of the purchased pill.
    event PackageBought(address indexed topLevelEOA, uint indexed miladyId, uint32 indexed shipId, uint pillId);

    /// @notice Onboard and purchase a package for a specific Milady.
    /// @param miladyId The ID of the Milady to onboard.
    /// @return shipId The ID of the purchased ship.
    /// @return pillId The ID of the purchased pill.
    /// @dev Charges the user the full amount of ether needed.
    /// @dev Effectively packages together the _requestMiladyOnboard and _purchaseAppPackage functions.
    function onboardAndPurchaseForMilady(uint miladyId)
        external
        payable
        returns(uint32 shipId, uint pillId)
    {
        (,,uint shipPrice,,,) = shipStoreContract.getStackInfo(shipStackId);
        (,,uint appPrice,,,,,,) = pillStoreContract.getPillSetInfo(mosPillSetId);

        uint totalPrice = shipPrice + appPrice + onboardingGasForwardAmount;

        require(msg.value == totalPrice, "incorrect ether amount included");

        _requestMiladyOnboard(miladyId);
        address miladyOwner = miladysContract.ownerOf(miladyId);
        // implicitly returns
        (shipId, pillId) = _purchaseAppPackage(miladyOwner, shipPrice, appPrice);

        emit PackageBought(miladyOwner, miladyId, shipId, pillId);
    }

    /// @notice Get the onboarded Azimuth points for a specific Milady.
    /// @param miladyId The ID of the Milady to check.
    /// @return numOnboardedPoints The number of valid onboarded points.
    /// @return onboardedPoints The list of onboarded points.
    /// @dev onboardedPoints may contain uninitialized elements beyond numOnboardedPoints.
    function getOnboardedAzimuthPointsForMilady(uint miladyId)
        external
        view
        returns (uint numOnboardedPoints, uint32[] memory onboardedPoints)
    {
        address miladyOwnerAddress = miladysContract.ownerOf(miladyId);

        uint32[] memory ownedPoints = azimuthOwnerWrapperContract.azimuthContract().getOwnedPoints(miladyOwnerAddress);

        onboardedPoints = new uint32[](ownedPoints.length);
        for (uint i; i<ownedPoints.length; i++) {
            address tgaAddress = getTGA(address(azimuthOwnerWrapperContract), ownedPoints[i]);
            if (pillStoreContract.getPillSetContract(mosPillSetId).balanceOf(tgaAddress) > 0) {
                onboardedPoints[numOnboardedPoints] = ownedPoints[i];
                numOnboardedPoints ++;
            }
        }
    }

    /// @notice Retrieve a set of values pertinent to the onboarding interface.
    /// @return shipPrice The current price of a ship.
    /// @return numShipsRemaining The number of ships remaining in the underlying shipStack.
    /// @return appPrice The current price of an app.
    /// @return onboardingGasPrice The amount captured and forwarded to miladyAuthority.
    function getMarketInfo()
        public
        view
        returns(uint shipPrice, uint numShipsRemaining, uint appPrice, uint onboardingGasPrice)
    {
        (,,shipPrice,,,numShipsRemaining) = shipStoreContract.getStackInfo(shipStackId);
        (,,appPrice,,,,,,) = pillStoreContract.getPillSetInfo(mosPillSetId);
        onboardingGasPrice = onboardingGasForwardAmount;
    }

    /// @notice Create a new Token Gated Account (TGA) for a given NFT contract and its ID.
    /// @param tokenContractAddress The address of the NFT contract.
    /// @param tokenId The ID of the token.
    /// @return The address of the newly created TGA.
    function createTGA(address tokenContractAddress, uint tokenId)
        internal
        returns(address payable)
    {
        return payable(tgaRegistry.createAccount(
            address(tgaAccountImpl),
            block.chainid, 
            tokenContractAddress,
            tokenId,
            0,
            ""
        ));
    }

    /// @notice Retrieve the address of an existing Token Gated Account (TGA).
    /// @param tokenContractAddress The address of the NFT contract.
    /// @param tokenId The ID of the token.
    /// @return The address of the existing TGA.
    function getTGA(address tokenContractAddress, uint tokenId)
        internal
        view
        returns(address payable)
    {
        return payable(tgaRegistry.account(
            address(tgaAccountImpl),
            block.chainid, 
            tokenContractAddress,
            tokenId,
            0
        ));
    }
}