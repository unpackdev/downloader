// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Delegated is Ownable{

  mapping(address => bool) internal _delegates;

  constructor(){
    _delegates[owner()] = true;
  }

  modifier onlyDelegates {
    require(_delegates[msg.sender], "You are not a delegate." );
    _;
  }
  
  function isDelegate( address addr ) public view returns ( bool ){
    return _delegates[addr];
  }

  function setDelegate( address addr, bool isDelegate_ ) external onlyOwner{
    _delegates[addr] = isDelegate_;
  }
  
}

contract NFT is ERC721Enumerable, Delegated, ReentrancyGuard {

  using Strings for uint256;

  string public baseURI = "https://gateway.pinata.cloud/ipfs/QmSweC6n7kYSJUJ56Jq9SjJKW37q57up8Ji79q6YLv9Qga/";
  string public baseExtension = ".json";

  bool public paused = false;

  uint256 public maxSupply = 69;
  uint256 public whiteListSupply = 66;
  uint256 public mintPrice = 0.1 ether;
  uint256 public maxPerMintCount = 1;
  uint256 public whitelistMinted = 0;

  address public unlimitedWallet = 0xf0E05cDB482DceAF3b93De1De78E34B94Cc3944b; 
  address public withdrawWallet = 0x4F03ad78F76F102ff876F0d51aE72E00c4f8c761;

  mapping(address => bool) public whitelisted;
  address[] initialWhitelist;

  constructor() ERC721("Monstarz NFT Kings of the court", "MOG") {
    initialWhitelist = [ 
      0x6371f346D89CAa1AB6FE97A49F6b4307Ac560b20,
      0x275E60123C050206a6AC693f8A78c770eE6Ef023,
      0x01572C56d38405D1ebc0F4b88600aE5Be370598f,
      0x9f7CBc32bFf2e72AB85c471c879dCFC349B49577,
      0x942dB6CC8BeBF69fc6aFd0b0c4fD94F6ea6aE748,
      0x6027d8675a138834F73eA95346D8D73a763c21A8,
      0x970B3c158b535d266795BB5B441041F33969c783,
      0xC50740Ef03F40091c201a2AF5e482C286d3b6B3a,
      0x4A2b9659A70429DEc862C1d0Fbb7A3325FEaF8eD,
      0x7e86E0A6bEB34dC51aA57327Bfe00d138F5d6D2B,
      0xaA1Bb5241f596BD65bA20DA8814004a84B1b6b58,
      0xAF7Dd1bd24eAd3C2D7706768F032C872EA1059DF,
      0x996fba69dB40776c1b8Aa5B18412a403F0169971,
      0xcF228F5C880C2173efa10079E28e78Eb38Ec5dD5,
      0xfbdb2751B2550A5Cbc525c8f2f6B98D56faf2779,
      0x983BA77495FCB0eC288EB23EE79Bd3Aa308e9210,
      0x97AbB268ccb8DD156C7a720FaD8F3286B19F7f19,
      0xe47fCB5C702a513a6a93D50090eD449316e2067a,
      0xACc9A522f923768D9da53Ac442a533d62fa1fe7B,
      0x9625457A4EC3178C137ee52cEF45f785A83D3c86,
      0xf668e86B27D7eE2cfA7bE97Fc63D3e61171b8a0f,
      0x90bC65459C1e71020cafefa7476AAb707E9130dC,
      0x0FCe396F947348310434a70cF628D11D39317496,
      0xafff3eF09e2ed09759dC9f6f74Ed600b9caA7eEF,
      0x3D3292D9142c9194de2e1FC7ea8f1Ac51c01e408,
      0xaA610109F60daF66800C0feaD7b8f76960d86Ce4,
      0x35b1ba1bb3458844D56262735C311Cd68c7E63f1,
      0x9b1795830a7de5535ed6449C459e0456e402F668,
      0x970B3c158b535d266795BB5B441041F33969c783,
      0xA65eFB88748c70aC6FeB97b459df7FbD36D4D41E,
      0xA2b9917E497DB6116664b946aE42fC8C4cD550a2,
      0xBE5CB77deb343D3308b3bF225Da97BeD8854a3b3,
      0x7135De8F279dC563d26eDafc65EC78a8FbA9EDAF,
      0x69AfC5cE15D954ea37c76EcFB92a87C5cD5BcC05,
      0x335f64De2F6B52afDFeDa0eB9bCaEeC22D23afa4,
      0xe7b9fc15c3e40Ac46827A46Be78C41C6D6B3B492,
      0xB7E0669a6d78a8A343074bF2C0D29258D950d7E8,
      0x6744AC367Ba5F3bf3e9Fc32FB6fa0d721A1EA98a,
      0x996fba69dB40776c1b8Aa5B18412a403F0169971,
      0x550349c5D1033314cfDe1BA1d6Bf7b10Bd1d75bf,
      0x91c0290Fd9a43F721a2144Fb9Cdc1D73a425abB2,
      0x78dd78eBAB94a0D96c1d901caACfd9bC9eF9b1f8,
      0x974D71Ed96bb363dACce8785ef25Eb084F29eD81,
      0x01967dbcB4774f4e5D4e19FB9a8FDAA3189345F6,
      0x689fA9fFaCa202bf36D2ec071f7bF110c711cae2,
      0x5EC8de9bdee1f106DfB15668AB1dbDfdC4E8402c,
      0xC46BCc76e4bE53a2E8b805B2e10d32c6d51cA7F5,
      0xd1A7d9864204451afE737970DfC294f5957c783d,
      0x83870202A0746FB275466463D76152B40399063A,
      0xfCe5c85E7d2C7388fe6F7b32611416133A076adC,
      0xc23bff6cF496e78C59cf0ec99C37D0263e670153,
      0xabcF94Eac0f1607B63CE4905E6e29c82E23DbF1C,
      0x9F17a161ce864B651bfc4B86f8041E2C160c9Eff,
      0x2D2D96ca525a209a8944c6B84F7f1fbAA99a4f3A,
      0x4E7AF72c1c6266f50F92AE441952274885048A58,
      0xC24813F98f706C341A08cCc4F87431E10173AaF5,
      0x14D4c369B7792EE9A1BeaDa5eb8D25555aD246BF,
      0x21C57925070826e9D3Cf22684A80e5C006d7aD3B,
      0x87055f573a6787cFe52d851EFB87C5D604F4D2c2,
      0xA5A4d249D7237b48F38F48339C7Bf377dF12380b,
      0xDAC9abA52f81F2d990380A524F2949eD7C5d327d,
      0x4be4dc98Ec8ecC290076D985005dfa7C4b923cdf,
      0x0A51a3821Bd44f86bbD5F641b9920EB11Be277d6,
      0xa1dA072ac08DF7697b54718c1511F92438a17a3b,
      0x50f11D13475739F9E888D38528405A992A5f2E6f,
      0xaC08C1b08430aA3976D6d26E837cd4955e3530aA
    ];
	  whitelistUser(initialWhitelist);
  }
  
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
    
  function mint(address _to, uint _mintCount) public payable {
    require(!paused, "NFT mint is paused.");
    uint256 supply = totalSupply();

    if ( msg.sender != owner()  || _to != unlimitedWallet) {
      require(msg.value >= mintPrice * _mintCount, "Not enough fees to mint.");
      
      if(supply < maxSupply )  {
        if(whitelisted[_to] == true) {
          whitelistMinted ++;
        }
      }
    }
    
    for (uint256 i = 1; i <= _mintCount; i++) {
      _safeMint(_to, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
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
      "ERC721Metadata: URI query for nonexistent NFT"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
  
  function setMaxSupply(uint256 _newSupply) public onlyDelegates() {
    maxSupply = _newSupply;
  }
  
  function setBaseURI(string memory _newBaseURI) public onlyDelegates {
    baseURI = _newBaseURI;
  }

  function withdraw() public payable onlyDelegates {
    require(payable(withdrawWallet).send(address(this).balance));
  }
  
  function pause(bool _state) public onlyDelegates {
    paused = _state;
  }

  function setUnlimitedWallet(address _user) public onlyDelegates {
    unlimitedWallet = _user;
  }

  function setWithdrawWallet(address _user) public onlyDelegates {
    withdrawWallet = _user;
  }
  
  function whitelistUser(address[] memory _user) public onlyDelegates {
    uint256 x = 0;
    whiteListSupply += _user.length;
    for (x = 0; x < _user.length; x++) {
        whitelisted[_user[x]] = true;
    }
  }
  
  function removeWhitelistUser(address[] memory _user) public onlyDelegates {
    uint256 x = 0;
    whiteListSupply -= _user.length;
    for (x = 0; x < _user.length; x++) {
        whitelisted[_user[x]] = false;
    }
  }
}