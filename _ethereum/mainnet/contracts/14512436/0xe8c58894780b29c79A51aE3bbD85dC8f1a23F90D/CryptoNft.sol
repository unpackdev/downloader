// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";



//solhint-disable-next-line no-empty-blocks
contract OwnableDelegateProxy {
}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract CryptoNft is ERC721Upgradeable, OwnableUpgradeable {
    
    mapping(address => bool) whitelistedAddresses;
    uint256 public constant TOTAL_PIECES = 1000;
    uint256 public totalMinted;
    string public uri;
    bool public preSale;

    address public proxyRegistryAddress;
    bool public isOpenSeaProxyActive;
    event SetURI(string _uri);

   
    function __CryptoNft_init(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) public initializer {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        setURI(_uri);
    }

   
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

   
    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    
    function activeOpenseaProxy(
        address _proxyRegistryAddress,
        bool _isOpenSeaProxyActive
    ) public onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    
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

   
    function setURI(string memory _uri) public onlyOwner {
        uri = _uri;

        emit SetURI(_uri);
    }

    function whitelistUser(address _addressToWhitelist) public onlyOwner {
      whitelistedAddresses[_addressToWhitelist] = true;
    }

    function verifyUser(address _whitelistedAddress) public view returns(bool) {
        bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
        return userIsWhitelisted;
    }

    function isPresale(bool _presale) public onlyOwner {
        preSale = _presale;
    }

      function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override{
        if(preSale == true){
            require(whitelistedAddresses[to], "You need to be whitelisted");
            require(balanceOf(to) <= 5 ,"Limit exceed, you already bought 5 NFTs");
            require(balanceOf(0xbC95A36bE7C66b33dfb65cc4c64Ae2c25c6C5aa7) >= 500 ,"Presale NFTs are sold");
            super._beforeTokenTransfer(_msgSender(), to, tokenId);
        }else{
            super._beforeTokenTransfer(_msgSender(), to, tokenId);
        }
    }

    function mint(address _to, uint256 startNft, uint256 endNft) external onlyOwner {
    //   uint256 length = _ids.length;
    //   require(totalMinted + length <= TOTAL_PIECES, "you are minting excess amount");
   
      for (uint256 i = startNft; i <= endNft; i++){
        _mint(_to, i);
        totalMinted += 1;
      }
    }
}
