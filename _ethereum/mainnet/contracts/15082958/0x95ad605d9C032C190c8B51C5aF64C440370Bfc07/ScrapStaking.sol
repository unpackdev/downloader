// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

//Interface for SCRAP V2 Hub that contains minting/balance of SCRAP

interface IScrapHub {
    function increaseScrapBalance(address _address, uint256 _amount) external;

    function decreaseScrapBalance(address _address, uint256 _amount) external;
}

//Interface for Genesis Dysto Apez Contract
interface IDystoGen {
    function ownerOf(uint256 id) external view returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

//Interface for Elder Apez Contract
interface IElderApe {
    function ownerOf(uint256 id) external view returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract ScrapStake is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{


//    ==== Declarations ====

    bool private _paused;

    //Structure for tracking genesis staking stats
    struct GenesisStake {
        uint256 legendaryCount;
        uint256 count;
        uint256[] tokens;
    }

    //Structure for tracking other staking stats
    struct stake {
        uint256 count;
        uint256[] tokens;
    }

    //Structure for tracking elder staking stats
    struct ElderStake {
        uint256 count;
        uint256[] tokens;
    }

    //Declaration of interfaces
    IScrapHub public constant SCRAP_HUB =
        IScrapHub(0x829cE04A6114e11217B6DcF38884d15260e569d0);
    IDystoGen public constant DYSTO_GEN =
        IDystoGen(0x648E8428e0104Ec7D08667866a3568a72Fe3898F);
    IElderApe public constant ELDER_APE =
        IElderApe(0x943f4f7fc2D48F3AD8C524cf8A8794B64100df3F);

    //There are 10 legendary Dysto Apez that receive a bonus yield
    uint256 public constant LEGENDARY_SUPPLY = 10;

    //Daily rate of yield
    uint256 public dailyRate;

    //Daily bonus for legendary Dysto Apez - legendary apez get bonus and daily rate
    uint256 public dailyLegendaryBonus;

    //Daily yield rate for elder apez - elder apez DO NOT also collect 100 SCRAP
    uint256 public dailyElderRate;

    //array of addresses to keep track of which addresses have been added to yield
    address[] public yieldAddressIndex;

    //mapping of user addresses to the genesis staking structure
    mapping(address => GenesisStake) public accountGenesisStake;

    //mapping of user addresses to the elder staking structure
    mapping(address => ElderStake) public accountElderStake;

    //mapping of contract addresses with cooresponding yield rates
    mapping(address => uint256) public yieldMap;

    //mapping for other, non-genesis staking
    mapping(address => mapping(address => stake)) public accountStake;

    //mapping to track ownership of individual tokenIds
    mapping(uint256 => address) public ownerOfGenesis;

    //mapping to track ownership of individual tokenIds
    mapping(uint256 => address) public ownerOfElder;

    //mappig to track ownership of non-genesis staked tokens
    mapping(address => mapping(uint256 => address)) public ownerOfOtherStake;

    //mapping to track global last update of user account
    mapping(address => uint256) public accountLastUpdate;

    //bool to enable staking/yield of non-genesis assets
    bool public otherStakeActive;
    bool public elderStakeActive;


//    ==== Modifiers ====


    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        dailyRate = 100 ether;
        dailyLegendaryBonus = 700 ether;
        dailyElderRate = 500 ether;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /*
    ==== User Stake/Unstake Functions ====
*/

    function stakeGen(uint256[] memory tokenIds)
        public
        nonReentrant
        whenNotPaused
    {
        updateReward(msg.sender);
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                DYSTO_GEN.ownerOf(tokenIds[i]) == msg.sender,
                "Not the owner"
            );
            DYSTO_GEN.transferFrom(msg.sender, address(this), tokenIds[i]);
            ownerOfGenesis[tokenIds[i]] = msg.sender;
            accountGenesisStake[msg.sender].tokens.push(tokenIds[i]);
            if (tokenIds[i] <= LEGENDARY_SUPPLY) {
                accountGenesisStake[msg.sender].legendaryCount++;
            }
        }
        accountGenesisStake[msg.sender].count =
            accountGenesisStake[msg.sender].count +
            tokenIds.length;
    }

