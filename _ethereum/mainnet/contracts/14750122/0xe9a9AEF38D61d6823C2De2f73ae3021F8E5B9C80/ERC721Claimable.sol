// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./Pausable.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract ERC721Claimable is ERC721, Pausable, Ownable {
    using Strings for uint;

    uint public startMintId;
    uint public price;
    string public contractURI;
    string public baseTokenURI;
    string public baseTokenURIClaimed;
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public freelisted;
    mapping(uint => bool) public claimed;
    address public feeCollectorAddress;

    bool public claimStarted;
    bool public publicMint;
    uint public max;

    /// @notice Constructor for the ONFT
    /// @param _name the name of the token
    /// @param _symbol the token symbol
    /// @param _contractURI the contract URI
    /// @param _baseTokenURI the base URI for computing the tokenURI
    /// @param _baseTokenURIClaimed //the base URI after token has been claimed
    /// @param _price that must be paid for a pass
    /// @param _feeCollectorAddress the address fee collector
    constructor(string memory _name, string memory _symbol, string memory _contractURI, string memory _baseTokenURI, string memory _baseTokenURIClaimed, uint _price, address _feeCollectorAddress) ERC721(_name, _symbol) {
        contractURI = _contractURI;
        baseTokenURI = _baseTokenURI;
        baseTokenURIClaimed = _baseTokenURIClaimed;
        startMintId = 0;
        max = 29;
        price = _price;
        feeCollectorAddress = _feeCollectorAddress;
        claimStarted = false;
    }

    function claim(uint tokenId) external {
        require(claimStarted, "Claim period has not begun");
        require(ownerOf(tokenId) == msg.sender, "Must be owner");
        claimed[tokenId] = true;
    }

    function mintPublic() external payable {
        require(msg.value >= price, "Insufficient funds.");
        require(publicMint, "public mint period has not begun");
        require(startMintId < max, "No more left");
        _mint(msg.sender, startMintId++);
    }

    function mint() external payable {
        require(msg.value >= price, "Insufficient funds.");
        require(whitelisted[msg.sender], "Address not whitelisted.");
        require(startMintId < max, "No more left");
        whitelisted[msg.sender] = false;
        _mint(msg.sender, startMintId++);
    }

    function mintFree() external {
        require(freelisted[msg.sender], "Address not freelisted.");
        require(startMintId < max, "No more left");
        freelisted[msg.sender] = false;
        _mint(msg.sender, startMintId++);
    }

    function mintDirect(address to) external onlyOwner {
        _mint(to, startMintId++);
    }

    function pauseSendTokens(bool pause) external onlyOwner {
        pause ? _pause() : _unpause();
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        if (claimed[tokenId]) {
            return string(abi.encodePacked(baseTokenURIClaimed, tokenId.toString()));
        }
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    function setFeeCollector(address _feeCollectorAddress) external onlyOwner {
        feeCollectorAddress = _feeCollectorAddress;
    }

    function setMintPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setBaseURIClaimed(string memory _baseTokenURIClaimed) public onlyOwner {
        baseTokenURIClaimed = _baseTokenURIClaimed;
    }

    function setClaimStart(bool _isStarted) public onlyOwner {
        claimStarted = _isStarted;
    }

    function setPublicMint(bool _isStarted) public onlyOwner {
        publicMint = _isStarted;
    }

    function addToWhitelist(address[] memory _whitelist) public onlyOwner {
        for (uint i = 0; i < _whitelist.length; i++) {
            whitelisted[_whitelist[i]] = true;
        }
    }

    function addToFreelist(address[] memory _freelist) public onlyOwner {
        for (uint i = 0; i < _freelist.length; i++) {
            freelisted[_freelist[i]] = true;
        }
    }

    function revokeFreelist(address _toRevoke) public onlyOwner {
        freelisted[_toRevoke] = false;
    }

    function revokeWhitelist(address _toRevoke) public onlyOwner {
        whitelisted[_toRevoke] = false;
    }

    function _beforeTokenTransfer(address from, address to, uint tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!claimed[tokenId], "ERC721Claimable: token has already been claimed");
    }

    function withdraw(address to) public onlyOwner {
        bool success;
        (success, ) = to.call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }
}
