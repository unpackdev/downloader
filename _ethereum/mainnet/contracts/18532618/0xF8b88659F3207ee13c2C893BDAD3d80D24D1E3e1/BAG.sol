// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

error SaleNotActive();
error SoldOut();
error MaxPerTransactionExceeded();
error AlreadyMintedDuringPresale();

contract BoredApeGulf is ERC721A, Ownable, ReentrancyGuard {
  
  bool public presaleActive;
  uint256 public apePerTransaction = 1;
  uint256 public constant SUPPLY = 4998;
  string public baseURI;
  mapping (address => uint256) public presaleClaimAmount;

  constructor(address initialOwner) Ownable(initialOwner) ERC721A("Bored Ape Gulf", "BAG") {}

  /* ADMIN FUNCTIONS */
  
  function togglePresale() external onlyOwner {
    presaleActive = !presaleActive;
  }

   function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

  function setBaseUri(string memory _uri) external onlyOwner {
    baseURI = _uri;
  }

  function adminMint(address wallet, uint256 count) external onlyOwner {
    if (SUPPLY < (totalSupply() + count)) revert SoldOut();

    _mint(wallet, count);
  }
  /* END ADMIN FUNCTIONS */

    function presaleMint(uint256 count) payable public {
    if (!presaleActive) revert SaleNotActive();
    if (SUPPLY < (totalSupply() + count)) revert SoldOut();
    if (count > apePerTransaction) revert MaxPerTransactionExceeded();
    if (presaleClaimAmount[msg.sender] + count > apePerTransaction) revert AlreadyMintedDuringPresale();

    presaleClaimAmount[msg.sender] += count;
    _mint(msg.sender, count);
  }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }   
}