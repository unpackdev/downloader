// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/*
    Voodoo Vault / 2022 / V10k.1
*/
import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./IERC1155.sol";
import "./ERC1155Burnable.sol";

contract VoodooVaultBrokenPass is ERC1155Burnable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 private supply;

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant mintPrice = 0.038 ether;
    uint256 public constant VV_PER_MINT = 10;
    uint256 public constant tokenIdToMint = 0;
    uint256 public constant VV_COMMUNITY_VAULT = 100;

    string public constant NAME = "VOODOO VAULT BROKEN PASS";
    string public constant SYMBOL = "VVBRKN";
    string private baseURI;

    address private VOODOO_VAULT = 0x0B42487db1c12f4cA02E399dcfb9A5B013F36914;
    address private ARTIST_VAULT = 0xD9861771C138d57f74A14eD066c9D9d435DF4B5D;

    bool public saleLive = false;
    bool public locked = false;

    constructor(
        string memory _baseURI
    ) ERC1155(_baseURI) {
        baseURI = _baseURI;
    }

    modifier notLocked {
        require(!locked, "Contract metadata is locked");
        _;
    }

    function mintCommunity() external onlyOwner {
        require(supply + VV_COMMUNITY_VAULT <= MAX_SUPPLY, "MAX_MINT_ACHIEVED");

        supply += VV_COMMUNITY_VAULT;

        _mint(msg.sender, tokenIdToMint, VV_COMMUNITY_VAULT, "");
    }

    function buy(uint256 tokenQuantity) external payable {
        require(saleLive, "SALE CLOSED");
        require(tokenQuantity > 0 && tokenQuantity <= VV_PER_MINT, "MINT AT LEAST 1 AND NOT MORE THAN 10 TOKENS");
        require(supply + tokenQuantity <= MAX_SUPPLY, "MAX_MINT_ACHIEVED");
        require(mintPrice * tokenQuantity == msg.value, "INCORRECT PAYMENT AMOUNT ");

        supply += tokenQuantity;

        _mint(msg.sender, tokenIdToMint, tokenQuantity, "");
    }

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(bytes(baseURI).length > 0, "BASE URI NOT SET");
        require(id == 0, "URI: nonexistent token");
        return string(abi.encodePacked(baseURI, Strings.toString(id)));
    }

    function totalSupply() public view returns (uint256) {
        return supply;
    }

    //functions allowed only for OWNER
    function withdraw() external onlyOwner {
        uint _balance = address(this).balance;
        payable(ARTIST_VAULT).transfer(_balance * 17/100);
        payable(VOODOO_VAULT).transfer(_balance * 83/100);
    }

    function setBaseUri(string calldata _baseURI) external onlyOwner notLocked{
        baseURI = _baseURI;
    }

    function lockMetadata() external onlyOwner {
        locked = true;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }
}
