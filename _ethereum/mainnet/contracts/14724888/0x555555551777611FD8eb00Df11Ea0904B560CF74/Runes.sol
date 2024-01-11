// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./Base64.sol";

contract Runes is ERC721 {
    uint256 public constant RUNE_OF_POWER = 1;
    uint256 public constant RUNE_OF_WEALTH = 2;
    uint256 public constant RUNE_OF_TIME = 3;
    uint256 public constant RUNE_OF_SPACE = 4;
    uint256 public constant RUNE_OF_INFLUENCE = 5;

    uint256 public lastPrice;
    uint256 public lastPower;
    uint256 public lastTime;
    uint256 public cooldown = 1 days;
    uint256 public lastBasefee;
    uint256 public lastVotes;

    mapping(address => mapping(uint256 => address)) public nominations;
    mapping(address => uint256) public votes;

    address public creator;

    constructor() ERC721("Rune", "RUNE") {
        _mint(msg.sender, RUNE_OF_POWER);
        _mint(msg.sender, RUNE_OF_WEALTH);
        _mint(msg.sender, RUNE_OF_TIME);
        _mint(msg.sender, RUNE_OF_SPACE);
        _mint(msg.sender, RUNE_OF_INFLUENCE);

        creator = msg.sender;
    }

    function claimRuneOfPower(uint256 nonce) external {
        uint256 power = uint256(
            keccak256(abi.encodePacked(lastPower, nonce, msg.sender))
        );
        require(power > lastPower, "Not powerful enough");
        lastPower = power;

        _transfer(ownerOf(RUNE_OF_POWER), msg.sender, RUNE_OF_POWER);
    }

    function claimRuneOfWealth() external payable {
        require(msg.value > lastPrice, "Insufficient payment");

        address lastClaimer = ownerOf(RUNE_OF_WEALTH);
        uint256 refund = lastPrice;
        uint256 gift = address(this).balance - refund;

        _transfer(lastClaimer, msg.sender, RUNE_OF_WEALTH);
        lastPrice = msg.value;

        bool success = payable(lastClaimer).send(refund);
        if (!success) {
            WETH weth = WETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
            weth.deposit{value: refund}();
            require(weth.transfer(lastClaimer, refund), "Payment failed");
        }

        payable(creator).transfer(gift);
    }

    function claimRuneOfTime() external {
        require(block.timestamp > lastTime + cooldown, "Need to wait");
        lastTime = block.timestamp;
        cooldown = cooldown + cooldown / 10;
        _transfer(ownerOf(RUNE_OF_TIME), msg.sender, RUNE_OF_TIME);
    }

    function claimRuneOfSpace() external {
        require(block.basefee > lastBasefee, "Block space not dense enough");
        lastBasefee = block.basefee;
        _transfer(ownerOf(RUNE_OF_SPACE), msg.sender, RUNE_OF_SPACE);
    }

    function nominate(
        address collection,
        uint256 tokenId,
        address who
    ) external {
        require(tx.origin == msg.sender, "Only humans");
        require(who != address(0), "Address is 0");
        require(
            collection == 0x4D2BB1FDfBdd3e5aC720a4c557117daB75351bfC ||
                collection == 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7 ||
                collection == 0x5180db8F5c931aaE63c74266b211F580155ecac8 ||
                collection == 0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63,
            "Not from this universe"
        );
        require(
            IERC721Ownership(collection).ownerOf(tokenId) == msg.sender,
            "Not authorized"
        );

        address prev = nominations[collection][tokenId];
        if (prev != address(0)) {
            votes[prev] -= 1;
        }

        nominations[collection][tokenId] = who;
        votes[who] += 1;

        if (votes[who] > lastVotes) {
            lastVotes = votes[who];
            _transfer(ownerOf(RUNE_OF_INFLUENCE), who, RUNE_OF_INFLUENCE);
        }
    }

    function tokenURI(uint256 id) public pure override returns (string memory) {
        string[5] memory names = [
            "Power",
            "Wealth",
            "Time",
            "Space",
            "Influence"
        ];
        string[5] memory paths = [
            "m135 99-5 162c0 7 5 12 11 12l7-1c6 0 11-5 11-11l-4-127c0-9 10-14 17-9l32 21c3 2 5 5 5 9l-5 106c0 6 5 11 11 11h8c6 0 11-5 11-11l-5-117c0-4-2-8-6-9a315 315 0 0 1-70-44c-7-6-18-2-18 8Z",
            "M138 117c2 71-1 118-3 139 0 7 5 13 12 13h3c6 0 11-6 11-12l-3-77c0-4 2-7 5-9l62-41c5-4 6-12 2-17l-2-2c-4-4-10-4-15-1-16 12-52 37-52 26v-11c0-4 2-8 6-10 13-7 42-22 42-26 0-6-5-11-9-15-3-3-8-3-12 0-9 7-27 17-27 10V73c0-5-4-9-9-10-5 0-11-1-15 2-7 3 3 34 4 52Z",
            "m162 260-1 1c-5 5-12 4-16 0l-53-60c-4-5-4-11 0-15l44-46c4-4 12-4 16 0l1 1c5 5 4 14-2 18-14 10-37 27-37 37 0 9 30 34 47 47 6 4 6 12 1 17ZM171 202l1 1c5 5 12 4 16 0l46-52c4-4 4-11 0-15l-54-57c-4-5-12-5-16 0l-2 2c-5 5-4 13 1 17 18 13 51 37 51 46 0 8-27 30-42 41-5 4-5 12-1 17Z",
            "M150 246c-3 5-10 6-14 2-5-4-4-12 1-15 11-8 27-20 27-25 0-6-18-21-29-31-6-5-6-13 0-18 11-10 29-25 29-30s-17-17-28-25c-5-4-5-11-1-16 5-4 12-4 16 2 8 10 19 25 24 25s17-15 25-26c4-5 12-5 16-1 4 5 2 12-2 15-12 8-28 20-28 26 0 5 18 20 30 30 5 5 5 13 0 18-12 10-30 27-30 31s16 16 26 23c4 3 5 10 2 14-4 5-12 5-16-1-7-10-18-24-23-24s-17 16-25 26Zm35-58c-5 5-12 5-16 1l-14-14c-4-4-4-10-1-15l13-14c4-4 11-4 16 0l13 15c4 4 4 10 0 15l-11 12Z",
            "M169 145c-7 0-1 65 2 91a10 10 0 1 1-20 1V87c0-9 10-14 17-10l52 34a10 10 0 1 1-12 16l-27-20-1-1c-5-4-13-1-14 6-1 5 0 11 3 14 6 6 32 19 46 26a9 9 0 1 1-10 16c-11-9-29-23-36-23Z"
        ];
        string memory svg = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" style="background:#000">',
            '<path d="',
            paths[id - 1],
            '" fill-rule="evenodd" clip-rule="evenodd" fill="#fff"/>',
            "</svg>"
        );
        string memory json = string.concat(
            '{"name":"Rune of ',
            names[id - 1],
            '","image":"data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '"}'
        );
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(bytes(json))
            );
    }

    function totalSupply() public pure returns (uint256) {
        return 5;
    }
}

interface WETH {
    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);

    function balanceOf(address who) external returns (uint256);
}

interface IERC721Ownership {
    function ownerOf(uint256 tokenId) external returns (address);
}
