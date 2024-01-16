// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721Enumerable.sol";
import "./ERC20.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Tradeable.sol";

// Fisherman by Fishyx                                                                
// A free mint contract for those who are smart enough to follow clues

contract Fisherman is Context, ERC721Tradeable {
  using SafeMath for uint256;
  using SafeMath for int256;
  using Counters for Counters.Counter;

  address payable payableAddress;
  constructor(address _proxyRegistryAddress) ERC721Tradeable("Fisherman", "FISHMAN", _proxyRegistryAddress) {
    _baseTokenURI = "ipfs://bafybeihrmbtiqjqy5nin3w4ykwtibhqy4yc3gbn2e2wyb4wuq6ajtv27ge/";
    payableAddress = payable(0x3D0C3CEa111D03B6F675E1392707907fAa622ea6);
  }


    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     */
    function mint(
        uint256 amount
    ) public virtual payable {
        _mintValidate(amount, _msgSender(), false);
        _safeMintTo(_msgSender(), amount, 0);
    }

    function mintTo(address _to) public onlyOwner {
        _mintValidate(1, _to, true);
        _safeMintTo(_to, 1, 0);
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
      _baseTokenURI = uri;
    }

    function _safeMintTo(
        address to,
        uint256 amount,
        uint256 forcedTokenId // this is useful only for the airdrop scenario
    ) internal {
      uint256 startTokenId = _nextTokenId.current();
      require(SafeMath.sub(startTokenId, 1) + amount <= MAX_SUPPLY, "sold out");
      require(to != address(0), "mint to the zero address");
      
      _beforeTokenTransfers(address(0), to, startTokenId, amount);
      if (forcedTokenId > 0) {
        require(amount == 1, "forcedTokenId can only be used for _safeMintTo with 1 token");
        _mint(to, forcedTokenId);
      } else {
        for(uint256 i; i < amount; i++) {
          uint256 tokenId = _nextTokenId.current();
          _nextTokenId.increment();
          _mint(to, tokenId);
        }
      }
      _afterTokenTransfers(address(0), to, startTokenId, amount);
    }

    function airdrop(uint256[] memory tokenIds, address[] memory recipients) public onlyOwner {
      require(tokenIds.length == recipients.length, "errrr on airdrop, not validate");
      //require(_nextTokenId.current() + tokenIds.length == (tokenIds[0] + tokenIds.length - 1), "tokenIds must be sequential and match the internal counter");
      for(uint256 i; i < tokenIds.length; i++) {
        _safeMintTo(recipients[i], 1, tokenIds[i]);
      }
    }

    function _mintValidate(uint256 amount, address to, bool isTeamMint) internal virtual {
      require(hasFishyx(), "you need to have fishyx to mint");
      require(amount != 0, "quantity is invalid, valid quantities are 1");
      if (!isTeamMint && balanceOf(to) + amount >= maxFreePerAcc()) {
        int256 freeAllowed = int256(maxFreePerAcc()) - int256(balanceOf(to));
        if(freeAllowed > 0) {
          require(int256(msg.value) >= (int256(amount) - freeAllowed) * int256(mintPriceInWei()), "incorrect value sent");
        } else {
          require(msg.value >= SafeMath.mul(amount, mintPriceInWei()), "incorrect value sent");
        }
      }
      require((isTeamMint || amount <= MAX_PER_TX), string.concat("max amount per transaction is ", Strings.toString(MAX_PER_TX)));
      require((isTeamMint || balanceOf(to) + amount <= MAX_PER_WALLET), "cannot mint more than 10 tokens per wallet");
      require(isSaleActive() == true, "sale not active");
    }

    function hasFishyx() public view returns (bool) {
      uint256 fishyx = Fishyx(fishyx).balanceOf(msg.sender);
      return fishyx > 0;
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Pauses all token transfers.
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

    function isSaleActive() public view returns (bool) {
        return _isActive;
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
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
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
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
      return "ipfs://bafkreibcjjc5gyggkatk6gfdyleuc5xfztvmej27dl2qn52njncv2wncra";
    }

    function withdraw() public onlyOwner  {
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

abstract contract Fishyx {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
}