    function unStakeGen(uint256[] memory tokenIds)
        public
        nonReentrant
        whenNotPaused
    {
        updateReward(msg.sender);
        for (uint256 i; i < tokenIds.length; i++) {
            require(ownerOfGenesis[tokenIds[i]] == msg.sender, "Not the owner");
            delete (ownerOfGenesis[tokenIds[i]]);
            removeGenToken(msg.sender, tokenIds[i]);
            DYSTO_GEN.transferFrom(address(this), msg.sender, tokenIds[i]);
            if (tokenIds[i] <= LEGENDARY_SUPPLY) {
                accountGenesisStake[msg.sender].legendaryCount--;
            }
        }
        accountGenesisStake[msg.sender].count =
            accountGenesisStake[msg.sender].count -
            tokenIds.length;
    }

    function stakeElder(uint256[] memory tokenIds)
        public
        nonReentrant
        whenNotPaused
    {
        updateReward(msg.sender);
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                ELDER_APE.ownerOf(tokenIds[i]) == msg.sender,
                "Not the owner"
            );
            ELDER_APE.transferFrom(msg.sender, address(this), tokenIds[i]);
            ownerOfElder[tokenIds[i]] = msg.sender;
            accountElderStake[msg.sender].tokens.push(tokenIds[i]);
        }
        accountElderStake[msg.sender].count =
            accountElderStake[msg.sender].count +
            tokenIds.length;
    }

    function unStakeElder(uint256[] memory tokenIds)
        public
        nonReentrant
        whenNotPaused
    {
        updateReward(msg.sender);
        for (uint256 i; i < tokenIds.length; i++) {
            require(ownerOfElder[tokenIds[i]] == msg.sender, "Not the owner");
            delete (ownerOfElder[tokenIds[i]]);
            removeElderToken(msg.sender, tokenIds[i]);
            ELDER_APE.transferFrom(address(this), msg.sender, tokenIds[i]);
        }
        accountElderStake[msg.sender].count =
            accountElderStake[msg.sender].count -
            tokenIds.length;
    }

    function stakeOther(address _contract, uint256[] memory tokenIds)
        public
        nonReentrant
        whenNotPaused
    {
        require(yieldMap[_contract] != 0, "This is not a stakable token");
        updateReward(msg.sender);
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                IERC721(_contract).ownerOf(tokenIds[i]) == msg.sender,
                "Not the owner"
            );
            IERC721(_contract).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
            ownerOfOtherStake[_contract][tokenIds[i]] = msg.sender;
            accountStake[_contract][msg.sender].tokens.push(tokenIds[i]);
        }
        accountStake[_contract][msg.sender].count =
            accountStake[_contract][msg.sender].count +
            tokenIds.length;
    }

    function unStakeOther(address _contract, uint256[] memory tokenIds)
        public
        nonReentrant
        whenNotPaused
    {
        updateReward(msg.sender);
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                ownerOfOtherStake[_contract][tokenIds[i]] == msg.sender,
                "Not the owner"
            );
            delete (ownerOfOtherStake[_contract][tokenIds[i]]);
            removeOtherToken(_contract, msg.sender, tokenIds[i]);
            IERC721(_contract).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );
        }
        accountStake[_contract][msg.sender].count =
            accountStake[_contract][msg.sender].count -
            tokenIds.length;
    }

//    ==== View Functions ====

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    //returns requested staking struct
    function getAccountGenesisStaked(address user)
        external
        view
        returns (GenesisStake memory)
    {
        return accountGenesisStake[user];
    }

    function getAccountElderStaked(address user)
        external
        view
        returns (ElderStake memory)
    {
        return accountElderStake[user];
    }

    function getAccountOtherStaked(address _contract, address user)
        external
        view
        returns (stake memory)
    {
        return accountStake[_contract][user];
    }

    //returns array of staked tokenIds for inputted address
    function getAccountStakedTokens(address user)
        external
        view
        returns (uint256[] memory)
    {
        return accountGenesisStake[user].tokens;
    }

    //returns the daily yield rate for an address
    function getYieldPerDay(address user) external view returns (uint256) {
        uint256 dailyYield = (accountGenesisStake[user].count * dailyRate) +
            (accountGenesisStake[user].legendaryCount * dailyLegendaryBonus);
        dailyYield += (accountElderStake[user].count * dailyElderRate);
        for (uint256 i; i < yieldAddressIndex.length; i++) {
            dailyYield += (accountStake[yieldAddressIndex[i]][user].count *
                yieldMap[yieldAddressIndex[i]]);
        }
        return dailyYield;
    }

    //Returns total pending rewards
    function viewRewards(address _staker) public view returns (uint256) {
        return
            getPendingGenReward(_staker) +
            getPendingReward(_staker) +
            getPendingElderReward(_staker);
    }


