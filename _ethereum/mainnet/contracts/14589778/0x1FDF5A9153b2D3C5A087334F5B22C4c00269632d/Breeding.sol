// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./ERC721Holder.sol";
import "./IERC721.sol";
import "./ERC20.sol";
import "./Counters.sol";
import "./GeneScienceInterface.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./GatchaItem.sol";
import "./ReentrancyGuard.sol";
import "./FadeAwayBunnyNFT.sol";
import "./IPillToken.sol";

contract BreedingRouter is Ownable, Pausable, ERC721Holder, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    /// in Ethereum, the average block time is between 12 to 14 seconds and is evaluated after each block
    /// for calculation countDownBlock;
    uint256 public constant secondsPerBlock = 12;
    uint256 public constant maxFertility = 7;
    uint256 public constant timestampPerDay = uint256(1 days);
    uint256 public maxPillForStaking = 10000000 * 10**18;
    uint256 public totalPillClaimed = 254671655242666660000000 + 1315417591000000000000000;

    uint256 public breedCostPerDay = 600 * 10**18;
    // 33.33%
    uint256 public rentFee = 3333;
    uint256 public itemNum = 20;
    uint256 public nyanKeeCost = 10000 * 10**18;
    // config later
    uint256 public resetFerdilityCost = 10000000 * 10**18;
    // config later
    uint256 public turnOnBreedGen1Cost = 10000000 * 10**18;

    uint256 public dripRate = 4000; // same with rewardRate, 10000 = 100%
    uint256 public finalRewardBlock; // The block number when token rewarding has to end.
    uint256 public rewardPerDay = 100 * 1e18; // 100 PILL per day
    uint256 public itemEffectBlock = 50400; // 7 days with 12s each block
    uint256 public constant blockPerDay = 7200; // 1 day with 12s each block
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public itemPrice = 800 * 10**18;
    uint256 public dripCost = 400 * 1e18;
    FadeAwayBunnyNFT public nftAddress;
    GatchaItem public gatchaItem;
    IPillToken public rewardToken;
    GeneScienceInterface public geneScience;

    struct UserInfo {
        uint256 amount;
        uint256 harvestedReward;
        mapping(uint256 => uint256) itemEndBlock;
        EnumerableSet.UintSet nftIds;
        mapping(uint256 => uint256) lastRewardBlock;
    }
    mapping(address => UserInfo) private userInfo;
    //// SuicideRate in zoom 10000 -> 30% = 3000, 60% = 6000
    uint16[] public intToSuicideRate;
    struct LeaseMarket {
        // price by day
        uint256 price;
        uint256 timestampLease;
        uint256 timestampRent;
        address renter;
        address owner;
        // duration for rent
        uint256 duration;
        bool usedToBreed;
    }
    struct Breeding {
        // bunny id 1
        uint256 bunnyId1;
        // bunny id 2
        uint256 bunnyId2;
        // bunny contract
        address bunnyContract;
        // owner who breeding
        address owner;
        // owner who breeding
        address rentedBunnyOwner;
        // time give breeding
        uint256 timestampBreeding;
        // time duration for breeding
        uint256 duration;
        /// block number
        uint256 cooldownEndBlock;
        /// block number
        uint256 successRate;
        /// is use ryankee
        bool useRyanKee;
        // is Rented Bunnies.
        bool isRentedBunny;
    }

    mapping(uint256 => LeaseMarket) public tokenIdLeaseMarket;
    mapping(uint256 => Breeding) public tokenIdBreedings;
    mapping(uint256 => uint256) public idToBreedCounts;
    event Deposit(address indexed user, uint256 indexed nftId);
    event Withdraw(address indexed user, uint256 indexed nftId);
    event Harvest(address indexed user, uint256 indexed nftId, uint256 amount);
    event ApplyItem(address indexed user, uint256 indexed nftId, uint256 itemExpireBlock);

    event UserLeaseBunny(address _user, uint256 _tokenId, uint256 _price);
    event UserCancelLeaseBunny(address _user, uint256 _tokenId);
    event UserRentBunny(address _owner, address _user, uint256 _tokenId, uint256 _price, uint256 _duration);
    event UserRentExtensionBunny(address _owner, address _user, uint256 _tokenId, uint256 _price, uint256 _duration);
    event UserBreedBunny(
        address _user,
        address _rentedBunnyOwner,
        uint256 _bunnyId1,
        uint256 _bunnyId2,
        bool _isRentedBunny,
        uint256 _duration
    );
    event UserGiveBirth(address _user, uint256 _bunnyId1, uint256 _bunnyId2, uint256 _childrenBunnyId);
    event UserGatchaBunny(address _user, uint256 _bunnyId1, uint256 _itemId);
    event UserBuyGatchaItem(address _user, uint256 _itemId);

    constructor(
        IPillToken _rewardToken,
        FadeAwayBunnyNFT _nftAddress,
        GatchaItem _gatchaItem,
        uint256 _finalRewardBlock
    ) {
        rewardToken = _rewardToken;
        nftAddress = _nftAddress;
        gatchaItem = _gatchaItem;
        finalRewardBlock = _finalRewardBlock;
    }

    /// @dev Update the address of the genetic contract, can only be called by the Owner.
    /// @param _address An address of a GeneScience contract instance to be used from this point forward.
    function setGeneScienceAddress(address _address) external onlyOwner {
        GeneScienceInterface candidateContract = GeneScienceInterface(_address);
        require(candidateContract.isGeneScience());
        // Set the new contract address
        geneScience = candidateContract;
    }

    function setNFTAddress(FadeAwayBunnyNFT _nftAddress) external onlyOwner {
        nftAddress = _nftAddress;
    }

    function setGatChaItem(GatchaItem _gatchaItem) external onlyOwner {
        gatchaItem = _gatchaItem;
    }

    function setRewardToken(IPillToken _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setItemNum(uint256 _itemNum) external onlyOwner {
        itemNum = _itemNum;
    }

    function getFertility(uint256 tokenId) public view returns (uint256) {
        require(tokenId >= 0, "invalid token id");
        /// bunny gen 1 have breed count = 255 util have turn on breeding
        if (idToBreedCounts[tokenId] == 255) {
            return 0;
        } else {
            return maxFertility.sub(idToBreedCounts[tokenId]);
        }
    }

    function configCost(
        uint256 _breedCostPerDay,
        uint256 _dripCost,
        uint256 _nyankeeCost,
        uint256 _gatchaItemPrice,
        uint256 _resetFerdilityCost,
        uint256 _turnOnBreedGen1Cost,
        uint256 _dripRate,
        uint256 _rentFeePercen,
        uint256 _maxPillForStaking
    ) external onlyOwner {
        breedCostPerDay = _breedCostPerDay;
        dripCost = _dripCost;
        nyanKeeCost = _nyankeeCost;
        itemPrice = _gatchaItemPrice;
        resetFerdilityCost = _resetFerdilityCost;
        turnOnBreedGen1Cost = _turnOnBreedGen1Cost;
        dripRate = _dripRate;
        rentFee = _rentFeePercen;
        maxPillForStaking = _maxPillForStaking;
    }

    function resetFerdility(uint256 tokenId) external {
        (, , , , uint16 generation) = nftAddress.bunnies(tokenId);
        require(generation == 0, "that function only provice for gen 0");
        require(rewardToken.balanceOf(msg.sender) >= resetFerdilityCost, "Not enougn token for this function");
        ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, resetFerdilityCost);
        idToBreedCounts[tokenId] = 0;
    }

    function changeGen1Ferdility(uint256 tokenId) external {
        (, , , , uint16 generation) = nftAddress.bunnies(tokenId);
        require(generation == 1, "that function only provice for gen 1");
        require(rewardToken.balanceOf(msg.sender) >= turnOnBreedGen1Cost, "Not enougn token for this function");

        ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, turnOnBreedGen1Cost);
        idToBreedCounts[tokenId] = 0;
    }

    // because use bytes32 can't split it live strings
    function _parseBytes32(bytes32 gens, uint8 index) internal pure returns (bytes1 result) {
        uint8 start = (index - 1) * 8;
        assembly {
            result := shl(start, gens)
        }
    }

    function setIntToSuicideRate(uint16[] calldata suicideRates) external onlyOwner {
        intToSuicideRate = suicideRates;
    }

    function cancelLease(uint256 tokenId) external {
        LeaseMarket storage leaseMarket = tokenIdLeaseMarket[tokenId];
        require(leaseMarket.owner == msg.sender, "you are not owner");
        withdraw(tokenId);
        delete tokenIdLeaseMarket[tokenId];
        emit UserCancelLeaseBunny(msg.sender, tokenId);
    }

    function lease(uint256 tokenId, uint256 price) external {
        require(!paused(), "contract paused");
        if (!isUserStakedNft(msg.sender, tokenId)) {
            require(nftAddress.ownerOf(tokenId) == msg.sender, " you are not owners");
            // lease are still staking
            deposit(tokenId, false);
        }
        LeaseMarket memory leaseMarket;
        leaseMarket.owner = msg.sender;
        leaseMarket.price = price;
        leaseMarket.timestampLease = block.timestamp;
        leaseMarket.renter = address(0);
        tokenIdLeaseMarket[tokenId] = leaseMarket;
        emit UserLeaseBunny(msg.sender, tokenId, price);
    }

    function _rent(uint256 tokenId, uint256 durationInDay) internal {
        require(!paused(), "contract paused");
        LeaseMarket storage leaseMarket = tokenIdLeaseMarket[tokenId];
        require(rewardToken.balanceOf(msg.sender) >= leaseMarket.price.mul(durationInDay), "Not enougn token for rent");
        require(
            rewardToken.allowance(msg.sender, address(this)) >= leaseMarket.price.mul(durationInDay),
            "Please approval for contract can use Pill token"
        );
        require(leaseMarket.renter == address(0), "Bunny not available for rent");

        ERC20(address(rewardToken)).safeTransferFrom(msg.sender, address(this), leaseMarket.price.mul(durationInDay));

        // transfer rent fee market for fee recient;
        ERC20(address(rewardToken)).safeTransfer(
            burnAddress,
            leaseMarket.price.mul(durationInDay).mul(rentFee).div(10000)
        );

        // transfer rent fee for owner;
        ERC20(address(rewardToken)).safeTransfer(
            leaseMarket.owner,
            leaseMarket.price.mul(durationInDay).sub(leaseMarket.price.mul(durationInDay).mul(rentFee).div(10000))
        );
        leaseMarket.renter = msg.sender;
        leaseMarket.timestampRent = block.timestamp;
        leaseMarket.duration = durationInDay.mul(timestampPerDay);
        emit UserRentBunny(leaseMarket.owner, msg.sender, tokenId, leaseMarket.price, leaseMarket.duration);
    }

    function _calculateBreedTime(
        bool isUseNyanKee,
        uint256 fertility1,
        uint256 fertility2,
        uint256 breedBoots1,
        uint256 breedBoots2
    ) internal pure returns (uint256) {
        /// calculate in zoom 10000, smart contract don't have decimal;
        uint256 nyanKeeRate = 0;
        if (isUseNyanKee) {
            nyanKeeRate = 1500;
        }
        uint256 group1 = uint256(10000) + (breedBoots1 + breedBoots2).div(2);
        uint256 group2 = ((fertility1.mul(10000) + fertility2.mul(10000)).mul(30000)).div(10000);
        uint256 group3 = 720000 - group2;
        uint256 group4 = group3.mul(10000).div(group1);
        uint256 breedTimeInDay = uint256(10000 - nyanKeeRate).mul(group4).div(10000).div(10000);
        return breedTimeInDay;
    }

    function estimateBreedTimeAndCost(
        uint256 bunnyId1,
        uint256 bunnyId2,
        bool useNyanKee
    ) external view returns (uint256, uint256) {
        uint256 breedingDay = _getBreedingTime(bunnyId1, bunnyId2, useNyanKee);
        if (useNyanKee) {
            return (breedingDay, breedingDay.mul(breedCostPerDay).add(nyanKeeCost));
        } else {
            return (breedingDay, breedingDay.mul(breedCostPerDay));
        }
    }

    function _calculateSuccessRate(uint256 suicideRate1, uint256 suicideRate2) internal pure returns (uint256) {
        /// calculate in zoom 10000, smart contract don't have decimal;
        uint256 successRate = (20000 - suicideRate1 - suicideRate2).mul(10000).div(20000);
        /// return sucess rate in zoom 10000;
        return successRate;
    }

    function getSuccessRate(uint256 bunnyId1, uint256 bunnyId2) public view returns (uint256) {
        /// calculate in zoom 10000, smart contract don't have decimal;
        (bytes32 gens1, , , , ) = nftAddress.bunnies(bunnyId1);
        (bytes32 gens2, , , , ) = nftAddress.bunnies(bunnyId2);

        uint256 suicideRate1 = intToSuicideRate[uint8(_parseBytes32(gens1, 3))];
        uint256 suicideRate2 = intToSuicideRate[uint8(_parseBytes32(gens2, 3))];
        uint256 successRate = _calculateSuccessRate(suicideRate1, suicideRate2);
        /// return sucess rate in zoom 10000;
        return successRate;
    }

    // breed time in day
    function _getBreedingTime(
        uint256 bunnyId1,
        uint256 bunnyId2,
        bool useNyanKee
    ) internal view returns (uint256) {
        (bytes32 gens1, , , , ) = nftAddress.bunnies(bunnyId1);
        (bytes32 gens2, , , , ) = nftAddress.bunnies(bunnyId2);
        // breed boots = 50% - SuicideRate
        // but get intToSuicideRate from secound pair
        uint256 breedBoots1 = 5000 - intToSuicideRate[uint8(_parseBytes32(gens1, 3))];
        uint256 breedBoots2 = 5000 - intToSuicideRate[uint8(_parseBytes32(gens2, 3))];
        uint256 fertility1 = getFertility(bunnyId1);
        uint256 fertility2 = getFertility(bunnyId2);
        /// return day in int
        uint256 breedingTimeInDay = _calculateBreedTime(useNyanKee, fertility1, fertility2, breedBoots1, breedBoots2);
        /// return breed day
        return breedingTimeInDay;
    }

    // ignore check owner of rented Bunny
    // check rented bunny valid by time and duration
    // can't breed staking bunny, just write this function for bunny in wallet
    function _breedingWithRentedBunny(
        uint256 bunnyId1,
        uint256 rentedBunnyId,
        bool useNyanKee
    ) internal returns (uint256) {
        require(!paused(), "contract paused");
        require(
            nftAddress.isApprovedForAll(msg.sender, address(this)) == true,
            "Please approval for contract can take your bunny"
        );
        require(bunnyId1 != rentedBunnyId, "need 2 bunny to breed");

        if (!isUserStakedNft(msg.sender, bunnyId1)) {
            require(nftAddress.ownerOf(bunnyId1) == msg.sender, "you are not owner of bunnies");
            nftAddress.safeTransferFrom(msg.sender, address(this), bunnyId1);
        } else {
            _stopStakingForBreeding(bunnyId1, msg.sender);
            //// staking without lease
            LeaseMarket storage userLease = tokenIdLeaseMarket[bunnyId1];
            require(userLease.owner == address(0), "bunny have been lease out");
        }

        uint256 breedTimeInDay = _getBreedingTime(bunnyId1, rentedBunnyId, useNyanKee);
        _rent(rentedBunnyId, breedTimeInDay);
        LeaseMarket storage rentedBunny = tokenIdLeaseMarket[rentedBunnyId];

        require(getFertility(bunnyId1) >= 2, "Not enough Ferdility");
        if (useNyanKee) {
            require(
                rewardToken.allowance(msg.sender, address(this)) >= nyanKeeCost,
                "Please approval for contract can take Pill token"
            );
            require(rewardToken.balanceOf(msg.sender) >= nyanKeeCost, "Not enough token for NyanKee");
            ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, nyanKeeCost);
        }
        // for test
        // uint256 breedingTime = 100;
        // uint256 pillCost = 200 * 10**18;
        uint256 breedingTime = timestampPerDay.mul(breedTimeInDay);
        uint256 pillCost = breedTimeInDay.mul(breedCostPerDay);

        require(
            rewardToken.allowance(msg.sender, address(this)) >= pillCost,
            "Please approval for contract can take Pill token"
        );

        require(rewardToken.balanceOf(msg.sender) >= pillCost, "not enough pill");
        ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, pillCost);

        // Parent bunny descrease to 2.. rented bunny don't descrease
        idToBreedCounts[bunnyId1] = idToBreedCounts[bunnyId1] + 2;

        rentedBunny.usedToBreed = true;
        // escow bunny to contract

        _stopStakingForBreeding(rentedBunnyId, rentedBunny.owner);

        uint256 successRate = getSuccessRate(bunnyId1, rentedBunnyId);

        Breeding memory breed;
        breed.bunnyId1 = bunnyId1;
        breed.bunnyId2 = rentedBunnyId;
        breed.bunnyContract = address(nftAddress);
        breed.owner = msg.sender;
        breed.rentedBunnyOwner = rentedBunny.owner;
        breed.isRentedBunny = true;
        breed.useRyanKee = useNyanKee;
        breed.duration = breedingTime;
        breed.timestampBreeding = block.timestamp;
        /// estimate block target;
        breed.successRate = successRate;
        breed.cooldownEndBlock = block.number + breedingTime.div(secondsPerBlock);

        tokenIdBreedings[bunnyId1] = breed;

        emit UserBreedBunny(msg.sender, rentedBunny.owner, bunnyId1, rentedBunnyId, true, breedingTime);

        return bunnyId1;
    }

    // check owner of bunies
    // escow bunies to contract.
    // can use staked bunny for breed, stop staking while they breed
    function _breedingWithBunnies(
        uint256 bunnyId1,
        uint256 bunnyId2,
        bool useNyanKee
    ) internal returns (uint256) {
        require(!paused(), "contract paused");
        require(
            nftAddress.isApprovedForAll(msg.sender, address(this)) == true,
            "Please approval for contract can take your bunny"
        );
        require(bunnyId1 != bunnyId2, "need 2 bunny to breed");

        // escow bunny to contract
        if (!isUserStakedNft(msg.sender, bunnyId1)) {
            require(nftAddress.ownerOf(bunnyId1) == msg.sender, "you are not owner of bunnies");
            nftAddress.safeTransferFrom(msg.sender, address(this), bunnyId1);
        } else {
            //// staking without lease
            LeaseMarket storage userLease = tokenIdLeaseMarket[bunnyId1];
            require(userLease.owner == address(0), "bunny have been lease out");
            _stopStakingForBreeding(bunnyId1, msg.sender);
        }
        if (!isUserStakedNft(msg.sender, bunnyId2)) {
            require(nftAddress.ownerOf(bunnyId2) == msg.sender, "you are not owner of bunnies");
            nftAddress.safeTransferFrom(msg.sender, address(this), bunnyId2);
        } else {
            //// staking without lease
            LeaseMarket storage userLease = tokenIdLeaseMarket[bunnyId2];
            require(userLease.owner == address(0), "bunny have been lease out");
            _stopStakingForBreeding(bunnyId2, msg.sender);
        }

        if (useNyanKee) {
            require(rewardToken.balanceOf(msg.sender) >= nyanKeeCost, "Not enough token for NyanKee");
            ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, nyanKeeCost);
        }
        require(getFertility(bunnyId1) > 0, "Not enough Ferdility");
        require(getFertility(bunnyId2) > 0, "Not enough Ferdility");

        uint256 breedTimeInDay = _getBreedingTime(bunnyId1, bunnyId2, useNyanKee);
        // for test
        // uint256 breedingTime = 100;
        // uint256 pillCost = 200 * 10**18;
        uint256 breedingTime = timestampPerDay.mul(breedTimeInDay);
        uint256 pillCost = breedTimeInDay.mul(breedCostPerDay);
        require(rewardToken.balanceOf(msg.sender) >= pillCost, "not enough pill");
        ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, pillCost);

        // inscrease Breed Count 1
        idToBreedCounts[bunnyId1] = idToBreedCounts[bunnyId1] + 1;
        idToBreedCounts[bunnyId2] = idToBreedCounts[bunnyId2] + 1;
        uint256 successRate = getSuccessRate(bunnyId1, bunnyId2);

        Breeding memory breed;
        breed.bunnyId1 = bunnyId1;
        breed.bunnyId2 = bunnyId2;
        breed.bunnyContract = address(nftAddress);
        breed.owner = msg.sender;
        breed.rentedBunnyOwner = msg.sender;
        breed.isRentedBunny = false;
        breed.useRyanKee = useNyanKee;
        breed.duration = breedingTime;
        breed.timestampBreeding = block.timestamp;
        breed.successRate = successRate;
        /// estimate block;
        breed.cooldownEndBlock = block.number + breedingTime.div(secondsPerBlock);
        tokenIdBreedings[bunnyId1] = breed;
        emit UserBreedBunny(msg.sender, msg.sender, bunnyId1, bunnyId2, false, breedingTime);

        return bunnyId1;
    }

    function breedingWithBunnies(
        uint256 bunnyId1,
        uint256 bunnyId2,
        bool useNyanKee
    ) external returns (uint256) {
        return _breedingWithBunnies(bunnyId1, bunnyId2, useNyanKee);
    }

    function gatchaBunny(uint256 tokenId, uint256[] memory itemIds) external {
        require(!paused(), "contract paused");
        require(nftAddress.ownerOf(tokenId) == msg.sender, "you are not owner of bunny");
        for (uint256 i = 0; i < itemIds.length; i++) {
            gatchaItem.safeTransferFrom(msg.sender, burnAddress, itemIds[i], 1, "0x");
            emit UserGatchaBunny(msg.sender, tokenId, itemIds[i]);
        }
    }

    function buyGatchaItem(uint256 quantity) external {
        require(!paused(), "contract paused");
        require(rewardToken.balanceOf(msg.sender) >= itemPrice * quantity, "Not enougn token for this function");
        ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, itemPrice * quantity);
        for (uint256 i = 0; i < quantity; i++) {
            uint256 itemId = _rand(i, true);
            gatchaItem.mint(msg.sender, itemId, 1);
            emit UserBuyGatchaItem(msg.sender, itemId);
        }
    }

    function gatchaBunnyWithRandomItem(uint256 tokenId) external {
        require(!paused(), "contract paused");
        require(nftAddress.ownerOf(tokenId) == msg.sender, "you are not owner of bunny");
        ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, itemPrice);
        uint256 itemId = _rand(tokenId, true);
        emit UserBuyGatchaItem(msg.sender, itemId);
        emit UserGatchaBunny(msg.sender, tokenId, itemId);
    }

    function breedingWithRentedBunny(
        uint256 bunnyId1,
        uint256 rentedBunnyId,
        bool useNyanKee
    ) external returns (uint256) {
        return _breedingWithRentedBunny(bunnyId1, rentedBunnyId, useNyanKee);
    }

    function giveBirth(uint256 tokenId) external returns (uint256) {
        Breeding storage breed = tokenIdBreedings[tokenId];
        require(!paused(), "contract paused");
        require(_isPregnant(tokenId), "bunny don't breeding yet");
        require(_canGiveBirth(tokenId), "can't give birth now");
        require(msg.sender == breed.owner || msg.sender == breed.rentedBunnyOwner, "You are not owner");
        (bytes32 gens1, , , , ) = nftAddress.bunnies(breed.bunnyId1);
        (bytes32 gens2, , , , ) = nftAddress.bunnies(breed.bunnyId2);

        // Call the sooper-sekret gene mixing operation.
        bytes32 childGenes = geneScience.mixGenes(uint256(gens1), uint256(gens2), breed.cooldownEndBlock - 1);
        // random 0->9999
        uint256 random = _rand(breed.bunnyId1, false);
        // suceesRate in zoom 10000 -> 80% = 8000 (1>8000 == true).
        uint256 childrenBunnyId = 0;
        if (random + 1 <= breed.successRate) {
            childrenBunnyId = nftAddress.createFadeAwayBunny(
                breed.bunnyId1,
                breed.bunnyId2,
                1,
                childGenes,
                address(this)
            );
        }
        // Make the new bunny!
        // new born bunny alway gen 1

        if (!breed.isRentedBunny) {
            // if user use 2 bunnies for breeding -> give them back.
            _depositFromBreeding(breed.owner, breed.bunnyId1);
            _depositFromBreeding(breed.owner, breed.bunnyId2);
            if (childrenBunnyId > 0) {
                idToBreedCounts[childrenBunnyId] = 255;
                _depositFromBreeding(breed.owner, childrenBunnyId);
            }
        } else {
            /// give back rented bunny for Lease Market
            _updateBunnyRentState(breed.bunnyId2, true);
            _depositFromBreeding(breed.owner, breed.bunnyId1);
            LeaseMarket storage rentedBunny = tokenIdLeaseMarket[breed.bunnyId2];
            _depositFromBreeding(rentedBunny.owner, breed.bunnyId2);
            if (childrenBunnyId > 0) {
                // bunny gen 1 can't breed
                idToBreedCounts[childrenBunnyId] = 255;
                _depositFromBreeding(breed.owner, childrenBunnyId);
            }
        }
        emit UserGiveBirth(msg.sender, breed.bunnyId1, breed.bunnyId2, childrenBunnyId);
        delete tokenIdBreedings[tokenId];
        return childrenBunnyId;
    }

    function _updateBunnyRentState(uint256 tokenId, bool isGiveBirth) internal returns (bool) {
        LeaseMarket storage rentedBunny = tokenIdLeaseMarket[tokenId];
        require(rentedBunny.timestampRent >= 0, "Bunny not yet rented");
        if (isGiveBirth) {
            //// alway give back lease market when breed done.
            rentedBunny.usedToBreed = false;
            rentedBunny.renter = address(0);
            rentedBunny.duration = 0;
            rentedBunny.timestampRent = 0;
            return true;
        } else if (rentedBunny.timestampRent + rentedBunny.duration <= block.timestamp) {
            rentedBunny.usedToBreed = false;
            rentedBunny.renter = address(0);
            rentedBunny.duration = 0;
            rentedBunny.timestampRent = 0;
            return true;
        } else {
            return false;
        }
    }

    function updateBunnyRentState(uint256 tokenId) external {
        _updateBunnyRentState(tokenId, false);
    }

    function _rand(uint256 index, bool randomItem) internal view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                        block.number +
                        index
                )
            )
        );
        /// return rd value from 0 - 9999
        if (!randomItem) {
            return (seed - ((seed / 10000) * 10000));
        } else {
            return (seed - ((seed / itemNum) * itemNum));
        }
    }

    function _canGiveBirth(uint256 tokenId) internal view returns (bool) {
        Breeding storage breed = tokenIdBreedings[tokenId];
        if (breed.timestampBreeding == 0) return false;
        return (breed.timestampBreeding + breed.duration <= block.timestamp);
    }

    function canGiveBirth(uint256 tokenId) external view returns (bool) {
        return _canGiveBirth(tokenId);
    }

    function _isPregnant(uint256 tokenId) internal view returns (bool) {
        return tokenIdBreedings[tokenId].timestampBreeding > 0;
    }

    function isPregnant(uint256 tokenId) external view returns (bool) {
        return _isPregnant(tokenId);
    }

    // Update item effect block by the owner
    function setItemEffectBlock(uint256 _itemEffectBlock) public onlyOwner {
        itemEffectBlock = _itemEffectBlock;
    }

    // Update reward rate by the owner
    function setRewardPerDay(uint256 _rewardPerDay) public onlyOwner {
        rewardPerDay = _rewardPerDay;
    }

    // Update final reward block by the owner
    function setFinalRewardBlock(uint256 _finalRewardBlock) public onlyOwner {
        finalRewardBlock = _finalRewardBlock;
    }

    function getUserInfo(address _user) external view returns (uint256, uint256) {
        UserInfo storage user = userInfo[_user];

        return (user.amount, user.harvestedReward);
    }

    function getApliedItemInfo(address _user, uint256 _tokenId) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        return user.itemEndBlock[_tokenId];
    }

    //check deposited nft.
    function depositsOf(address _user) external view returns (uint256[] memory) {
        UserInfo storage user = userInfo[_user];
        EnumerableSet.UintSet storage depositSet = user.nftIds;
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    function deposit(uint256 _nftId, bool _applyItem) public {
        UserInfo storage user = userInfo[msg.sender];

        nftAddress.safeTransferFrom(address(msg.sender), address(this), _nftId);
        user.amount = user.amount.add(1);
        user.lastRewardBlock[_nftId] = block.number;
        user.nftIds.add(_nftId);
        emit Deposit(msg.sender, _nftId);
        if (_applyItem) {
            applyItem(_nftId);
        }
    }

    function _depositFromBreeding(address userAddress, uint256 _nftId) internal {
        UserInfo storage user = userInfo[userAddress];
        user.amount = user.amount.add(1);
        user.lastRewardBlock[_nftId] = block.number;
        user.nftIds.add(_nftId);
        emit Deposit(userAddress, _nftId);
    }

    function batchDeposit(uint256[] memory _nftIds) public nonReentrant {
        uint256 i;
        for (i = 0; i < _nftIds.length; i++) {
            deposit(_nftIds[i], false);
        }
    }

    function viewNftRate(uint256 _nftId) public view returns (uint16) {
        (bytes32 genes, , , , uint16 generation) = nftAddress.bunnies(_nftId);

        if (generation == 1) {
            return 10000;
        }

        uint16 earnRateInt = 10000 + (5000 - intToSuicideRate[uint8(_parseBytes32(genes, 3))]);
        return earnRateInt;
    }

    function isUserStakedNft(address _user, uint256 _nftId) public view returns (bool) {
        UserInfo storage user = userInfo[_user];

        return user.nftIds.contains(_nftId);
    }

    function viewReward(address _user, uint256 _nftId) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint16 nftRate = viewNftRate(_nftId);
        uint256 maxBlock;

        if (block.number > finalRewardBlock) {
            maxBlock = finalRewardBlock;
        } else {
            maxBlock = block.number;
        }

        if (user.lastRewardBlock[_nftId] >= maxBlock) {
            return 0;
        }

        if (user.itemEndBlock[_nftId] != 0 && user.lastRewardBlock[_nftId] <= user.itemEndBlock[_nftId]) {
            if (maxBlock <= user.itemEndBlock[_nftId]) {
                return
                    rewardPerDay.mul(maxBlock - user.lastRewardBlock[_nftId]).mul(dripRate).mul(nftRate).div(1e8).div(
                        blockPerDay
                    );
            } else {
                uint256 itemPeriod = user.itemEndBlock[_nftId] - user.lastRewardBlock[_nftId];
                uint256 normalPeriod = maxBlock - user.itemEndBlock[_nftId];
                uint256 tmpItemRate = dripRate;
                uint256 itemPeriodReward = rewardPerDay.mul(itemPeriod).mul(tmpItemRate).mul(nftRate).div(1e8).div(
                    blockPerDay
                );
                uint256 normalPeriodReward = rewardPerDay.mul(normalPeriod).mul(nftRate).div(10000).div(blockPerDay);
                return itemPeriodReward + normalPeriodReward;
            }
        } else {
            return rewardPerDay.mul(maxBlock - user.lastRewardBlock[_nftId]).mul(nftRate).div(10000).div(blockPerDay);
        }
    }

    function harvest(uint256 _nftId) public {
        require(isUserStakedNft(msg.sender, _nftId), "harvest:: this nft is not yours");
        UserInfo storage user = userInfo[msg.sender];
        uint256 reward = viewReward(msg.sender, _nftId);
        if (maxPillForStaking - totalPillClaimed == 0) {
            return;
        }
        if (maxPillForStaking - totalPillClaimed < reward) {
            reward = maxPillForStaking - totalPillClaimed;
        }
        if (reward == 0) {
            return;
        }
        totalPillClaimed = totalPillClaimed + reward;
        user.lastRewardBlock[_nftId] = block.number;
        user.harvestedReward = user.harvestedReward + reward;
        rewardToken.mint(msg.sender, reward);

        emit Harvest(msg.sender, _nftId, reward);
    }

    function _harvestForSomeOne(uint256 _nftId, address _owner) internal {
        require(isUserStakedNft(_owner, _nftId), "harvest:: this nft is not user");
        UserInfo storage user = userInfo[_owner];
        uint256 reward = viewReward(_owner, _nftId);
        if (maxPillForStaking - totalPillClaimed == 0) {
            return;
        }
        if (maxPillForStaking - totalPillClaimed < reward) {
            reward = maxPillForStaking - totalPillClaimed;
        }
        if (reward == 0) {
            return;
        }
        totalPillClaimed = totalPillClaimed + reward;

        user.lastRewardBlock[_nftId] = block.number;
        user.harvestedReward = user.harvestedReward + reward;
        rewardToken.mint(_owner, reward);

        emit Harvest(_owner, _nftId, reward);
    }

    function harvestAll() public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        EnumerableSet.UintSet storage depositSet = user.nftIds;

        for (uint256 i; i < depositSet.length(); i++) {
            harvest(depositSet.at(i));
        }
    }

    function batchHarvest(uint256[] memory _nftIds) public nonReentrant {
        uint256 i;
        for (i = 0; i < _nftIds.length; i++) {
            harvest(_nftIds[i]);
        }
    }

    function batchWithdraw(uint256[] memory _nftIds) public nonReentrant {
        uint256 i;
        for (i = 0; i < _nftIds.length; i++) {
            withdraw(_nftIds[i]);
        }
    }

    function _stopStakingForBreeding(uint256 _nftId, address _owner) internal {
        require(isUserStakedNft(_owner, _nftId), "stop staking:: this nft is not yours");
        UserInfo storage user = userInfo[_owner];
        _harvestForSomeOne(_nftId, _owner);
        user.amount = user.amount.sub(1);
        user.nftIds.remove(_nftId);
        emit Withdraw(msg.sender, _nftId);
    }

    function withdraw(uint256 _nftId) public {
        require(isUserStakedNft(msg.sender, _nftId), "withdraw:: this nft is not yours");
        UserInfo storage user = userInfo[msg.sender];
        LeaseMarket storage leaseMarket = tokenIdLeaseMarket[_nftId];
        if (leaseMarket.owner == msg.sender) {
            delete tokenIdLeaseMarket[_nftId];
            emit UserCancelLeaseBunny(msg.sender, _nftId);
        }
        harvest(_nftId);
        user.amount = user.amount.sub(1);
        nftAddress.safeTransferFrom(address(this), address(msg.sender), _nftId);
        user.nftIds.remove(_nftId);
        emit Withdraw(msg.sender, _nftId);
    }

    function applyItem(uint256 _nftId) public nonReentrant {
        require(isUserStakedNft(msg.sender, _nftId), "applyItem:: this nft is not yours!");
        require(rewardToken.balanceOf(msg.sender) >= dripCost, "applyItem:: not enough Pill for DRIP cost!");
        ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, dripCost);
        UserInfo storage user = userInfo[msg.sender];
        require(block.number >= user.itemEndBlock[_nftId], "applyItem:: only 1 ecstasy can be used at a time!");
        harvest(_nftId);
        user.itemEndBlock[_nftId] = block.number + itemEffectBlock;
        emit ApplyItem(msg.sender, _nftId, block.number + itemEffectBlock);
    }

    function batchApplyItem(uint256[] memory _nftIds) public {
        for (uint8 i = 0; i < _nftIds.length; i++) {
            applyItem(_nftIds[i]);
        }
    }
}
