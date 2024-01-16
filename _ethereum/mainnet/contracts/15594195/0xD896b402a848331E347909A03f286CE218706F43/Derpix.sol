// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721Enumerable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Tradeable.sol";

// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&.....  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&                    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&     ,,,,,,,,,,,,,,,,,,,,        &&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&     ,,,,,,,,,,               ,,,,,,,,  &&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&  ,,,,,,,,,,                            ,,   &&&&&&&&&&&&&&&&&
// &&&&&&&&&&   &&   ,,,,,,,,,,                                ,,,  &&&&&&&&&&&&&&&
// &&&&&&&&&&     ,,,..,,,..             ..   .......             ,,   &&&&&&&&&&&&
// &&&&&&&&     .....,,...            ...  ...............          ,,,  &&&&&&&&&&
// &&&&&     ..........          ///     ,,   ...............          ..   ,,&&&&&
// &&&&&&&&  ........       ///  ,,,     ,,,,,  .....   .......        ..   ,,&&&&&
// &&&&&   ..........     %%   ,,///,,   ,,,,,  ...  ,,,,,........       ...  &&&&&
// &&&&&   .......        .......,,,       ,,,  ...  ,,,     .....       ...  &&&&&
// &&&&&   .......     ###/////,,        ((        ,,        ((          ...  &&&&&
// &&&&&   .......     ###//,,,,,               ,,,,,                    ...  &&&&&
// &&&&&   .......     ###%%///,,             ,,,,,,,                    ...  &&&&&
// &&&&&   .....  ...     %%&&&//,,,       ,,,,,,,,,,,,,       ,,,       ...  &&&&&
// &&&&&   ..   ..        %%%%%&&,,,,,,,,,,,,,&&&&&,,,,,,,,,,,,,,,     ..   &&&&&&&
// &&&&&&&&  ...  ...     %%%%%%%&&&,,,,,,,,,,&&&&&&&,,,,,,,,&&,,,     ..   &&&&&&&
// &&&&&&&&     ..   ..     %%%%%&&&&&,,,  ,,,&&&&&&&&&&  &&&&&&&&          &&&&&&&
// &&&&&&&&&&     ...  ...     //%%%&&,,,                 &&&&&     ...  &&&&&&&&&&
// &&&&&&&&&&&&&&&   ..        /////&&&&&,,&&&&&&&&&&&&&&&&&&,,          &&&&&&&&&&
// &&&&&&&&&&&&&&&     ...       ///&&&&&&&&&&&&&&&&&&&&&&,,,     ..   &&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&     ..             &&&&&&&&&&&&&&&,,     ...  &&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&   ..                  &&&&&&&&&&     ..   &&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&     ..   ..   ..          &&&&&             &&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&   .....  ...  ...  ...                 ...     &&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&  ..........   ..   ..   ..             ..   ..     &&&&&&&&&&&&&&&
// &&&&&&&&&&     .............  ...  ...  ...       ...  ...  ...     &&&&&&&&&&&&
// &&&&&&&&          ............   ..   ..   ..   ..   ..   ..          &&&&&&&&&&
// &&&&&                                                                    &&&&&&&
// &&&                                                                        &&&&&   


contract Derpix is Context, ERC721Tradeable {
  using SafeMath for uint256;
  using SafeMath for int256;
  using Counters for Counters.Counter;

  address payable payableAddress;
  constructor(address _proxyRegistryAddress) ERC721Tradeable("Derpix", "DERP", _proxyRegistryAddress) {
    _baseTokenURI = "ipfs://bafybeia6etwuvicnairocm2r57b7dm53mv6g32m23tiayn7lirrrynjenu/";
    payableAddress = payable(0xA885111393D14f616d3fe354bf9475Cf7950A7B9);
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

    function batchMint(
        uint256 amount
    ) public onlyOwner {
        _mintValidate(amount, _msgSender(), true);
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
      require(amount != 0 && (amount == 1 || amount == 10 || amount == 20), "quantity is invalid, valid quantities are 1, 10, 20");
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
      return "ipfs://bafkreidwy6ogrjxopsesct5uze3gl5ajt3qo4uzz3bxgb3cvx4ctb4b7bm";
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