//    ==== Interal Staking Functions ====

    //calculates bonus yield for staking multiple Genesis Dysto Apez
    function _calculateBonus(address _user) internal view returns (uint256) {
        uint256 stakedBalance = accountGenesisStake[_user].count;
        if (stakedBalance >= 20) return 400 ether;
        if (stakedBalance >= 10) return 150 ether;
        if (stakedBalance >= 5) return 50 ether;
        if (stakedBalance >= 2) return 10 ether;
        return 0;
    }

    //Functions to return the pending rewards for user
    function getPendingGenReward(address user) internal view returns (uint256) {
        if (accountGenesisStake[user].count == 0) {
            return 0;
        } else {
            uint256 timeSinceLastClaim = block.timestamp -
                accountLastUpdate[user];
            uint256 pendingBasic = accountGenesisStake[user].count *
                ((dailyRate * timeSinceLastClaim) / 86400);
            uint256 pendingLegendary = accountGenesisStake[user]
                .legendaryCount *
                ((dailyLegendaryBonus * timeSinceLastClaim) / 86400);
            uint256 pendingBonus = (_calculateBonus(user) *
                timeSinceLastClaim) / 86400;
            return pendingBasic + pendingLegendary + pendingBonus;
        }
    }

    function getPendingElderReward(address user)
        internal
        view
        returns (uint256)
    {
        if (accountElderStake[user].count == 0) {
            return 0;
        } else {
            uint256 timeSinceLastClaim = block.timestamp -
                accountLastUpdate[user];
            uint256 pending = accountElderStake[user].count *
                ((dailyElderRate * timeSinceLastClaim) / 86400);
            return pending;
        }
    }

    function getPendingReward(address _user) internal view returns (uint256) {
        uint256 totalPendingReward;
        for (uint256 i; i < yieldAddressIndex.length; i++) {
            uint256 timeSinceLastClaim = block.timestamp -
                accountLastUpdate[_user];
            totalPendingReward +=
                accountStake[yieldAddressIndex[i]][_user].count *
                ((yieldMap[yieldAddressIndex[i]] * timeSinceLastClaim) / 86400);
        }
        return totalPendingReward;
    }

    //Functions to remove a specific tokenId from staked token array in staking structures
    function removeGenToken(address _user, uint256 id) internal {
        for (uint256 i; i < accountGenesisStake[_user].tokens.length; i++) {
            if (accountGenesisStake[_user].tokens[i] == id) {
                accountGenesisStake[_user].tokens[i] = accountGenesisStake[
                    _user
                ].tokens[accountGenesisStake[_user].tokens.length - 1];
                accountGenesisStake[_user].tokens.pop();
                break;
            }
        }
    }

    function removeElderToken(address _user, uint256 id) internal {
        for (uint256 i; i < accountElderStake[_user].tokens.length; i++) {
            if (accountElderStake[_user].tokens[i] == id) {
                accountElderStake[_user].tokens[i] = accountElderStake[_user]
                    .tokens[accountElderStake[_user].tokens.length - 1];
                accountElderStake[_user].tokens.pop();
                break;
            }
        }
    }

    function removeOtherToken(
        address _contract,
        address _user,
        uint256 id
    ) internal {
        for (uint256 i; i < accountStake[_contract][_user].tokens.length; i++) {
            if (accountStake[_contract][_user].tokens[i] == id) {
                accountStake[_contract][_user].tokens[i] = accountStake[
                    _contract
                ][_user].tokens[
                        accountStake[_contract][_user].tokens.length - 1
                    ];
                accountStake[_contract][_user].tokens.pop();
                break;
            }
        }
    }

    //Function to set the time of last yield update to the current block timestamp
    function updateLastTime(address user) internal {
        accountLastUpdate[user] = block.timestamp;
    }

    //Function to update reward and add pending rewards to user balance
    function updateReward(address _staker) public nonReentrant {
        uint256 pendingRewards = getPendingGenReward(_staker);
        if (otherStakeActive = true)
            pendingRewards += getPendingReward(_staker);
        if (elderStakeActive = true)
            pendingRewards += getPendingElderReward(_staker);
        updateLastTime(_staker);
        SCRAP_HUB.increaseScrapBalance(_staker, pendingRewards);
    }


