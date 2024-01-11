// SPDX-License-Identifier: Unlicensed

/*
   ________              __            __  _______
  / ____/ /_  ___  ___  / /____  __   /  |/  / __/__  __________
 / /   / __ \/ _ \/ _ \/ //_/ / / /  / /|_/ / /_/ _ \/ ___/ ___/
/ /___/ / / /  __/  __/ ,< / /_/ /  / /  / / __/  __/ /  (__  )
\____/_/ /_/\___/\___/_/|_|\__, /  /_/  /_/_/  \___/_/  /____/
                          /____/

Coded by Vethalik

*/

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract CheekyMfers is ERC721, ERC721Enumerable, Ownable {
    address payable public shareholderAddress;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_MINT_PER_TX = 10;
    uint256 public constant MINT_PRICE = 0.05 ether;

    string private _baseURIextended = "ipfs://CHANGE_ME/";

    bool public saleIsActive = false;


    constructor() ERC721("CheekyMfers", "CMFERS") {
        setShareholderAddress(payable(msg.sender));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function batchMint(address recipient, uint256 amount) private {
        uint256 mintIndex = totalSupply() + 1;

        unchecked {
            for (uint256 i = 0; i < amount; i++) {
                _safeMint(recipient, mintIndex);
                mintIndex++;
            }
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve() external onlyOwner {
      batchMint(msg.sender, 150);
    }

    function mint(uint numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= MAX_MINT_PER_TX, "Exceeded max token purchase");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max supply of tokens");
        require(MINT_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");

        batchMint(msg.sender, numberOfTokens);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(
            abi.encodePacked(
                _baseURI(),
                Strings.toString(tokenId),
                ".json"
            )
        );
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function setSaleState(bool newState) external onlyOwner {
        saleIsActive = newState;
    }

    function setShareholderAddress(address payable newShareholderAddress) public onlyOwner {
        require(newShareholderAddress != address(0), "You need to provide a shareholder Address");
        shareholderAddress = newShareholderAddress;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(shareholderAddress, balance);
    }
}