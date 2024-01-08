// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./Strings.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract FracturedCells is Context, ERC721, Ownable {

  using Strings for uint256;

  /** public */
  string public __baseURI;
  uint256 public maxFracturedCells = 1500;
  uint256 public numFracturedCells;
  uint256 public maxAirdrop = 500;

  uint256 public price = 0.1 ether;

  uint256 public publicMintStartBlockNumber = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  address public t1Wallet;
  address public t2Wallet;

  /** event */
  event onFracturedCellCreated(uint256 tokenId);
  event onPublicMintStarted();

  constructor(string memory baseURI_, address t1Wallet_, address t2Wallet_) ERC721("Fractured Cells", "FRACTUREDCELLS") {
    require(t1Wallet_ != address(0), "team wallet cannot be zero address");
    require(t2Wallet_ != address(0), "team wallet cannot be zero address");
    __baseURI = baseURI_;
    t1Wallet = t1Wallet_;
    t2Wallet = t2Wallet_;
    numFracturedCells = 0;
  }

  /**
    * @dev override ERC721 _baseURI
    */
  function _baseURI() internal view virtual override returns (string memory) {
    return __baseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
  }

  function publicMintStarted() public view returns (bool) {
    return block.number >= publicMintStartBlockNumber;
  }

  function _create(address to, uint256 tokenId) internal {
    _safeMint(to, tokenId);
    emit onFracturedCellCreated(tokenId);
  }

  function create(uint256 qty) external payable {
    require (publicMintStarted(), "minting has not yet started");
    require (qty > 0 && qty <= 10, "quantity must be greater than 0 and no greater than 10");
    require (numFracturedCells < maxFracturedCells, "Fractured Cells minting has ended");
    require ((numFracturedCells + qty) <= maxFracturedCells, "quantity exceeds the number of Fractured Cells that remain");
    require (msg.value >= (price * qty), "value is too low");

    for (uint256 i = 0; i < qty; i++) {
      numFracturedCells += 1;
      uint256 tokenId = numFracturedCells;
      _create(_msgSender(), tokenId);
    }
  }

  /** team */

  modifier onlyTeam() {
    require((_msgSender() == t1Wallet || _msgSender() == t2Wallet), "caller does not belong to team");
    _;
  }

  /**
  * @dev team members can withdraw funds
  */
  function withdraw(uint256 _amount) external onlyTeam {
    uint256 t1Payment = (_amount / 100) * 80;
    require(payable(t1Wallet).send(t1Payment));
    require(payable(t2Wallet).send(_amount - t1Payment));
  }

  function withdrawAll() external payable onlyTeam {
    uint256 t1Payment = (address(this).balance / 100) * 80;
    require(payable(t1Wallet).send(t1Payment));
    require(payable(t2Wallet).send(address(this).balance));
  }

  function forwardERC20s(IERC20 _token, uint256 _amount, address target) external onlyOwner {
    _token.transfer(target, _amount);
  }

  /** owner */

  /**
    * @dev owner can set the block on which the public can begin minting
    */
  function setPublicMintStartBlockNumber(uint256 _publicMintStartBlockNumber) external onlyOwner {
    publicMintStartBlockNumber = _publicMintStartBlockNumber;
    emit onPublicMintStarted();
  }

  /**
    * @dev owner can modify __baseURI for reveal and maintainability
    */
  function setBaseURI(string calldata baseURI) external onlyOwner {
    __baseURI = baseURI;
  }

  /**
    * @dev owner can airdrop Fractured Cells before public minting begins
    */
  function airdrop(address[] calldata addresses) external onlyOwner {
    require (addresses.length > 0, "addresses required");
    require ((numFracturedCells + addresses.length) <= maxFracturedCells, "quantity exceeds the number of Fractured Cells that remain");
    require ((numFracturedCells + addresses.length) <= maxAirdrop, "quantity exceeds the number of Fractured Cells allocated for airdrop");

    for (uint256 i = 0; i < addresses.length; i++) {
      numFracturedCells += 1;
      uint256 tokenId = numFracturedCells;
      _create(addresses[i], tokenId);
    }
  }
}