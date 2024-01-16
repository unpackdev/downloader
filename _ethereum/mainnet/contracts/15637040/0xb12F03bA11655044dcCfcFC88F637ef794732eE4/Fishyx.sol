// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721Enumerable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Tradeable.sol";                                                              

//         _,;_;/-",_
//      ,")  (  ((O) "  .`,
//    ,` (    )  ;  -.,/;`}
//  ,"  o    (  ( (  . -_-.
// `.  ;      ;  ) ) \`; \;
//   `., )   (  ( _-`   \,'
//      "`'-,,`.jb
// Keep swimming, you may find something valuable

contract Fishyx is Context, ERC721Tradeable {
  using SafeMath for uint256;
  using SafeMath for int256;
  address payable payableAddress;
  using Counters for Counters.Counter;

  constructor(address _proxyRegistryAddress) ERC721Tradeable("Fishyx", "FISH", _proxyRegistryAddress) {
    _baseTokenURI = "ipfs://bafybeic4ekfqxvo4emnbxtsz7ibe55pbino7qhk4tb73g3h7xe5bwpf2ii/";
    payableAddress = payable(0x3D0C3CEa111D03B6F675E1392707907fAa622ea6);
  }

     /**
     * This method is used to mint Fishyx, if you're also looking to mint the Fisherman, keep swimming
     *
     * See {ERC1155-_mint}.
     *
     */
    function mint(
        uint256 amount
    ) public virtual payable {
        _mintValidate(amount, _msgSender());
        _safeMintTo(_msgSender(), amount);
    }

    function teamMint(
        uint256 amount,
        address to
    ) public virtual onlyOwner {
        _safeMintTo(to, amount);
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
      _baseTokenURI = uri;
    }

    function mintTo(address _to) public onlyOwner {
        _mintValidate(1, _to);
        _safeMintTo(_to, 1);
    }

    function _safeMintTo(
        address to,
        uint256 amount
    ) internal {
      uint256 startTokenId = _nextTokenId.current();
      require(SafeMath.sub(startTokenId, 1) + amount <= MAX_SUPPLY, "collection sold out");
      require(to != address(0), "cannot mint to the zero address");
      
      _beforeTokenTransfers(address(0), to, startTokenId, amount);
        for(uint256 i; i < amount; i++) {
          uint256 tokenId = _nextTokenId.current();
          _nextTokenId.increment();
          _mint(to, tokenId);
        }
      _afterTokenTransfers(address(0), to, startTokenId, amount);
    }

    function _mintValidate(uint256 amount, address to) internal virtual {
      require(amount != 0, "cannot mint 0");
      require(isSaleActive() == true, "sale non-active");
      uint256 balance = balanceOf(to);
      if (balance + amount >= maxFree()) {
        int256 free = int256(maxFree()) - int256(balance);
        if(free > 0) {
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

    /**
     * 販売状況の変更に使用
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function setPublicSale(bool toggle) public virtual onlyOwner {
        _isActive = toggle;
    }
    //[0xeb287ee15f40143a655f3643ec9dae62aa2857756fcfa1651e8dfa1ff290f3a1,0x9f7dc5a47ee6ea1087367c755567db95e15a397bc2ec7c66d9d7ffc8f5775d44,0x62ede0fee6fb5b91998c53b3077a38ccb7aa02d8027e178540de7c181ad1e716,0x997ebf26cc3d4e9d9fc249c8a066deba8e124bd29b69d6518128508030ff148d,0x3685b7f1cdd9418f5c553ac1e337a0b035308e9070e65bfe025883cf57fcc332,0xe9fc86e158d0c9734bdecf7d6884bcd58770155b4033b6935123ad8b3af3a0f8]
    //use this merkleproof fren

    function isSaleActive() public view returns (bool) {
        return _isActive;
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    // Call this function to know how to find a free Fisherman
    function whereIsTheFisherman() public view returns (string memory) {
        return fishermanLocation;
    }

    function setFishermanLocation(string memory location) public onlyOwner {
        fishermanLocation = location;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

     /**
     * オーバーライド isApprovedForAll を使用して、ユーザーの OpenSea プロキシ アカウントをホワイトリストに登録し、ガスレス リスティングを有効にします。
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public pure returns (string memory) {
      return "ipfs://bafkreidtytagxelcix3twiehr2vqo3ulnascebsip3d7a3qu76i7jzbvs4";
    }

    function payment() public onlyOwner  {
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
