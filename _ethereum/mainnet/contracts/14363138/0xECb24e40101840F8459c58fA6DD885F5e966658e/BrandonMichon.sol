// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract BrandonMichon is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 constant MAX_SUPPLY = 10000;
    uint256 constant MAX_AMOUNT = 5;
    uint256 private _currentId;

    string public baseURI;

    bool public isActive = false;

    uint256 public price = 0.08 ether;

    mapping(address => uint256) private _alreadyMinted;

    constructor() ERC721("Brandon Michon", "MICHON") {}

    // setup
    function setActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    function alreadyMinted(address addr) public view returns (uint256) {
        return _alreadyMinted[addr];
    }

    function totalSupply() public view returns (uint256) {
        return _currentId;
    }

    // Metadata
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Minting
    function mint(uint256 amount) public payable nonReentrant {
        address sender = _msgSender();

        require(isActive, "Sale is closed");
        require(
            amount + _alreadyMinted[sender] <= MAX_AMOUNT,
            "Insufficient mints left"
        );
        require(msg.value == price * amount, "Incorrect payable amount");

        _alreadyMinted[sender] += amount;
        _internalMint(sender, amount);
    }

    function ownerMint(address to, uint256 amount) public onlyOwner {
        _internalMint(to, amount);
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Private
    function _internalMint(address to, uint256 amount) private {
        require(
            _currentId + amount <= MAX_SUPPLY,
            "Will exceed maximum supply"
        );

        for (uint256 i = 1; i <= amount; i++) {
            _currentId++;
            _safeMint(to, _currentId);
        }
    }
}
