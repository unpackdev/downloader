// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./VRFConsumerBase.sol";
import "./AggregatorV3Interface.sol";
import "./FoxHen.sol";

contract HenHouse is Ownable, VRFConsumerBase {
    FoxHen fh;
    IERC20 eggs;
    AggregatorV3Interface priceFeed;
    uint24 public constant poolFee = 3000;
    struct Staking {
        uint256 timestamp;
        address owner;
        uint16 stolen;
    }

    struct CurrentValue {
        uint256 tokenId;
        uint256 timestamp;
        uint256 value;
        string metadata;
    }

    struct Fox {
        uint256 timestamp;
        uint256 dailyCount;
        uint256 foxValue;
    }

    mapping(uint256 => Staking) public stakings;
    mapping(address => uint256[]) public stakingsByOwner;

    uint256 public foxValue;
    uint256 public foxCount;
    uint256 public eggsHeistedAmount;
    uint256 public heistAmount;
    uint256 public totalTaxAmount;
    mapping(uint256 => Fox) public foxes;
    mapping(bytes32 => uint256) heists;

    uint16 public taxPercentage = 15;
    uint16 public heistPercentage = 30;
    uint16 public taxFreeDays = 3;

    bytes32 internal keyHash;
    uint256 internal fee;

    bool public paused;

    event Heist(
        address indexed owner,
        uint256 indexed fox,
        uint256 hen,
        uint256 amount
    );

    constructor(
        address _fh,
        address _eggs,
        address _vrf,
        address _link,
        address _feed,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_vrf, _link) {
        fh = FoxHen(_fh);
        eggs = IERC20(_eggs);
        priceFeed = AggregatorV3Interface(_feed);
        IERC20(_link).approve(msg.sender, type(uint256).max);
        keyHash = _keyHash;
        fee = _fee;
    }

    // Reads
    function daysStaked(uint256 tokenId) public view returns (uint256) {
        Staking storage staking = stakings[tokenId];
        uint256 diff = block.timestamp - staking.timestamp;
        return uint256(diff) / 1 days;
    }

    function calculateReward(uint256 tokenId) public view returns (uint256) {
        require(fh.ownerOf(tokenId) == address(this), "The hen must be staked");
        uint256 balance = eggs.balanceOf(address(this));
        Staking storage staking = stakings[tokenId];
        uint256 baseReward = 100000 ether / uint256(1 days);
        uint256 diff = block.timestamp - staking.timestamp;
        uint256 dayCount = uint256(diff) / (1 days);
        if (dayCount < 1 || balance == 0) {
            return 0;
        }
        uint256 yesterday = dayCount - 1;
        uint256 dayRewards = (yesterday * yesterday + yesterday) /
            2 +
            10 *
            dayCount;
        uint256 ratio = (((dayRewards / dayCount) *
            (diff - dayCount * 1 days)) / 1 days) + dayRewards;
        uint256 reward = baseReward * ratio;
        return reward < balance ? reward : balance;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        return stakingsByOwner[owner][index];
    }

    function balanceOf(address owner) public view returns (uint256) {
        return stakingsByOwner[owner].length;
    }

    function allStakingsOfOwner(address owner)
        public
        view
        returns (CurrentValue[] memory)
    {
        uint256 balance = balanceOf(owner);
        CurrentValue[] memory list = new CurrentValue[](balance);
        for (uint16 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            Staking storage staking = stakings[tokenId];
            uint256 reward = calculateReward(tokenId) - staking.stolen;
            string memory metadata = fh.tokenURI(tokenId);
            list[i] = CurrentValue(tokenId, staking.timestamp, reward, metadata);
        }
        return list;
    }

    function linkPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function heistCost(uint256 tokenId) public view returns (uint256) {
        Fox storage fox = foxes[tokenId];
        uint256 diff = block.timestamp - fox.timestamp;
        uint256 exp = diff > 1 days ? 1 : fox.dailyCount + 1;
        return ((2**exp) * linkPrice() * 102) / 100;
    }

    // Staking

    function stakeHen(uint256 tokenId) public {
        require(!paused, "Contract paused");
        require(fh.ownerOf(tokenId) == msg.sender, "You must own that hen");
        require(!fh.isFox(tokenId), "You can only stake hens");
        require(fh.isApprovedForAll(msg.sender, address(this)));

        Staking memory staking = Staking(block.timestamp, msg.sender, 0);
        stakings[tokenId] = staking;
        stakingsByOwner[msg.sender].push(tokenId);
        fh.transferFrom(msg.sender, address(this), tokenId);
    }

    function multiStakeHen(uint256[] memory henIds) public {
        for (uint8 i = 0; i < henIds.length; i++) {
            stakeHen(henIds[i]);
        }
    }

    function unstakeHen(uint256 tokenId) public {
        require(fh.ownerOf(tokenId) == address(this), "The hen must be staked");
        Staking storage staking = stakings[tokenId];
        require(staking.owner == msg.sender, "You must own that hen");
        uint256[] storage stakedHens = stakingsByOwner[msg.sender];
        uint16 index = 0;
        for (; index < stakedHens.length; index++) {
            if (stakedHens[index] == tokenId) {
                break;
            }
        }
        require(index < stakedHens.length, "Hen not found");
        stakedHens[index] = stakedHens[stakedHens.length - 1];
        stakedHens.pop();
        staking.owner = address(0);
        fh.transferFrom(address(this), msg.sender, tokenId);
    }

    function claimHenRewards(uint256 tokenId, bool unstake) public {
        require(!paused, "Contract paused");
        uint256 netRewards = _claimHenRewards(tokenId);
        if (unstake) {
            unstakeHen(tokenId);
        }
        if (netRewards > 0) {
            require(eggs.transfer(msg.sender, netRewards));
        }
    }

    function claimManyHenRewards(uint256[] calldata hens, bool unstake) public {
        require(!paused, "Contract paused");
        uint256 netRewards = 0;
        for (uint8 i = 0; i < hens.length; i++) {
            netRewards += _claimHenRewards(hens[i]);
        }
        if (netRewards > 0) {
            require(eggs.transfer(msg.sender, netRewards));
        }
        if (unstake) {
            for (uint8 i = 0; i < hens.length; i++) {
                unstakeHen(hens[i]);
            }
        }
    }

    function claimManyFoxesRewards(uint256[] calldata claimingFoxes) public {
        for (uint8 i = 0; i < claimingFoxes.length; i++) {
            heist(claimingFoxes[i], false);
        }
    }

    // Heists
    function heist(uint256 tokenId, bool enterHenHouse) public payable {
        require(!paused, "Contract paused");
        require(
            fh.ownerOf(tokenId) == msg.sender && fh.isFox(tokenId),
            "You must own that fox"
        );
        Fox storage fox = foxes[tokenId];

        if (fox.timestamp == 0) {
            fox.timestamp = block.timestamp;
            fox.foxValue = foxValue;
            foxCount++;
        }

        if (enterHenHouse) {
            uint256 cost = heistCost(tokenId);

            require(msg.value >= cost, "You must pay the correct amount");

            uint256 diff = block.timestamp - fox.timestamp;
            if (diff > 1 days) {
                fox.timestamp = block.timestamp;
                fox.dailyCount = 1;
            } else {
                fox.dailyCount++;
            }

            heistAmount++;
            bytes32 requestId = requestRandomness(keyHash, fee);
            heists[requestId] = tokenId;
        }

        if (fox.foxValue < foxValue) {
            uint256 tax = foxValue - fox.foxValue;
            fox.foxValue = foxValue;
            totalTaxAmount += tax;
            eggs.transfer(msg.sender, tax);
        }
    }

    // Internal
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 foxId = heists[requestId];
        address foxOwner = fh.ownerOf(foxId);
        require(foxOwner != address(0));
        uint256 henIndex = randomness % fh.balanceOf(address(this));
        uint256 henId = fh.tokenOfOwnerByIndex(address(this), henIndex);
        Staking storage staking = stakings[henId];

        uint256 rewards = calculateReward(henId) - staking.stolen;
        uint256 stealAmount = (heistPercentage * rewards) / 100;

        if (stealAmount > 0) {
            eggsHeistedAmount += stealAmount;
            eggs.transfer(foxOwner, stealAmount);
        }
        emit Heist(foxOwner, foxId, henId, stealAmount);
    }

    function _claimHenRewards(uint256 tokenId) internal returns (uint256) {
        require(fh.ownerOf(tokenId) == address(this), "The hen must be staked");
        Staking storage staking = stakings[tokenId];
        require(staking.owner == msg.sender, "You must own that hen");

        uint256 rewards = calculateReward(tokenId);
        require(rewards >= staking.stolen, "You have no rewards at this time");
        rewards -= staking.stolen;

        uint256 tax = foxCount == 0 || daysStaked(tokenId) >= taxFreeDays
            ? 0
            : (taxPercentage * rewards) / 100;
        uint256 netRewards = rewards - tax;

        if (foxCount > 0 && tax > 0) {
            foxValue += tax / foxCount;
        }

        staking.stolen = 0;
        staking.timestamp = block.timestamp;

        return netRewards;
    }

    // Admin
    function withdraw(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }
}
