// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
/*
              /////                
           *//////////   //////    
           /////////////////////   
               ///////////////.    
    /////      //////////////      
  //////////////////////////////   
  //////////////////////////////// 
    ////////////////////,*//////// 
       //////////////      /////   
     ///////////////*              
    ////////////////////          
    /////   //////////           
                 ///// 

//Puzzle Prize NFT

import "ERC721.sol";
import "Counters.sol";
import "MerkleProof.sol";
import "Ownable.sol";

contract PuzzlePrize is ERC721, Ownable {

    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter public tokenCounter;
    Counters.Counter public prizeTokenCounter;

    bytes32 public whitelistMerkleRoot;
    bytes32 public prizeMerkleRoot;
    bytes32 public freeMerkleRoot;

    string public baseURI;

    uint256 public totalPieces = 5040;
    uint256 public prizeClaimThreshold = 757; 
    uint256 public totalPrizePieces = 510; 
    uint256 public publicPieceLimit = 8;
    uint256 public presalePieceLimit = 16;
    uint256 public maxPresaleSupply = 800;
    uint256 public _wlPrice = .02 ether; 
    uint256 public _price = .06 ether; 
    uint256 public totalPrizes = 10;

    bool public publicPaused = true;

    address public founder = 0x29Bdc8A1aA8DCAeE884Fd504e08a0b13760cE6b0;
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    address public wheelAddress;

    mapping(uint256 => uint256) public paidSpinsAvailable;
    mapping(uint256 => uint256) public freeSpinsAvailable;
    mapping(uint256 => uint256) public prizeCount; 
    mapping(uint256 => uint256) public prizeValues;
    mapping(address => uint256) public addressToMinted;
    mapping(address => bool) public projectProxy;
    mapping(uint256 => bool) public pieceToClaimed;
    mapping(bytes32 => mapping(address => bool)) merkleToMintClaimed;

    constructor () ERC721("Puzzle Prize NFT", "PZL") public 
         {

        } 
    modifier onlyWheel {
        require(_msgSender() == wheelAddress);
        _;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function setPrizeMerkleRoot(bytes32 _prizeMerkleRoot) external onlyOwner {
        prizeMerkleRoot = _prizeMerkleRoot;
    }

    function setFreeMerkleRoot(bytes32 _freeMerkleRoot) external onlyOwner {
        freeMerkleRoot = _freeMerkleRoot;
    } 

    function setWheelAddress(address _wheelAddress) external onlyOwner {
        wheelAddress = _wheelAddress;
    }

    function setPrizeClaimThreshold(uint256 _prizeClaimThreshold) external onlyOwner {
        prizeClaimThreshold = _prizeClaimThreshold;
    }

    function pausePublic(bool val) external onlyOwner {       
        publicPaused = val;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function doPresale (uint256 amount, bytes32[] calldata proof) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(addressToMinted[_msgSender()] + amount < presalePieceLimit, "You have exceeded the limit");
        require(amount + tokenCounter.current() < maxPresaleSupply, "There are no more pieces left for presale");
        require(amount * _wlPrice == msg.value , "Not enough ether sent");
        require(MerkleProof.verify(proof, whitelistMerkleRoot, leaf), "Invalid proof");
        addressToMinted[_msgSender()] += amount;
        for(uint256 i; i < amount; i++){
            _safeMint(_msgSender(), tokenCounter.current());
            tokenCounter.increment();
        }
    }

    function doPublic (uint256 amount) external payable {
        require(addressToMinted[_msgSender()] + amount < publicPieceLimit, "You have exceeded the limit");
        require(amount + tokenCounter.current() < totalPieces, "There are no more pieces left for public");
        require(amount * _price == msg.value, "Not enough ether sent");
        require(publicPaused == false, "Public has not begun yet");
        addressToMinted[_msgSender()] += amount;
        for(uint256 i; i < amount; i++){
            _safeMint(_msgSender(), tokenCounter.current());
            tokenCounter.increment();
        }
    }

    function freeMint (bytes32[] calldata proof) external {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(tokenCounter.current() + 1 < totalPieces, "There are no more pieces left for presale");
        require(MerkleProof.verify(proof, freeMerkleRoot, leaf), "Invalid proof");
        require(merkleToMintClaimed[freeMerkleRoot][_msgSender()] == false, "You already claimed your free mint");
        merkleToMintClaimed[freeMerkleRoot][_msgSender()] = true;
        _safeMint(_msgSender(), tokenCounter.current());
        tokenCounter.increment();
    }

    function setPrizes(uint256[] calldata _prizeCount, uint256[] calldata _prizeAmount) external onlyOwner {
        for(uint256 x; x < _prizeCount.length; x++){
            prizeCount[x] = _prizeCount[x];
            prizeValues[x] = _prizeAmount[x];
        }
    }
    
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        _price = _newPrice;
    }

    function setWlPrice(uint256 _newPrice) external onlyOwner {
        _wlPrice = _newPrice;
    }
    function setMaxSupply(uint256 _maxValue) external onlyOwner {
        totalPieces = _maxValue;
    }

    function setMaxPresaleSupply(uint256 _maxValue) external onlyOwner {
        maxPresaleSupply = _maxValue;
    }

    function setMaxPresaleToMint(uint256 _maxValue) external onlyOwner {
        presalePieceLimit = _maxValue;
    }

    function setMaxPublicToMint(uint256 _maxValue) external onlyOwner {
        publicPieceLimit = _maxValue;
    }    

    function setTotalPrizes(uint256 _totalPrizes) external onlyOwner {
        totalPrizes = _totalPrizes;
    }
    function createPrize () internal  {
        require(prizeTokenCounter.current() + 1 < totalPrizePieces, "Sorry its wrong");
        _safeMint(_msgSender(), totalPieces + prizeTokenCounter.current());
        prizeTokenCounter.increment();
    }

    function claimPrize(uint256 tokenID, bytes32[] calldata proof, string memory rarity, uint256 position) public {
        require(ownerOf(tokenID) == _msgSender(), "You are not the owner of this piece");
        require(tokenID < prizeClaimThreshold, "Your group is not able to claim prizes yet");
        require(pieceToClaimed[tokenID] == false, "This piece had it's prize claimed already");
        require(prizeWinner(tokenID, proof, rarity, position), "Invalid proof");
        require(prizeTokenCounter.current() + 1 < totalPrizePieces, "Sorry there are no more prizes available for claiming");
        
        uint256 prizeAmount;
        for(uint256 i = 0; i < totalPrizes; i ++){
            if(position < prizeCount[i]){
                prizeAmount = prizeValues[i];
                break;
            }
        }
        if(keccak256(abi.encodePacked(rarity)) == keccak256(abi.encodePacked("Rare"))){
            prizeAmount += (prizeAmount/10);
        }
        else if(keccak256(abi.encodePacked(rarity)) == keccak256(abi.encodePacked("Epic"))){
            prizeAmount += 2*(prizeAmount/10);
        }
        else if (keccak256(abi.encodePacked(rarity)) == keccak256(abi.encodePacked("Legendary"))){
            prizeAmount += 3*(prizeAmount/10);
        }
        pieceToClaimed[tokenID] = true;
        createPrize(); 
        payable(_msgSender()).transfer(prizeAmount);
    }

    function prizeWinner(uint256 tokenID, bytes32[] calldata proof, string memory rarity, uint256 position) public view returns (bool) {
        require(ownerOf(tokenID) == _msgSender());
        bytes32 leaf = keccak256(abi.encodePacked(tokenID.toString(), rarity, position.toString()));
        return (MerkleProof.verify(proof, prizeMerkleRoot, leaf));
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(founder).transfer(amount);
    }

    function addFreeSpin(uint256 tokenID, uint256 quantity, address requester) public onlyWheel { //add onlyProxies?
        require(ownerOf(tokenID) == requester, "You are not the owner of this piece");
        freeSpinsAvailable[tokenID] += quantity;
    }
    
    function subFreeSpin(uint256 tokenID, uint256 quantity, address requester) public onlyWheel{ //add onlyProxies?
        require(ownerOf(tokenID) == requester, "You are not the owner of this piece");
        freeSpinsAvailable[tokenID] -= quantity;
    }

    function addPaidSpin(uint256 tokenID, uint256 quantity, address requester) public onlyWheel { //add onlyProxies?
        require(ownerOf(tokenID) == requester, "You are not the owner of this piece");
        paidSpinsAvailable[tokenID] += quantity;
    }
    
    function subPaidSpin(uint256 tokenID, uint256 quantity, address requester) public onlyWheel{ //add onlyProxies?
        require(ownerOf(tokenID) == requester, "You are not the owner of this piece");
        paidSpinsAvailable[tokenID] -= quantity;
    }

}
contract OwnableDelegateProxy {}
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
