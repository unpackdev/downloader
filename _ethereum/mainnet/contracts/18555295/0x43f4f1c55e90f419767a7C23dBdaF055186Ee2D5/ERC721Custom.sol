// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./Strings.sol";

//
// ███████╗ ██████╗ ██╗  ██╗███████╗███████╗███████╗
// ██╔════╝██╔═══██╗╚██╗██╔╝╚══███╔╝╚══███╔╝██╔════╝
// ███████╗██║   ██║ ╚███╔╝   ███╔╝   ███╔╝ ███████╗
// ╚════██║██║   ██║ ██╔██╗  ███╔╝   ███╔╝  ╚════██║
// ███████║╚██████╔╝██╔╝ ██╗███████╗███████╗███████║
// ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
//
//        ██████╗ ██╗██████╗     ██╗████████╗
//        ██╔══██╗██║██╔══██╗    ██║╚══██╔══╝
//        ██║  ██║██║██║  ██║    ██║   ██║
//        ██║  ██║██║██║  ██║    ██║   ██║
//        ██████╔╝██║██████╔╝    ██║   ██║
//        ╚═════╝ ╚═╝╚═════╝     ╚═╝   ╚═╝
//            I'm only the dev no rage
//

contract ERC721Custom is ERC721A, Ownable, ReentrancyGuard, ERC2981 {
  using Strings for uint256;

  uint256 public maxSupply;
  uint256 public mintPrice;
  uint256 public whitelistMintPrice;

  string public baseURI;
  bytes32 public merkleRoot;

  bool public mintStarted = false;
  bool public revealed = false;
  bool public airdropDone = false;
  bool public whitelistDone = false;

  uint256 public devSplit = 4;
  uint256 public artistSplit = 31;
  uint256 public thirdPartySplit = 30;

  address public devAddress = 0xEfF5ffD4659b9FaB41c2371B775d37F00b287CCf;
  address public artistAddress = 0x82210FbEd5336cb60Bc23e27703713a2D10136Cf;
  address public thirdPartyAddress = 0x079B52077621b101294Baeefa87bCc3bdCcfEd55;

  mapping(address => uint256) public whitelistClaimed;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _baseURI,
    address _admin,
    bytes32 _merkleRoot,
    uint256 _mintPrice,
    uint256 _whitelistMintPrice,
    uint256 _maxSupply,
    uint96 feeNumerator
   ) ERC721A(_tokenName, _tokenSymbol) {
    transferOwnership(_admin);
    baseURI = _baseURI;
    merkleRoot = _merkleRoot;
    mintPrice = _mintPrice;
    whitelistMintPrice = _whitelistMintPrice;
    maxSupply = _maxSupply;
    _setDefaultRoyalty(_admin, feeNumerator);
  }

  modifier whitelistMintCompliance(address to, bytes32[] calldata _merkleProof, uint256 amount) {
    require(airdropDone, "Airdrop not done");
    require(mintStarted, "Mint not started");
    require(!whitelistDone, "Whitelist mint ended");
    require(totalSupply() + amount <= maxSupply, "Can't mint more than 555 Clones Evolution");
    require(totalSupply() + amount <= 125, "Can't mint more than 100 Clones Evolution in whitelist");
    require(amount <= 2, "Can't get more than 2 Clones in whitelist");
    require(checkMerkleProof(to, _merkleProof), "You are not whitelisted");
    require(whitelistClaimed[to] < 2, "Can't get more than 2 Clones in whitelist");
    require(msg.value >= whitelistMintPrice * amount, "You can't pay less than 0.015 ETH by Clone");
    _;
  }

  modifier mintCompliance(address to, uint256 amount) {
    require(mintStarted, "Mint not started");
    require(whitelistDone, "Whitelist mint not ended");
    require(totalSupply() + amount <= maxSupply, "Can't mint more than 555 Clones Evolution");
    require(amount <= 5, "Can't get more than 5 Clones");
    require(msg.value >= mintPrice * amount, "You can't pay less than 0.035 ETH by Clone");
    _;
  }

  function airdropMint(address _to) public onlyOwner {
    require(!airdropDone, "Airdrop already minted");
    require(totalSupply() == 0, "Can't airdrop when mint already started");
    airdropDone = true;
    mintStarted = true;
    _mint(_to, 25);
  }

  function whitelistMint(bytes32[] calldata _merkleProof, uint256 amount) public payable whitelistMintCompliance(_msgSender(), _merkleProof, amount) {
    whitelistClaimed[_msgSender()] += amount;
    _mint(_msgSender(), amount);
  }

  function mint(uint256 amount) public payable mintCompliance(_msgSender(), amount) {
    _mint(_msgSender(), amount);
  }

  function setWhitelistDone() public onlyOwner {
    require(airdropDone, "You need to complete airdrop first");
    require(!whitelistDone, "You can't close whitelist mint twice");
    whitelistDone = true;
  }

  function baseTokenURI() public view returns (string memory) {
    return baseURI;
  }

  function checkMerkleProof(address to, bytes32[] calldata _merkleProof) public view returns(bool) {
    bytes32 leaf = keccak256(abi.encodePacked(to));
    if (MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
      return true;
    }
    return false;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override(ERC721A)
    returns (string memory)
  {
    if (!revealed) {
      return baseTokenURI();
    }
    return string(abi.encodePacked(baseTokenURI(), _tokenId.toString(), '.json'));
  }

  function reveal(string memory _revealURI) public onlyOwner {
    require(!revealed, "Collection already revealed");
    baseURI = _revealURI;
    revealed = true;
  }

  function pauseMint() public onlyOwner {
    require(mintStarted, "Mint not started");
    mintStarted = false;
  }

  function startMint() public onlyOwner {
    require(!mintStarted, "Mint already started");
    mintStarted = true;
  }

  function withdrawFund(address to) public onlyOwner nonReentrant {
    require(address(this).balance > 0, "Shit nothing to take here, bad marketing mb !");

    uint256 devShare = address(this).balance * devSplit / 100;
    uint256 artistShare = address(this).balance * artistSplit / 100;
    uint256 thirdPartyShare = address(this).balance * thirdPartySplit / 100;

    (bool payDev, ) = payable(devAddress).call{value: devShare }('');
    require(payDev);
    (bool payArtist, ) = payable(artistAddress).call{value: artistShare }('');
    require(payArtist);
    (bool payThirdParty, ) = payable(thirdPartyAddress).call{value: thirdPartyShare }('');
    require(payThirdParty);
    (bool payTeam, ) = payable(to).call{value: address(this).balance}('');
    require(payTeam);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
      _setDefaultRoyalty(_receiver, _feeNumerator);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}