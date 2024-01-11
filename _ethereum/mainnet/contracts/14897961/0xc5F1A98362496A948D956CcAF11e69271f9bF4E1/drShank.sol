// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC20.sol";

import "./MerkleProof.sol";

import "./ERC2981Interface.sol";

contract DrShank is ERC721, Ownable, IERC2981Royalties {


    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }
    
    RoyaltyInfo private _royalties;

    //merkle root used for whitelist minting
    bytes32 public merkleRoot; 
    //mapping of already claimed whitelist addreeses
    mapping(address => bool) public whitelistClaimed;
    bool private whitelistIsOpen =false;

    //Interface for royalties
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    uint256 public _tokenIds_general;
    uint256 public _tokenIds_reserved;

    bool private publicSaleIsOpen = false;

    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public constant PRICE = 0.099 ether;

    uint256 public constant MAX_PER_MINT = 11;
    uint256 public constant MAX_PER_WALLET = 31;

    uint256 private reservedMints = 50;

    uint96 public constant ROYALTIES_POINTS = 500; //5%
    

    //Dev2
    address public constant PROJECTADRESS = 0xDC54544c088967e792531abEEdE6351202Db33F3;
    address public rewardPool;

    string public baseTokenURI;

    //amount of mints that each address has executed
    mapping(address => uint256) public mintsPerAddress;

    constructor(string memory baseURI) ERC721("DrShank", "DSH") {
        setBaseURI(baseURI);
        _tokenIds_reserved = 0;
        _tokenIds_general = reservedMints;
    }

    modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

    function _baseURI() internal view virtual override returns (string memory) {
       return baseTokenURI;
    }
    
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setRewardPoolAddress(address _newRewardPool) public onlyOwner{
        rewardPool = _newRewardPool;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner{
        merkleRoot = _newMerkleRoot;
    }

    function setMaxReservedMints(uint256 _newMaxReservedMints) public onlyOwner {
        require(whitelistIsOpen && publicSaleIsOpen == false, "Cannot modify reserved mints with sales open");
        _tokenIds_general = _newMaxReservedMints;
    }

    function openWhitelistSale() external onlyOwner {
        require(whitelistIsOpen == false, 'Whitelist Sale is already Open!');
        whitelistIsOpen = true;
    }
    function openPublicSale() external onlyOwner {
        require(publicSaleIsOpen == false, 'Sale is already Open!');
        publicSaleIsOpen = true;
    }

    function mintNFTs(uint256 _number) public callerIsUser payable {
        uint256 totalMinted = _tokenIds_general;

        require(publicSaleIsOpen == true, "Opensale is not Open");
        require(totalMinted + _number < MAX_SUPPLY, "Not enough NFTs!");
        require(mintsPerAddress[msg.sender] + _number < MAX_PER_WALLET, "Cannot mint more than 5 NFTs per wallet");
        require(_number > 0 && _number < MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(msg.value == PRICE * _number , "Not enough/too much ether sent");
        
        mintsPerAddress[msg.sender] += _number;

        for (uint i = 0; i < _number; i++) {
            _mintSingleNFT();
        }
    }

    function getCurrentId() public view returns (uint256) {
        return _tokenIds_general;
    }


    function _mintSingleNFT() internal {
      uint newTokenID = _tokenIds_general;
      _safeMint(msg.sender, newTokenID);
      _tokenIds_general++;

    }

    function whitelistMint(uint256 _number, bytes32[] calldata _merkleProof) external payable callerIsUser{
        uint256 totalMinted = _tokenIds_general;
        
        //basic validation. Wallet has not already claimed
        require(whitelistIsOpen == true, "Whitelist sale is not Open");
        require(!whitelistClaimed[msg.sender], "Address has already claimed NFT");
        require(totalMinted + _number < MAX_SUPPLY, "Not enough NFTs left to mint..");
        require(_number > 0 && _number < MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(mintsPerAddress[msg.sender] < MAX_PER_WALLET, "Cannot mint more than 5 NFTs per wallet");
        require(msg.value == PRICE * _number, "Not enough/too much ether sent");

        //veryfy the provided Merkle Proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Proof");

        //Mark address as having claimed the token
        whitelistClaimed[msg.sender] = true;

        mintsPerAddress[msg.sender] += _number;

        //mint tokens 
        for (uint i = 0; i < _number; i++) {
            _mintSingleNFT();
        }
    }

    function reservedNFTs(uint256 number) public onlyOwner {
        uint256 totalMinted = _tokenIds_reserved;
        
        require((totalMinted + number) < MAX_SUPPLY, "Max NFT supply exceeded");
        require(_tokenIds_reserved + number <= reservedMints, "Max reserved NFT minting exceeded");
        
        for (uint256 i = 0; i < number; i++) {
            _mintReservedNFT();
        }
    }

    function _mintReservedNFT() internal {
      uint newTokenID = _tokenIds_reserved;
      _safeMint(msg.sender, newTokenID);
      _tokenIds_reserved++;

    }

//Withdraw money in contract to Owner
    function withdraw() external onlyOwner {
     uint256 balance = address(this).balance;
     require(balance > 0, "No ether left to withdraw");
     require(rewardPool != address(0), "No reward contract set");

     uint256 balanceToProject = (balance*8000)/10000;
     (bool successProject, ) = PROJECTADRESS.call{value: balanceToProject}("");

     uint256 balanceTorewardPool = (balance*2000)/10000;
     (bool successrewardPool, ) = rewardPool.call{value: balanceTorewardPool}("");

     require(successProject && successrewardPool, "Transfer failed.");
     
    }

    //interface for royalties
    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool){

        return interfaceId == type(IERC2981Royalties).interfaceId || super.supportsInterface(interfaceId);
    }

    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        require(value <= 10000, 'ERC2981Royalties: Too high');

        _royalties = RoyaltyInfo(recipient, uint24(value));
    }

    function royaltyInfo(uint256, uint256 value) external view override returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }

        //fallback receive function
        receive() external payable {
        
    }
    
}