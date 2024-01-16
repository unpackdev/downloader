// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract FAT is
  ERC721A,
  Ownable,
  ReentrancyGuard
{
  using Strings for uint256;
  using Counters for Counters.Counter;

  bytes32 private wlroot;
  bytes32 private ogroot;

  address proxyRegistryAddress;

  uint256 public totalMaxSupply = 10000;
  uint256 private wlMintSupply = 7500;
  uint256 private publicMintSupply = 9500;

  uint256 teamMintAmount = 303;
  uint256 publicMintAmount = 5;
  uint256 wlMintAmount = 2;
  uint256 ogMintAmount = 1;

  bool public paused = true;
  bool public revealed = false;
  bool public wlMintState = false;
  bool public publicMintState = false;
  bool public ogMintState = false;

  uint256 publicMprice = 69000000000000000; // 0.069 ETH
  uint256 WLMprice = 42000000000000000; // 0.042 ETH
  uint256 ogMprice = 0; // 0.00 ETH

  string public baseURI;
  string public notRevealedUri =
    'https://fatguysnft.mypinata.cloud/ipfs/QmeUbu1KhuTPeFe2jEDw9wuo6rgrg9qiUTxiuBks2q794A/UNREVEALED.json';
  string public baseExtension = '.json';

  mapping(address => uint256) public _wlClaimed;
  mapping(address => uint256) public _ogClaimed;
  mapping(address => uint256) public _publicClaimed;

  Counters.Counter private _tokenIds;

  constructor(
    string memory uri,
    bytes32 wlMerkleroot,
    bytes32 ogMerkleroot,
    address _proxyRegistryAddress
  )
    ERC721A('FAT', 'FAT')
    ReentrancyGuard() // A modifier that can prevent reentrancy during certain functions
  {
    wlroot = wlMerkleroot;
    ogroot = ogMerkleroot;
    proxyRegistryAddress = _proxyRegistryAddress;

    setBaseURI(uri);

    _safeMint(msg.sender, teamMintAmount);
    for(uint i = 0; i < teamMintAmount; i++)
    {
      _tokenIds.increment();
    }
  }

  function setPublicMintPrice(uint256 _newPublicPrice) public onlyOwner {
    publicMprice = _newPublicPrice;
  }

  function setWlMintPrice(uint _newWlPrice) public onlyOwner {
    WLMprice = _newWlPrice;
  }

  function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
    baseURI = _tokenBaseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

    function setMerkleRoot(bytes32 wlMerkleroot) public onlyOwner {
    wlroot = wlMerkleroot;
  }

  function srtOgRoot(bytes32 ogMerkleroot) public onlyOwner {
    ogroot = ogMerkleroot;
  }

  modifier onlyAccounts() {
    require(msg.sender == tx.origin, 'Not allowed origin');
    _;
  }

  modifier isValidMerkleProof(bytes32[] calldata _proof) {
    require(
      MerkleProof.verify(
        _proof,
        wlroot,
        keccak256(abi.encodePacked(msg.sender))
      ) == true,
      'Not allowed origin'
    );
    _;
  }

  modifier isValidOgProof(bytes32[] calldata _proof) {
    require(
      MerkleProof.verify(
        _proof,
        ogroot,
        keccak256(abi.encodePacked(msg.sender))
      ) == true,
      'Not allowed origin'
    );
    _;
  }

  function reveal() public onlyOwner {
    revealed = true;
  }

  function togglePause() public onlyOwner {
    paused = !paused;
  }

  function toggleOG() public onlyOwner {
    ogMintState = !ogMintState;
  }

  function toggleWL() public onlyOwner {
    wlMintState = !wlMintState;
  }

  function togglePublicMint() public onlyOwner {
    publicMintState = !publicMintState;
  }

  function ogMint(
    address account,
    uint256 _amount,
    bytes32[] calldata _proof
  ) external payable isValidOgProof(_proof) onlyAccounts nonReentrant {
    require(msg.sender == account, 'FAT: Not allowed');
    require(ogMintState, 'FAT: OG Mint is OFF');
    require(!paused, 'FAT: Contract is paused');
    require(
      _amount <= ogMintAmount,
      "FAT: You can't mint so much tokens"
    );
    require(
      _ogClaimed[msg.sender] + _amount <= ogMintAmount,
      "FAT: You can't mint so much tokens"
    );

    uint256 current = _tokenIds.current();

    require(current + _amount <= totalMaxSupply, 'FAT: max supply exceeded');
    require(ogMprice * _amount <= msg.value, 'FAT: Not enough ethers sent');

    _ogClaimed[msg.sender] += _amount;

    _safeMint(msg.sender, _amount);
    for(uint i = 0; i < _amount; i++)
    {
      _tokenIds.increment();
    }
  }

  function whitelistMint(
    address account,
    uint256 _amount,
    bytes32[] calldata _proof
  ) external payable isValidMerkleProof(_proof) onlyAccounts nonReentrant {
    require(msg.sender == account, 'FAT: Not allowed');
    require(wlMintState, 'FAT: WL Mint is OFF');
    require(!paused, 'FAT: Contract is paused');
    require(
      _amount <= wlMintAmount,
      "FAT: You can't mint so much tokens"
    );
    require(
      _wlClaimed[msg.sender] + _amount <= wlMintAmount,
      "FAT: You can't mint so much tokens"
    );

    uint256 current = _tokenIds.current();

    require(current + _amount <= wlMintSupply, 'FAT: max supply for wl mint exceeded');
    require(WLMprice * _amount <= msg.value, 'FAT: Not enough ethers sent');

    _wlClaimed[msg.sender] += _amount;

    _safeMint(msg.sender, _amount);
    for(uint i = 0; i < _amount; i++)
    {
      _tokenIds.increment();
    }
  }
  
  function publicMint(uint256 _amount) external payable onlyAccounts nonReentrant {
    require(publicMintState, 'FAT: Public Mint is OFF');
    require(!paused, 'FAT: Contract is paused');
    require(_amount > 0, 'FAT: zero amount');
    require(
      _amount <= publicMintAmount, 
      "FAT: You can't mint so much tokens"
      );

    require(
      _publicClaimed[msg.sender] + _amount <= publicMintAmount,
      "FAT: You can't mint so much tokens"
    );

    uint256 current = _tokenIds.current();

    require(current + _amount <= publicMintSupply, 'FAT: Max supply for public mint exceeded');
    require(publicMprice * _amount <= msg.value, 'FAT: Not enough ethers sent');

    _publicClaimed[msg.sender] += _amount;

    _safeMint(msg.sender, _amount);
    for(uint i = 0; i < _amount; i++)
    {
      _tokenIds.increment();
    }
  }

  function totalSupply() public view override returns (uint) {
        return _tokenIds.current();
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
      'ERC721Metadata: URI query for nonexistent token'
    );
    if (revealed == false) {
      return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();

    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
        )
        : '';
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
  
  function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
  {
    
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }
}

/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy {

}

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}


