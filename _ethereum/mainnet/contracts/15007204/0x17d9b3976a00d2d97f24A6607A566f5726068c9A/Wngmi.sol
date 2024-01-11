//SPDX-License-Identifier: MIT

/*
 #     #  #     #   #####   #     #  ###
 #  #  #  ##    #  #     #  ##   ##   #
 #  #  #  # #   #  #        # # # #   #
 #  #  #  #  #  #  #  ####  #  #  #   #
 #  #  #  #   # #  #     #  #     #   #
 #  #  #  #    ##  #     #  #     #   #
  ## ##   #     #   #####   #     #  ###

    WNGMI! We're not gonna make it!
*/

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract Wngmi is ERC721A, Ownable, ReentrancyGuard, Pausable {
    bool public whitelistMintEnabled = false;
    bool public publicMintEnabled = false;
    uint256 public MAX_WNGMI_SUPPLY = 1200;  // total maximum wngmi
    uint256 public maxWngmiMint = 3; // maximum mint wngmi per address
    string public baseURI;

    mapping(bytes32 => bool) whitelistedAddresses;
    uint32 public currentMappingVersion;

    constructor() ERC721A("Wngmi", "WNGMI") {}

    function isAddressWhitelisted(address _user) public view onlyOwner returns (bool) {
        bytes32 key = keccak256(abi.encodePacked(currentMappingVersion, _user));
        return whitelistedAddresses[key];
    }

    function isOwnAddressWhitelisted() public view returns (bool) {
        bytes32 key = keccak256(abi.encodePacked(currentMappingVersion, msg.sender));
        return whitelistedAddresses[key];
    }

    function whitelistAddress(address _user) external onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(currentMappingVersion, _user));
        whitelistedAddresses[key] = true;
    }

    function whitelistAddresses(address[] calldata _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            bytes32 key = keccak256(abi.encodePacked(currentMappingVersion, _users[i]));
            whitelistedAddresses[key] = true;
        }
    }

    function clearWhitelist() external onlyOwner {
        // increments the mapping version which invalidates previous hashed whitelist
        currentMappingVersion++;
    }

    function deleteWhitelistedAddress(uint32 _version, address _user) external onlyOwner {
        require(_version <= currentMappingVersion);
        bytes32 key = keccak256(abi.encodePacked(_version, _user));
        delete (whitelistedAddresses[key]);
    }

    function publicMint(uint256 _quantity) external whenNotPaused nonReentrant {
        require(publicMintEnabled, "Public minting disabled");
        require(_quantity + _numberMinted(msg.sender) <= maxWngmiMint, "Address already minted max WNGMIs");
        require(totalSupply() + _quantity <= MAX_WNGMI_SUPPLY, "All WNGMIs are minted");
        require(msg.sender == tx.origin);

        _safeMint(msg.sender, _quantity);
    }

    function teamMint(address _toAddress, uint256 _quantity) public onlyOwner {
        require(totalSupply() + _quantity <= MAX_WNGMI_SUPPLY, "All WNGMIs are minted");
        require(msg.sender == tx.origin);

        _safeMint(_toAddress, _quantity);
    }

    function whitelistMint(uint256 _quantity) external whenNotPaused nonReentrant {
        require(whitelistMintEnabled, "Whitelist minting disabled");
        bytes32 key = keccak256(abi.encodePacked(currentMappingVersion, msg.sender));
        require(whitelistedAddresses[key], "Only whitelisted addresses are allowed to mint");
        require(_quantity + _numberMinted(msg.sender) <= maxWngmiMint, "Whitelist address already minted max WNGMIs");
        require(totalSupply() + _quantity <= MAX_WNGMI_SUPPLY, "All WNGMIs are minted");
        require(msg.sender == tx.origin);

        _safeMint(msg.sender, _quantity);
    }

    function setWhitelistMint(bool _whitelistMintFlag) external onlyOwner {
        whitelistMintEnabled = _whitelistMintFlag;
    }

    function setPublicMint(bool _publicMintFlag) external onlyOwner {
        publicMintEnabled = _publicMintFlag;
    }

    function setMaxWngmi(uint256 _maxNumber) external onlyOwner {
        maxWngmiMint = _maxNumber;
    }

    function withdraw() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _theBaseURI) external onlyOwner {
        baseURI = _theBaseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function wngmiMinted() external view returns (uint256) {
        return _numberMinted(msg.sender);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // OpenSea metadata initialization
    function contractURI() public pure returns (string memory) {
        return "https://wngmibros.xyz/wngmi_contract_metadata.json";
    }
}