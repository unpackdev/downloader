// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Counters.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";

//
//   ,-.          ,-.  ,------.       ,--.                                   ,--.
//  / .',--,--,--.'. \ |  .---',-----.|  |    ,---.  ,---.  ,---. ,--,--,  ,-|  |
// |  | |        | |  ||  `--, '-----'|  |   | .-. :| .-. || .-. :|      \' .-. |
// |  | |  |  |  | |  ||  `---.       |  '--.\   --.' '-' '\   --.|  ||  |\ `-' |
//  \ '.`--`--`--'.' / `------'       `-----' `----'.`-  /  `----'`--''--' `---'
//   `-'          `-'                               `---'
//
contract MeLegendGen1 is ERC721Enumerable, Ownable, PaymentSplitter {
  using Strings for uint256;
  using Counters for Counters.Counter;

  enum State {
    NoSale,
    PreSale,
    PublicSale,
    ClaimSale
  }

  uint256 public immutable maxMintSupply = 6000;
  uint256 public immutable maxClaimSupply = 888;
  uint256 public immutable maxSupply = 6888;

  State public state = State.NoSale;

  bytes32 public presaleRoot;
  uint256 public totalClaimed = 0;

  uint256 public presaleMintLimit = 3;
  uint256 public mintLimit = 5;

  ERC721Enumerable public genesisNFT;

  string public baseURI;

  mapping(address => uint256) public _presaleClaimed;
  mapping(uint256 => address) public _genesisClaimed;

  uint256 public immutable presaleMintPrice = 100000000000000000; //0.1 ETH
  uint256 public immutable publicMintPrice = 120000000000000000; //0.12 ETH

  Counters.Counter private _tokenIds;

  uint256[] private _teamShares = [50, 35, 80, 30, 20, 23, 15, 747];

  address[] private _team = [
    0x7b9174E8ca22d365dd874FADe5571FdfC5ae66A2,
    0x719AE202520A2E574dB2DD97dF2070d2449c63f1,
    0xCC52D2F235547dc2e08fbBE5e6111BEDE5810237,
    0xF6282045E32ddbC8425cDe8E1edC8479B4a40eaD,
    0x844a36Da63fbff8f1cdEb366ad883Cd0cD824780,
    0x486C2349F8Ec03cADBC0cf3C59B2CC022D46b5D4,
    0x9Ea60a19Fde50c9087C38b5b6D393Df1F5180cED,
    0x71699b347127883b7db6C5AffBA1F6526316CE32
  ];

  constructor(address _genesisNFT) ERC721("MELegend NFT gen1", "MLegNFT") PaymentSplitter(_team, _teamShares) {
    require(_genesisNFT != address(0), "genesis contract empty");
    genesisNFT = ERC721Enumerable(_genesisNFT);
    _mintNext(_msgSender());
  }

  function enablePresale(bytes32 _presaleRoot) public onlyOwner {
    state = State.PreSale;
    presaleRoot = _presaleRoot;
  }

  function enablePublic() public onlyOwner {
    state = State.PublicSale;
  }

  function enableClaiming() public onlyOwner {
    state = State.ClaimSale;
  }

  function disable() public onlyOwner {
    state = State.NoSale;
  }

  function setBaseURI(string calldata _tokenBaseURI) external onlyOwner {
    baseURI = _tokenBaseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "nonexistent token");
    string memory base = _baseURI();
    return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString(), ".json")) : "";
  }

  function presaleMint(uint256 _amount, bytes32[] memory proof) external payable {
    require(state == State.PreSale, "presale not enabled");

    // Amount check
    require(_amount > 0, "zero amount");
    require(_presaleClaimed[_msgSender()] + _amount <= presaleMintLimit, "can't mint such a amount");

    // Max supply check
    require(totalSupply() + _amount <= maxMintSupply, "max supply exceeded");

    // Sender value check
    require(msg.value >= presaleMintPrice * _amount, "value sent is not correct");

    // Merkleproof check
    require(verify(_msgSender(), proof), "not selected for the presale");

    for (uint256 ind = 0; ind < _amount; ind++) {
      _mintNext(_msgSender());
    }

    _presaleClaimed[_msgSender()] = _presaleClaimed[_msgSender()] + _amount;
  }

  function publicMint(uint256 _amount) external payable {
    require(state == State.PublicSale, "public sale not enabled");

    // Amount check
    require(_amount > 0, "zero amount");
    require(_amount <= mintLimit, "can't mint so much tokens");

    // Max supply check
    require(totalSupply() + _amount <= maxMintSupply, "max supply exceeded");

    // Sender value check
    require(msg.value >= publicMintPrice * _amount, "value sent is not correct");

    for (uint256 ind = 0; ind < _amount; ind++) {
      _mintNext(_msgSender());
    }
  }

  function claimMint() external payable {
    require(state == State.ClaimSale, "public sale not enabled");
    require(totalClaimed <= maxClaimSupply, "max claim supply exceeded");

    uint256 balance = genesisNFT.balanceOf(_msgSender());
    uint256 claimed = 0;

    for (uint256 i = 0; i < balance; i++) {
      uint256 tokenId = genesisNFT.tokenOfOwnerByIndex(_msgSender(), i);

      if (_genesisClaimed[tokenId] != address(0)) {
        continue;
      }

      _mintNext(_msgSender());
      _genesisClaimed[tokenId] = _msgSender();
      claimed++;
    }

    totalClaimed = totalClaimed + claimed;
  }

  function claimableAmount() public view returns (uint256, uint256) {
    uint256 balance = genesisNFT.balanceOf(_msgSender());
    uint256 claimed = 0;

    for (uint256 i = 0; i < balance; i++) {
      uint256 tokenId = genesisNFT.tokenOfOwnerByIndex(_msgSender(), i);
      if (_genesisClaimed[tokenId] == address(0)) {
        continue;
      }
      claimed++;
    }
    return (balance, claimed);
  }

  function _mintNext(address to) internal returns (uint256) {
    _tokenIds.increment();
    _safeMint(to, _tokenIds.current());
    return _tokenIds.current();
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function verify(address account, bytes32[] memory proof) internal view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(account));
    return MerkleProof.verify(proof, presaleRoot, leaf);
  }
}
