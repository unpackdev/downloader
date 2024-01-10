// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
*
* ╞██                                                                    ╫█▓
* ╞██                                                                    ║█▓
* ╞██         ,,,,,,__                               _,,▄╖╗╖╖,_          ║█▓
* [██      ╗▓████████▓▓φ,                         ╒Φ██████▀▀▀███▓╦       ║█▓
* [██    ╒███████▀^` `"▓██W_                   ,Æ██████Γ      '███▓_     ╫█▓
*  ██_  ╒███████        ║███▌                 ╣███████▓         ████     ██▌
*  ▓█▓  ████████        ╒████▓_             ╔██████████        [█████    ██
*  ║█▓  ████████▓┐_   ,á███████            ╔███████████▓╗╖,,┌╗▓██████   ╣█▓
*   ██▌ ███████████████████████▓          ╒██████████████████████████  ╒██
*   ║██ ╟███████████████████████╕         ▓█████████████████████████▓  ▓█▌
*    ██▌ ▓██████████████████████▓         ██████████████████████████  Å█▓
*    ╚██  █████▀╜╜███████████████        ▐████╨²╝██████████████████  /██
*     ▓█▓  ▀███    ██████████████         ███L   ║███████████████M  ┌██
*     `▓█▓  `▀█▓@Æ██████████████▓         ▀███▓@▓██████████████╜    ▓█`
*       ██▓    "▓█████████████▀`            '▀▓████████████▌┘      ▓█Γ
*        ▓█▌        `^^''`                _         ```          ╒██`
*         ╫█▓                  ▓▌╗,_ __,@██                     é█
*          ╘██w                 '╝▓███▓▀╜`                    ╒▓█^
*            ╫█▓w                                           ╒▓█M
*             `▀█▓┐                                      _╔▓█┘
*
* Thanks for checking out the Laika League smart contract!
* By eschewing whitelists, auctions, and other fancy stuff, we're able to deploy
* with an incredibly small and gas effective contract.
* It may not be perfect but I hope it is perfectly usable for our purpose and aids
* collectors in the cheapest mint we can reasonably achieve.
*
* Thank you to @nftchance, @masonnft, and @squeebo_nft
* for development of the Nuclear Nerds contract and for answering
* my DMs to help us integrate its use here for Laika League <3
*
* Special thanks to @whalegoddess for providing a contract audit and
* assisting in the implementation of key features.
*/

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract LaikaLeague is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    
    address public              proxyRegistryAddress;
    address public              devWallet;

    uint256 public              MAX_SUPPLY;
    
    uint256 public              priceInWei;
    uint256 public constant     MAX                 = 16;
    uint256 public constant     RESERVES            = 200;


    bool public revealed = false;

    mapping(address => bool) public projectProxy;
    mapping(address => uint) public addressToMinted;

    constructor(
        address _proxyRegistryAddress, 
        address _devWallet
    )

        ERC721("Laika League", "LAIKA")
    {
        setHiddenMetadataUri("ipfs://QmeyAZ48VQbgJwb1Vevk7qnc9G27Bp1EVwZ5RDa9wZSxhw/hidden.json");
        proxyRegistryAddress = _proxyRegistryAddress;
        devWallet = _devWallet;
    }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }


  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }


  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function collectReserves() external onlyOwner {
        require(_owners.length == 0, 'Reserves already taken.');
        for(uint256 i; i < RESERVES; i++)
            _mint(_msgSender(), i);
    }

    function togglePublicSale(uint256 _MAX_SUPPLY) external onlyOwner {
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function publicMint(uint256 count) public payable {
        uint256 totalSupply = _owners.length;
        require(totalSupply + count < MAX_SUPPLY, "Excedes max supply.");
        require(tx.origin == msg.sender, "Contracts cannot mint.");
        require(addressToMinted[msg.sender] + count < MAX, "Don't be greedy!");
                    if (totalSupply > 700 ) {
            require(count * priceInWei == msg.value, "Invalid funds provided.");
        }  
        for(uint i; i < count; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
        addressToMinted[msg.sender] += count;
    }

    function setCost(uint256 _priceInWei) public onlyOwner {
        priceInWei = _priceInWei;
    }

    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function withdraw() public  {
        (bool success, ) = devWallet.call{value: address(this).balance}("");
        require(success, "Failed to send to dev wallet.");
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }

        return true;
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function _baseURI() internal view virtual returns (string memory) {
        return uriPrefix;
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}