// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC20Mintable.sol";
import "./ShipsHelper.sol";

// The ships
// **music**
// Sweet dreams are made of this
// Who am I to disagree
// I travel the world and the seven seas :pepe jamming:
// (fr tho, when r twitch emotes gunna be added to sol natspec standard... fukin boomers man)
// @author 1929

contract Ships is ERC721, ERC721Enumerable, Ownable {
    struct Attributes {
        uint8 name;
        uint8 expedition;
        uint32 length;
        uint32 speed;
    }

    struct Path {
        address tokenContract;
        uint256 tokenId;
    }

    struct Ship {
        uint256 tokenId;
        string name;
        string expedition;
        uint32 length;
        uint32 speed;
        Path[] route;
    }

    struct TokenHarvest {
        address resourceTokenContract;
        uint256 amount;
    }

    string[] public names = ["Canoe", "Longship", "Clipper", "Galleon", "Man-of-war"];
    string[] public expeditions = ["Trader", "Explorer", "Pirate", "Military", "Diplomat"];

    uint32[] public speedMultipliers = [10, 20, 50, 40, 40];
    uint32[] public lengthMultipliers = [5, 10, 10, 30, 40];

    ShipsHelper public helperContract;
    ERC20Mintable public goldTokenContract;

    mapping(uint256 => Attributes) public tokenIdToAttributes;
    mapping(uint256 => Path[]) public tokenIdToRoute;
    mapping(uint256 => uint256) public tokenIdToLastRouteUpdate;

    uint256 purchasedShipsCount = 1000;
    uint256 maxPurchaseLimit = 10_000;

    mapping(address => bool) permissionedMinters;

    constructor(ERC20Mintable goldTokenContract_) ERC721("Ships", "SHIP") {
        goldTokenContract = goldTokenContract_;
    }

    /** Setters */
    function setHelperContract(ShipsHelper helperContract_) public onlyOwner {
        helperContract = helperContract_;
    }

    function setMaxPurchaseLimit(uint256 maxPurchaseLimit_) public onlyOwner {
        maxPurchaseLimit = maxPurchaseLimit_;
    }

    // For L1 -> L2 bridges
    // This allows NFTs to be minted on the L2 and then bridged to the L1 as oppose
    // to just being minted on the L1 and transferred to the L2.
    function togglePermissionedMinter(address minter, bool enabled) public onlyOwner {
        permissionedMinters[minter] = enabled;
    }

    /** Getters */
    function getShipInfo(uint256 tokenId) public view returns (Ship memory) {
        require(_exists(tokenId), "Ship with that tokenId doesn't exist");

        Attributes memory attr = tokenIdToAttributes[tokenId];

        return
            Ship({
                tokenId: tokenId,
                name: names[attr.name],
                expedition: expeditions[attr.expedition],
                length: attr.length,
                speed: attr.speed,
                route: tokenIdToRoute[tokenId]
            });
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return helperContract.tokenURI(tokenId);
    }

    function getTokenIdToAttributes(uint256 tokenId) public view returns (Attributes memory) {
        return tokenIdToAttributes[tokenId];
    }

    function getRandomNumber(bytes memory seed, uint256 maxValue) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(seed))) % maxValue;
    }

    function getUnharvestedTokens(uint256 tokenId) public view returns (TokenHarvest[] memory) {
        return helperContract.getUnharvestedTokens(tokenId);
    }

    function getSailingDuration(uint256 tokenId) public view returns (uint256) {
        Ship memory shipInfo = getShipInfo(tokenId);
        return helperContract.getSailingDuration(shipInfo);
    }

    /** State modifications */
    function mint(uint256 tokenId) public {
        require(!_exists(tokenId), "Ship with that id already exists");
        require(tokenId <= 999, "Ship id is invalid");

        uint256 value = getRandomNumber(abi.encode(tokenId, "n", block.timestamp), 1000);
        uint8 name = uint8(value < 900 ? value % 3 : value < 950 ? value % 4 : value % 5);

        _mintShip(name, tokenId);
    }

    // Intended for use by L2->L1 bridges
    // This is necessary since we want to allow minting on both L2 and L1.
    // In order to maintain synchronicity between both chains, the L2 withdrawal tx
    // must be able to mint new tokens on L1 if it doesn't already exist in escrow.
    function permissionedMint(
        uint256 tokenId,
        Attributes memory attr,
        Path[] memory route
    ) public {
        require(permissionedMinters[msg.sender], "You are not a permissioned minter");
        require(!_exists(tokenId), "Can't mint token that already exists");

        tokenIdToAttributes[tokenId] = attr;
        _updateRoute(route, tokenId, true);
        _safeMint(msg.sender, tokenId);
    }

    function harvest(uint256 tokenId) public {
        TokenHarvest[] memory unharvestedTokens = getUnharvestedTokens(tokenId);
        tokenIdToLastRouteUpdate[tokenId] = block.number;

        uint256 totalGoldTax = 0;
        for (uint256 i = 0; i < unharvestedTokens.length; i++) {
            ERC20Mintable(unharvestedTokens[i].resourceTokenContract).mint(
                ownerOf(tokenId),
                unharvestedTokens[i].amount
            );

            // 6% tax to the originating settlement
            totalGoldTax += (unharvestedTokens[i].amount * 6) / 100;
        }

        address taxDestination = helperContract.getTaxDestination(tokenId);
        goldTokenContract.mint(taxDestination, totalGoldTax);
    }

    function updateRoute(Path[] memory route, uint256 tokenId) public {
        _updateRoute(route, tokenId, false);
    }

    function _updateRoute(
        Path[] memory route,
        uint256 tokenId,
        bool init
    ) internal {
        require(helperContract.isValidRoute(route, tokenId, msg.sender, init), "Invalid route");

        delete tokenIdToRoute[tokenId];
        for (uint256 i = 0; i < route.length; i++) {
            tokenIdToRoute[tokenId].push(route[i]);
        }

        tokenIdToLastRouteUpdate[tokenId] = block.number;
    }

    function purchaseShip(uint8 name) public {
        require(
            purchasedShipsCount <= maxPurchaseLimit,
            "Maximum amount of ships have been purchased"
        );

        TokenHarvest[] memory cost = helperContract.getCost(name);
        for (uint256 i = 0; i < cost.length; i++) {
            ERC20Mintable(cost[i].resourceTokenContract).burnFrom(msg.sender, cost[i].amount);
        }

        purchasedShipsCount += 1;
        _mintShip(name, purchasedShipsCount);
    }

    function _mintShip(uint8 name, uint256 tokenId) internal {
        Attributes memory attr;

        attr.name = name;

        uint256 value = getRandomNumber(abi.encode(tokenId, "c"), 1000);
        attr.expedition = uint8(value % 5);

        value = getRandomNumber(abi.encode(tokenId, "l"), 50);
        attr.length = uint32((value + 1) * uint256(lengthMultipliers[attr.name])) / 10 + 2;
        attr.length = attr.length < lengthMultipliers[attr.name]
            ? lengthMultipliers[attr.name]
            : attr.length;

        value = getRandomNumber(abi.encode(tokenId, "s"), 100);
        attr.speed = uint32((value + 1) * uint256(speedMultipliers[attr.name])) / 100 + 2;
        attr.speed = attr.speed < speedMultipliers[attr.name] / 2
            ? speedMultipliers[attr.name] / 2
            : attr.speed;

        tokenIdToAttributes[tokenId] = attr;

        _updateRoute(helperContract.getInitialRoute(tokenId, attr.name), tokenId, true);
        _safeMint(msg.sender, tokenId);
    }

    /** Library overrides */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
