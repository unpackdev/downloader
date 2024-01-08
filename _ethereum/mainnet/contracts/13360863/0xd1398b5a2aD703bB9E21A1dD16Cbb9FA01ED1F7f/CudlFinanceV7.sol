//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC721HolderUpgradeable.sol";

import "./Initializable.sol";

// Interface for our erc20 token
interface IToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

contract CudlFinanceV7 is
    Initializable,
    ERC721HolderUpgradeable,
    OwnableUpgradeable
{
    address public mooncats;
    address public PONDERWARE;
    address public MUSE_DAO;
    address public MUSE_DEVS;

    uint256 public gas; // if gas higher then this you can't kill
    uint256 public lastGas; //here we record last gas paid, to keep track of chain gas. If gas is high, no pets can die.

    IToken public token;

    struct Pet {
        address nft;
        uint256 id;
    }

    mapping(address => bool) public supportedNfts;
    mapping(uint256 => Pet) public petDetails;

    // mining tokens
    mapping(uint256 => uint256) public lastTimeMined;

    // Pet properties
    mapping(uint256 => uint256) public timeUntilStarving;
    mapping(uint256 => uint256) public petScore;
    mapping(uint256 => bool) public petDead;
    mapping(uint256 => uint256) public timePetBorn;

    // items/benefits for the PET could be anything in the future.
    mapping(uint256 => uint256) public itemPrice;
    mapping(uint256 => uint256) public itemPoints;
    mapping(uint256 => string) public itemName;
    mapping(uint256 => uint256) public itemTimeExtension;

    mapping(uint256 => mapping(address => address)) public careTaker;

    mapping(address => mapping(uint256 => bool)) public isNftInTheGame; //keeps track if nft already played
    mapping(address => mapping(uint256 => uint256)) public nftToId; //keeps track if nft already played

    uint256 public feesEarned;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;
    CountersUpgradeable.Counter private _itemIds;

    event Mined(uint256 nftId, uint256 reward, address recipient);
    event BuyAccessory(
        uint256 nftId,
        uint256 itemId,
        uint256 amount,
        uint256 itemTimeExtension,
        address buyer
    );
    event Fatalize(uint256 opponentId, uint256 nftId, address killer);
    event NewPlayer(
        address nftAddress,
        uint256 nftId,
        uint256 playerId,
        address owner
    );
    event Bonk(
        uint256 attacker,
        uint256 victim,
        uint256 winner,
        uint256 reward
    );

    // Rewards algorithm

    uint256 public la;
    uint256 public lb;
    uint256 public ra;
    uint256 public rb;

    address public lastBonker;

    // NEW STORE v2

    mapping(uint256 => uint256) public spent;
    mapping(address => uint256) public balance;
    mapping(address => bool) public isOperator;

    constructor() {}

    function claimCudlDeposited() external {
        uint256 amount = balance[msg.sender];
        balance[msg.sender] = 0;

        if (amount > 0) token.mint(msg.sender, amount);
    }
}
