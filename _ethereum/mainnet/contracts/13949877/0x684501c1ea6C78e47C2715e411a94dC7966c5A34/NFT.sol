// SPDX-License-Identifier: GPL-3.0

/*Smart Contract by Simon Bindefeld-Boccara*/

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.021 ether;
  uint256 public maxSupply = 2100;
  uint256 public maxMintAmount = 2100; //5
  uint256 public nftPerAddressLimit = 2100; //3
  uint256 public wave2MaxMintAmt = 2100; //1
  uint256 public counter = 0;
  uint256 public limit = 2100; //300 for wave 1
  uint256 public mathP = 225; //
  uint256 public deuxP = 250; //
  uint256 public frkP = 0; //
  uint256 public sarP = 100;
  bool public paused = false;
  bool public revealed = true;
  bool public onlyWhitelisted = true;
  bool public wave2Auth = false;
  // address[] public whitelistedAddresses;
  address[] public pushWhitelist= [0xD2680f6d8d99c280D072267Cba46FCA35A00c3bf,
  0x0cFb325CbcA93Ff083e9FA3A0114d7933fa51B59,
  0x9cf74DD01F9a8d5c1d6a78168C9A21Be80501927,
  0x401fA49BeCDb0d9A0848a76dCF5DD3a6A7c59977,
  0x4ED182FCeD0C87b1884b047C4f2FC6c0EBcfd620,
  0x3c203B8c52D0890A29c4A1a63cC7a2C072f888f7,
  0xbAa069466de6B74A9DD9170d8D4E1220195a0803,
  0x14905045a31D76bc7E1ba26af02E86d0d8bC9ebD,
  0x2bE5e0F8D60872a2edC48F4178283966a79F2823,
  0xAB28df490e43a46d70b15f4e9F0A3DE945B1d052,
  0x6A825Dd17b463D4Af1D449a6018C60daD4B15329,
0x7dF569A54922420b14536e321591178E302dB78b,
0xcAf26285f5753C6735354866e32Ff76267acE7f0,
0xeae5Ae2604a75b75b4d007898A8da1971a0d771a,
0x901AEB4822D62e8B199abB0bBA5a1204dC6Ad1ba,
0x874B473E7c0FA6B3eee699Bf977efB1Bd62E6D86,
0xD28443397307482Cf549646b7501f5D748e9176a,
0x95ca490Ec807a89695b2842198Caecd7DdeFbaD7,
0xf93bDD043e97C0f7da55A229fA0eFEC341322429,
0x7639CB90BBa57B0B78Ed67466197e81A23B51317,
0x0C55Fd58626ceCdB36b780B79Bb4E2F2D2710962,
0xF5058135e987cf360326130f80816E753c61d911,
0xF0C87994045d4ab242855FC37850aA89aF9AD189,
0x7Fdb48732aB0f20E8aFaB50EcDd04ADC00242EE4,
0x6b3c0Ee24332d2b2fdb1C7Ab433F2Ae0d85dEfb2,
0xCccE2361d36e16f862b2ee0E239eb3431E3CabE1,
0xc3dE901344B9bC3386f1373A5A3DdF39CAbc0ee1,
0x0Db4C01003BD62da21Ac5e6A552dF414Ac5fcD19,
0xe27744Cb1e7d14a845518c762eFD9F2195CD295F,
0x992CA80B4920DDd6AE005D411B5Fa02677385955,
0x257aFa1217998Cc0Bf27F84d34FD788190d98cD2,
0xBB57552A3E6e6122576E794270Daf4351eA24D88,
0xfd412F5Ac28627E0DE39fF69eafA12434189b853,
0xdECed667e210dcCeb8a5221a56231a36930159f5,
0xAde891164705FECf6Cb5f3c02937B83360285433,
0xe0cAcb00103081A44C37e4Ff468233Ece8194986,
0x9C406FA5864Ef2547B37929aAeE4215A2A7F6c47,
0xBB7DFe9f835b1Ef12BA48E93fcF2Bd8B4782a7Bd,
0xFDf2CcFDF2FeFaEDc1BafD15Bca1CF5Ac5b3ba5A,
0x5F260c82e4ab61e499F0d6BCe65f67c2048900bc,
0xeB381B8Cf662326A1c29655805C94418aEE65E3c,
0x4A829329B2B27793398862BbB91f757D87c2eb09,
0xe95a426062e8DCB86F0Bde9F3803660DDADB464F,
0xF8D131c569Ded17b829CF4c2f328d8AfE9CdeeAE,
0xBe9D5e8BE4F06F1ceFE4ddA11a769E2835c2Db56,
0xbfB0FfA6cEa68F9468f4d6C0518bffB76F9d9a0e,
0xdA4F96AC1E2BCB5AC38d00C7Bf81CCA4c2a244D0,
0xF8B886Ee30f757286B9aBf018E6E0F57eb15c9E2,
0x0bD057d0FDf1F71e742cbb88622E890350FCfdcF,
0xe624c6682e624d16d9a1dceFf8201cd9CFB4605C,
0x608A03D50Ea8c0dbbfcF778E028afE91ac67C1F6,
0xC70c4c91126d4ace892eC247c9c2f0B360A01840,
0xe27e3E68A9fDfE53De232104B8038d7c81a7239C,
0x7e8a983CAf45Ae743c55685AFDBa26D4959Ba6d2,
0xF2a29bED0249dC9BE793ed83cc531da13EcA6Bc2,
0xb43248cF05D23E1cd8d5524D82B91d7448D83A22,
0x42131B83d8fAd17DeE4A374DECA92b0127F19Ca3,
0xaCd66dd31Eae2653982a2106D5123adD575BAeF2,
0xEb16E0928A1534cCE1AA19f645B384B94e3f8422,
0xa01d2DFb766aB7CBBCFa06ef2Fd80c7286cb622f,
0xae78694cFe6C69F54a50D1585D18B5F330859C0f,
0xf7bd9309D73D5dE6E584EF2712F55CeeFFadCF66,
0xED50A89bDfa62e4f5be627ca04B6B039a76f1c90,
0xFEf3100e9C83023DfC2c7c9a29C2CCb902cF5827,
0xad9Cb67d6c95a4B594438da20Aa94dA26059e041];


  mapping(address => uint256) public addressMintedBalance;
  mapping(address => uint256) public wave2Counter;
  // mapping(address =>bool) public whiteListMap;

