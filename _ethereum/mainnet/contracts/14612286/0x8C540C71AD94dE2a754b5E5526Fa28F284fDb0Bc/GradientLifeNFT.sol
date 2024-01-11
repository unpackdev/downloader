// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "MerkleProof.sol";
import "ERC721AOwnersExplicit.sol";
import "ERC721APausable.sol";
import "ERC721AQueryable.sol";

contract GradientLifeNFT is
    Ownable,
    ERC721AOwnersExplicit,
    ERC721APausable,
    ERC721AQueryable
{
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    string public defaultURI;
    uint256 public revealedProgress = 0;
    uint256 public generalCost = 0.04 ether;
    uint256 public whitelistCost = 0.03 ether;
    uint256 public maxSupply = 3333;
    uint256 public mintPerAddressLimit = 5;
    uint256 public mintPerTransactionLimit = 5;
    uint256 public reserved = 333;
    bool public isWhitelist = true;

    address public owner1 = 0x5E2448CE7bfAebE840e6E6dd2600c0aa9D88f4F7;
    address public owner2 = 0xAE175b64cE7C4Df5cf3e07bb28Bcbaea847F3683;

    bytes32 merkleRoot = 0xa9a8214c20a2642c3196fc892703040bc039f1bee925a25c37a3b49d7e24b452;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setDefaultURI(_initNotRevealedUri);

        _safeMint(owner1, 1);
        _safeMint(owner2, 1);
    }

    function _beforeTokenTransfers( address from, address to, uint256 tokenId, uint256 quantity) internal override(ERC721A, ERC721APausable) {
        super._beforeTokenTransfers(from, to, tokenId, quantity);
        if (paused()) revert ContractPaused();
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // public
    function WhitelistMint(uint256 _amount, bytes32[] calldata _merkleProof) public payable whenNotPaused {
        require(_amount > 0, "need to mint at least 1 NFT");
        require(msg.value >= whitelistCost * _amount, "insufficient funds");
        require(_amount <= mintPerTransactionLimit, "max mint per transaction exceeded");

        uint256 supply = totalSupply();
        require(supply + _amount <= maxSupply - reserved, "max supply exceeded");

        //check if there's a mint per address limit
        uint256 mintedCount = numberMinted(msg.sender);
        require(mintedCount + _amount <= mintPerAddressLimit, "max mint per address exceeded");

        //check for whitelist
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "invalid proof, you're not in the whitelist");

        _safeMint(msg.sender, _amount);
    }

    function GeneralMint(uint256 _amount) public payable whenNotPaused {
        require(!isWhitelist, "only whitelist can mint now");
        require(_amount > 0, "need to mint at least 1 NFT");
        require(msg.value >= generalCost * _amount, "insufficient funds");
        require(_amount <= mintPerTransactionLimit, "max mint per transaction exceeded");

        uint256 supply = totalSupply();
        require(supply + _amount <= maxSupply - reserved, "max supply exceeded");

        //check if there's a mint per address limit
        uint256 mintedCount = numberMinted(msg.sender);
        require(mintedCount + _amount <= mintPerAddressLimit, "max mint per address exceeded");

        _safeMint(msg.sender, _amount);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function getOwnershipData(uint256 tokenId) public view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        if (bytes(currentBaseURI).length > 0 && tokenId <= revealedProgress) {
            return string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)); 
        } else {
            return string(abi.encodePacked(defaultURI, tokenId.toString(), baseExtension)); 
        }
    }

    //ONLY OWNER
    function burn(uint256 tokenId) public virtual onlyOwner{
        _burn(tokenId, true);
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    //set merkle root for whitelist verification
    function setMerkleRoot(bytes32 _set) external onlyOwner {
        merkleRoot = _set;
    }

    //mint _amount amount of LIFE for to an address
    function giveAway(address _to, uint256 _amount) external onlyOwner {
        require(_amount > 0, "need to mint at least 1 NFT");
        require(_amount <= reserved, "Exceeds reserved supply");

        uint256 supply = totalSupply();
        _safeMint(_to, _amount);
        reserved -= _amount;
    }

    function givewayForAll(address[] memory _to) external onlyOwner {
        require(_to.length > 0, "need to mint at least 1 NFT");
        require(_to.length <= reserved, "Exceeds reserved supply");

        uint256 supply = totalSupply();
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], 1);
        }
        reserved -= _to.length;
    }

    function setRevealedProgress(uint256 _set) public onlyOwner {
        revealedProgress = _set;
    }

    function setCost(uint256 _setGenral, uint256 _setWhitelist) public onlyOwner {
        generalCost = _setGenral;
        whitelistCost = _setWhitelist;
    }

    function setBaseURI(string memory _set) public onlyOwner {
        baseURI = _set;
    }

    function setBaseExtension(string memory _set) public onlyOwner {
        baseExtension = _set;
    }

    function setDefaultURI(string memory _set) public onlyOwner {
        defaultURI = _set;
    }

    function setOnlyWhitelisted(bool _set) public onlyOwner {
        isWhitelist = _set;
    }

    function setMintPerAddressLimit(uint256 _limit) public onlyOwner {
        mintPerAddressLimit = _limit;
    }

    function setMintPerTransactionLimit(uint256 _limit) public onlyOwner {
        mintPerTransactionLimit = _limit;
    }

    function withdrawAll() external onlyOwner {
        uint256 amount = address(this).balance / 2;
        require(amount > 0);
        _widthdraw(owner1, amount);
        _widthdraw(owner2, amount);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function setGradientLifeOwner(address _set1, address _set2) public onlyOwner {
        owner1 = _set1;
        owner2 = _set2;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner {
        _setOwnersExplicit(quantity);
    }
}
