pragma solidity ^0.8.18;

import "./IERC721.sol";
import "./Ownable.sol";
import "./TGARegistry.sol";
import "./TokenGatedAccount.sol";
import "./Interfaces.sol";
import "./ShipStore.sol";
import "./PillStore.sol";
import "./AzimuthOwnerWrapper.sol";

contract MOSOnboarding is Ownable {
    IERC721 public immutable miladysContract;
    IERC721 public immutable avatarContract;
    AzimuthOwnerWrapper public immutable azimuthOwnerWrapperContract;
    ISoulboundAccessories public immutable soulboundAccessoriesContract;
    TGARegistry public immutable tgaRegistry;
    TokenGatedAccount public immutable tgaAccountImpl;

    ShipStore public immutable shipStoreContract;
    uint public immutable shipStackId;
    
    PillStore public immutable pillStoreContract;
    uint public immutable mosPillSetId;

    uint public onboardingGasForwardAmount;
    
    constructor(
        IERC721 _miladysContract,
        IERC721 _avatarContract,
        AzimuthOwnerWrapper _azimuthOwnerWrapperContract,
        ISoulboundAccessories _soulboundAccessoriesContract,
        TGARegistry _tgaRegistry,
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

    function setOnboardingGasForwardAmount(uint _amount)
        external
        onlyOwner()
    {
        onboardingGasForwardAmount = _amount;
    }

    event SoulboundMintRequested(uint miladyId);
    
    function _requestMiladyOnboard(uint miladyId)
        internal
    {
        createTGA(address(miladysContract), miladyId);
        createTGA(address(avatarContract), miladyId);

        payable(soulboundAccessoriesContract.miladyAuthority()).transfer(onboardingGasForwardAmount);

        emit SoulboundMintRequested(miladyId);
    }

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

    event PackageBought(address indexed topLevelEOA, uint indexed miladyId, uint32 indexed shipId, uint pillId);

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

    // Due to limits in Solidity, will return a list possibly longer than the number of valid points
    // so we also return `numOnboardedPoints`, the number of elements in the list that are legitimate
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

    function getMarketInfo()
        public
        view
        returns(uint shipPrice, uint numShipsRemaining, uint appPrice, uint onboardingGasPrice)
    {
        (,,shipPrice,,,numShipsRemaining) = shipStoreContract.getStackInfo(shipStackId);
        (,,appPrice,,,,,,) = pillStoreContract.getPillSetInfo(mosPillSetId);
        onboardingGasPrice = onboardingGasForwardAmount;
    }

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