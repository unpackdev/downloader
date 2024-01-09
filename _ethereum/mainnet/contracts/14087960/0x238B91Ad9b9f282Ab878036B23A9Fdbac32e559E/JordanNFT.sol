// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";

/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/

//solhint-disable-next-line no-empty-blocks
contract OwnableDelegateProxy {

}

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract JordanNFT is ERC721Upgradeable, OwnableUpgradeable {
    uint256 public constant TOTAL_PIECES = 500;
    
    uint256 public totalMinted;
    string public uri;

    address public proxyRegistryAddress;
    bool public isOpenSeaProxyActive;
    event SetURI(string _uri);

    /**
     * @dev Upgradable initializer
     * @param _name Token name
     * @param _symbol Token symbol
     */
    function __JordanNFT_init(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) public initializer {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        setURI(_uri);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable)
        returns (bool)
    {
        return
            super.supportsInterface(_interfaceId);
    }

    /**
     * @dev Return of base uri
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    /**
     * @notice Active opensea proxy
     * @param _proxyRegistryAddress Address of opensea proxy
     * @param _isOpenSeaProxyActive Active opensea proxy by assigning true value
     */
    function activeOpenseaProxy(
        address _proxyRegistryAddress,
        bool _isOpenSeaProxyActive
    ) public onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     * @param _account Address of Owner
     * @param _operator Address of operator
     */
    function isApprovedForAll(address _account, address _operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(_account)) == _operator
        ) {
            return true;
        }

        return super.isApprovedForAll(_account, _operator);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * @param _uri String of uri
     */
    function setURI(string memory _uri) public onlyOwner {
        uri = _uri;

        emit SetURI(_uri);
    }

    function mint(address _to, uint256[] memory _ids) external onlyOwner {
      uint256 length = _ids.length;
      require(totalMinted + length <= TOTAL_PIECES, "you are minting excess amount");
   
      for (uint256 i = 0; i < length; i++){
        _mint(_to, _ids[i]);
        totalMinted += 1;
      }
    }
}
