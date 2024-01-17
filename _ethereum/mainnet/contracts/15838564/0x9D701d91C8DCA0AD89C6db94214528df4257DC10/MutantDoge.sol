// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC721.sol";
import "./ERC1155Holder.sol";
import "./ReentrancyGuard.sol";
import "./Serum.sol";
import "./Dogc.sol";

contract MutantDoge is ERC721, ERC1155Holder, Ownable, ReentrancyGuard {
  uint256 public m1Price = 0; // free mint by default
  uint256 public m2Price = 0; // free mint by default
  uint256 public megaPrice = 0; // free mint by default
  uint256 public m1MaxSupply = 10000;
  uint256 public m2MaxSupply = 10000;
  uint256 public megaMaxSupply;
  uint256 public constant M2_MUTATION_OFFSET = 20000;
  uint256 public constant MEGA_MUTATION_OFFSET = 30000;
  uint256 public m2TokenId = 20000;
  uint256 public megaTokenId = 30000;

  mapping(uint8 => bool) public mintState;

  uint256 public m1Supply;
  uint256 public m2Supply;

  DogeSerum public serum;
  Dogc public dogc;

  string public baseURI;
  event SetBaseURI(string indexed _baseURI);

  constructor(address _serum, address _dogc) ERC721("Mutant Doge", "MDOG") {
    serum = DogeSerum(_serum);
    dogc = Dogc(_dogc);
    mintState[serum.M1_SERUM()] = false;
    mintState[serum.M2_SERUM()] = false;
    mintState[serum.MEGA_SERUM()] = false;
  }

  function contractURI() public pure returns (string memory) {
    return "https://ipfs.filebase.io/ipfs/QmY1xSQyRiD8erkHDNjgMHrmKq9kpCnu9CYBK99sNXExrL";
  }

  function updateSerumAddress(address _serum) external onlyOwner {
    serum = DogeSerum(_serum);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155Receiver, ERC721)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function flipMintState(uint8 _serumType) external onlyOwner {
    mintState[_serumType] = !mintState[_serumType];
  }

  function mintM1(uint256 _tokenId) external payable nonReentrant {
    require(mintState[serum.M1_SERUM()], "Mint haven't started");
    require(msg.value >= m1Price, "Insufficient payment");
    require(m1Supply <= m1MaxSupply, "Sold out");
    require(
      serum.isApprovedForAll(msg.sender, address(this)),
      "Haven't approve"
    );
    require(dogc.ownerOf(_tokenId) == msg.sender, "Not own dogc with given id");

    _safeMint(msg.sender, _tokenId);
    m1Supply = m1Supply++;

    serum.burn(msg.sender, serum.M1_SERUM(), 1);
  }

  function mintM1Batch(uint256[] memory _tokenIds)
    external
    payable
    nonReentrant
  {
    require(mintState[serum.M1_SERUM()], "Mint haven't started");
    require(msg.value >= m1Price * _tokenIds.length, "Insufficient payment");
    require(m1Supply + _tokenIds.length <= m1MaxSupply, "Insufficient remains");
    require(
      serum.isApprovedForAll(msg.sender, address(this)),
      "Haven't approve"
    );

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      if (dogc.ownerOf(_tokenIds[i]) == msg.sender) {
        _safeMint(msg.sender, _tokenIds[i]);
        serum.burn(msg.sender, serum.M1_SERUM(), 1);
        m1Supply = m1Supply++;
      }
    }
  }

  function mintM2(uint256 _tokenId) external payable nonReentrant {
    require(mintState[serum.M2_SERUM()], "Mint haven't started");
    require(msg.value >= m2Price, "Insufficient payment");
    require(m2Supply <= m2MaxSupply, "Sold out");
    require(
      serum.isApprovedForAll(msg.sender, address(this)),
      "Haven't approve"
    );
    require(dogc.ownerOf(_tokenId) == msg.sender, "Not own dogc with given id");

    _safeMint(msg.sender, _tokenId);
    m2Supply = m2Supply++;

    serum.burn(msg.sender, serum.M2_SERUM(), 1);
  }

  function mintMega() external payable nonReentrant {
    require(mintState[serum.MEGA_SERUM()], "Mint haven't started");
    require(msg.value >= megaPrice, "Insufficient payment");
    require(m1Supply <= megaMaxSupply, "Sold out");
    require(
      serum.isApprovedForAll(msg.sender, address(this)),
      "Haven't approve"
    );

    _safeMint(msg.sender, megaTokenId);
    megaTokenId = megaTokenId++;

    serum.burn(msg.sender, serum.MEGA_SERUM(), 1);
  }

  function setBaseURI(string memory _baseuri) external onlyOwner {
    baseURI = _baseuri;
    emit SetBaseURI(baseURI);
  }

  function _baseURI()
    internal
    view
    virtual
    override(ERC721)
    returns (string memory)
  {
    return baseURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  // rescue
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawToken(address _tokenContract) external onlyOwner {
    IERC20 tokenContract = IERC20(_tokenContract);

    bool success = tokenContract.transfer(
      msg.sender,
      tokenContract.balanceOf(address(this))
    );
    require(success, "Transfer failed.");
  }
}
