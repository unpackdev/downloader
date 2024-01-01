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
  uint256 public splitPercent = 10;
  uint256 public mintPrice;
  uint256 public maxMint = 5;
  string public baseURI;
  bytes32 public merkleRoot;

  bool public mintStarted = false;
  bool public revealed = false;
  bool public freemintDone = false;
  bool public lengendaryMinted = false;

  address public devAddress = 0x8668E2261d528964E3f7085DD16DE8dc3cbB2Cb1;

  event PermanentURI(string _value, uint256 indexed _id);

  mapping(address => bool) public freemintClaimed;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _baseURI,
    address _admin,
    bytes32 _merkleRoot,
    uint256 _mintPrice,
    uint256 _maxSupply,
    uint96 feeNumerator
   ) ERC721A(_tokenName, _tokenSymbol) {
    transferOwnership(_admin);
    baseURI = _baseURI;
    merkleRoot = _merkleRoot;
    mintPrice = _mintPrice;
    maxSupply = _maxSupply;
    _setDefaultRoyalty(_admin, feeNumerator);
  }

  modifier freemintCompliance(address to, bytes32[] calldata _merkleProof) {
    require(mintStarted, "Mint not started");
    require(!freemintDone, "Freemint has ended");
    require(totalSupply() + 1 <= maxSupply, "Can't mint more than 444 Skully");
    require(checkMerkleProof(to, _merkleProof), "It seems you are not whitelisted for a freemint");
    require(!freemintClaimed[to], "You already free minted one Skully");
    _;
  }

  modifier presaleCompliance(address to, bytes32[] calldata _merkleProof, uint256 amount) {
    require(mintStarted, "Mint not started");
    require(!freemintDone, "Freemint has ended");
    require(totalSupply() + amount <= maxSupply, "Can't mint more than 444 Skully");
    require(checkMerkleProof(to, _merkleProof), "It seems you are not whitelisted for a presale mint");
    require(freemintClaimed[to], "You have not minted your free one, mint it first it's free ;)");
    require(balanceOf(to) + amount <= maxMint, "It's 5 per wallet max");
    require(msg.value >= mintPrice * amount, "You can't pay less than mint price");
    _;
  }

  modifier publicmintCompliance(address to, uint256 amount) {
    require(mintStarted, "Mint not started");
    require(freemintDone, "Freemint has not ended");
    require(totalSupply() + amount <= maxSupply, "Can't mint more than 444 Skully");
    require(balanceOf(to) + amount <= maxMint, "It's 5 per wallet max");
    require(msg.value >= mintPrice * amount, "You can't pay less than mint price");
    _;
  }

  function freeMintCombo(bytes32[] calldata _merkleProof, uint256 amount) public payable {
    freeMint(_merkleProof);
    presaleMint(_merkleProof, amount);
  }

  function freeMint(bytes32[] calldata _merkleProof) public freemintCompliance(_msgSender(), _merkleProof) {
    freemintClaimed[_msgSender()] = true;
    _mint(_msgSender(), 1);
  }

  function presaleMint(bytes32[] calldata _merkleProof, uint256 amount) public payable presaleCompliance(_msgSender(), _merkleProof, amount) {
    _mint(_msgSender(), amount);
  }

  function mint(uint256 amount) public payable publicmintCompliance(_msgSender(), amount) {
    _mint(_msgSender(), amount);
  }

  function premintLegendary() public onlyOwner {
    require(!lengendaryMinted, "Legendary Skully are already minted");
    lengendaryMinted = true;
    _mint(_msgSender(), 3);
  }

  function startMint() public onlyOwner {
    require(!mintStarted, "Mint already started");
    mintStarted = true;
  }

  function pauseMint() public onlyOwner {
    require(mintStarted, "Mint not started");
    mintStarted = false;
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
      return string(abi.encodePacked(baseTokenURI()));
    }
    return string(abi.encodePacked(baseTokenURI(), _tokenId.toString(), '.json'));
  }

  function reveal(string memory _revealURI) public onlyOwner {
    require(!revealed, "Collection already revealed");
    baseURI = _revealURI;
    revealed = true;
  }

  function withdrawFund(address to) public onlyOwner nonReentrant {
    require(address(this).balance > 0, "Shit nothing to take here, bad marketing mb !");
    (bool hs, ) = payable(devAddress).call{value: address(this).balance * splitPercent / 100}('');
    require(hs);
    (bool os, ) = payable(to).call{value: address(this).balance}('');
    require(os);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setFreemintDone() public onlyOwner {
    require(!freemintDone, "Freemint already ended");
    freemintDone = true;
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