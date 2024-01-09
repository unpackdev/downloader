// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Popheads is ERC721, Ownable {
  constructor() ERC721("Popheads", "POP") {}

  string private uri = "https://assets.bossdrops.io/popheads/metadata/";
  bool public lockedSupply = false;
  uint public numMinted = 0;
  uint public startIndex;
  uint MAX_SUPPLY = 69;
  /**
   * Airdrop can only be called once and should be called with an array of MAX_SUPPLY addresses.
   */
  function airdrop(address[] memory addresses) public onlyOwner {
    require(!lockedSupply, "Supply is locked");
    require(addresses.length == MAX_SUPPLY, "addresses length must be MAX_SUPPLY");
    setRandomStartIndex();
    for (uint i = startIndex; i < MAX_SUPPLY; i++) {
      _mint(addresses[i], numMinted);
      numMinted++;
    }
    for (uint i = 0; i < startIndex; i++) {
      _mint(addresses[i], numMinted);
      numMinted++;
    }
    lockedSupply = true;
  }

  function setRandomStartIndex() private {
    startIndex = uint(uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % MAX_SUPPLY);
  }
  
  function setBaseURI(string memory baseURI) public onlyOwner {
    uri = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
  {
    return
        OpenSeaGasFreeListing.isApprovedForAll(owner, operator) ||
        super.isApprovedForAll(owner, operator);
  }
}


library OpenSeaGasFreeListing {
    /**
    @notice Returns whether the operator is an OpenSea proxy for the owner, thus
    allowing it to list without the token owner paying gas.
    @dev ERC{721,1155}.isApprovedForAll should be overriden to also check if
    this function returns true.
     */
    function isApprovedForAll(address owner, address operator)
        internal
        view
        returns (bool)
    {
        ProxyRegistry registry;
        assembly {
            switch chainid()
            case 1 {
                // mainnet
                registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 4 {
                // rinkeby
                registry := 0xf57b2c51ded3a29e6891aba85459d600256cf317
            }
        }

        return
            address(registry) != address(0) &&
            address(registry.proxies(owner)) == operator;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
