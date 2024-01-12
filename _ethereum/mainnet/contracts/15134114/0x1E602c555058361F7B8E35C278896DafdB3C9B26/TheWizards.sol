// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*
___________.__              __      __.__                         .___      
\__    ___/|  |__   ____   /  \    /  \__|____________ _______  __| _/______
  |    |   |  |  \_/ __ \  \   \/\/   /  \___   /\__  \\_  __ \/ __ |/  ___/
  |    |   |   Y  \  ___/   \        /|  |/    /  / __ \|  | \/ /_/ |\___ \ 
  |____|   |___|  /\___  >   \__/\  / |__/_____ \(____  /__|  \____ /____  >
                \/     \/         \/           \/     \/           \/    \/                                                                                     

*/

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./MerkleProof.sol";

contract TheWizards is ERC721A, Ownable {
    using Address for address payable;
    using Strings for uint256;

    bytes32 public merkleRoot;

    mapping(address => bool) public whitelistClaimed;

    string private baseTokenURI;
    bool private saleStatus = false;
    uint256 private totalReservedSupply = 0;
    uint256 private salePrice = 0.005 ether;

    uint256 public MAX_SUPPLY = 5555;
    uint256 public MAX_WHITELIST_MINT = 1;
    uint256 public MAX_MINTS_PER_TX = 5;
    
    uint256 private TEAM_SUPPLY = 33;

    constructor() ERC721A("The Wizards", "WIZARDS") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function toggleSaleStatus() external onlyOwner {
        saleStatus = !saleStatus;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseTokenURI, _tokenId.toString(), ".json"));
    }
    
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function mint(uint256 quantity)
        external
        payable
        callerIsUser
    {
                require(isSaleActive(), "The Wizards: Sale has not started.");
        require(salePrice <= msg.value, "The Wizards: Insufficient fund.");
        require(quantity <= MAX_MINTS_PER_TX, "The Wizards: Amount exceeds transaction limit.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "The Wizards: Amount exceeds supply.");
        _safeMint(msg.sender, quantity);
    }

    function whitelistMint(bytes32[] calldata _merkleProof) external callerIsUser {
        require(isSaleActive(), "The Wizards: Sale has not started.");
        require(totalSupply() + 1 < MAX_SUPPLY, "The Wizards: Amount exceeds supply.");
        require(!whitelistClaimed[msg.sender], "The Wizards: Address has already claimed the token.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "The Wizards: Invalid proof.");
        
        whitelistClaimed[msg.sender] = true;

        _safeMint(msg.sender, 1);
    }

    function checkClaimed() public view returns (bool) {
        return whitelistClaimed[msg.sender];
    }

    function checkWhitelist(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function adminMint(uint256 _quantity) external onlyOwner {
        require(totalReservedSupply + _quantity <= TEAM_SUPPLY, "The Wizards: Reserved amount is exceeded");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "The Wizards: Amount exceeds supply");
        totalReservedSupply += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 1;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= totalSupply()
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function mintToAddress(address _to, uint256 _quantity) external onlyOwner {
        require(TEAM_SUPPLY + _quantity <= totalReservedSupply, "The Wizards: Reserved amount is exceeded");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "The Wizards: Amount exceeds supply");

        _safeMint(_to, _quantity);
    }

    function setSalePrice(uint256 _salePrice) external onlyOwner {
        salePrice = _salePrice;
    }

    function isSaleActive() public view returns (bool) {
        return saleStatus;
    }

    function getSalePrice() public view returns (uint256) {
        return salePrice;
    }

}