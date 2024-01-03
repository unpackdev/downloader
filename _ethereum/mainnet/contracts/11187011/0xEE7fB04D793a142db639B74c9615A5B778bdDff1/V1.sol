pragma solidity ^0.6.0;
import "./Counters.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./EnumerableSet.sol";

import "./IMuseToken.sol";
import "./IVNFT.sol";

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
        string name;
        uint256 price;
        uint256 rarity;
        string artistName;
        address artist;
        uint256 quantity;
        uint256 used;
    }

    using EnumerableSet for EnumerableSet.UintSet;

    mapping(uint256 => Addon) public addon;

    mapping(uint256 => EnumerableSet.UintSet) private addonsConsumed;

    //nftid to rarity points
    mapping(uint256 => uint256) public rarity;

    using Counters for Counters.Counter;
    Counters.Counter private _addonId;

    constructor() public {}

    function challenge1(uint256 _nftId) public {
        rarity[_nftId] = rarity[_nftId] + 100;
    }
}
