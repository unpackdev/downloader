// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./AccessControl.sol";
import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ERC721Enumerable, ContextMixin, NativeMetaTransaction, Ownable, AccessControl{
    using SafeMath for uint256;
    using Strings for string;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  address proxyRegistryAddress;
    uint256 private _currentTokenId = 349;
    uint256 private _currentReservedTokenId = 19;
    uint256 TOTAL_SUPPLY = 7777;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
      proxyRegistryAddress = _proxyRegistryAddress;
      _initializeEIP712(_name);
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _setupRole(MINTER_ROLE, _msgSender());
      _setupRole(BURNER_ROLE, _msgSender());
    }

  function reserveMint(address _to, uint256 _quantity, uint256 _startTokenId) public {
    for (uint256 i = _startTokenId; i < _startTokenId+_quantity; i++) {
      _mint(_to, i);
    }
  }

  function dipMint(address _to) public {
    require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
    uint256 newTokenId = _getNextReservedTokenId();
    assert(newTokenId < 350);
    _mint(_to, newTokenId);
    _incrementReservedTokenId();
  }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public {
      require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
      uint256 newTokenId = _getNextTokenId();
      assert(newTokenId < TOTAL_SUPPLY);
      _mint(_to, newTokenId);
      _incrementTokenId();
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
  function _getNextReservedTokenId() private view returns (uint256) {
    return _currentReservedTokenId.add(1);
  }

  function getCurrentReservedTokenId() public view returns (uint256) {
    return _currentReservedTokenId;
  }

  function _incrementReservedTokenId() private {
    _currentReservedTokenId++;
  }

    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    function getCurrentTokenId() public view returns (uint256) {
      return _currentTokenId;
    }
  /**
 * @dev increments the value of _currentTokenId
 */
  function _incrementTokenId() private {
    _currentTokenId++;
  }


  function burn(uint256 tokenId) public virtual {
      //solhint-disable-next-line max-line-length
      require(hasRole(BURNER_ROLE, _msgSender()), "ERC721Burnable: caller is not owner nor approved");
      _burn(tokenId);
    }

    function baseTokenURI() virtual public pure returns (string memory);

    function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    function transferOwnership(address newOwner) override public onlyOwner {
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

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
