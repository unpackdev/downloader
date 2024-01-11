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
    PublicSale,
    ClaimSale
  }

  uint256 public immutable maxMintSupply = 6000;

  uint256 public immutable maxClaimSupply = 888;

  uint256 public immutable maxSupply = 6888;

  string public baseURI;

  uint256 public totalClaimed = 0;

  uint256 public mintPrice = 33000000000000000; //0.033 ETH

  State public state = State.NoSale;

  ERC721Enumerable public genesisNFT;

  mapping(uint256 => address) public _genesisClaimed;

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

  address public signer = address(0xeA9d695900700C209B1944a164d14189CeA4fEbf);

  constructor(address _genesisNFT) ERC721("MELegend NFT gen1", "MLegNFT") PaymentSplitter(_team, _teamShares) {
    require(_genesisNFT != address(0), "genesis contract empty");
    genesisNFT = ERC721Enumerable(_genesisNFT);

    _mintNext(signer);
    _transferOwnership(signer);
  }

  function setPrice(uint256 price) public onlyOwner {
    mintPrice = price;
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

  function publicMint(uint256 _amount) external payable {
    require(state == State.PublicSale, "public sale not enabled");

    // Amount check
    require(_amount > 0, "zero amount");
    require(_amount <= 10, "can't mint so much tokens");

    // Max supply check
    require(totalSupply() + _amount <= maxMintSupply, "max supply exceeded");

    // Sender value check
    require(msg.value >= mintPrice * _amount, "value sent is not correct");

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

  function gift(address[] calldata _addresses, uint16[] calldata _amounts) external onlyOwner {
    require(_addresses.length == _amounts.length, "no length match");

    for (uint256 ind = 0; ind < _addresses.length; ind++) {
      require(_addresses[ind] != address(0), "null address");
      require(_amounts[ind] != 0, "null amount");
      _giftSingle(_addresses[ind], _amounts[ind]);
    }
  }

  function _giftSingle(address _address, uint16 _amount) internal {
    require(_address != address(0), "null address");
    require(_amount != 0, "null amount");

    for (uint256 ind = 0; ind < _amount; ind++) {
      _mintNext(_address);
    }
  }

  function _mintNext(address to) internal returns (uint256) {
    _tokenIds.increment();
    _safeMint(to, _tokenIds.current());
    return _tokenIds.current();
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }
}
