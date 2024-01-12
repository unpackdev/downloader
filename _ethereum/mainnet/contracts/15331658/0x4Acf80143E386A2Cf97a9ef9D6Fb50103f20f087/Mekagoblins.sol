//SPDX-License-Identifier: MIT

/*
 _______       _              _______       _     _  _
(_______)     | |            (_______)     | |   | |(_)
 _  _  _ _____| |  _ _____    _   ___  ___ | |__ | | _ ____   ___
| ||_|| | ___ | |_/ |____ |  | | (_  |/ _ \|  _ \| || |  _ \ /___)
| |   | | ____|  _ (/ ___ |  | |___) | |_| | |_) ) || | | | |___ |
|_|   |_|_____)_| \_)_____|   \_____/ \___/|____/ \_)_|_| |_(___/

    Meka Goblins! 8,192 Meka Goblin Collection
*/

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract Mekagoblins is ERC721A, Ownable, ReentrancyGuard, Pausable {
    bool public allowlistMintEnabled = false;
    bool public publicMintEnabled = false;
    bool public teamMintComplete = false;
    uint256 public MAX_MEKAGOBLINS_SUPPLY = 8192;  // total maximum meka goblins
    uint256 public maxMekagoblinsMint = 3; // maximum mint per address
    string public baseURI;

    bool private isRevealed = false;
    string private preRevealURI = "ipfs://QmVHYA59t9CNGvA1ZWfBvPE1N97jWmgqvk5fA3VdjrAviP";

    mapping(bytes32 => bool) allowlistedAddresses;
    uint32 public currentMappingVersion;

    constructor() ERC721A("Meka Goblins", "MEKAGOBLINS") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Meka Goblins :: Cannot be called by a contract");
        _;
    }

    function isAddressAllowlisted(address _user) public view onlyOwner returns (bool) {
        bytes32 key = keccak256(abi.encodePacked(currentMappingVersion, _user));
        return allowlistedAddresses[key];
    }

    function isOwnAddressAllowlisted() public view returns (bool) {
        bytes32 key = keccak256(abi.encodePacked(currentMappingVersion, msg.sender));
        return allowlistedAddresses[key];
    }

    function allowlistAddress(address _user) external onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(currentMappingVersion, _user));
        allowlistedAddresses[key] = true;
    }

    function allowlistAddresses(address[] calldata _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            bytes32 key = keccak256(abi.encodePacked(currentMappingVersion, _users[i]));
            allowlistedAddresses[key] = true;
        }
    }

    function clearAllowlist() external onlyOwner {
        // increments the mapping version which invalidates previous hashed allowlist
        currentMappingVersion++;
    }

    function deleteAllowlistedAddress(uint32 _version, address _user) external onlyOwner {
        require(_version <= currentMappingVersion);
        bytes32 key = keccak256(abi.encodePacked(_version, _user));
        delete (allowlistedAddresses[key]);
    }

    function publicMint(uint256 _quantity) external whenNotPaused nonReentrant callerIsUser {
        require(publicMintEnabled, "Meka Goblins :: Public minting is on pause");
        require(_quantity + _numberMinted(msg.sender) <= maxMekagoblinsMint, "Meka Goblins :: 3 Meka Goblins max mint per address");
        require(totalSupply() + _quantity <= MAX_MEKAGOBLINS_SUPPLY, "Meka Goblins :: All Meka Goblins NFTs are minted");

        _safeMint(msg.sender, _quantity);
    }

    function teamMint(address _toAddress) public onlyOwner callerIsUser {
        require(totalSupply() + 100 <= MAX_MEKAGOBLINS_SUPPLY, "Meka Goblins :: All Meka Goblins NFTs are minted");
        require(!teamMintComplete, "Meka Goblins :: Team mint already completed");
        teamMintComplete = true;
        _safeMint(_toAddress, 100);
    }

    function allowlistMint(uint256 _quantity) external whenNotPaused nonReentrant callerIsUser {
        require(allowlistMintEnabled, "Meka Goblins :: Allowlist minting is on pause");
        bytes32 key = keccak256(abi.encodePacked(currentMappingVersion, msg.sender));
        require(allowlistedAddresses[key], "Meka Goblins :: Only allowlisted addresses are allowed to mint");
        require(_quantity + _numberMinted(msg.sender) <= maxMekagoblinsMint, "Meka Goblins :: 3 Meka Goblins max mint per address");
        require(totalSupply() + _quantity <= MAX_MEKAGOBLINS_SUPPLY, "Meka Goblins :: All Meka Goblins NFTs are minted");

        _safeMint(msg.sender, _quantity);
    }

    function setAllowlistMint(bool _allowlistMintFlag) external onlyOwner {
        allowlistMintEnabled = _allowlistMintFlag;
    }

    function setPublicMint(bool _publicMintFlag) external onlyOwner {
        publicMintEnabled = _publicMintFlag;
    }

    function setMaxMekagoblins(uint256 _maxNumber) external onlyOwner {
        maxMekagoblinsMint = _maxNumber;
    }

    function withdraw() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mekagoblinsMinted() external view returns (uint256) {
        return _numberMinted(msg.sender);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!isRevealed) {
            return preRevealURI;
        }
        return super.tokenURI(tokenId);
    }

    function reveal(string memory _theBaseURI) external onlyOwner {
        baseURI = _theBaseURI;
        isRevealed = true;
    }

    // OpenSea metadata initialization
    function contractURI() public pure returns (string memory) {
        return "https://mekagoblins.com/mekagoblin_contract_metadata.json";
    }
}