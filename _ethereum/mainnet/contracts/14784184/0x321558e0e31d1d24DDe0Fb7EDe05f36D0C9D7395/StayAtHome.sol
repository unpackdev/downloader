// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

contract StayAtHome is ERC721A, Ownable, AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public constant MAX_SUPPLY = 100 * 31;
    uint256 public constant PRICE = 1 ether;
    // 2022-5-20 10:00:00+08:00
    uint256 public constant START_TIMESTAMP = 1653012000;
    // 2022-6-19 12:00:00+08:00
    uint256 public constant TRANSFERABLE_TIMESTAMP = 1655611200;

    string public baseURI = "https://stayathome-6tapimffyq-de.a.run.app/";

    address public roalityAccount = address(0x3A5e5695Bf61a3ac33C3231b6ABE2ec00aD870b0);
    uint256 public roality = 25;

    constructor() ERC721A("Stay at Home", "STAYATHOME") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, address(0x3A5e5695Bf61a3ac33C3231b6ABE2ec00aD870b0));
    }

    function setRoalityAccount(address _roalityAccount) external onlyRole(ADMIN_ROLE) {
        roalityAccount = _roalityAccount;
    }

    function setRoality(uint256 _roality) external onlyRole(ADMIN_ROLE) {
        roality = _roality;
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
        return super.supportsInterface(interfaceId);
    }
}
