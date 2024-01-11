// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

interface IRoality {
    function roalityAccount() external view returns (address);

    function roality() external view returns (uint256);

    function setRoalityAccount(address) external;

    function setRoality(uint256) external;
}

contract StayAtHome is ERC721A, Ownable, AccessControl, ReentrancyGuard, IRoality {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public constant MAX_SUPPLY = 100 * 31;
    uint256 public constant PRICE = 1 ether;
    // 2022-5-20 10:00:00+08:00
    uint256 public constant START_TIMESTAMP = 1653012000;
    // 2022-6-19 12:00:00+08:00
    uint256 public constant TRANSFERABLE_TIMESTAMP = 1655611200;

    string public baseURI = "https://stayathome-6tapimffyq-de.a.run.app/";

    address public override roalityAccount = address(0x3A5e5695Bf61a3ac33C3231b6ABE2ec00aD870b0);
    uint256 public override roality = 50;

    constructor() ERC721A("Stay at Home", "STAYATHOME") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, address(0x3A5e5695Bf61a3ac33C3231b6ABE2ec00aD870b0));
    }

    function setRoalityAccount(address _roalityAccount) external override onlyRole(ADMIN_ROLE) {
        roalityAccount = _roalityAccount;
    }

    function setRoality(uint256 _roality) external override onlyRole(ADMIN_ROLE) {
        roality = _roality;
    }

    function airDrop() external onlyRole(ADMIN_ROLE) {
        _safeMint(address(0x3FF0b65b06Aee4DAd91B0109638678AbA5588d6E), 31);
        _safeMint(address(0xF978C2A676D2836EE516922572533abC20817481), 31);
        _safeMint(address(0xa4273276e0bbb5fa2738A5dbCA629C461EeC186E), 31);
        _safeMint(address(0x5B3F6082A00BE13402927767FBb1c7C68C5C6635), 31);
        _safeMint(address(0x564B6b9b3BB13EA978D54ab161FcFBB522093046), 31);
        _safeMint(address(0xca9CEe83a566E922686CA9e14Ca8cDAC8Ac783F4), 31);
        _safeMint(address(0xf13898ce2d5A51AA445Cfc96aF5c3778C2149B54), 31);
        _safeMint(address(0x5076fB7509E7FDC58405078918d76C5a41F80A56), 31);
        _safeMint(address(0x84079A003B3c725ba718f233CC8980907e79bCEF), 31);
        _safeMint(address(0xEa9F95E7c64BF7c04eB5BDd349de9A8aC98a88DA), 31);
        _safeMint(address(0x3FeA9477d0Ea723047869f1d02Dc6586356b7AE8), 31);
        _safeMint(address(0x0212A2f59b756847c4aCAFa1eC051B66c9B089E4), 31);
        _safeMint(address(0xe8856B1ded713dA51985A490c8db556D8c7D02B5), 31);
    }

    function adminMint(address to, uint256 quantity) external onlyRole(ADMIN_ROLE) {
        _safeMint(to, quantity * 31);
    }

    function withdraw() external onlyRole(ADMIN_ROLE) nonReentrant {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function setBaseURI(string memory newBaseURI) external onlyRole(ADMIN_ROLE) {
        baseURI = newBaseURI;
    }

    function mint(address to, uint256 quantity) external payable nonReentrant {
        require(block.timestamp >= START_TIMESTAMP, "START_TIMESTAMP");
        require(quantity <= 2, "quantity > 2");
        require(tx.origin == msg.sender, "!EOA");
        require(totalSupply() + quantity * 31 <= MAX_SUPPLY, "MAX_SUPPLY");
        require(msg.value >= quantity * PRICE, "PRICE");

        // _safeMint(to, quantity * 31);
        // Save transfer gas fee.
        for (uint256 i; i < quantity; i++) {
            _safeMint(to, 31);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        require(
            from == address(0) || from == owner() || block.timestamp >= TRANSFERABLE_TIMESTAMP,
            "TRANSFERABLE_TIMESTAMP"
        );
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControl) returns (bool) {
        return interfaceId == type(IRoality).interfaceId || super.supportsInterface(interfaceId);
    }
}
