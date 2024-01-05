pragma solidity ^0.5.0;

import "./ERC721Tradable.sol";
import "./Ownable.sol";

/**
 * @title Tokstory token
 * Tokstory - a contract for my non-fungible collectibles.
 * Website: Tokstory.com
 */
contract Tokstory is TradeableERC721Token {
  constructor(address _proxyRegistryAddress, string memory token_name, string memory token_symbol) TradeableERC721Token(token_name, token_symbol, _proxyRegistryAddress) public {  }

  function baseTokenURI() public view returns (string memory) {
    return "https://api.tokstory.com/tokens/attributes/";
  }
}