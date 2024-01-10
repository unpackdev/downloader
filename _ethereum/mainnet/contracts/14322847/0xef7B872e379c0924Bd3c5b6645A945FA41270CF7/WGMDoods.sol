// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//  __     __     ______     __    __     _____     ______     ______     _____     ______
// /\ \  _ \ \   /\  ___\   /\ "-./  \   /\  __-.  /\  __ \   /\  __ \   /\  __-.  /\  ___\
// \ \ \/ ".\ \  \ \ \__ \  \ \ \-./\ \  \ \ \/\ \ \ \ \/\ \  \ \ \/\ \  \ \ \/\ \ \ \___  \
//  \ \__/".~\_\  \ \_____\  \ \_\ \ \_\  \ \____-  \ \_____\  \ \_____\  \ \____-  \/\_____\
//   \/_/   \/_/   \/_____/   \/_/  \/_/   \/____/   \/_____/   \/_____/   \/____/   \/_____/

import "./ERC721A.sol";
import "./Ownable.sol";

contract WGMDoods is Ownable, ERC721A {
    uint256 public constant SUPPLY = 4040;
    uint256 public constant ALLOWED_PER_TX = 20;
    uint256 public constant FREE_PER_WALLET = 2;
    uint256 private constant AMOUNT_FOR_DEVS = 20;

    uint256 public tokenPrice = 0.01 ether;
    uint256 public freeMintsRemaining = 100;

    address private constant TEAM_ADDRESS_1 =
        0x536041f204685A477965d79a2c14ec99acA0126F;
    address private constant TEAM_ADDRESS_2 =
        0xA377F8aC970410FC3A74F528EE1Bd21b7bE85bf3;
    address private constant DEV_ADDRESS =
        0xbbF8c66D737DFCeeeeDfE9d42740B511E5f765d1;

    bool public isPublic = false;

    constructor() ERC721A("WGMDoods", "WGMDOOD") {}

    modifier isNotContract() {
        require(tx.origin == msg.sender, "No contracts");
        _;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function toggleSale() external onlyOwner {
        isPublic = !isPublic;
    }

    function mint(uint256 amount) external payable isNotContract {
        require(isPublic, "Not public");
        require(amount <= ALLOWED_PER_TX, "Don't be greedy!");
        require(totalSupply() + amount <= SUPPLY, "Exceeds supply");
        require(tokenPrice * amount <= msg.value, "Incorrect ether value");
        _safeMint(msg.sender, amount);
    }

    function mintFree(uint256 amount) external payable isNotContract {
        require(isPublic, "Not public");
        require(amount <= freeMintsRemaining, "Not enough free mints remain");
        require(freeMintsRemaining >= 0, "No longer free");
        require(totalSupply() + amount <= SUPPLY, "Exceeds supply");

        uint64 freeMinted = _getAux(msg.sender);
        require(freeMinted + amount <= FREE_PER_WALLET, "Exceeds free allowed");

        freeMintsRemaining -= amount;
        _setAux(msg.sender, uint64(amount));
        _safeMint(msg.sender, amount);
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= AMOUNT_FOR_DEVS, "Exceeds supply");
        _safeMint(msg.sender, quantity);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient balance");

        _withdraw(DEV_ADDRESS, ((balance * 120) / 1000));
        _withdraw(TEAM_ADDRESS_2, ((balance * 375) / 1000));
        _withdraw(TEAM_ADDRESS_1, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to widthdraw");
    }
}
