// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

contract RecreatedMfers is ERC721Enumerable, Ownable, ReentrancyGuard {
    event Royalties(uint256 indexed received);

    address payable public clientWallet;
    address payable public qtWallet;
    uint256 public maxSupply = 555;
    uint256 public price = 0.08 ether;
    uint256 public royalties;
    uint256 public minted;
    uint8 public maxBatch = 5;
    
    string public baseURI;
    string _name = 'recreated mfers';
    string _symbol = 'ai mfers';
    mapping(address => uint8) public tokenPerWallet;

    constructor(address payable _qtWallet, address payable _client, string memory _uri) ERC721(_name, _symbol) {
      clientWallet =_client;
      qtWallet = _qtWallet;
      baseURI = _uri;
    }

    receive() payable external {
      royalties += msg.value;
      emit Royalties(royalties);
    }
    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function _canMint(uint8 batch) view internal {
      require(batch <= maxBatch && batch > 0, "Batch between 1 to 5");
      require(minted + batch<= maxSupply, "Sold Out");
      require(msg.value == price * batch, "Wrong value");
      require(tokenPerWallet[_msgSender()] < maxBatch && tokenPerWallet[_msgSender()] + batch <= maxBatch, "Maximum 5 nfts per wallet");
    }

    function mint(uint8 batch) payable external {
      _canMint(batch);
      tokenPerWallet[_msgSender()] += batch;
      for (uint256 index = 0; index < batch; index++) {
        _mint(_msgSender(), minted);
        ++minted;
      }
    }

    function walletDistro() external nonReentrant {
      if (royalties > 0) {
        uint old = royalties;
        royalties = 0;
        Address.sendValue(clientWallet, old * 95 / 100);
        Address.sendValue(qtWallet, old * 5 / 100);
      }
      uint256 contractBalance = address(this).balance;
      if (contractBalance > 0) {  
        Address.sendValue(clientWallet, contractBalance * 75 / 100);
        Address.sendValue(qtWallet, contractBalance * 25 / 100);
      }
    }
    function changeWallet(address payable _clientWallet) external onlyOwner {
      clientWallet = _clientWallet;
    }

    function changeQTWallet(address payable _qtWallet) external {
      require(_msgSender() == qtWallet, "Not from QT tech");
      qtWallet = _qtWallet;
    }
    
    function walletInventory(address _owner) external view returns (uint256[] memory) {
      uint256 tokenCount = balanceOf(_owner);
      uint256[] memory tokensId = new uint256[](tokenCount);
      for (uint256 i = 0; i < tokenCount; i++) {
          tokensId[i] = tokenOfOwnerByIndex(_owner, i);
      }
      return tokensId;
    }

    function burn(uint256 tokenId) external {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
}