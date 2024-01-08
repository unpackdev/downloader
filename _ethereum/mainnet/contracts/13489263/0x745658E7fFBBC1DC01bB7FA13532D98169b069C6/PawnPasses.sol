// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Address.sol";

import "./ERC1151Burnable.sol";

contract PawnPasses is ERC1155, ERC1155Burnable, Ownable {
    using Address for address;

    uint constant SILVER_TOKEN_ID = 0;
    uint constant GOLDEN_TOKEN_ID = 1;

    uint[] public TOKEN_IDS = [0, 1];
    uint[] public MAX_SUPPLIES = [100, 50];
    uint[] public PRICES = [0.03 ether, 0.075 ether];

    uint[] public tokensMinted = [0, 0];
    uint[] public tokensBurned = [0, 0];

    uint public mintingStartTimestamp;
    uint public maxMintsPerTransaction;
    address public burner;

    constructor() ERC1155("https://storage.googleapis.com/pawnbears/token_meta/{id}") {
        mintingStartTimestamp = 1635202800;
        maxMintsPerTransaction = 10;
        _mint(msg.sender, SILVER_TOKEN_ID, 1, "");
    }

    // setters region
    function setURI(string memory uri) external onlyOwner {
        _setURI(uri);
    }

    function setMintingStartTimestamp(uint _mintingStartTimestamp) external onlyOwner {
        mintingStartTimestamp = _mintingStartTimestamp;
    }

    function setMaxMintsPerTransaction(uint _maxMintsPerTransaction) external onlyOwner {
        maxMintsPerTransaction = _maxMintsPerTransaction;
    }

    function setBurner(address _burner) external onlyOwner {
        burner = _burner;
    }


    function configure(
        uint _mintingStartTimestamp,
        uint _maxMintsPerTransaction,
        address _burner
    ) external onlyOwner {
        mintingStartTimestamp = _mintingStartTimestamp;
        maxMintsPerTransaction = _maxMintsPerTransaction;
        burner = _burner;
    }
    // endregion


    // mint region
    function mintSilver(uint amount) external payable {
        mint(SILVER_TOKEN_ID, amount);
    }

    function mintGolden(uint amount) external payable {
        mint(GOLDEN_TOKEN_ID, amount);
    }

    function mint(uint tokenId, uint amount) internal {
        require(block.timestamp >= mintingStartTimestamp, "Minting is not available");
        require(tokensMinted[tokenId] + amount <= MAX_SUPPLIES[tokenId], "Token supply is out");
        require(amount > 0 && amount <= maxMintsPerTransaction, "Can't mint such amount of tokens");
        require(PRICES[tokenId] * amount == msg.value, "Wrong ethers value");
        require(!msg.sender.isContract(), "Minting with contract is not allowed");

        tokensMinted[tokenId] += amount;
        _mint(msg.sender, tokenId, 1, "");
    }

    function airdrop(address[] memory addresses, uint tokenId, uint[] memory amounts) external onlyOwner {
        require(amounts.length == addresses.length, "amounts.length != addresses.length");
        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i], tokenId, amounts[i], "");
        }
    }
    // endregion

    // let burn tokens for specific address
    function burn(address account, uint tokenId, uint amount) override external {
        require(msg.sender == burner, "Burning is not allowed for your address");
        require(tokenId < 2, "Wring tokenId");
        tokensBurned[tokenId] += amount;
        _burn(account, tokenId, amount);
    }
    //

    // provide supply getters
    function tokenSupply(uint tokenId) public view returns (uint) {
        if (tokenId < 2) {
            return tokensMinted[tokenId] - tokensBurned[tokenId];
        }
        return 0;
    }

    function silverTokensSupply() public view returns (uint) {
        return tokensMinted[SILVER_TOKEN_ID] - tokensBurned[SILVER_TOKEN_ID];
    }

    function goldenTokensSupply() public view returns (uint) {
        return tokensMinted[GOLDEN_TOKEN_ID] - tokensBurned[GOLDEN_TOKEN_ID];
    }
    // endregion


    receive() external payable {

    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(0xFbf496400645476fc92900a32c505B1Cc2Ec9222).transfer(balance * 15 / 100);
        payable(0x1d36262D0e6C665c98587c1Ae023E008d6381Da7).transfer(balance * 85 / 100);
    }
}