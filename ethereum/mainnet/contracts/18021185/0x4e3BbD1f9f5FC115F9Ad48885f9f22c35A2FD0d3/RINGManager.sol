// SPDX-License-Identifier: MIT


pragma solidity ^0.8.19;



// ░░██╗██╗██╗░░░██╗████████╗░░███╗░░░██████╗████████╗░░███╗░░░█████╗░
// ░██╔╝██║██║░░░██║╚══██╔══╝░████║░░██╔════╝╚══██╔══╝░████║░░██╔══██╗
// ██╔╝░██║██║░░░██║░░░██║░░░██╔██║░░╚█████╗░░░░██║░░░██╔██║░░██║░░╚═╝
// ███████║██║░░░██║░░░██║░░░╚═╝██║░░░╚═══██╗░░░██║░░░╚═╝██║░░██║░░██╗
// ╚════██║╚██████╔╝░░░██║░░░███████╗██████╔╝░░░██║░░░███████╗╚█████╔╝
// ░░░░░╚═╝░╚═════╝░░░░╚═╝░░░╚══════╝╚═════╝░░░░╚═╝░░░╚══════╝░╚════╝░

// ██████╗░██████╗░░██╗░░░░░░░██╗░░██╗██╗██████╗░██████╗░░██████╗
// ██╔══██╗╚════██╗░██║░░██╗░░██║░██╔╝██║██╔══██╗██╔══██╗██╔════╝
// ██████╔╝░█████╔╝░╚██╗████╗██╔╝██╔╝░██║██████╔╝██║░░██║╚█████╗░
// ██╔══██╗░╚═══██╗░░████╔═████║░███████║██╔══██╗██║░░██║░╚═══██╗
// ██║░░██║██████╔╝░░╚██╔╝░╚██╔╝░╚════██║██║░░██║██████╔╝██████╔╝
// ╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░╚═╝░░░░░░░╚═╝╚═╝░░╚═╝╚═════╝░╚═════╝░

// Docs: https://docs.shpos9999iqrun.com/
// Website: https://shpos9999iqrun.com/
// Twitter: https://twitter.com/Shpos9999IQRun
// Telegram: http://t.me/Shpos9999IQRun



import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./Base64Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";

import "./OwnerRecoveryUpgradeable.sol";
import "./SonicImplementationPointerUpgradeable.sol";
import "./LiquidityPoolManagerImplementationPointerUpgradeable.sol";

