//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PRBMathUD60x18.sol";
import "./Signed.sol";
import "./IBredStrain.sol";
import "./IStrain.sol";
import "./IRaks.sol";
import "./IStaking.sol";

contract Breeding is
    Initializable,
    SignedUpgradable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IDeclareCoreTraits
{
    using PRBMathUD60x18 for uint256;

    int64 public constant DIVISOR = 2_147_483_647;

    mapping(uint256 => bool) private usedVrfs;
    IStrain private _strainToken;
    IBredStrain private _bredStrainToken;
    IRaks private _raksToken;
    IStaking private _stakingContract;

    struct BreedRequest {
        uint256[] strainIds;
        uint8[] strainTypes;
        uint256 seedId;
        int32[] randomNumbers;
    }

    function initialize(
        address strainToken,
        address bredStrainToken,
        address raksToken,
        address stakingContract
    ) public initializer {
        __Signed_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        _strainToken = IStrain(strainToken);
        _bredStrainToken = IBredStrain(bredStrainToken);
        _raksToken = IRaks(raksToken);
        _stakingContract = IStaking(stakingContract);
    }

    function breedWithRaks(
        bytes calldata breedRequestData,
        bytes calldata signature
    ) external whenNotPaused nonReentrant {
        BreedRequest memory breedRequest = abi.decode(
            breedRequestData,
            (BreedRequest)
        );

        _sharedBreedingValidations(breedRequestData, signature);
        _raksToken.burn(msg.sender, _breedWithRaksCost());
        _sharedBreedingLogic(breedRequest);
    }

    function breedWithParents(
        bytes calldata breedRequestData,
        bytes calldata signature
    ) external whenNotPaused nonReentrant {
        BreedRequest memory breedRequest = abi.decode(
            breedRequestData,
            (BreedRequest)
        );

        require(
            breedRequest.strainTypes[0] == 1 &&
                breedRequest.strainTypes[1] == 1,
            "Only can burn bred strains"
        );
        _sharedBreedingValidations(breedRequestData, signature);
        _stakingContract.burn(msg.sender, breedRequest.strainIds[0]);
        _stakingContract.burn(msg.sender, breedRequest.strainIds[1]);
        _sharedBreedingLogic(breedRequest);
    }

    function _breedWithRaksCost() private returns (uint256) {
        uint256 mintedStrains = _strainToken.genesisSupply() +
            _bredStrainToken.bredSupply();
        uint256 exponent = mintedStrains / _strainToken.maxGenesisSupply();
        return
            PRBMathUD60x18
                .fromUint(2)
                .pow(PRBMathUD60x18.fromUint(exponent))
                .mul(PRBMathUD60x18.fromUint(1000))
                .toUint() * 1e18;
    }

    function _sharedBreedingValidations(
        bytes calldata breedRequestData,
        bytes calldata signature
    ) private view {
        BreedRequest memory breedRequest = abi.decode(
            breedRequestData,
            (BreedRequest)
        );
        require(
            _stakingContract.ownerOf(
                breedRequest.strainIds[0],
                breedRequest.strainTypes[0]
            ) == msg.sender,
            "Not owner of strain A or not staked"
        );
        require(
            _stakingContract.ownerOf(
                breedRequest.strainIds[1],
                breedRequest.strainTypes[1]
            ) == msg.sender,
            "Not owner of strain B or not staked"
        );
        require(
            !(breedRequest.strainTypes[0] == breedRequest.strainTypes[1] &&
                breedRequest.strainIds[0] == breedRequest.strainIds[1]),
            "Breeding the same strain"
        );
        require(!usedVrfs[breedRequest.seedId], "VRF already used");
        verifySignature(breedRequestData, signature);
    }

    function _sharedBreedingLogic(BreedRequest memory breedRequest) private {
        CoreTraits memory coreTraitsA = _getCoreTraits(
            breedRequest.strainIds[0],
            breedRequest.strainTypes[0]
        );
        CoreTraits memory coreTraitsB = _getCoreTraits(
            breedRequest.strainIds[1],
            breedRequest.strainTypes[1]
        );

        uint32 size = _calculateCoreTrait(
            coreTraitsA.size,
            coreTraitsB.size,
            breedRequest.randomNumbers[0],
            500,
            10000
        );

        uint32 thc = _calculateCoreTrait(
            coreTraitsA.thc,
            coreTraitsB.thc,
            breedRequest.randomNumbers[1],
            2000,
            3000
        );

        uint32 terpenes = _calculateCoreTrait(
            coreTraitsA.terpenes,
            coreTraitsB.terpenes,
            breedRequest.randomNumbers[2],
            250,
            500
        );

        usedVrfs[breedRequest.seedId] = true;

        _bredStrainToken.breedMint(
            msg.sender,
            breedRequest.seedId,
            CoreTraits(size, thc, terpenes, 0)
        );
    }

    function _getCoreTraits(uint256 strainId, uint8 strainType)
        private
        view
        returns (CoreTraits memory)
    {
        if (strainType == 0) {
            return _strainToken.coreTraits(strainId);
        } else {
            return _bredStrainToken.coreTraits(strainId);
        }
    }

    function _calculateCoreTrait(
        uint32 strainACoreTrait,
        uint32 strainBCoreTrait,
        int32 randomNumber,
        uint32 minValue,
        uint32 maxValue
    ) internal pure returns (uint32) {
        uint32 steps = 10;
        uint32 scale = (maxValue - minValue) / steps;
        int64 decimalPlaces = 10000;
        int64 normalizedRandom = (int64(randomNumber) * decimalPlaces) /
            DIVISOR;
        if (normalizedRandom < 0) {
            normalizedRandom = normalizedRandom * -1;
        }
        uint32 childCoreTrait = randomNumber % 2 == 0
            ? strainACoreTrait
            : strainBCoreTrait;
        uint32 threshold = _scaleBetween(
            childCoreTrait,
            2000, //80%
            6000, //40%
            minValue,
            maxValue
        );
        if (normalizedRandom > int64(uint64(threshold))) {
            childCoreTrait += scale;
        } else {
            childCoreTrait -= scale / 2;
        }
        if (childCoreTrait < minValue) return minValue;
        else if (childCoreTrait > maxValue) return maxValue;
        else return childCoreTrait;
    }

    function _scaleBetween(
        uint32 unscaledNum,
        uint32 minAllowed,
        uint32 maxAllowed,
        uint32 min,
        uint32 max
    ) private pure returns (uint32) {
        return (((maxAllowed - minAllowed) * (unscaledNum - min)) /
            (max - min) +
            minAllowed);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function setStrainToken(address strainTokenAddress) external onlyAdmin {
        _strainToken = IStrain(strainTokenAddress);
    }

    function setBredStrainToken(address bredStrainTokenAddress)
        external
        onlyAdmin
    {
        _bredStrainToken = IBredStrain(bredStrainTokenAddress);
    }

    function setRaksToken(address raksTokenAddress) external onlyAdmin {
        _raksToken = IRaks(raksTokenAddress);
    }

    function setStakingContract(address stakingContractAddress)
        external
        onlyAdmin
    {
        _stakingContract = IStaking(stakingContractAddress);
    }
}
