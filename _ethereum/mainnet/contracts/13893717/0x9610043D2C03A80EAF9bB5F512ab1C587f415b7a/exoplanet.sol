// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "ERC1155.sol";
import "Counters.sol";
import "Ownable.sol";
import "Strings.sol";

// For Rarible royalties; OpenSea royalties set manually in collection manager
library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account, uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// For OpenSea whitelisting
contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract AstronomicsExoplanets is ERC1155, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // New Marketplace royalty standard
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0x44c74bcc;

    string public LICENSE_TEXT = "GPLv2";
    uint256 public planetPrice = 0; // 0.0 ETH to start
    // uint256 public planetSetPrice = 300000000000000; // 0.0003 ETH
    uint256 public planetSetPrice = 100000000000000000; // 0.1 ETH
    uint96 public royaltyBPS = 700; // 7% royalty for Rarible/Mintable
    uint public constant maxPlanetPurchase = 5;
    // uint256 public constant MAX_PLANETS = 50;
    // uint256 public constant FREE_PLANETS = 20; // NOTE: remember to change site
    // uint256 public constant ALLOWED_PLANETS = 22;
    uint256 public constant MAX_PLANETS = 4000;
    uint256 public constant FREE_PLANETS = 100;
    uint256 public constant ALLOWED_PLANETS = 1000;
    bool public saleIsActive = false;
    bool public priceIsSet = false;
    string public name;
    string public symbol;
    string public prerevealURI = "https://gateway.pinata.cloud/ipfs/QmZPAsceAWvwWqMQHdCXSCNnwfVg4hQzGEXPkzcMn5CrQL";

    // For OpenSea gas free sale listing
    // address proxyRegistryAddress = 0xF57B2c51dED3A29e6891aba85459d600256Cf317; //rinkeby
    address proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1; //mainnet

    string public baseTokenURI;
    bool public baseTokenUriNotSet = true;

    // Not passing final URI yet
    constructor(string memory _name, string memory _symbol) ERC1155("") {
      name = _name;
      symbol = _symbol;
    }

    function toHex16 (bytes16 data) internal pure returns (bytes32 result) {
        result = bytes32(data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
                (bytes32(data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
        result = result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
                (result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
        result = result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
                (result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
        result = result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
                (result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
        result = (result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
                (result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
        result = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
                uint256(result) +
               (uint256(result) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
               0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 39);
    }

    function bytes32ToString (bytes32 data) public pure returns (string memory) {
        return string(abi.encodePacked(toHex16 (bytes16 (data)), toHex16(bytes16 (data << 128))));
    }

    // Override for custom uri
    function uri(uint256 _tokenId) override public view returns (string memory) {
      if (baseTokenUriNotSet) {
        // pre-reveal metadata
        return prerevealURI;
      }
      return string(abi.encodePacked(baseTokenURI, bytes32ToString(sha256(abi.encodePacked(Strings.toString(_tokenId)))), ".json"));
    }
    function setBaseTokenURI(string memory newuri) public onlyOwner {
      if (baseTokenUriNotSet) {
        baseTokenUriNotSet = !baseTokenUriNotSet;
      }
      baseTokenURI = newuri;
    }

    // Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(account)) == operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(account, operator);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokenIds.current();
    }

    // Returns balance of all tokens owned by address.
    function balanceOfPlanet(address account) public view virtual returns (uint256) {
        require(account != address(0), "No zero");
        uint256 balance = 0;
        for (uint256 i = 0; i < totalSupply(); ++i) {
            balance += balanceOf(account, i);
        }

        return balance;
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        require(owner != address(0), "No zero");

        uint256 tokenCount = 0;
        for (uint256 i = 0; i < totalSupply(); ++i) {
            tokenCount += balanceOf(owner, i);
        }

        // Needed tokenCount for fixed array size (memory array)
        uint256[] memory ids = new uint256[](tokenCount);
        uint256 j = 0;
        for (uint256 i = 0; i < totalSupply(); ++i) {
            if (1 == balanceOf(owner, i)) {
                ids[j] = i;
                j++;
            }
        }

        return ids;
    }

    // Minting method (supply = 1 for all tokens)
    function _mintNFTs(address account, uint256 numberOfTokens) internal virtual {
        if (numberOfTokens == 1) {
            _mint(account, totalSupply(), 1, "");
            _tokenIds.increment();
        } else {
            uint256[] memory ids = new uint256[](numberOfTokens);
            uint256[] memory amounts = new uint256[](numberOfTokens);
            for (uint256 i = 0; i < numberOfTokens; ++i) {
                ids[i] = totalSupply() + i;
                amounts[i] = 1; //only 1 per token, an NFT
            }
            _mintBatch(account, ids, amounts, "");

            // Update counters
            for (uint256 i = 0; i < numberOfTokens; ++i) {
                _tokenIds.increment();
            }
        }
    }

    function reservePlanets(address _to, uint _reserveAmount) public onlyOwner {
        require((totalSupply() + _reserveAmount) <= MAX_PLANETS, "Exceeds max. supply of planets");
        require(_reserveAmount > 0, "Must be positive number");

        if (((totalSupply() + _reserveAmount) >= FREE_PLANETS) && !priceIsSet) {
          planetPrice = planetSetPrice;
          priceIsSet = !priceIsSet;
        }

        _mintNFTs(_to, _reserveAmount);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // Returns the license for tokens
    function tokenLicense(uint _id) public view returns(string memory) {
        require(_id < totalSupply(), "Invalid Token");
        return LICENSE_TEXT;
    }

    // Change the mintPrice
    function setMintPrice(uint256 newPrice) public onlyOwner {
        require(newPrice != planetPrice, "Not new");
        planetPrice = newPrice;
    }

    // Change the royaltyBPS
    function setRoyaltyBPS(uint96 newRoyaltyBPS) public onlyOwner {
        require(newRoyaltyBPS != royaltyBPS, "Not new");
        royaltyBPS = newRoyaltyBPS;
    }

    function mintPlanets(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale Inactive");
        require(totalSupply() + numberOfTokens <= MAX_PLANETS, "Exceeds max. supply of planets");

        if (totalSupply() < FREE_PLANETS) {
          require(numberOfTokens == 1, "May only mint 1 free planet");
          require(msg.value == 0, "Check price");
          require(balanceOfPlanet(msg.sender) == 0, "Cannot mint free planet if you already own one");
        } else {
          require(numberOfTokens > 0 && numberOfTokens <= maxPlanetPurchase, "May only mint between 1 and 5 planets at a time");
          require(msg.value == planetPrice * numberOfTokens, "Check price");
          require((balanceOfPlanet(msg.sender) + numberOfTokens) <= ALLOWED_PLANETS, "Exceeds max. allowed planets per wallet in order to mint");
        }

        if (((totalSupply() + numberOfTokens) >= FREE_PLANETS) && !priceIsSet) {
          planetPrice = planetSetPrice;
          priceIsSet = !priceIsSet;
        }

        _mintNFTs(msg.sender, numberOfTokens);

    }

    // Rarible royalty interface new
    function getRaribleV2Royalties(uint256 /*id*/) external view returns (LibPart.Part[] memory) {
         LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = royaltyBPS;
        _royalties[0].account = payable(owner());
        return _royalties;
    }

    // Mintable/ERC2981 royalty handler
    function royaltyInfo(uint256 /*_tokenId*/, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
       return (owner(), (_salePrice * royaltyBPS)/10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        if(interfaceId == _INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if(interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}
