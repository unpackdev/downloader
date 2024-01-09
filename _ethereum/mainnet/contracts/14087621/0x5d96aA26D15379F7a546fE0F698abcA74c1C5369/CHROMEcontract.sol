// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract CHROMEcontract is ERC721Enumerable, Ownable {

    bytes32 public whitelistMerkleRoot;
    
    address public UnemploymentOffice; 
    address public partner;
    
    string public baseURI;
    string public CHROMEKID_PROVENANCE = "";

    mapping(address => uint) public presaleMints;
    
    uint256 public constant MAX_KIDS = 3334;
    uint256 public constant KIDS_PER_TX = 11; 
    uint256 public constant KID_PRICE = 0.03 ether; 
    
    bool public presaleLive = true;
    bool public saleLive = false;
    bool public REVEALED = false;    

    constructor(
        string memory _baseURI,
        address _unemployment,
        address _partner
        )
        ERC721("CHROME kids", "CHROME") payable {
            baseURI = _baseURI;
            UnemploymentOffice = payable(_unemployment);
            partner = payable(_partner);
        }
    

    function presaleMint(uint256 _mintAmount, bytes32[] calldata proof) external payable {
        require(presaleLive, "Presale Closed");
        require(_verify(_leaf(msg.sender), proof), "Invalid proof");
        require(presaleMints[msg.sender] + _mintAmount < 4, "No more than 3 presale mints per wallet");
        require( KID_PRICE * _mintAmount == msg.value, "Invalid amount of ETH bruh.");
        
        presaleMints[msg.sender] += _mintAmount;
        uint256 totalSupply = _owners.length;
        for (uint256 i = 0; i < _mintAmount; i++) {
          _mint(_msgSender(), totalSupply + i);
        }
    }
    
    function publicMint(uint256 _mintAmount) public payable {
        uint256 totalSupply = _owners.length;
        require(saleLive, "Public sale is not active");
        require(totalSupply + _mintAmount < MAX_KIDS, "Transaction will exceed supply");
        require(_mintAmount < KIDS_PER_TX, "Exceeded max per transaction");
        require(_mintAmount * KID_PRICE == msg.value, "Not enough ETH bruh.");
  
        for (uint256 i = 0; i < _mintAmount; i++) {
          _mint(_msgSender(), totalSupply + i);
        }
    }

    function gift(address[] calldata receivers) external onlyOwner { 
        uint256 totalSupply = _owners.length;   
        require(totalSupply + receivers.length < MAX_KIDS, "Transaction will exceed supply");  
        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], totalSupply + i);
        }
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory){
        require(
          _exists(_tokenId),
          "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = baseURI;
        if (REVEALED == false) {
            return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, "hidden", ".json"))
            : "";
        } else {
            return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), ".json"))
            : "";
        }
  
    }

    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
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

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }

        return true;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        CHROMEKID_PROVENANCE = provenanceHash;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function reveal() public onlyOwner() {
        REVEALED = !REVEALED;
    }

    function flipPresaleState() public onlyOwner {
        !presaleLive ? presaleLive = true : presaleLive = false;
    }

    function flipSaleState() public onlyOwner {
        saleLive = !saleLive;
    }

    function withdraw() public onlyOwner {

        (bool cool, ) = payable(partner).call{value: address(this).balance * 10 / 100}("");
        require(cool, "Couldnt do it");

        (bool success, ) = payable(UnemploymentOffice).call{value: address(this).balance}("");
        require(success, "Fail");
    }    

}