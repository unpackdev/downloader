// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IGorfSeeder.sol";
import "./IGorfDescriptor.sol";
import "./IGorfDecorator.sol";
import "./base64.sol";

contract GorfToken is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    uint8 public constant MINT_LIMIT = 20;
    uint256 public PRICE = 0.05 ether;

    bool public saleActive = false;
    mapping(address => uint256) public salePurchases;
    mapping(uint256 => IGorfSeeder.Seed) public seeds;

    // Whether the decorator can be updated
    bool public isDecoratorLocked;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;

    // The Gorf token decorator
    IGorfDecorator public decorator;

    // The Nouns token URI descriptor
    IGorfDescriptor public descriptor;

    // The Nouns token seeder
    IGorfSeeder public seeder;

    /**
     * @notice Require that the decorator has not been locked.
     */
    modifier whenDecoratorNotLocked() {
        require(!isDecoratorLocked, 'Decorator is locked');
        _;
    }

    /**
     * @notice Require that the descriptor has not been locked.
     */
    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, 'Descriptor is locked');
        _;
    }

    /**
     * @notice Require that the seeder has not been locked.
     */
    modifier whenSeederNotLocked() {
        require(!isSeederLocked, 'Seeder is locked');
        _;
    }

    constructor() ERC721('Gorf Zone', 'GZ') {
        decorator = IGorfDecorator(0xb65783f1B45468A8f932511527A7e3FeBAE4e86d);
        descriptor = IGorfDescriptor(0x0Cfdb3Ba1694c2bb2CFACB0339ad7b1Ae5932B63);
        seeder = IGorfSeeder(0xCC8a0FB5ab3C7132c1b2A0109142Fb112c4Ce515);
    }

    function mint(uint256 mintAmount) public payable {
        require(saleActive, 'sale is not active');
        require(totalSupply() + mintAmount <= MAX_SUPPLY, 'request exceeds supply');
        require(salePurchases[msg.sender] + mintAmount <= MINT_LIMIT, 'address total mint limit exceeded');
        require(mintAmount * PRICE <= msg.value, 'ether value sent is not correct');

        for (uint i = 0; i < mintAmount; i++) {
            uint256 id = totalSupply();
            seeds[id] = seeder.generateSeed(id, descriptor);
            _safeMint(msg.sender, id);
            salePurchases[msg.sender]++;
        }
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'URI query for nonexistent token');

        string memory gorfId = tokenId.toString();
        string memory name = string(abi.encodePacked('Gorf ', gorfId));
        string memory description = string(abi.encodePacked('Gorf ', gorfId, ' is a member of the Gorf Zone'));

        return decorator.genericDataURI(name, description, seeds[tokenId]);
    }

    /**
     * @notice Set the token URI decorator.
     * @dev Only callable by the owner when not locked.
     */
    function setDecorator(IGorfDecorator _decorator) external onlyOwner whenDecoratorNotLocked {
        decorator = _decorator;
    }

    /**
     * @notice Lock the decorator.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDecorator() external onlyOwner whenDecoratorNotLocked {
        isDecoratorLocked = true;
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(IGorfDescriptor _descriptor) external onlyOwner whenDescriptorNotLocked {
        descriptor = _descriptor;
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor() external onlyOwner whenDescriptorNotLocked {
        isDescriptorLocked = true;
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(IGorfSeeder _seeder) external onlyOwner whenSeederNotLocked {
        seeder = _seeder;
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external onlyOwner whenSeederNotLocked {
        isSeederLocked = true;
    }

    function toggleSaleStatus() external onlyOwner {
        saleActive = !saleActive;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}