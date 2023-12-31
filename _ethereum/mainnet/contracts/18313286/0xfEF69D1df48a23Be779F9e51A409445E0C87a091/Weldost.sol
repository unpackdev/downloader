// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./Strings.sol";

contract Weldost is ERC1155, Ownable {
    using Strings for uint256;

    string public constant name = "Weldost";
    string public constant symbol = "WLD";

    string public baseURI;
    mapping(uint256 => TokenID) public tokenIds;
    uint120 public currentTokenSupply;
    bool public isSaleEnabled;

    struct TokenID {
        uint256 price;
        uint128 maxSupply;
        uint128 totalSupply;
    }

    constructor() ERC1155("") {
        TokenID storage starter = tokenIds[0];
        starter.maxSupply = 500;
        starter.price = 0.063 ether;

        TokenID storage bronze = tokenIds[1];
        bronze.maxSupply = 400;
        bronze.price = 0.31 ether;

        TokenID storage silver = tokenIds[2];
        silver.maxSupply = 300;
        silver.price = 0.63 ether;

        TokenID storage gold = tokenIds[3];
        gold.maxSupply = 200;
        gold.price = 0.94 ether;

        TokenID storage diamond = tokenIds[4];
        diamond.maxSupply = 100;
        diamond.price = 1.57 ether;

        TokenID storage elite = tokenIds[5];
        elite.maxSupply = 50;
        elite.price = 3.13 ether;

        currentTokenSupply = 6;
    }

    function mint(uint256 id, uint128 quantity) public payable {
        require(isSaleEnabled, "Sale is disabled");
        require(tx.origin == _msgSender(), "Contracts are prohibited");
        TokenID storage token = tokenIds[id];
        require(
            token.totalSupply + quantity <= token.maxSupply,
            "Max supply exceeded"
        );
        require(msg.value >= token.price * quantity, "Insufficient ETH");
        token.totalSupply += quantity;
        _mint(msg.sender, id, quantity, "");
    }

    function addToken(uint248 price, uint128 maxSupply) public onlyOwner {
        TokenID storage newToken = tokenIds[currentTokenSupply];
        newToken.price = price;
        newToken.maxSupply = maxSupply;
        currentTokenSupply++;
    }

    function editToken(
        uint256 id,
        uint248 price,
        uint128 maxSupply
    ) external onlyOwner {
        TokenID storage token = tokenIds[id];
        require(
            token.totalSupply <= maxSupply,
            "Cannot set max supply lower than current supply"
        );
        token.price = price;
        token.maxSupply = maxSupply;
    }

    function airdrop(
        address receiver,
        uint256 tokenId,
        uint128 amount
    ) external onlyOwner {
        TokenID storage token = tokenIds[tokenId];
        require(
            token.totalSupply + amount <= token.maxSupply,
            "Max supply exceeded"
        );
        token.totalSupply += amount;
        _mint(receiver, tokenId, amount, "");
    }

    function flipSaleState() external onlyOwner {
        isSaleEnabled = !isSaleEnabled;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function totalBalanceOf(
        address account
    ) public view returns (uint256[] memory balaces) {
        uint[] memory balances = new uint[](currentTokenSupply);
        for (uint i = 0; i < currentTokenSupply; i++) {
            balances[i] = (balanceOf(account, i));
        }
        return balances;
    }

    function uri(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(tokenId < currentTokenSupply, "Non existent token");
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Nothing to release");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    receive() external payable {}
}
