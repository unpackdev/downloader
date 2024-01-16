// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";

contract FATGUYS is
  ERC721A,
  ERC721ABurnable,
  Ownable,
  ReentrancyGuard,
  PaymentSplitter
{
  using Strings for uint256;
  using Counters for Counters.Counter;

  bytes32 private wlroot;
  bytes32 private ogroot;

  address proxyRegistryAddress;

  uint256 public totalMaxSupply = 1000;
  uint256 public wlMintSupply = 305;
  uint256 public publicMintSupply = 310;


  string public baseURI;
  string public notRevealedUri =
    'https://fatguysnft.mypinata.cloud/ipfs/QmeUbu1KhuTPeFe2jEDw9wuo6rgrg9qiUTxiuBks2q794A/UNREVEALED.json';
  string public baseExtension = '.json';

  bool public paused = true;
  bool public revealed = false;
  bool public wlMintState = false;
  bool public publicMintState = false;
  bool public ogMintState = false;

  uint256 teamMintAmount = 300;
  uint256 wlMintAmount = 2;
  uint256 ogMintAmount = 1;

  mapping(address => uint256) public _presaleClaimed;
  mapping(address => uint256) public _ogClaimed;

  uint256 publicMprice = 15000000000000000; // 0.015 ETH
  uint256 WLMprice = 10000000000000000; // 0.01 ETH
  uint256 ogMprice = 0; // 0.00 ETH

  Counters.Counter private _tokenIds;

  uint256[] private _teamShares = [100];
  address[] private _team = [0x49Cb19d30a971834E55f3Ec29d2112F126d024bC];

  constructor(
    string memory uri,
    bytes32 wlMerkleroot,
    bytes32 ogMerkleroot,
    address _proxyRegistryAddress
  )
    ERC721A('FATGUYS', 'FGS')
    PaymentSplitter(_team, _teamShares) // Split the payment based on the teamshares percentages
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

  function burn(uint256 tokenId) public virtual override onlyOwner {
        _burn(tokenId, true);
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
    require(msg.sender == account, 'Not allowed');
    require(ogMintState, 'Presale is OFF');
    require(!paused, 'Contract is paused');
    require(
      _amount <= ogMintAmount,
      "You can't mint so much tokens"
    );
    require(
      _ogClaimed[msg.sender] + _amount <= ogMintAmount,
      "You can't mint so much tokens"
    );

    uint256 current = _tokenIds.current();

    require(current + _amount <= totalMaxSupply, 'max supply exceeded');
    require(ogMprice * _amount <= msg.value, 'Not enough ethers sent');

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
    require(msg.sender == account, 'Not allowed');
    require(wlMintState, 'WL Mint is OFF');
    require(!paused, 'Contract is paused');
    require(
      _amount <= wlMintAmount,
      "You can't mint so much tokens"
    );
    require(
      _presaleClaimed[msg.sender] + _amount <= wlMintAmount,
      "You can't mint so much tokens"
    );

    uint256 current = _tokenIds.current();

    require(current + _amount <= wlMintSupply, 'max supply for wl mint exceeded');
    require(WLMprice * _amount <= msg.value, 'Not enough ethers sent');

    _presaleClaimed[msg.sender] += _amount;

    _safeMint(msg.sender, _amount);
    for(uint i = 0; i < _amount; i++)
    {
      _tokenIds.increment();
    }
  }

  function publicMint(uint256 _amount) external payable onlyAccounts nonReentrant {
    require(publicMintState, 'Public Mint is OFF');
    require(!paused, 'Contract is paused');
    require(_amount > 0, 'zero amount');

    uint256 current = _tokenIds.current();

    require(current + _amount <= publicMintSupply, 'Max supply for public mint exceeded');
    require(publicMprice * _amount <= msg.value, 'Not enough ethers sent');

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
  
  function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
  {
    // Whitelist OpenSea proxy contract for easy trading.
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
