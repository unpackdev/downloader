// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";
import "./Strings.sol"; 
import "./console.sol";

contract Kireigakuen is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;
    uint256 maxSupply = 888;
    uint256 maxPerWallet = 3;
    uint256 maxPerWL = 1;
    uint256 public wlcost = 0.003 ether;
    uint256 public publiccost = 0.0069 ether;
    event LogMsgValue(uint256 value);
    bool public isPublicOpen = false;
    bool public isWhitelistOpen = false;
    
    bytes32 public merkleRoot;

    mapping(address => bool) public whitelistClaimed;

    Counters.Counter private _tokenIdCounter;

    string public baseURI = "ipfs://";
    string public baseExtension = ".json";

    bool public revealed = false;
    string public notRevealedUri;

    constructor() ERC721("Kireigakuen", "KGKN") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function changeBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension))
                : "";
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    function ownerMint(address to, uint256 quantity) public onlyOwner {
        for (uint i = 0; i < quantity; i++){
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function togglePublic(bool _input) external onlyOwner{
        isPublicOpen = _input;
    }

    function toggleWhitelist(bool _input) external onlyOwner{
        isWhitelistOpen = _input;
    }

    function publicMint(uint256 quantity) public payable {
        emit LogMsgValue(msg.value);
        require(msg.value >= quantity * publiccost, "Need more funds");
        require(msg.value >= publiccost, "Price is 0.0069 each");
        require(quantity <= maxPerWallet, "Max per mint is 3");
        require(isPublicOpen == true, "Not yet public");
        mintRequirements(quantity);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata _merkleProof) public payable{
        require(msg.value >= quantity * wlcost, "Need more funds");
        require(msg.value >= wlcost, "Price is 0.003 each");
        require(quantity <= maxPerWL, "Max per WL is 1");
        require(isWhitelistOpen == true, "Not yet public");
        require(!whitelistClaimed[msg.sender], "Address already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof."
        );
        whitelistClaimed[msg.sender] = true;
        mintRequirements(quantity);
    }

    function mintRequirements(uint256 quantity) internal {
        console.log(msg.value, " this is msg.value");
        require(totalSupply() + quantity < maxSupply, "Sold Out");
        for (uint i = 0; i < quantity; i++){
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _mint(msg.sender, tokenId);
        }
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function withdrawBalance(address _addressTo) external onlyOwner {
        uint totalBalance = address(this).balance;
        payable(_addressTo).transfer(totalBalance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}