contract RINGManager is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    OwnerRecoveryUpgradeable,
    ReentrancyGuardUpgradeable,
    SonicImplementationPointerUpgradeable,
    LiquidityPoolManagerImplementationPointerUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct ringInfoEntity {
        RingEntity ring;
        uint256 id;
        uint256 pendingRewards;
        uint256 rewardPerDay;
        uint256 compoundDelay;
        uint256 pendingRewardsGross;
        uint256 rewardPerDayGross;
    }

    struct RingEntity {
        uint256 id;
        uint256 name;
        uint256 creationTime;
        uint256 lastProcessingTimestamp;
        uint256 rewardMult;
        uint256 ringValue;
        uint256 totalClaimed;
        bool exists;
        bool isMerged;
    }
    

    struct TierStorage {
        uint256 rewardMult;
        uint256 amountLockedInTier;
        bool exists;
    }

  struct Tier {
    uint32 level;
    uint32 slope;
    uint32 dailyAPR;
    uint32 claimFee;
    uint32 claimBurnFee;
    uint32 compoundFee;
    string name;
    string imageURI;
  }



    CountersUpgradeable.Counter private _ringCounter;
    mapping(uint256 => RingEntity) private _rings;
    mapping(uint256 => ringInfoEntity) private _ringInfo;
    mapping(uint256 => TierStorage) private _tierTracking;
    uint256[] _tiersTracked;

    bool public feesLive;
    uint256 public rewardPerDay;

    uint256 public creationPriceYellow = 3000 * 1e18;
    uint256 public creationPriceGreen = 7500 * 1e18;
    uint256 public creationPriceRed =  18000 * 1e18;



    uint256 public compoundDelay;
    uint256 public processingFee;
    

    Tier[3] public rings;

    string public ipfsBaseURI;
   
    uint256 private constant ONE_DAY = 86400;
    uint256 public totalValueLocked;



    function _onlyRingOwner() public view {
        address sender = _msgSender();
        require(
            sender != address(0),
            "Can not be the zero address"
        );
        require(
            isOwnerRing(sender), "only Ring owner"
         
        );
    }

    modifier onlyRingOwner() {
         _onlyRingOwner();
        _;
    }


    function _checkPermissions(uint256 _ringId) public view  {
         address sender = _msgSender();
        require(ringExists(_ringId), ": This ring doesn't exist");
        require(
            isApprovedOrOwnerOfRing(sender, _ringId),
            ": You do not have control over this ring"
        );
    }



    modifier checkPermissions(uint256 _ringId) {
        _checkPermissions(_ringId);
        _;
    }


    function _checkPermissionsMultiple(uint256[] memory _ringId) public view  {
            address sender = _msgSender();
        for (uint256 i = 0; i < _ringId.length; i++) {
            require(
                ringExists(_ringId[i]),
                ": This ring doesn't exist"
            );
            require(
                isApprovedOrOwnerOfRing(sender, _ringId[i]),
                ": You do not control this ring"
            );
        }
    }


    modifier checkPermissionsMultiple(uint256[] memory _ringId) {
       _checkPermissionsMultiple(_ringId);
        _;
    }



    event Compound(
        address indexed account,
        uint256 indexed ringId,
        uint256 amountToCompound
    );
    event Cashout(
        address indexed account,
        uint256 indexed ringId,
        uint256 rewardAmount
    );

    event Create(
        address indexed account,
        uint256 indexed newringId,
        uint256 amount
    );


    function initialize() external initializer {
        __ERC721_init("RING Farm", "RING");
        __Ownable_init();
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        feesLive = true;

        ipfsBaseURI = "ipfs://Qmev88mBuPK2xRGaU8QATSfvLkyoZrjqUZEcovgbMzKZ9v/";
    

        Tier[3] memory _sonic = [
        Tier({
            level: 1000,
            slope: 1000,
            dailyAPR: 150,
            claimFee: 80,
            claimBurnFee: 0,
            compoundFee: 0,
            name: "YellowRING",
            imageURI: string(abi.encodePacked(ipfsBaseURI, "yellowring.png"))
        }),
         Tier({
            level: 2000,
            slope: 1000,
            dailyAPR: 250,
            claimFee: 80,
            claimBurnFee: 0,
            compoundFee: 0,
            name: "GreenRING",
            imageURI: string(abi.encodePacked(ipfsBaseURI, "greenring.png"))
        }),
         Tier({
            level: 3000,
            slope: 1000,
            dailyAPR: 420,
            claimFee: 80,
            claimBurnFee: 0,
            compoundFee: 0,
            name: "RedRING",
            imageURI: string(abi.encodePacked(ipfsBaseURI, "redring.png"))
        })];
     
    changeTiers(_sonic);
        
    }

    function changeFeesLive(bool _feesLive) onlyOwner external{
        feesLive = _feesLive;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
        returns (string memory)
    {

        // ringInfoEntity memory tokenInfo = _ringInfo[tokenId]; 

        RingEntity memory _ring = _rings[tokenId];
        (, string memory _type, string memory image) = getTierMetadata(
        _ring.rewardMult
        );

       bytes memory dataURI = abi.encodePacked(
      '{ "image": "',
      image,
      '", "attributes": [',
      '{"trait_type": "type", "value": "',
      _type,
      '"}, {"trait_type": "tokens", "value": "',
      StringsUpgradeable.toString(_ring.ringValue / (10**18)),
      '"}]}'
    );


   return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64Upgradeable.encode(dataURI)
        )
      );

    }


      function getTierMetadata(uint256 prevMult)
    private
    view
    returns (
      uint256,
      string memory,
      string memory
    )
  {
    (Tier memory tier, uint256 tierIndex) = getTier(prevMult);
    return (tierIndex + 1, tier.name, tier.imageURI);
  }


