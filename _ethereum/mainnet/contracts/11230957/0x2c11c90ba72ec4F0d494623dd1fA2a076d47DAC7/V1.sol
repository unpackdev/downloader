pragma solidity ^0.6.0;
import "./Counters.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./EnumerableSet.sol";

import "./IMuseToken.sol";
import "./IVNFT.sol";
import "./IVNFTx.sol";

// @TODO create interface for VNFTx
contract V1 is Ownable, ERC1155Holder {
    using SafeMath for uint256;

    bool paused = false;
    //for upgradability
    address public delegateContract;
    address[] public previousDelegates;
    uint256 public total = 1;

    IVNFT public vnft;
    IMuseToken public muse;
    IERC1155 public addons;

    uint256 public artistPct = 5;

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

    using EnumerableSet for EnumerableSet.UintSet;

    mapping(uint256 => Addon) public addon;

    mapping(uint256 => EnumerableSet.UintSet) private addonsConsumed;

    //nftid to rarity points
    mapping(uint256 => uint256) public rarity;
    mapping(uint256 => uint256) public challengesUsed;

    //!important, decides which gem score hp is based of
    uint256 public healthGem = 100;
    uint256 public healthGemDays = 2;

    // premium hp is the min requirement for premium features.
    uint256 public premiumHp = 90;

    using Counters for Counters.Counter;
    Counters.Counter private _addonId;

    IVNFTx public vnftx;

    constructor(IVNFT _vnft, IMuseToken _muse) public {
        vnft = _vnft;
        muse = _muse;
    }

    function setVNFTX(IVNFTx _vnftx) public onlyOwner {
        vnftx = _vnftx;
    }

    modifier notPaused() {
        require(!paused, "PAUSED");
        _;
    }

    modifier tokenOwner(uint256 _id) {
        require(
            vnft.ownerOf(_id) == msg.sender ||
                vnft.careTaker(_id, vnft.ownerOf(_id)) == msg.sender,
            "You must own the vNFT or be a care taker to buy addons"
        );
        _;
    }

    // func to test store update with delegatecall
    function challenge1(uint256 _nftId) public {
        rarity[_nftId] = rarity[_nftId] + 888;
    }

    // simple battle for muse
    function battle(uint256 _nftId, uint256 _opponent)
        public
        tokenOwner(_nftId)
    {
        // require x challenges and x hp or xx rarity for battles
        require(
            vnftx.getChallenges(_nftId) >= 1 &&
                rarity[_nftId] >= 100 &&
                vnftx.getHp(_nftId) >= premiumHp &&
                vnft.level(_nftId) >= vnft.level(_opponent),
            "can't challenge"
        );

        // require opponent to be of certain threshold
        require(
            vnftx.getHp(_opponent) <= vnftx.getHp(_nftId),
            "You can't attack this pet"
        );

        // challenge used.
        challengesUsed[_nftId] = challengesUsed[_nftId].sub(1);

        // decrease something, maybe rarity or something that will lower the opponents hp;
        rarity[_opponent] = rarity[_opponent].sub(100);

        // send muse to attacker based on condition, maybe level of opponent
        muse.mint(msg.sender, 1 ether);
    }

    function cash(uint256 _nftId) external tokenOwner(_nftId) {
        //require to own the accessory and maintain x level of hp
        require(
            addonsConsumed[_nftId].contains(1) &&
                vnftx.getHp(_nftId) >= premiumHp,
            "You need to buy the accessory"
        );

        //TOOD do calculation based on level and muse acquired, should qualify for intervals so not all players get caashback at same price.

        // calculate deserving amount and send to user;
        uint256 amount = 100 * 10**18;
        muse.mint(msg.sender, amount);
    }
}
