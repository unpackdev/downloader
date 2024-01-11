/*
 ___________ _________________ _____ _   _  
|_   _| ___ \_   _| ___ \ ___ \_   _| \ | | 
  | | | |_/ / | | | |_/ / |_/ / | | |  \| | 
  | | |    /  | | |  __/|  __/  | | | . ` | 
  | | | |\ \ _| |_| |   | |    _| |_| |\  | 
  \_/ \_| \_|\___/\_|   \_|    \___/\_| \_/ 
                                            
                                            
 _____ ___________ _     _____ _   _  _____ 
|  __ \  _  | ___ \ |   |_   _| \ | |/  ___|
| |  \/ | | | |_/ / |     | | |  \| |\ `--. 
| | __| | | | ___ \ |     | | | . ` | `--. \
| |_\ \ \_/ / |_/ / |_____| |_| |\  |/\__/ /
 \____/\___/\____/\_____/\___/\_| \_/\____/ 
 
*/                                            

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC721A.sol";
import "./Ownable.sol";

contract TrippinGoblins is ERC721A, Ownable {
  string public baseURI;
  uint256 public constant maxSupply = 9999;
  uint256 public maxPerWallet = 1;
  bool public mintEnabled = false;

  mapping(address => uint256) private _walletMints;

  constructor() ERC721A("Trippin Goblins", "TRIPPINGOBLIN") {}
    
  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
      baseURI = baseURI_;
  }

  function mint(uint256 _amount) external payable {
    require(mintEnabled, "Goblins are sleepin...");
    require(_walletMints[_msgSender()] + _amount <= maxPerWallet, "Don't be a greedy goblin!");
    require(msg.sender == tx.origin, "who's dis?!");
    require(totalSupply() + _amount <= maxSupply, "aLL gObLiNs aRe gOnE byebyyy");

    _walletMints[_msgSender()] += _amount;
    _safeMint(msg.sender, _amount);
  }

  function mintForAddress(uint256 _amount, address _receiver) external onlyOwner {
    require(totalSupply() + _amount <= maxSupply, "enough for you, lord");
    _safeMint(_receiver, _amount);
  }

  function toggleMinting() external onlyOwner {
      mintEnabled = !mintEnabled;
  }

  function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
      maxPerWallet = _maxPerWallet;
  }
}