function updateDailyAPR(uint8 tierIndex, uint32 newAPR) public {
    require(tierIndex <= rings.length, "Invalid tier index");
    rings[tierIndex].dailyAPR = newAPR;
}


   function getTier(uint256 mult) public view returns (Tier memory, uint256) {
    Tier memory _ring;
    for (int256 i = int256(rings.length - 1); i >= 0; i--) {
      _ring = rings[uint256(i)];
      if (mult >= _ring.level) {
        return (_ring, uint256(i));
      }
    }
    return (_ring, 0);
  }

  

    function buyYellowRing(
    ) public whenNotPaused  returns (uint256) {
        address sender = _msgSender();
        uint256 ringValue = 3000 * 1e18;

        require(
            sonic.balanceOf(sender) >= ringValue,
            ": Balance too low for creation"
        );

        // Burn the tokens used to mint the NFT
        sonic.accountBurn(sender, ringValue);

        // Increment the total number of tokens
        _ringCounter.increment();

        uint256 newringId = _ringCounter.current();
        uint256 currentTime = block.timestamp;

        // Add this to the TVL
        totalValueLocked += ringValue;
        logTier(rings[0].level, int256(ringValue));

        // Add RING
            _rings[newringId] = RingEntity({
            id: newringId,
            name: newringId,
            creationTime: currentTime,
            lastProcessingTimestamp: currentTime,
            rewardMult: rings[0].level,
            ringValue: ringValue,
            totalClaimed: 0,
            exists: true,
            isMerged: false
        });

        // Assign the Ring to this account
        _mint(sender, newringId);

        emit Create(sender, newringId, ringValue);

        return newringId;
    }


    function buyGreenRing(
    ) public whenNotPaused  returns (uint256) {
        address sender = _msgSender();
        uint256 ringValue = 7500 * 1e18;

        require(
            sonic.balanceOf(sender) >= ringValue,
            ": Balance too low for creation"
        );

        // Burn the tokens used to mint the NFT
        sonic.accountBurn(sender, ringValue);

        // Increment the total number of tokens
        _ringCounter.increment();

        uint256 newringId = _ringCounter.current();
        uint256 currentTime = block.timestamp;

        // Add this to the TVL
        totalValueLocked += ringValue;
        logTier(rings[1].level, int256(ringValue));

        // Add RING
            _rings[newringId] = RingEntity({
            id: newringId,
            name: newringId,
            creationTime: currentTime,
            lastProcessingTimestamp: currentTime,
            rewardMult: rings[1].level,
            ringValue: ringValue,
            totalClaimed: 0,
            exists: true,
            isMerged: false
        });

        // Assign the Ring to this account
        _mint(sender, newringId);

        emit Create(sender, newringId, ringValue);

        return newringId;
    }



    function buyRedRing(
    ) public whenNotPaused  returns (uint256) {
        address sender = _msgSender();
        uint256 ringValue = 18000 * 1e18;

        require(
            sonic.balanceOf(sender) >= ringValue,
            ": Balance too low for creation"
        );

        // Burn the tokens used to mint the NFT
        sonic.accountBurn(sender, ringValue);

        // Increment the total number of tokens
        _ringCounter.increment();

        uint256 newringId = _ringCounter.current();
        uint256 currentTime = block.timestamp;

        // Add this to the TVL
        totalValueLocked += ringValue;
        logTier(rings[2].level, int256(ringValue));

        // Add RING
            _rings[newringId] = RingEntity({
            id: newringId,
            name: newringId,
            creationTime: currentTime,
            lastProcessingTimestamp: currentTime,
            rewardMult: rings[2].level,
            ringValue: ringValue,
            totalClaimed: 0,
            exists: true,
            isMerged: false
        });

        // Assign the Ring to this account
        _mint(sender, newringId);

        emit Create(sender, newringId, ringValue);

        return newringId;
    }

   

    function claimAll() external nonReentrant onlyRingOwner whenNotPaused {
        address account = _msgSender();
        uint256 rewardsTotal = 0;
        uint256[] memory ringsOwned = getRingIdsOf(account);
        for (uint256 i = 0; i < ringsOwned.length; i++) {
            uint256 amountToReward = _getringCashoutRewards(ringsOwned[i]);
            rewardsTotal += amountToReward;
        }
        _cashoutReward(rewardsTotal);
    }


   function getRingIdsOf(address account)
        public
        view
        returns (uint256[] memory)
    {
        uint256 numberOfRings = balanceOf(account);
        uint256[] memory ringIds = new uint256[](numberOfRings);
        for (uint256 i = 0; i < numberOfRings; i++) {
            uint256 _ringId = tokenOfOwnerByIndex(account, i);
            require(
                ringExists(_ringId),
                "ring: This ring doesn't exist"
            );
            ringIds[i] = _ringId;
        }
        return ringIds;
    }

    // Private reward functions

    function _getringCashoutRewards(uint256 _ringId)
        private
        returns (uint256)
    {
        RingEntity storage ring = _rings[_ringId];

        if (!isProcessable(ring)) {
            return 0;
        }

        uint256 reward = calculateReward(ring);
        ring.totalClaimed += reward;

        ring.lastProcessingTimestamp = block.timestamp;

        return reward;
    }




    function _cashoutReward(uint256 amountToReward) private {
        require(
            amountToReward > 0,
            "rings: You don't have enough reward to cash out"
        );
        address to = _msgSender();

        sonic.accountReward(to, amountToReward);
    }
    

     function getringByIds(uint256[] memory _ringIds)
        external
        view
        returns (ringInfoEntity[] memory)
    {
        ringInfoEntity[] memory ringsInfo = new ringInfoEntity[](
            _ringIds.length
        );

        for (uint256 i = 0; i < _ringIds.length; i++) {
            uint256 ringId = _ringIds[i];
            RingEntity memory ring = _rings[ringId];

            // need to create function if dynamics fees 
          

            uint256 pendingRewardsGross = calculateReward(ring);
            uint256 rewardsPerDayGross = rewardPerDayFor(ring);

            uint256 amountToReward = pendingRewardsGross;
            uint256 amountToRewardDaily = rewardsPerDayGross;  

            ringsInfo[i] = ringInfoEntity(
                ring,
                ringId,
                amountToReward,
                amountToRewardDaily,
                compoundDelay,
                pendingRewardsGross,
                rewardsPerDayGross
            );

        }

        return ringsInfo;
    }


    function logTier(uint256 mult, int256 amount) private {
        TierStorage storage tierStorage = _tierTracking[mult];
        if (tierStorage.exists) {
            require(
                tierStorage.rewardMult == mult,
                "rings: rewardMult does not match in TierStorage"
            );
            uint256 amountLockedInTier = uint256(
                int256(tierStorage.amountLockedInTier) + amount
            );
            require(
                amountLockedInTier >= 0,
                "rings: amountLockedInTier cannot underflow"
            );
            tierStorage.amountLockedInTier = amountLockedInTier;
        } else {
            // Tier isn't registered exist, register it
            require(
                amount > 0,
                "rings: Fatal error while creating new TierStorage. Amount cannot be below zero."
            );
            _tierTracking[mult] = TierStorage({
                rewardMult: mult,
                amountLockedInTier: uint256(amount),
                exists: true
            });
            _tiersTracked.push(mult);
        }
    }

    // Private view functions
    function getPercentageOf(uint256 rewardAmount, uint256 _feeAmount)
        private
        pure
        returns (uint256, uint256)
    {
        uint256 feeAmount = 0;
        if (_feeAmount > 0) {
            feeAmount = (rewardAmount * _feeAmount) / 100;
        }
        return (rewardAmount - feeAmount, feeAmount);
    }



      function increaseMultiplier(uint256 prevMult) private view returns (uint256) {
    (Tier memory tier, ) = getTier(prevMult);
    return tier.slope;
  }



    function getTieredRevenues(uint256 mult) private view returns (uint256) {
    (Tier memory tier, ) = getTier(mult);
    return tier.dailyAPR;
  }


    function isProcessable(RingEntity memory ring)
        private
        view
        returns (bool)
    {
        return
            block.timestamp >= ring.lastProcessingTimestamp + compoundDelay;
    }

    function calculateReward(RingEntity memory ring)
        private
        view
        returns (uint256)
    {
        return
            _calculateRewardsFromValue(
                ring.ringValue,
                ring.rewardMult,
                block.timestamp - ring.lastProcessingTimestamp
            );
    }

    function rewardPerDayFor(RingEntity memory ring)
        private
        view
        returns (uint256)
    {
        return
            _calculateRewardsFromValue(
                ring.ringValue,
                ring.rewardMult,
                ONE_DAY
            );
    }

    function _calculateRewardsFromValue(
        uint256 _ringValue,
        uint256 _rewardMult,
        uint256 _timeRewards
    ) private view returns (uint256) {
        uint256 numOfDays = ((_timeRewards * 1e10) / 1 days);
        uint256 yieldPerDay = getTieredRevenues(_rewardMult);
        return (numOfDays * yieldPerDay * _ringValue) / (1000 * 1e10);

    }



    function ringExists(uint256 _ringId) private view returns (bool) {
        require(_ringId > 0, "rings: Id must be higher than zero");
        RingEntity memory ring = _rings[_ringId];
        if (ring.exists) {
            return true;
        }
        return false;
    }



    // Public view functions

    function calculateTotalDailyEmission() external view returns (uint256) {
        uint256 dailyEmission = 0;
        for (uint256 i = 0; i < _tiersTracked.length; i++) {
            TierStorage memory tierStorage = _tierTracking[_tiersTracked[i]];
            dailyEmission += _calculateRewardsFromValue(
                tierStorage.amountLockedInTier,
                tierStorage.rewardMult,
                ONE_DAY
            );
        }
        return dailyEmission;
    }




    function isOwnerRing(address account) public view returns (bool) {
        return balanceOf(account) > 0;
    }

    function isApprovedOrOwnerOfRing(address account, uint256 _ringId)
        public
        view
        returns (bool)
    {
        return _isApprovedOrOwner(account, _ringId);
    }

    function getRingsOf(address account)
        public
        view
        returns (uint256[] memory)
    {
        uint256 numberOfrings = balanceOf(account);
        uint256[] memory ringsIds = new uint256[](numberOfrings);
        for (uint256 i = 0; i < numberOfrings; i++) {
            uint256 ringId = tokenOfOwnerByIndex(account, i);
            require(
                ringExists(ringId),
                "rings: This ring doesn't exist"
            );
            ringsIds[i] = ringId;
        }
        return ringsIds;
    }


  function changeTiers(Tier[3] memory _newRings) public onlyOwner {
     for (uint256 i = 0; i < _newRings.length; i++) {
      rings[i] = _newRings[i];
    }
  }
    
  
  


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function burn(uint256 _ringId)
        external
        virtual
        nonReentrant
        onlyRingOwner
        whenNotPaused
        checkPermissions(_ringId)
    {
        _burn(_ringId);
    }




    function liquidityReward(uint256 amountToReward) private {
        (, uint256 liquidityFee) = getPercentageOf(
            amountToReward,
            5 // Mint the 5% Treasury fee
        );
        sonic.liquidityReward(liquidityFee);
    }

    // Mandatory overrides
    function _burn(uint256 tokenId)
        internal
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
    {
        RingEntity storage ring = _rings[tokenId];
        ring.exists = false;
        logTier(ring.rewardMult, -int256(ring.ringValue));
        ERC721Upgradeable._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount,
        uint256 batchSize
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


}