// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Address.sol";
import "./IERC721.sol";

contract WorldStar is ERC721, Ownable {
  using Strings for uint256;
  using Address for address;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  IERC721 public mintPass;

  address private t1 ;
  address private t2 ;

  uint public constant maxSupply = 10000;
  uint public constant maxMintsPerTransaction = 20;
  uint public constant reservedAmount = 300;
  uint public constant salePrice = 0.069 ether;
  uint public reservedMintedAlready;

  mapping(address => uint256) public whitelist;
  mapping(uint => bool) public mintPassIdHasMinted;

  bool public presaleOpen = false;
  bool public saleOpen = false;
  bool public revealed = false;
  bool public milestoneReached = false;

  string public baseUri = "" ;
  string public hiddenTokenURI = "https://graffitimansionlabs.mypinata.cloud/ipfs/Qmf8xquZS1vqLNh43eU5UGKX2KupSKquopsRTn97TBW1PL";
  string public baseExtension = ".json";
  
  event MilestoneReachedStateChange(uint val, uint time);

  constructor() ERC721("WorldStar NFT Collection", "WSHH") {}

  // prevents Smart Contract Access
  modifier onlyEOA() {
    require(msg.sender == tx.origin, "Only EOA");
    _;
  }

  function addToWhitelist(address[] memory addresses, uint amount) public onlyOwner {
    for(uint256 i = 0; i < addresses.length; i++) {
      whitelist[addresses[i]] = amount;
    }
  }

  function mintSale(uint amount) external payable onlyEOA {
    require(saleOpen , "Sale not started yet");
    require(amount <= maxMintsPerTransaction, "amount out of bounds");
    require(totalSupply() + amount <= maxSupply - (reservedAmount - reservedMintedAlready), "max supply reached");
    require(msg.value == salePrice * amount, "sent incorrect price");
    _mintWorldstar(msg.sender, amount);
  }

  function mintPresale(uint amount) external onlyEOA {
    require(presaleOpen , "PreSale not started yet");
    require(totalSupply() + amount <= maxSupply - (reservedAmount - reservedMintedAlready), "max supply reached");
    require(whitelist[msg.sender] >= amount, "not enough whitelist balance");
    whitelist[msg.sender] -= amount;
    _mintWorldstar(msg.sender, amount);
  }

  function mintWithMintPass(uint[] memory mintPassIds) external payable onlyEOA {
    uint amount = mintPassIds.length;
    require(presaleOpen , "PreSale not started yet");
    require(totalSupply() + amount <= maxSupply - (reservedAmount - reservedMintedAlready), "max supply reached");
    for(uint i = 0; i < amount; i++){
      require(mintPass.ownerOf(mintPassIds[i]) == msg.sender, "mintpass Id not owned");
      require(!mintPassIdHasMinted[mintPassIds[i]], "mintpass id already minted");
    }
    require(msg.value == salePrice * amount, "sent incorrect price");
    for(uint j = 0; j < amount; j++){
      mintPassIdHasMinted[mintPassIds[j]] = true;
    }
    _mintWorldstar(msg.sender, amount);
  }

  function mintReserved(address receiver, uint amount) external onlyOwner {
    require(totalSupply() + amount <= maxSupply, "max reached");
    require(reservedMintedAlready + amount <= reservedAmount, "reserved max reached");
    reservedMintedAlready += amount;
    _mintWorldstar(receiver, amount);
  }

  function _mintWorldstar(address to, uint amount) private {
    for(uint i = 0; i < amount; i++){
      _mint(to, _tokenIds.current());
      _tokenIds.increment();
    }
  }

  function setBaseUri(string memory newBaseUri) external onlyOwner {
    baseUri = newBaseUri;
  }

  function setBaseExtension(string memory newBaseExtension) external onlyOwner {
    baseExtension = newBaseExtension;
  }

  function setMintPassAddress(address _mintpassAddress) external onlyOwner {
    mintPass = IERC721(_mintpassAddress);
  }

  function setT1Address(address _t1Address) external onlyOwner {
    t1 = _t1Address;
  }

  function setT2Address(address _t2Address) external onlyOwner {
    t2 = _t2Address;
  }

  function switchSaleState() external onlyOwner {
    saleOpen = !saleOpen;
  }

  function switchPresaleState() external onlyOwner {
    presaleOpen = !presaleOpen;
  }

  function switchRevealState() external onlyOwner {
    revealed = !revealed;
  }

  function switchMilestoneReachedState() external onlyOwner {
    emit MilestoneReachedStateChange(address(this).balance, block.timestamp);
    milestoneReached = !milestoneReached;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory _tokenURI = "Token with that ID does not exist.";
    if (_exists(tokenId)){
      if(!revealed){
        _tokenURI = hiddenTokenURI;
      }
      else{
      _tokenURI = string(abi.encodePacked(baseUri, tokenId.toString(),  baseExtension));
      }
    }
    return _tokenURI;
  }
  
  function totalSupply() public view returns(uint){
    return _tokenIds.current();
  }

  function withdrawAll() external onlyOwner {
    if (milestoneReached){
      (bool d,) = payable(t1).call{value: address(this).balance * 50 / 100}("");
      require(d, "withdraw failed");
      (bool s,) = payable(t2).call{value: address(this).balance}("");
      require(s, "withdraw failed");
    }
    else {
      (bool d,) = payable(t1).call{value: address(this).balance}("");
      require(d, "withdraw failed");
    }
  }


}
