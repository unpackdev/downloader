// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

contract MetamalsERC721 is OwnableUpgradeable, ERC721EnumerableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    event MetamalSaleStatusChanged(bool _saleActive);
    event MetamalPresaleStatusChanged(bool _presaleActive);

    /**
     * @dev maxSupply includes genesis, baby and legendaries
     */
    string public baseURI;
    uint256 public maxSupply;
    uint256 public maxMetamalCount;
    uint256 public babyCount;
    uint256 public price;

    bool public presaleActive;
    bool public saleActive;

    mapping(address => uint256) public presaleWhitelist;
    mapping(address => uint256) public balanceMetamal;
    mapping(uint256 => address) public Owner;

    modifier activeSale() {
        require(saleActive, "Sale is not active");
        _;
    }

    modifier activePresale() {
        require(presaleActive, "Presale is not active");
        _;
    }

    /**
     * Reserved for donations/legendaries
     */
    function reserveMetamals(uint256 numberOfMints) public onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 1; i <= numberOfMints; i++) {
            _safeMint(msg.sender, supply + i);
            balanceMetamal[msg.sender]++;
        }
    }

    // Minting
    // Limited to 'reserved' per person, can be set when we edit whitelist
    function mintPresale(uint256 numberOfMints) public payable {
        uint256 supply = totalSupply();
        uint256 reserved = presaleWhitelist[msg.sender];
        require(presaleActive, "Presale must be active to mint");
        require(reserved > 0, "No tokens reserved for this address");
        require(numberOfMints <= reserved, "Can't mint more than reserved");
        require(
            supply.add(numberOfMints) <= maxMetamalCount,
            "Purchase would exceed max supply of Metamals"
        );
        require(
            price.mul(numberOfMints) == msg.value,
            "Ether value sent is not correct"
        );
        presaleWhitelist[msg.sender] = reserved - numberOfMints;

        for (uint256 i = 1; i <= numberOfMints; i++) {
            _safeMint(msg.sender, supply + i);
            balanceMetamal[msg.sender]++;
        }
    }

    // Limited to 10 per transaction
    function mint(uint256 numberOfMints) public payable {
        uint256 supply = totalSupply();
        require(saleActive, "Sale must be active to mint");
        require(
            numberOfMints > 0 && numberOfMints <= 10,
            "Invalid purchase amount"
        );
        require(
            supply.add(numberOfMints) <= maxMetamalCount,
            "Purchase would exceed max supply of Metamals"
        );
        require(
            price.mul(numberOfMints) == msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 1; i <= numberOfMints; i++) {
            _safeMint(msg.sender, supply + i);
            balanceMetamal[msg.sender]++;
        }
    }

    // Edit presale whitelist reserved amounts
    function editPresale(address[] calldata presaleAddresses, uint256 amount)
        external
        onlyOwner
    {
        for (uint256 i; i < presaleAddresses.length; i++) {
            presaleWhitelist[presaleAddresses[i]] = amount;
        }
    }

    function walletOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    // Withdraw earnings
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function togglePresale() public onlyOwner {
        presaleActive = !presaleActive;
        emit MetamalPresaleStatusChanged(presaleActive);
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
        emit MetamalSaleStatusChanged(saleActive);
    }

    // Price change
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    // Base URI
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
