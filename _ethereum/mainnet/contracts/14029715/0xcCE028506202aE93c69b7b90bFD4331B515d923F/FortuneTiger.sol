// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*

$$$$$$$$\                   $$\                                         $$$$$$$$\ $$\                                         
$$  _____|                  $$ |                                        \__$$  __|\__|                                        
$$ |    $$$$$$\   $$$$$$\ $$$$$$\   $$\   $$\ $$$$$$$\   $$$$$$\           $$ |   $$\  $$$$$$\   $$$$$$\   $$$$$$\   $$$$$$$\ 
$$$$$\ $$  __$$\ $$  __$$\\_$$  _|  $$ |  $$ |$$  __$$\ $$  __$$\          $$ |   $$ |$$  __$$\ $$  __$$\ $$  __$$\ $$  _____|
$$  __|$$ /  $$ |$$ |  \__| $$ |    $$ |  $$ |$$ |  $$ |$$$$$$$$ |         $$ |   $$ |$$ /  $$ |$$$$$$$$ |$$ |  \__|\$$$$$$\  
$$ |   $$ |  $$ |$$ |       $$ |$$\ $$ |  $$ |$$ |  $$ |$$   ____|         $$ |   $$ |$$ |  $$ |$$   ____|$$ |       \____$$\ 
$$ |   \$$$$$$  |$$ |       \$$$$  |\$$$$$$  |$$ |  $$ |\$$$$$$$\          $$ |   $$ |\$$$$$$$ |\$$$$$$$\ $$ |      $$$$$$$  |
\__|    \______/ \__|        \____/  \______/ \__|  \__| \_______|         \__|   \__| \____$$ | \_______|\__|      \_______/ 
                                                                                      $$\   $$ |                              
                                                                                      \$$$$$$  |                              
                                                                                       \______/                               

                        Fortune Tigers | 2022  | version 1.0 | ERC 721
*/

import "./ERC721.sol";
import "./Ownable.sol";

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract FortuneTigers is ERC721, Ownable {
  using Strings for uint256;

  uint256 public constant MAX = 388;
  uint256 public SALE_PRICE = 0.008 ether;
  uint256 public tokensMinted;
  string private _imgURI = "https://ipfs.io/ipfs/QmepFr4wZ7GkHkrsTvmHpFkg48wDKoe9ch4iAfKrUJ8Se1/";
  address public OSProxy;

  constructor(address _OSProxy) ERC721("Fortune Tigers 2022", "FORTUNE") {
    OSProxy = _OSProxy;
  }

  //**** Mint/Purchase functions ****//
  /**
   * @dev Mint function
   */
  function Buy(uint256 tokenQuantity) external payable {
    address wallet = msg.sender;
    uint256 tokenQty = tokenQuantity;
    uint256 totalMinted = tokensMinted;

    require(totalMinted + tokenQty <= MAX, "OUT_OF_STOCK");
    require(SALE_PRICE * tokenQty <= msg.value, "INSUFFICIENT_ETH");

    tokensMinted += tokenQty;

    for (uint256 i = 0; i < tokenQty; i++) {
      totalMinted++;
      _mint(wallet, totalMinted);
    }
    delete wallet;
    delete tokenQty;
    delete totalMinted;
  }

  /**
   * @dev giveaways
   */
  function giveaway(address[] calldata receivers) external onlyOwner {
    uint256 totalMinted = tokensMinted;
    uint256 giftAddresses = receivers.length;

    require(totalMinted + giftAddresses <= MAX, "OUT_OF_STOCK");

    tokensMinted += giftAddresses;

    for (uint256 i = 0; i < giftAddresses; i++) {
      totalMinted++;
      _mint(receivers[i], totalMinted);
    }
    delete giftAddresses;
    delete totalMinted;
  }

  //**** Owner functions ****//

  /**
   * @dev withdraw
   */
  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  /**
   * @dev set Image URI
   */
  function setImageURI(string calldata URI) external onlyOwner {
    _imgURI = URI;
  }

  /**
   * @dev set Sale Price
   */
  function setSalePrice(uint256 newPrice) external onlyOwner {
    SALE_PRICE = newPrice;
  }

  /**
   * @dev set OS Proxy address
   */
  function setOSProxy(address Proxy) external onlyOwner {
    OSProxy = Proxy;
  }

  //**** View functions ****//
  function contractURI() public pure returns (string memory) {
    string memory output;
    string memory contractmeta = base64(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Fortune Tigers 2022", "description": "A collection of 388 unique Fortune Tigers (Mint @ https://fortunetigers.win). Welcome the Year of the Tiger 2022 with your very own Fortune Tiger! Time to get Lucky with your personal fortune and lucky set of numbers!",   "image": "https://fortunetigers.win/images/preview.gif", "external_link": "https://fortunetigers.win"}'
          )
        )
      )
    );

    output = string(abi.encodePacked("data:application/json;base64,", contractmeta));
    return output;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), "Cannot query non-existent token");

    return string(abi.encodePacked("data:application/json;base64,", base64(bytes(tokenURIstring(tokenId)))));
  }

  function tokenURIstring(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "Cannot query non-existent token");


    string memory output = string(abi.encodePacked(_imgURI, tokenId.toString(), ".png"));
    string memory json = string(
      abi.encodePacked(
        '{"name": "Fortune Tiger #',
        tokenId.toString(),
        '", "description": "A collection of 388 unique Fortune Tigers (Mint @ https://fortunetigers.win). Welcome the Year of the Tiger 2022 with your very own Fortune Tiger! Time to get Lucky with your personal fortune and lucky set of numbers!", "image":"',
        output,
        '"}'
      )
    );
    return json;
  }

  /**
   * @dev totalSupply()
   */
  function totalSupply() public view virtual returns (uint256) {
    return tokensMinted;
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
   */
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(OSProxy);
    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }

  /** BASE 64 - Written by Brech Devos */

  string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function base64(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return "";

    // load the table into memory
    string memory table = TABLE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)

      // prepare the lookup table
      let tablePtr := add(table, 1)

      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))

      // result ptr, jump over length
      let resultPtr := add(result, 32)

      // run over the input, 3 bytes at a time
      for {

      } lt(dataPtr, endPtr) {

      } {
        dataPtr := add(dataPtr, 3)

        // read 3 bytes
        let input := mload(dataPtr)

        // write 4 characters
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }
}
