// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./ERC721ABurnable.sol";

contract PEPEMON is ERC721A, ERC721ABurnable, Ownable {

    //Public vars
    uint256 public MAX_SUPPLY = 3300;
    uint256 public packPrice = 0.016 ether;
    uint256 public maxPackPerPublic = 5;
    uint256 public maxPackPerWhitelist = 1;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public hasMintedPublic;
    mapping(address => bool) public hasMintedWhitelist;
    string public uriSuffix = ".json";
    string public baseURI = "";
    bool public publicMintOpened;
    bool public whitelistMintOpened;
    bool public burnEnabled;

    constructor(
    string memory name,
    string memory symbol
  ) ERC721A(name, symbol) Ownable(msg.sender) {
    publicMintOpened = false;
    whitelistMintOpened = false;
    burnEnabled = false;
  }

    function mintPackPublic(uint256 Packs) public payable {
        require(publicMintOpened, "Public mint is not live yet!");
        require(Packs == 1 || Packs == 3 || Packs == 5, "Trying to mint wrong amount of packs");
        require(!hasMintedPublic[msg.sender], "Address has already minted");
        require(msg.value == (Packs * packPrice), "Wrong value");
        require(totalSupply() + (Packs * 10) <= MAX_SUPPLY, "Supply cap reached");
        _mint(msg.sender, Packs * 10);
        hasMintedPublic[msg.sender] = true;
    }

    function mintPackWhitelist(uint256 Packs) public payable{
        require(whitelistMintOpened, "Whitelist mint is not live yet!");
        require(Packs == maxPackPerWhitelist, "Trying to mint too many packs");
        require(!hasMintedWhitelist[msg.sender], "Address has already minted");
        require(whitelist[msg.sender], "Address is not whitelisted");
        require(msg.value == (Packs * packPrice), "Wrong value");
        require(totalSupply() + (Packs * 10) <= MAX_SUPPLY, "Supply cap reached");
        _mint(msg.sender, Packs * 10);
        hasMintedWhitelist[msg.sender] = true;
    }

    function addAddressesToWhitelist(address[] memory addressesToAdd) external onlyOwner {
        for (uint256 i = 0; i < addressesToAdd.length; i++) {
            whitelist[addressesToAdd[i]] = true;
        }
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        whitelist[_address] = false;
    }

    function setPackPrice(uint256 newPrice) public onlyOwner{
        packPrice = newPrice;
    }

    function setPublicMintStatus(bool _state) public onlyOwner {
        publicMintOpened = _state;
    }

    function setWhitelistMintStatus(bool _state) public onlyOwner {
        whitelistMintOpened = _state;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
          baseURI = newBaseURI;
    }

    function toggleBurn(bool _enabled) external onlyOwner {
        burnEnabled = _enabled;
    }

    function burnPepe(uint256 tokenId) external {
        require(burnEnabled, "Burn feature is not enabled");
        burn(tokenId);
    }

    function adminMint(uint256 Packs) external onlyOwner{
        require(totalSupply() + (Packs * 10) <= MAX_SUPPLY, "Supply cap reached");
        _mint(msg.sender, Packs * 10);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), uriSuffix)) : '';
    }

    function withdraw(address dev, address owner) public onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");

        uint256 totalBalance = address(this).balance;

        uint256 amountToBeneficiary1 = (totalBalance * 75) / 100;
        uint256 amountToBeneficiary2 = (totalBalance * 25) / 100;

        (bool success1, ) = dev.call{value: amountToBeneficiary2}("");
        (bool success2, ) = owner.call{value: amountToBeneficiary1}("");

        require(success1 && success2, "Withdraw failed");
    }
}