//   address payable public payments;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
    // address _payments
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    // payments = payable(_payments);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    counter+=_mintAmount;

    require(counter <= limit, "The Current Minting Limit for this Wave has been reached");
    require(!paused, "the contract is paused");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(pushisWhitelisted(msg.sender), "user is not whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        }
        require(msg.value >= cost * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      if (wave2Auth == true)
      {
        wave2Counter[msg.sender]++;
        require(wave2Counter[msg.sender] <= wave2MaxMintAmt, "Exceeded Mint Allowance for Wave 2");
      }
      
      _safeMint(msg.sender, supply + i);
    }
    
  }
  

  function startWave2() public onlyOwner()
  {
    wave2Auth = true;
  }

  function shutOffWave2() public onlyOwner()
  {
    wave2Auth = false;
  }

  function saveWave2MintAmount(uint256 _newMax) public onlyOwner(){
    wave2MaxMintAmt = _newMax;
  }

  function setPayouts(uint256 newMath, uint256 newKiks, uint256 newFrk, uint256 newSarp) public onlyOwner() {
    mathP = newMath;
    deuxP = newKiks;
    frkP = newFrk;
    sarP = newSarp;

  }
  // function isWhitelisted(address _user) public view returns (bool) {
  //   for (uint i = 0; i < whitelistedAddresses.length; i++) {
  //     if (whitelistedAddresses[i] == _user) {
  //         return true;
  //     }
  //   }
  //   return false;
  // }

    function pushisWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < pushWhitelist.length; i++) {
      if (pushWhitelist[i] == _user) {
          return true;
      }
    }
    return false;
  }
  
  function refreshCounter() public onlyOwner()
  {
      counter = 0;
  }
  function setLimit(uint256 new_limit) public onlyOwner(){
    limit = new_limit;
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
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner() {
      revealed = true;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner() {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  // function whitelistUsers(address[] calldata _users) public onlyOwner {
  //   delete whitelistedAddresses;
  //   whitelistedAddresses = _users;
  // }

    function pushToWhitelist(address []calldata _users) public onlyOwner {
    for(uint256 i=0; i<_users.length;i++){
      pushWhitelist.push(_users[i]);
  }
  }




 
  function withdraw() public payable onlyOwner {

    (bool payment, ) = payable(msg.sender).call{value: address(this).balance}("");  //Le Rest
    require(payment);
    // (bool pay,) = payable(payments).call{value: address(this).balance}("");
    // require(pay);

  }
}