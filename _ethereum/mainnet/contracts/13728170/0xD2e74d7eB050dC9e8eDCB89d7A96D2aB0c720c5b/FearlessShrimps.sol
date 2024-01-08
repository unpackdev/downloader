// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract FearlessShrimps is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter public _totalSupply;

  address payable public treasury;
  address payable public developer;

  string public baseURI;
  string public notRevealedUri;

  uint256 public cost = 0.08 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintPerTxn = 20;
  uint256 public maxMintPerWallet = 20; 

  uint256 public presaleWindow = 24 hours;
  uint256 public presaleStartTime = 1638558000; // 1900 UTC 3rd December
  uint256 public publicSaleStartTime = 1638648000; //  2000 UTC 4th December

  bool public paused = false;
  bool public revealed = false;
  bool public presaleOpen = false;
  bool public publicSaleOpen = false;

  mapping(address => bool) public whitelistedAddresses;
  mapping(address => uint256) public addressToMintedAmount;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    address _treasury,
    address _developer
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    treasury = payable(_treasury);
    developer = payable(_developer);
  }

  // dev team mint
  function devMint(uint256 _mintAmount) public onlyOwner {
    require(!paused); // contract is not paused
    require(
      _totalSupply.current() + _mintAmount <= maxSupply,
      "RRC: total mint amount exceeded supply, try lowering amount"
    );
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _totalSupply.increment();
      _safeMint(msg.sender, _totalSupply.current());
    }
  }
  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function publicMint(uint256 _mintAmount) public payable {
    require(!paused);
    require(isPublicSaleOpen() || publicSaleOpen, "RRC: Public Sale is not open");
    require(_totalSupply.current() + _mintAmount <= maxSupply, "RRC: Total mint amount exceeded");
    require(_mintAmount > 0, "RRC: Please mint atleast one NFT");
    require(_mintAmount <= maxMintPerTxn, "RRC: You can only mint up to 20 per txn");
    require(msg.value == cost * _mintAmount,"RRC: not enough ether sent for mint amount");
    require(addressToMintedAmount[msg.sender]+ _mintAmount <= maxMintPerWallet, "RRC: Exceeded max mints allowed per wallet");

    (bool successT, ) = treasury.call{ value: (msg.value*91)/100 }(""); // forward amount to treasury wallet
    require(successT, "RRC: not able to forward msg value to treasury");

    (bool successD, ) = developer.call{ value: (msg.value*9)/100 }(""); // forward amount to developer wallet
    require(successD, "RRC: not able to forward msg value to developer");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _totalSupply.increment();
      addressToMintedAmount[msg.sender]++;
      _safeMint(msg.sender, _totalSupply.current()); 
    }
  }

  // presale
  function presaleMint(uint256 _mintAmount) public payable {
    require(!paused);
    require(whitelistedAddresses[msg.sender], "RRC: You are not whitelisted");
    require(isPresaleOpen() || presaleOpen, "RRC: Presale is not open");
    require(_mintAmount > 0, "RRC: Please mint atleast one NFT");
    require(_totalSupply.current() + _mintAmount <= maxSupply, "RRC: Total mint amount exceeded");
    require(_mintAmount <= maxMintPerTxn, "RRC: You can only mint up to 20 per txn");
    require(msg.value == cost * _mintAmount,"RRC: not enough ether sent for mint amount");
    require(addressToMintedAmount[msg.sender] + _mintAmount <= maxMintPerWallet, "RRC: Exceeded max mints allowed per wallet");

    (bool successT, ) = treasury.call{ value: (msg.value*91)/100 }(""); // forward amount to treasury wallet
    require(successT, "RRC: not able to forward msg value to treasury");

    (bool successD, ) = developer.call{ value: (msg.value*9)/100 }(""); // forward amount to developer wallet
    require(successD, "RRC: not able to forward msg value to developer");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _totalSupply.increment();
      addressToMintedAmount[msg.sender]++;
      _safeMint(msg.sender, _totalSupply.current());
    }
  }

  function airdrop(address[] memory giveawayList) public onlyOwner {
  require(!paused, "RRC: contract is paused");
  require(
    balanceOf(msg.sender) >= giveawayList.length,
    "RRC: not enough in wallet for airdrop amount"
  );

  uint256[] memory ownerWallet = walletOfOwner(msg.sender);

  for (uint256 i = 0; i < giveawayList.length; i++) {
    _safeTransfer(msg.sender, giveawayList[i], ownerWallet[i], "0x00");
  }
}

  function isPresaleOpen() public view returns (bool) {
    return
      block.timestamp >= presaleStartTime &&
      block.timestamp < (presaleStartTime + presaleWindow);
  }

  function isPublicSaleOpen() public view returns (bool) {
    return block.timestamp >= publicSaleStartTime;
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
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
        : "";
  }

  function burn(uint256 _tokenId) public {
    require(
      _isApprovedOrOwner(_msgSender(), _tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );
    _burn(_tokenId);
  }

  //*** OnlyOwner Functions ***//
  function reveal() public onlyOwner() {
      revealed = true;
  }

  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintPerWallet = _newmaxMintAmount;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }

  function whitelistUsers(address[] calldata _users) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      whitelistedAddresses[_users[i]] = true;
    }
  }

  function setPresaleOpen(bool _presaleOpen) public onlyOwner {
    presaleOpen = _presaleOpen;
  }

  function setPublicSaleOpen(bool _publicSaleOpen) public onlyOwner {
    publicSaleOpen = _publicSaleOpen;
  }

  function setPublicSaleStartTime(uint256 _publicSaleStartTime) public onlyOwner {
    publicSaleStartTime = _publicSaleStartTime;
  }

  function setPresaleStartTime(uint256 _presaleStartTime) public onlyOwner {
    presaleStartTime = _presaleStartTime;
  }

}
