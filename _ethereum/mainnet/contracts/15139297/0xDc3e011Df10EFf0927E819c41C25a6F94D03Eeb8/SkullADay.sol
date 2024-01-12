// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract SkullADay is ERC721URIStorage, Ownable, ReentrancyGuard {
  uint256 public mintPrice = 0.1 ether;
  uint256 public totalSupply;
  uint256 public maxSupply;
  bool public isMintEnabled;

  receive() external payable {}
  uint256 public MAX_WALLET_LIMIT = 3;

  string private ipfsMetadataHash;
  address payable private _treasuryAddress;

  // fill this in!!
  address payable _SkullTreasuryAddress =
    payable(0xA7B3E098C65C5E79d8Fa82d5040d49532C428833);

  mapping(address => uint256) public mintedWallets;

  constructor() payable ERC721('Skull a Day', 'SKULLADAY') {
    maxSupply = 366;
  }

  function toggleIsMintEnabled() external onlyOwner {
    isMintEnabled = !isMintEnabled;
  }

  function setMaxSupply(uint256 maxSupply_) external onlyOwner {
    maxSupply = maxSupply_;
  }

  /**
   * @notice See {ERC721-baseURI}.
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return 'ipfs://bafybeielyggl4daqz2ex42thnsai7boorbicr5p5vcxmgxe6fttieiasxy';
  }

  function mint(uint256 _amount) external payable nonReentrant {
    require(isMintEnabled, 'minting not enabled');
    require(
      mintedWallets[msg.sender] < MAX_WALLET_LIMIT,
      'exceeds max per wallet'
    );
    require(msg.value == mintPrice*_amount, 'wrong value');
    require(maxSupply > totalSupply, 'sold out');

    string memory tokenURI;
    uint256 _tokenId;

    for (uint256 i; i < _amount; i++) {
      mintedWallets[msg.sender]++;
      totalSupply++;
      _tokenId = totalSupply;
      tokenURI = string(
        abi.encodePacked(ipfsMetadataHash, '/', Strings.toString(_tokenId))
      );
      _safeMint(msg.sender, _tokenId);
      _setTokenURI(_tokenId, tokenURI);
    }
  }

   /**
   * @notice Withdraws funds from contract.
   */
  function withdrawFunds() external onlyOwner {
      uint256 balance = address(this).balance;
      payable(_SkullTreasuryAddress).transfer(balance);
  }

  /**
   * @notice See {IERC2981-royaltyInfo}.
   */
  function royaltyInfo(
    uint256, /* _tokenId */
    uint256 _salePrice
  ) external view returns (address, uint256 royaltyAmount) {
    royaltyAmount = (_salePrice * 10) / 100;
    return (_SkullTreasuryAddress, royaltyAmount);
  }
}
