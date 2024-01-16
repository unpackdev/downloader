// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721Enumerable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Base64.sol";
import "./Ownable.sol";
import "./ERC721Tradeable.sol";

contract ProjektID is Context, ERC721Tradeable {
  using SafeMath for uint256;
  using SafeMath for int256;
  using Counters for Counters.Counter;
  mapping (uint256 => uint256) batchMints;
  uint256 batchCount = 0;
  address payable payableAddress;
  string baseImageURI = "ipfs://bafybeibs3ckffrovxk2irbo2oznhxwoc7lbfk66w6anpfvlvfmurigjwtm";
  bool isRelevealed = false;
  
  constructor(address _proxyRegistryAddress) ERC721Tradeable("ProjektID", "ID", _proxyRegistryAddress) {
    _baseTokenURI = "ipfs://tbd/";
    payableAddress = payable(0x8B7F715c37e7c7638c8F33A381bFf30dc7C797F1);
  }

    function publicMint(
        uint256 amount
    ) public virtual payable {
        _mintValidate(amount, _msgSender(), false);
        _safeMintTo(_msgSender(), amount);
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
      //metadata
      string memory base = _baseTokenURI;
      uint256 packLen = batchMints[id];
      if(packLen > 0){
        return string.concat(
          string.concat(base, 
            string.concat(Strings.toString(id)), 
              string.concat("_", Strings.toString(packLen))),
          ".json");
      } else {
        return string.concat(
          string.concat(base, Strings.toString(id)),
          ".json");
      }

    }

    function totalSupply() public view returns (uint256) {
      return _nextTokenId.current() - 1;
    }

    function openPack(uint256 originTokenId) public {
      require(ownerOf(originTokenId) == _msgSender(), "Request is not from token owner");
      uint256 batchAmount = batchMints[originTokenId];
      require(batchAmount > 0, "Token is not a batch");
      for (uint256 i = originTokenId + 1; i <= batchAmount + 1; i++) {
        _mint(_msgSender(), i);
      }
      batchMints[originTokenId] = 0;
      batchCount = batchCount - batchAmount;
    }

    function devMint(
        uint256 amount,
        address to
    ) public virtual onlyOwner {
        _safeMintTo(to, amount);
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
      _baseTokenURI = uri;
    }

    function _remintTo(address _to, uint256 _tokenId) internal virtual {
      _mint(_to, _tokenId);
    }
    
    function _safeMintTo(
        address to,
        uint256 amount
    ) internal {
      uint256 startTokenId = _nextTokenId.current();
      require(SafeMath.sub(startTokenId, 1) + amount <= MAX_SUPPLY, "collection sold out");
      require(to != address(0), "cannot mint to the zero address");
      
      _beforeTokenTransfers(address(0), to, startTokenId, amount);
      
      // in order give more flexibility for the holders and lower gas fees
      // we will store a reference to a pack of tokens and mint only the pack representation
      // the holder can sell his pack on the secondary or later call openPack(...) that will mint all the packed tokens individually
      if(amount > 1) {
        batchMints[startTokenId] = amount;
        batchCount = batchCount + amount;
        for(uint256 i; i < amount; i++) {
          _nextTokenId.increment();
        }
        _mint(to, startTokenId);
      } else {
        _nextTokenId.increment();
        _mint(to, startTokenId);
      }
      _afterTokenTransfers(address(0), to, startTokenId, amount);
    }

    function _mintValidate(uint256 amount, address to, bool isAllowlist) internal virtual {
      require(amount > 0 && (amount == 1 || amount == 10 || amount == 20), "Valid quantities for minting are 1, 10 or 20");
      require(isSaleActive() == true, "sale non-active");
      uint256 balance = balanceOf(to);
      if (balance + amount > maxFree()) {
        int256 free = int256(maxFree()) - int256(balance);
        if(isAllowlist && free > 0) {
          require(int256(msg.value) >= (int256(amount) - free) * int256(mintPriceInWei()), "incorrect value sent");
        } else {
          require(msg.value >= SafeMath.mul(amount, mintPriceInWei()), "incorrect value sent");
        }
      }
      require(amount <= maxMintPerTx(), "quantity is invalid, max reached on tx");
      require(balance + amount <= maxMintPerWallet(), "quantity is invalid, max reached on wallet");
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    function setPublicSale(bool toggle) public virtual onlyOwner {
        _isActive = toggle;
    }

    function isSaleActive() public view returns (bool) {
        return _isActive;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Tradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721)
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public pure returns (string memory) {
      return "ipfs://bafkreifpsbj6deycynleko4numy2ukz4tvv3mmgxchoyfsfdunbnye7aqi";
    }


    function withdraw() public onlyOwner {
      (bool success, ) = payableAddress.call{value: address(this).balance}('');
      require(success);
    }

    function maxSupply() public view virtual returns (uint256) {
        return MAX_SUPPLY;
    }

    function maxMintPerTx() public view virtual returns (uint256) {
        return MAX_PER_TX;
    }

    function maxMintPerWallet() public view virtual returns (uint256) {
        return MAX_PER_WALLET;
    }
}
