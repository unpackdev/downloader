/// ______ _   _ _____ _____ _   _     ___  ______ _____ _____
/// | ___ \ | | |_   _|_   _| \ | |   / _ \ | ___ \  ___/  ___|
/// | |_/ / | | | | |   | | |  \| |  / /_\ \| |_/ / |__ \ `--.
/// |  __/| | | | | |   | | | . ` |  |  _  ||  __/|  __| `--. \
/// | |   | |_| | | |  _| |_| |\  |  | | | || |   | |___/\__/ /
/// \_|    \___/  \_/  \___/\_| \_/  \_| |_/\_|   \____/\____/

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";

contract NFT is ERC721A, Ownable{
  using SafeMath for uint256;
  string public baseTokenURI;

  uint public constant MAX_SUPPLY = 2000;
  uint public constant PRICE = 0.039 ether;
  uint public constant MAX_PER_MINT = 20;

  constructor() ERC721A("Putin Apes", "PUTIN APES") {
    baseTokenURI = "";
  }

  /// @dev Returns an URI for a given token ID
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  /// @dev Sets the base token URI prefix.
  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner{
    baseTokenURI = _baseTokenURI;
  }

  function mint(uint256 quantity) external payable {
    require(quantity > 0, "Quantity cannot be zero");
    uint totalMinted = totalSupply();
    require(totalMinted.add(quantity) < MAX_SUPPLY, "Not enough NFTs left to mint");
    require(PRICE * quantity <= msg.value, "Insufficient funds sent");
    _safeMint(msg.sender, quantity);
  }

  function mintFree(uint256 quantity) external payable onlyOwner{
    require(quantity > 0, "Quantity cannot be zero");
    _safeMint(msg.sender, quantity);
  }

  function withdraw() public onlyOwner {
      uint balance = address(this).balance;
      payable(msg.sender).transfer(balance);
  }
}
