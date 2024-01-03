pragma solidity ^0.6.0;

import "./Initializable.sol";
import "./IERC165Upgradeable.sol";

import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

// @TODO DOn't Forget!!!
import "./ERC1155HolderUpgradeable.sol";

import "./EnumerableSetUpgradeable.sol";

import "./IMuseToken.sol";
import "./IVNFT.sol";

// SPDX-License-Identifier: MIT

// Extending IERC1155 with mint and burn
interface IERC1155 is IERC165Upgradeable {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external;
}

contract VNFTxV5 is
    Initializable,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable
{
    /* START V1  STORAGE */
    using SafeMathUpgradeable for uint256;

    bool paused;

    IVNFT public vnft;
    IMuseToken public muse;
    IERC1155 public addons;

    uint256 public artistPct;

    struct Addon {
        string _type;
        uint256 price;
        uint256 requiredhp;
        uint256 rarity;
        string artistName;
        address artistAddr;
        uint256 quantity;
        uint256 used;
    }

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    mapping(uint256 => Addon) public addon;

    mapping(uint256 => EnumerableSetUpgradeable.UintSet) private addonsConsumed;
    EnumerableSetUpgradeable.UintSet lockedAddons;

    //nftid to rarity points
    mapping(uint256 => uint256) public rarity;
    mapping(uint256 => uint256) public challengesUsed;

    //!important, decides which gem score hp is based of
    uint256 public healthGemScore;
    uint256 public healthGemId;
    uint256 public healthGemPrice;
    uint256 public healthGemDays;

    // premium hp is the min requirement for premium features.
    uint256 public premiumHp;
    uint256 public hpMultiplier;
    uint256 public rarityMultiplier;
    uint256 public addonsMultiplier;
    //expected addons to be used for max hp
    uint256 public expectedAddons;
    //Expected rarity, this should be changed according to new addons introduced.
    uint256 expectedRarity;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _addonId;

    /* END V1 STORAGE */

    uint256 cashbackPct;

    event BuyAddon(uint256 nftId, uint256 addon, address player);
    event CreateAddon(
        uint256 addonId,
        string _type,
        uint256 rarity,
        uint256 quantity
    );
    event EditAddon(
        uint256 addonId,
        string _type,
        uint256 price,
        uint256 _quantity
    );
    event AttachAddon(uint256 addonId, uint256 nftId);
    event RemoveAddon(uint256 addonId, uint256 nftId);

    /* EnD OF v3 Storage */

    mapping(uint256 => uint256) public hpLostOnBattle;
    mapping(uint256 => uint256) public timesAttacked;

    mapping(address => uint256) public toReceiveCashback;
    mapping(uint256 => uint256) private alreadyReceivedCashback;

    event Cashback(uint256 nft, uint256 amount);
    event Battle(uint256 winner, uint256 loser, uint256 museWon);

    /*
     ** END OF V4 STORAGE
     */

    mapping(uint256 => uint256) private petAlreadyReceivedCashback;

    constructor() public {}

    // function initialize(
    //     IVNFT _vnft,
    //     IMuseToken _muse,
    //     IERC1155 _addons
    // ) public initializer {
    //     vnft = _vnft;
    //     muse = _muse;
    //     addons = _addons;
    //     paused = false;
    //     artistPct = 5;
    //     healthGemScore = 100;
    //     healthGemId = 1;
    //     healthGemPrice = 13 * 10**18;
    //     healthGemDays = 1;
    //     premiumHp = 90;
    //     hpMultiplier = 70;
    //     rarityMultiplier = 15;
    //     addonsMultiplier = 15;
    //     expectedAddons = 10;
    //     expectedRarity = 300;
    //     OwnableUpgradeable.__Ownable_init();
    //     cashbackPct = 40;
    // }

    modifier tokenOwner(uint256 _id) {
        require(
            vnft.ownerOf(_id) == msg.sender,
            "3" //You must own the vNFT to use this feature
        );
        _;
    }

    modifier notLocked(uint256 _id) {
        require(!lockedAddons.contains(_id), "1"); //This addon is locked
        _;
    }

    modifier containsAddon(uint256 nftId, uint256 addonId) {
        require(addonsConsumed[nftId].contains(addonId), "fail");
        _;
    }
    modifier notPaused() {
        require(!paused, "2"); //Contract paused!
        _;
    }

    // get how many addons a pet is using
    function addonsBalanceOf(uint256 _nftId) public view returns (uint256) {
        return addonsConsumed[_nftId].length();
    }

    // get a specific addon
    function addonsOfNftByIndex(uint256 _nftId, uint256 _index)
        public
        view
        returns (uint256)
    {
        return addonsConsumed[_nftId].at(_index);
    }

    function getHp(uint256 _nftId) public view returns (uint256) {
        // A vnft need to get at least x score every two days to be healthy
        uint256 currentScore = vnft.vnftScore(_nftId);

        uint256 daysLived = getDaysLived(_nftId);

        // multiply by healthy gem divided by 2 (every 2 days)
        uint256 expectedScore = daysLived
            .mul(healthGemScore.div(healthGemDays))
            .add(hpLostOnBattle[_nftId]);

        // get # of addons used
        uint256 addonsUsed = addonsBalanceOf(_nftId);

        if (
            !vnft.isVnftAlive(_nftId) //not dead
        ) {
            return 0;
        } else if (daysLived < 1) {
            return 70;
        }
        // here we get the % they get from score, from rarity, from used and then return based on their multiplier
        uint256 fromScore = min(currentScore.mul(100).div(expectedScore), 100);
        uint256 fromRarity = min(
            rarity[_nftId].mul(100).div(expectedRarity),
            100
        );
        uint256 fromUsed = min(addonsUsed.mul(100).div(expectedAddons), 100);
        uint256 hp = (fromRarity.mul(rarityMultiplier))
            .add(fromScore.mul(hpMultiplier))
            .add(fromUsed.mul(addonsMultiplier));

        return min(hp.div(100), 100);
    }

    function getChallenges(uint256 _nftId) public view returns (uint256) {
        if (vnft.level(_nftId) <= challengesUsed[_nftId]) {
            return 0;
        }

        return vnft.level(_nftId).sub(challengesUsed[_nftId]);
    }

    function buyAddon(uint256 _nftId, uint256 addonId)
        public
        tokenOwner(_nftId)
        notPaused()
    {
        Addon storage _addon = addon[addonId];

        require(!addonsConsumed[_nftId].contains(addonId), "4"); // Pet already has this addon

        require(getHp(_nftId) >= _addon.requiredhp, "5"); // Pet already has this addon
        require(
            _addon.used < _addon.quantity &&
                addons.balanceOf(address(this), addonId) >= 1,
            "6"
        ); //Addon not available

        _addon.used = _addon.used.add(1);

        addonsConsumed[_nftId].add(addonId);

        rarity[_nftId] = rarity[_nftId].add(_addon.rarity);

        uint256 artistCut = _addon.price.mul(artistPct).div(100);

        muse.transferFrom(msg.sender, _addon.artistAddr, artistCut);
        muse.burnFrom(msg.sender, _addon.price.sub(artistCut));
        emit BuyAddon(_nftId, addonId, msg.sender);
    }

    function useAddon(uint256 _nftId, uint256 _addonID)
        public
        tokenOwner(_nftId)
        notPaused()
    {
        require(!addonsConsumed[_nftId].contains(_addonID), "4"); // Pet already has this addon
        require(addons.balanceOf(msg.sender, _addonID) >= 1, "7"); //own the addon to use it

        Addon storage _addon = addon[_addonID];

        require(getHp(_nftId) >= _addon.requiredhp, "8"); // Raise your HP to use this addon

        addonsConsumed[_nftId].add(_addonID);

        rarity[_nftId] = rarity[_nftId].add(_addon.rarity);

        addons.safeTransferFrom(msg.sender, address(this), _addonID, 1, "");
        emit AttachAddon(_addonID, _nftId);
    }

    function removeAddon(uint256 _nftId, uint256 _addonID)
        public
        tokenOwner(_nftId)
        notLocked(_addonID)
        containsAddon(_nftId, _addonID)
    {
        Addon storage _addon = addon[_addonID];
        rarity[_nftId] = rarity[_nftId].sub(_addon.rarity);

        addonsConsumed[_nftId].remove(_addonID);
        emit RemoveAddon(_addonID, _nftId);

        addons.safeTransferFrom(address(this), msg.sender, _addonID, 1, "");
    }

    function getDaysLived(uint256 _nftId) public view returns (uint256) {
        return (now - vnft.timeVnftBorn(_nftId)) / 1 days;
    }

    function getAttackInfo(uint256 _nftId, uint256 _opponent)
        public
        view
        returns (
            uint256 oponentHp,
            uint256 attackerHp,
            uint256 successPercent,
            uint256 estimatedReward
        )
    {
        oponentHp = getHp(_opponent);
        attackerHp = getHp(_nftId);
        // The percentage of attack is weighted between your HP and the pet HP
        // in the case where oponent as 20HP and attacker has 100
        // the chance of winning is 3 times your HP: 3*100 out of 320 (sum of both HP and attacker hp*3)
        successPercent = attackerHp.mul(3).mul(100).div(
            oponentHp.add(attackerHp.mul(3))
        );

        estimatedReward = vnft
            .level(_nftId)
            .add(vnft.level(_opponent))
            .mul(10)
            .div(100);
        if (estimatedReward <= 4) {
            estimatedReward = 4;
        }
    }

    // kill them all
    function battle(uint256 _nftId, uint256 _opponent)
        public
        tokenOwner(_nftId)
        containsAddon(_nftId, 4)
        notPaused()
    {
        (
            uint256 oponentHp,
            uint256 attackerHp,
            uint256 successPercent,

        ) = getAttackInfo(_nftId, _opponent);

        require(vnft.ownerOf(_opponent) != msg.sender, "A"); // Can't atack yourself

        // require x challenges and x hp or xx rarity for battles
        require(
            getChallenges(_nftId) >= 1 && attackerHp >= 70, //decide
            "D"
        ); // can't challenge

        require(timesAttacked[_opponent] <= 10, "E"); // This pet was attacked 10 times already

        // require opponent to be of certain threshold 30?
        require(oponentHp <= 90, "F"); // You can't attack this pet

        challengesUsed[_nftId] = challengesUsed[_nftId] + 1;
        timesAttacked[_opponent] = timesAttacked[_opponent] + 1;

        //decide winner
        uint256 loser;
        uint256 winner;

        if (randomNumber(_nftId + _opponent, 100) > successPercent) {
            loser = _nftId;
            winner = _opponent;
        } else {
            loser = _opponent;
            winner = _nftId;
        }

        // then do all calcs based on winner, could be opponent or nftid
        if (getHp(loser) < 20) {
            // need 6 health gem score more to to expected score
            hpLostOnBattle[loser] = hpLostOnBattle[loser].add(
                healthGemScore * 6
            );
        } else if (getHp(loser) >= 20) {
            // need 3 health gem score more to to expected score
            hpLostOnBattle[loser] = hpLostOnBattle[loser].add(
                healthGemScore * 3
            );
        }
        uint256 museWon = 0;
        if (winner == _nftId) {
            // get 15% of level in muse
            museWon = (vnft.level(winner).add(vnft.level(loser)).mul(10)) / 100;
            if (museWon <= 4) {
                museWon = 4;
            }
            muse.mint(vnft.ownerOf(winner), museWon * 10**18);
        }

        emit Battle(winner, loser, museWon);
    }

    function cashback(uint256 _nftId)
        external
        tokenOwner(_nftId)
        containsAddon(_nftId, 1)
        notPaused()
    {
        //    have premium hp
        require(getHp(_nftId) >= premiumHp, "H"); // Raise your hp to claim cashback
        // didn't get cashback in last 7 days or first time (0)
        require(
            (toReceiveCashback[msg.sender] <= block.timestamp &&
                petAlreadyReceivedCashback[_nftId] <= block.timestamp) ||
                (toReceiveCashback[msg.sender] == 0 &&
                    petAlreadyReceivedCashback[_nftId] == 0),
            "I"
        ); // You can't claim cahsback yet

        petAlreadyReceivedCashback[_nftId] = block.timestamp.add(7 days);

        uint256 currentScore = vnft.vnftScore(_nftId);

        uint256 daysLived = getDaysLived(_nftId);

        require(daysLived >= 14, "J"); // Lived at least 14 days for cashback

        uint256 expectedScore = daysLived.mul(
            healthGemScore.div(healthGemDays)
        );

        uint256 fromScore = min(currentScore.mul(100).div(expectedScore), 100);

        uint256 museSpent = healthGemPrice.mul(7).mul(fromScore).div(100);

        uint256 cashbackAmt = museSpent.mul(cashbackPct).div(100);

        muse.mint(msg.sender, cashbackAmt);

        alreadyReceivedCashback[_nftId] = alreadyReceivedCashback[_nftId].add(
            cashbackAmt
        );

        emit Cashback(_nftId, cashbackAmt);
    }

    // this is in case a dead pet addons is stuck in contract, we can use for diff cases.
    function withdraw(uint256 _id, address _to) external onlyOwner {
        addons.safeTransferFrom(address(this), _to, _id, 1, "");
    }

    function createAddon(
        string calldata _type,
        uint256 price,
        uint256 _hp,
        uint256 _rarity,
        string calldata _artistName,
        address _artist,
        uint256 _quantity,
        bool _lock
    ) external onlyOwner {
        _addonId.increment();
        uint256 newAddonId = _addonId.current();

        addon[newAddonId] = Addon(
            _type,
            price,
            _hp,
            _rarity,
            _artistName,
            _artist,
            _quantity,
            0
        );
        addons.mint(address(this), newAddonId, _quantity, "");

        if (_lock) {
            lockAddon(newAddonId);
        }

        emit CreateAddon(newAddonId, _type, _rarity, _quantity);
    }

    function getVnftInfo(uint256 _nftId)
        public
        view
        returns (
            uint256 _vNFT,
            uint256 _rarity,
            uint256 _hp,
            uint256 _addonsCount,
            uint256[10] memory _addons
        )
    {
        _vNFT = _nftId;
        _rarity = rarity[_nftId];
        _hp = getHp(_nftId);
        _addonsCount = addonsBalanceOf(_nftId);
        uint256 index = 0;
        while (index < _addonsCount && index < 10) {
            _addons[index] = (addonsConsumed[_nftId].at(index));
            index = index + 1;
        }
    }

    function editAddon(
        uint256 _id,
        string calldata _type,
        uint256 price,
        uint256 _requiredhp,
        uint256 _rarity,
        string calldata _artistName,
        address _artist,
        uint256 _quantity,
        uint256 _used,
        bool _lock
    ) external onlyOwner {
        Addon storage _addon = addon[_id];
        _addon._type = _type;
        _addon.price = price * 10**18;
        _addon.requiredhp = _requiredhp;
        _addon.rarity = _rarity;
        _addon.artistName = _artistName;
        _addon.artistAddr = _artist;
        if (_quantity > _addon.quantity) {
            addons.mint(address(this), _id, _quantity.sub(_addon.quantity), "");
        } else if (_quantity < _addon.quantity) {
            addons.burn(address(this), _id, _addon.quantity - _quantity);
        }
        _addon.quantity = _quantity;
        _addon.used = _used;

        if (_lock) {
            lockAddon(_id);
        }

        emit EditAddon(_id, _type, price, _quantity);
    }

    function lockAddon(uint256 _id) public onlyOwner {
        lockedAddons.add(_id);
    }

    function setHealthStrat(
        uint256 _score,
        uint256 _healthGemPrice,
        uint256 _healthGemId,
        uint256 _days,
        uint256 _hpMultiplier,
        uint256 _rarityMultiplier,
        uint256 _expectedAddons,
        uint256 _addonsMultiplier,
        uint256 _expectedRarity,
        uint256 _premiumHp,
        uint256 _cashbackPct
    ) external onlyOwner {
        healthGemScore = _score;
        healthGemPrice = _healthGemPrice;
        healthGemId = _healthGemId;
        healthGemDays = _days;
        hpMultiplier = _hpMultiplier;
        rarityMultiplier = _rarityMultiplier;
        expectedAddons = _expectedAddons;
        addonsMultiplier = _addonsMultiplier;
        expectedRarity = _expectedRarity;
        premiumHp = _premiumHp;
        cashbackPct = _cashbackPct;
    }

    function pause(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    /* generates a number from 0 to 2^n based on the last n blocks */
    function randomNumber(uint256 seed, uint256 max)
        public
        view
        returns (uint256 _randomNumber)
    {
        uint256 n = 0;
        for (uint256 i = 0; i < 5; i++) {
            n += uint256(
                keccak256(
                    abi.encodePacked(blockhash(block.number - i - 1), seed)
                )
            );
        }
        return (n * seed) % max;
    }
}
