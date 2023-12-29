// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./IERC721A.sol";

contract PepemonEvoLotion is ERC721A, Ownable {
    //Public vars
    IERC721A private pepemonContract;
    IERC721A private holoContract;
    uint256 public constant MAX_SUPPLY = 2100;
    uint256 public packPrice = 0.022 ether;
    uint256 public constant maxPackPerPublic = 5;
    uint256 public constant cardsForPackage = 5;
    uint256 public constant maxPackPerWhitelist = 5;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public hasMintedPublic;
    mapping(address => bool) public hasMintedWhitelist;
    string public constant uriSuffix = ".json";
    string public baseURI = "https://bafybeihdpojpvynkrb5hypgma74wumac7woxqaem7l6j3zo7dyl557pxc4.ipfs.nftstorage.link/";
    bool public publicMintOpened;
    bool public whitelistMintOpened;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) Ownable(msg.sender) {
        publicMintOpened = false;
        whitelistMintOpened = false;
        pepemonContract = IERC721A(0x8dd23D86C4F85335e124949152fCc23312B0e927);
        holoContract = IERC721A(0x3f35e2518cb1DF66d924CF08b5B94A73e84882ac);
    }

    function mintPackPublic(uint256 packs) public payable {
        require(publicMintOpened, "Public mint is not live yet!");
        require(
            packs == 1 || packs == 3 || packs == 5,
            "Trying to mint wrong amount of packs"
        );
        require(!hasMintedPublic[msg.sender], "Address has already minted");
        require(msg.value == (packs * packPrice), "Wrong value");
        require(
            totalSupply() + (packs * cardsForPackage) <= MAX_SUPPLY,
            "Supply cap reached"
        );
        _mint(msg.sender, packs * cardsForPackage);
        hasMintedPublic[msg.sender] = true;
    }

    function mintPackWhitelist(uint256 packs) public payable {
        require(whitelistMintOpened, "Whitelist mint is not live yet!");
        require(
            packs == 1 || packs == 3 || packs == 5,
            "Trying to mint wrong amount of packs"
        );
        require(!hasMintedWhitelist[msg.sender], "Address has already minted");
        require(
            pepemonContract.balanceOf(msg.sender) > 0 ||
                holoContract.balanceOf(msg.sender) > 0 ||
                whitelist[msg.sender],
            "No Pepemon or Holo cards or whitelisted address"
        );
        require(msg.value == (packs * packPrice), "Wrong value");
        require(
            totalSupply() + (packs * cardsForPackage) <= MAX_SUPPLY,
            "Supply cap reached"
        );
        _mint(msg.sender, packs * cardsForPackage);
        hasMintedWhitelist[msg.sender] = true;
    }

    function addAddressesToWhitelist(
        address[] memory addressesToAdd
    ) external onlyOwner {
        for (uint256 i = 0; i < addressesToAdd.length; i++) {
            whitelist[addressesToAdd[i]] = true;
        }
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        whitelist[_address] = false;
    }

    function setPackPrice(uint256 newPrice) public onlyOwner {
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

    function adminMint(uint256 Packs) external onlyOwner {
        require(
            totalSupply() + (Packs * cardsForPackage) <= MAX_SUPPLY,
            "Supply cap reached"
        );
        _mint(msg.sender, Packs * cardsForPackage);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A) returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(baseURI, _toString(tokenId), uriSuffix)
                )
                : "";
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
