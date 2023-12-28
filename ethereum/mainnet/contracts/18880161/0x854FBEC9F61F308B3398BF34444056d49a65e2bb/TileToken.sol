// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

interface EtheriaWrapper {
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function ownerOf(uint tokenId) external view returns (address);
    function transferFrom(address from, address to, uint tokenId) external;
    function setNameViaWrapper(uint8 col, uint8 row, string memory name) external;
}

contract TileToken is ERC20 {

    event TokensMinted(address indexed owner);
    event NameChanged(address indexed namer);
    event TileBought(address indexed buyer);
    event PaymentCollected(address indexed owner, uint indexed balanceSender);

    EtheriaWrapper public ew = EtheriaWrapper(0x629A493A94B611138d4Bee231f94f5C08aB6570A);

    uint8 constant COL = 18;
    uint8 constant ROW = 18;
    uint constant ID = COL * 33 + ROW;
    uint constant MAX_SUPPLY = 1000000;
    uint constant NAME_REQ = MAX_SUPPLY / 10;
    uint constant SECS_PER_MONTH = 2628288;
    uint constant BUYOUT_PRICE = 1e19;

    uint lastNameChange;

    constructor() ERC20("Tile-18-18", "T-18-18") {}

    function getMaxSupply() public pure returns (uint) {
        return MAX_SUPPLY;
    }

    function doesContractOwnTile() public view returns (bool) {
        return ew.ownerOf(ID) == address(this);
    }

    function canTileBeNamed() public view returns (bool) {
        return block.timestamp > lastNameChange + SECS_PER_MONTH;
    }

    function getTokensForNaming() public pure returns (uint) {
        return NAME_REQ;
    }

    function getBuyoutPrice() public pure returns (uint) {
        return BUYOUT_PRICE;
    }

    function mintTokens() external {
        require(ew.ownerOf(ID) == msg.sender, "You don't own the wrapped tile");
        require(ew.isApprovedForAll(msg.sender, address(this)), "Contract not approved for transfers");
        require(totalSupply() == 0, "Tokens already exist");
        
        ew.transferFrom(msg.sender, address(this), ID);
        _mint(msg.sender, MAX_SUPPLY);
        
        emit TokensMinted(msg.sender);
    }

    function setName(string memory name) external {
        require(doesContractOwnTile(), "Contract does not own tile");
        require(canTileBeNamed(), "Not enough time has passed since last name change");
        require(balanceOf(msg.sender) >= NAME_REQ, "You don't have enough tokens to name the tile");

        ew.setNameViaWrapper(COL, ROW, name);
        
        emit NameChanged(msg.sender);
    }

    function buyTile() external payable {
        require(doesContractOwnTile(), "Contract does not own tile");
        require(msg.value == BUYOUT_PRICE, "Incorrect buyout price");

        ew.transferFrom(address(this), msg.sender, ID);

        emit TileBought(msg.sender);
    }

    function collectPayment() external {
        uint balanceOfSender = balanceOf(msg.sender);
        
        require(!doesContractOwnTile(), "Contract still owns tile");
        require(balanceOfSender > 0, "You do not own any tokens");
        
        payable(msg.sender).transfer(BUYOUT_PRICE * balanceOfSender / MAX_SUPPLY);
        _burn(msg.sender, balanceOfSender);

        emit PaymentCollected(msg.sender, balanceOfSender);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }
}