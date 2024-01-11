// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";


contract AxoloxNFT is ERC721Enumerable, Ownable {
    string  public              baseURI;
    
    address public              taakin;

    bytes32 public              whitelistMerkleRoot;
    uint256 public              MAX_SUPPLY;
    
    //TIME VARIABLES
    uint256 public whiteListWindowStart = 1653501600;
    uint256 public publicWindowStart = 1653588000;
    uint256 public     priceInWei          = 0.06 ether;
    uint256 public      maxPerWallet      = 4;
    
    uint256 public constant     MAX_PER_TX          = 4;
    uint256 public constant     RESERVES            = 85;
   

    mapping(address => uint) public addressToMinted;

    constructor(
        string memory _baseURI
    )
        ERC721("AxoloxNFT", "AXOLOX")
    {
        baseURI = _baseURI;
    }

    function setTaakin(address _taakin) public onlyOwner {
        taakin = _taakin;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setPrice(uint256 _priceInWei) public onlyOwner {
        priceInWei = _priceInWei;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId),"Token does not exist");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function collectReserves() external onlyOwner {
        require(_owners.length == 0, 'Reserves already taken.');
        for(uint256 i; i < RESERVES; i++)
            _mint(_msgSender(), i);
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function toggleWhiteListSale(uint256 _MAX_SUPPLY) external onlyOwner {
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function _leaf(string memory allowance, string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload, allowance));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
    }

    function setWhiteListWindowStart(uint256 _whiteListWindowStart) external onlyOwner {
        whiteListWindowStart = _whiteListWindowStart;
    }

    function setPublicWindowStart(uint256 _publicWindowStart) external onlyOwner {
        publicWindowStart = _publicWindowStart;
    }

    function whitelistMint(uint256 count, bytes32[] calldata _merkleProof) public payable{
        require(block.timestamp >= whiteListWindowStart, "White list sale has not started.");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(_verify(leaf, _merkleProof), ":( You are not whitelisted");
        require(count * priceInWei == msg.value, "Invalid funds provided.");
        uint256 totalSupply = _owners.length;
        require(addressToMinted[_msgSender()] + count <= maxPerWallet, "Exceeds max wallet supply");
        require(totalSupply + count <= MAX_SUPPLY, "Exceeds max supply.");
        for(uint i; i < count; i++) { 
            _mint(_msgSender(), totalSupply + i);
            addressToMinted[_msgSender()]= addressToMinted[_msgSender()] + 1;
        }
    }

    function publicMint(uint256 count) public payable {
        require(block.timestamp >= publicWindowStart, "Public sale has not started.");
        uint256 totalSupply = _owners.length;
        require(totalSupply + count <= MAX_SUPPLY, "Exceeds max supply.");
        require(addressToMinted[_msgSender()] + count <= maxPerWallet, "Exceeds max wallet supply");
        require(count <= MAX_PER_TX, "Exceeds max per transaction.");
        require(count * priceInWei == msg.value, "Invalid funds provided.");
        for(uint i; i < count; i++) { 
            _mint(_msgSender(), totalSupply + i);
            addressToMinted[_msgSender()]= addressToMinted[_msgSender()] + 1;
        }
    }

    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = taakin.call{value: address(this).balance}("");
        require(success, "Failed to send to taakin");
    }

    function evolve(uint256 tokenId) public {
         uint256 tokenCount = balanceOf(_msgSender());
         require(tokenCount > 1, "No tokens to evolve.");
         burn(tokenId);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }
        return true;
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
}