//    ==== Admin Functions ====


    function setPaused(bool _state) external onlyOwner {
        _paused = _state;
    }

    //functions to update the yield rates - in ether
    function updateGenRate(uint256 rate) external onlyOwner {
        dailyRate = rate * 1 ether;
    }

    function updateLegendaryBonus(uint256 rate) external onlyOwner {
        dailyLegendaryBonus = rate * 1 ether;
    }

    function updateElderRate(uint256 rate) external onlyOwner {
        dailyElderRate = rate * 1 ether;
    }

    function setElderStakeActive(bool _state) external onlyOwner {
        elderStakeActive = _state;
    }

    //Add a contract to the yielding process
    function addYieldcontract(address _contract, uint256 _rate)
        external
        onlyOwner
    {
        require(
            yieldMap[_contract] == 0,
            "This contract has already been added"
        );
        yieldMap[_contract] = _rate * 1 ether;
        yieldAddressIndex.push(_contract);
    }

    //Update the yield for a contract already added to the yielding process
    function updateContractYield(address _contract, uint256 _rate)
        external
        onlyOwner
    {
        require(
            yieldMap[_contract] != 0,
            "this contrcat has not been added to the yield system. Please add it using addYieldContract function"
        );
        yieldMap[_contract] = _rate * 1 ether;
    }

    //Remove contract from the yield mapping
    function removeYieldcontract(address _contract) external onlyOwner {
        require(yieldMap[_contract] != 0, "Contract not found");
        delete yieldMap[_contract];
        for (uint256 i; i < yieldAddressIndex.length; i++) {
            if (yieldAddressIndex[i] == _contract) {
                yieldAddressIndex[i] = yieldAddressIndex[
                    yieldAddressIndex.length - 1
                ];
                yieldAddressIndex.pop();
                break;
            }
        }
    }

    //withdraws tokens to their respective owner. For use in case of emergency.
    function emergencyWithdrawGen(uint256[] memory tokenIds)
        public
        onlyOwner
        whenPaused
    {
        require(tokenIds.length <= 50, "50 is max per tx");
        for (uint256 i; i < tokenIds.length; i++) {
            address receiver = ownerOfGenesis[tokenIds[i]];
            if (
                receiver != address(0) &&
                DYSTO_GEN.ownerOf(tokenIds[i]) == address(this)
            ) {
                DYSTO_GEN.transferFrom(address(this), receiver, tokenIds[i]);
            }
        }
    }

    function emergencyWithdrawElder(uint256[] memory tokenIds)
        public
        onlyOwner
        whenPaused
    {
        require(tokenIds.length <= 50, "50 is max per tx");
        for (uint256 i; i < tokenIds.length; i++) {
            address receiver = ownerOfElder[tokenIds[i]];
            if (
                receiver != address(0) &&
                ELDER_APE.ownerOf(tokenIds[i]) == address(this)
            ) {
                ELDER_APE.transferFrom(address(this), receiver, tokenIds[i]);
            }
        }
    }

    function emergencyWithdrawOther(
        uint256[] memory tokenIds,
        address _contract
    ) public onlyOwner whenPaused {
        require(tokenIds.length <= 50, "50 is max per tx");
        for (uint256 i; i < tokenIds.length; i++) {
            address receiver = ownerOfOtherStake[_contract][tokenIds[i]];
            if (
                receiver != address(0) &&
                IERC721(_contract).ownerOf(tokenIds[i]) == address(this)
            ) {
                IERC721(_contract).transferFrom(
                    address(this),
                    receiver,
                    tokenIds[i]
                );
            }
        }
    }
}
