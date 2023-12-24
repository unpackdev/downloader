// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IMoonboyzToken.sol";
import "./IMoonboyzNFT.sol";

import "./UUPSUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

contract MoonboyzUtilities is UUPSUpgradeable, AccessControlUpgradeable {
    IMoonboyzToken public mbz;
    IMoonboyzNFT public moonboyz;

    bytes32 public OPERATOR_ROLE;

    uint256 public mergeSupplyLimit;
    uint256 public mergeReward;
    address public burnAddress; 

    bool public lootboxesActive;

    mapping(uint256 => bool) public isLootbox;

    event Merge(uint256 indexed source, uint256 indexed destination, address indexed merger, bytes32 attributesString);
    event CreateLootbox(uint256 indexed index);
    event BuyLootbox(uint256 indexed lootboxId, uint256 amount, address indexed buyer, uint256 price, bool indexed isHolder);

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not owner");
        _;
    }

    constructor() {}

    function initialize(
        address _mbz,
        address _moonboyz,
        address[] memory _operators
    ) public initializer {
        __AccessControl_init();

        mbz = IMoonboyzToken(_mbz);
        moonboyz = IMoonboyzNFT(_moonboyz);

        OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        for (uint256 i = 0; i < _operators.length; i++) {
            _grantRole(OPERATOR_ROLE, _operators[i]);
        }

        mergeSupplyLimit = 10_000;
        mergeReward = 3650 ether;
        burnAddress = 0x000000000000000000000000000000000000dEaD;
    }

    receive() external payable {}

    function merge(uint256 source, uint256 destination, bytes32 attributesString) external {
        require(_realSupply() > mergeSupplyLimit, "Target supply reached");
        require(!mbz.isDivine(source), "Source is divine");
        require(!mbz.isDivine(destination), "Destination is divine");
        require(source != destination, "Source and destination are the same");

        require(moonboyz.ownerOf(source) == msg.sender, "Source NFT not owned");
        require(moonboyz.ownerOf(destination) == msg.sender, "Destination NFT not owned");

        moonboyz.transferFrom(msg.sender, burnAddress, source);
        mbz.mint(msg.sender, mergeReward);

        emit Merge(source, destination, msg.sender, attributesString);
    }
   
    function buyLootbox(
        uint256 lootboxId, 
        uint256 amount,
        uint256 price
    ) external {
        require(isLootbox[lootboxId], "Invalid lootbox");
        bool isHolder = moonboyz.balanceOf(msg.sender) > 0;
        mbz.transferFrom(msg.sender, address(this), price * amount);
        emit BuyLootbox(lootboxId, amount, msg.sender, price, isHolder);
    }

    function tradingEnabled(address from, address to, uint256 amount) external view returns (bool) {
        return !lootboxesActive;
    }

    function addLootbox(
        uint256 lootboxId
    ) external onlyRole(OPERATOR_ROLE) {
        require(!isLootbox[lootboxId], "Lootbox already registered");
        isLootbox[lootboxId] = true;
        emit CreateLootbox(lootboxId);
    }

    function setLootboxesActive(
        bool active
    ) external onlyRole(OPERATOR_ROLE) {
        lootboxesActive = active;
    }

    function _realSupply() internal view returns (uint256) {
        return moonboyz.totalSupply() - moonboyz.balanceOf(burnAddress);
    }

     // @dev required for UUPSUpgradeable
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
