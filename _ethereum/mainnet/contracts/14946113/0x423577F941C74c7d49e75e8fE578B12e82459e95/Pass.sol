// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC2981.sol";
import "./ERC721Enumerable.sol";

//          ___________ _        ___   _     ______ _   _   ___            //
//         |_   _| ___ \ |      / _ \ | |    | ___ \ | | | / _ \           //
// ______    | | | |_/ / |     / /_\ \| |    | |_/ / |_| |/ /_\ \  ______  //
//|______|   | | |    /| |     |  _  || |    |  __/|  _  ||  _  | |______| //
//          _| |_| |\ \| |____ | | | || |____| |   | | | || | | |          //
//          \___/\_| \_\_____/ \_| |_/\_____/\_|   \_| |_/\_| |_/          //


contract Pass is ERC721Enumerable, ERC2981, Ownable {
    string  public              baseURI;
    string  public              contractMetadata;
    address public              proxyRegistryAddress;
    address public              withdrawAddress;

    uint256 public              MaxSupply       = 440;
    uint256 public constant     neonPrice       = 1.0 ether;
    uint256 public constant     noirPrice       = 0.25 ether;
    uint256 public constant     maxNeonPasses   = 69;
    uint256 public constant     maxNoirPasses   = 351;
    uint256 public              neonCount       = 0;
    uint256 public              noirCount       = 0;
    bool public                 premintIsActive = true;
    bool public                 saleIsActive    = false;

    mapping(address => bool)    public projectProxy;
    mapping (uint256 => string) internal _tokenURIs;

    mapping(address => bool)    private alphaHaver;
    mapping(address => bool)    private neonPremint;
    mapping(address => bool)    private noirPremint;
    mapping(address => uint256) public  mintPerWallet;

    uint256 private constant perWalletLimit = 3;

    string private constant _neonMetadata      = "QmPJYFF4V1GuBqtL4URabfMUoxchuoWB4PxCY9d3nH2qAw";
    string private constant _noirMetadata      = "QmUbNqszgBN2VsPCfiz8ez9j7FKtQhn6ndoiZ1zBon4RvH";
    string private constant _noirPartyMetadata = "QmTGoYjwreFcbU5cSc7vCoPtUhguAXaeFQsoxvtmzcrq6W";
    string private constant _neonPartyMetadata = "QmZj3PfYqvCbTMLUEX4q2PnuefDcCfdRS3tT82wyPRvQQg";

    event MintNeon(address minter);
    event MintNoir(address minter);

    constructor(
        string memory _baseURI,
        address _proxyRegistryAddress,
        string memory _contractMetadata,
        address _withdrawAddress
    )
        ERC721("IRL", "IRL Alpha Pass")
    {
        baseURI              = _baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        contractMetadata     = _contractMetadata;
        withdrawAddress      = _withdrawAddress;
        _setDefaultRoyalty(withdrawAddress, 750);

        // The Party Crew!
        alphaHaver[0xB3B222F9A47C1DAd79b4318d298deF4B07B3b0c1] = true;
        alphaHaver[0x2Ad5AC132e307d55Dde390E6Fd0b80209735E900] = true;
        alphaHaver[0x4a4958222fdD1674148e5117F0b784f7D1c06e9a] = true;
        alphaHaver[0x4B5bF7fCCCbd98450b215b619B7DbDb036a3dd46] = true;
        alphaHaver[0xDfaFC2b5AA357B6Abd449079A6A739e9351e302c] = true;
        alphaHaver[0xbC50552A5EFA8a0448821ab96164aB03E023044d] = true;
        alphaHaver[0x7cf5D886771bBF65Cd22d8d63E703c1325Eb79E0] = true;
        alphaHaver[0xb337FB8e4Cd712E8716992899842A47Bd95d9c34] = true;
        alphaHaver[0x647C6F3b6fBdecBB41c1D3D8783E793833D5B991] = true;
        alphaHaver[0x15f4DB34B519A4585513371B15b5a5381235dA3e] = true;
        alphaHaver[0x0a5fAC45Bb46C3579b51470018f5893aCf4C4114] = true;
        alphaHaver[0x6d5B79F66FFd63568Ab5f583C6fccd00413afd2a] = true;
        alphaHaver[0x6A45B137c9681cf3CF531Eb61E68545779FACC36] = true;
        alphaHaver[0x0817E382a40d484A8b90C792b399667174E50aB8] = true;
        alphaHaver[0x5dBA9f769dEf51CFE74A90DCC2D0acDA8a43EFF8] = true;
        alphaHaver[0x9689ee48E0BB9e169422dBC999Acd5308045Fe1A] = true;
        alphaHaver[0xBA34F770905BCA025b74e3e32130159d069998BA] = true;
        alphaHaver[0xAA4e17A7a9f3E46339715F214D261D139805E4a4] = true;
        alphaHaver[0xc61961193cACA4cd561e815886Fc13e96Cf18d26] = true;
        alphaHaver[0x4834614C3993e059A5F70a2d48A4Ea90d30e7C13] = true;
        alphaHaver[0x89f59DD98463c2Dbe42B76812666D6E187448E8f] = true;
        alphaHaver[0x097f71D2aBAF370e686fB3F3d773592D9B0031eD] = true;
    }

    function mintNeon(address to) public payable {
        require(saleIsActive, "Sale must be active to mint Pass!");

        if (premintIsActive) {
          require(neonPremint[to], "Must be on Neon Premint List");
        }

        require(msg.value >= neonPrice, "You need more ether!");
        require(mintPerWallet[to] < perWalletLimit, "You've already minted too many!");
        require(neonCount + 1 <= maxNeonPasses, "There's no more Neon Passes to mint!");

        uint256 id = _owners.length;

        string memory metadata;
        if (hasTheAlpha(to) || neonPremint[to] ) {
          metadata = _neonPartyMetadata;
        } else {
          metadata = _neonMetadata;
        }

        _tokenURIs[id] = metadata;
        _mint(to, id);

        mintPerWallet[to] = mintPerWallet[to] + 1;
        ++neonCount;
        emit MintNeon(to);
    }

    function mintNoir(address to) public payable {
        require(saleIsActive, "Sale must be active to mint Pass!");

        if (premintIsActive) {
          require(noirPremint[to], "Must be on Noir Premint List");
        }

        require(mintPerWallet[to] < perWalletLimit, "You've already minted too many!");
        require(msg.value >= noirPrice, "You need more ether!");
        require(noirCount + 1 <= maxNoirPasses, "There's no more Noir Passes to mint!");

        uint256 id = _owners.length;

        string memory metadata;
        if (hasTheAlpha(to) || noirPremint[to] ) {
          metadata = _noirPartyMetadata;
        } else {
          metadata = _noirMetadata;
        }

        _tokenURIs[id] = metadata;
        _mint(to, id);

        mintPerWallet[to] = mintPerWallet[to] + 1;
        ++noirCount;
        emit MintNeon(to);
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _resetTokenRoyalty(tokenId);
        _burn(tokenId);
    }

    function withdraw() public  {
        (bool success, ) = withdrawAddress.call{value: address(this).balance}("");
        require(success, "Failed to send to withdrawAddress.");
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

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    function setNeonPremintList(address[] calldata _addresses) public {
        for (uint256 i = 0; i < _addresses.length; i++) {
          neonPremint[_addresses[i]] = true;
        }
    }

    string[] private doNotWorryAboutIt = [
      "QmWGsLs4Pek1JPHdEAKvrbyw7rgoSMuKaRTJBcbBq2on4Q",
      "QmUTgna4rmEUNfdMNGxEUuxz2gsMNKnERyFvx5bMTqAonb",
      "QmeDZgjqFUpfutXDthhbEKMNGyGSWYdsqsxTFNpx9SGLA3"
      "QmUQKRHXUoRnmKCgvtP2enW2356W8Y24ye6DDBAs9uj8ba",
      "QmdzxDsW82YpkPXxxAyq79hSDvagk5cc7Jk84PsyXX292Q",
      "QmcYBX6ERYFRCeSFiFGb9W2xuQ2YNRwtJUvpCBajv2AHjK",
      "QmUrySu8kFzFwpfTXHQNycYcFtkDHWmdMxVFauZsHHs6ex",
      "QmTpTTJ43ivdQpdftbg6puYc4nt8VnUGYs8MhKsNUrTYBD",
      "Qmcb3c9uHi6H1Urb422xA9tG7GtP2P2njxhQQHj68zHs6c",
      "QmdK5jzTwiSYTGwo5kkEQCC8nac6ZURb7YvjoDTf6WmSF4",
      "QmYhKrx92VctAbFUk4YMqn269EGrvy3fyu7NH3S4bdC7nY",
      "QmSLV5Yo4ycYb4Eyq3SemrjS87Zbj8YX19mRfbGW4cvtP9",
      "QmXusMHd2W8MRjFdWMYuR8dkUcQU99vJ8Q7SvFQATRvzNE",
      "QmcoVHtJW3p3Y3aqX9CfJYB7uMrwjs3CxF32WsNctGsoG8",
      "QmeKHkcvpjzM5VZFDMkxYkFPf53YXBUotBuW3euyN5NJqP",
      "QmP2V4AUhgVeTHTLi8Q9pKDQt3GRhJKJiapkdXv1mvEc8X",
      "QmTdwGg8Dzh6fZeWkq2hGanZSsKUvzGaLoEFxZpg3jQTcV",
      "QmaQKbHhZtFG4227pszDEsF99eXCDEux5TyeXn6ii1YsBK",
      "QmNgeWNGimn1psx7LkhxXCeC9PGVJA4nNxBSiyyarHjEED",
      "QmQaTdXLeeh3BYAT3XSMLKA8FRnxF6eXnquT9fdCERUUZo"
    ];

    // We have to charge you something, or you'll just grab all of them
    uint256 private constant     hackerPriceInWei = 0.08 ether;
    uint256 private              hackerCount      = 0;

    function caveatEmptor(address to) public payable {
        require(saleIsActive, "Sale must be active to mint Pass!");

        require(mintPerWallet[to] < perWalletLimit, "You've already minted too many!");
        require(msg.value >= hackerPriceInWei, "You need more ether!");
        require(hackerCount + 1 <= doNotWorryAboutIt.length, "There's no more Neon Passes to mint!");

        uint256 id = _owners.length;

        string memory metadata = doNotWorryAboutIt[hackerCount];

        _tokenURIs[id] = metadata;
        _mint(to, id);

        mintPerWallet[to] = mintPerWallet[to] + 1;
        ++hackerCount;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractMetadata = _contractURI;
    }

    function contractURI() public view returns (string memory) {
        return contractMetadata;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setWithdrawAddress(address newAddress) public onlyOwner {
        withdrawAddress = newAddress;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(keccak256(abi.encodePacked(_tokenURIs[_tokenId])) != keccak256(abi.encodePacked("")));
        string memory uri = _tokenURIs[_tokenId];
        return string(abi.encodePacked(baseURI, uri));
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    // 10 Neon and 10 Noir passes to early contributors of GoodWork
    // who got us here where we are today without pay!
    function rewardTheEarlyCrew() external onlyOwner {
        require(_owners.length == 0, 'Minting already has begun.');

        for(uint256 i; i < 10; i++) {
          _tokenURIs[i] = _neonPartyMetadata;
          _mint(owner(), i);
          ++neonCount;
        }

        for(uint256 i = 10; i < 20; i++) {
          _tokenURIs[i] = _noirPartyMetadata;
          _mint(owner(), i);
          ++noirCount;
        }

    }

    function addAlphaHaver(address _degen) public onlyOwner {
      alphaHaver[_degen] = true;
    }

    function hasTheAlpha(address _degen) public view returns(bool) {
      bool userHasAlpha = alphaHaver[_degen];
      return userHasAlpha;
    }

    function updateAlphaStatus(uint256 tokenId) public onlyOwner {
      bytes32 uri = keccak256(abi.encodePacked(_tokenURIs[tokenId]));
      require(
        uri == keccak256(abi.encodePacked(_neonMetadata)) ||
        uri == keccak256(abi.encodePacked(_noirMetadata)),
        "Only can upgrade plain regular passes"
      );

      if (uri == keccak256(abi.encodePacked(_neonMetadata))) {
        _tokenURIs[tokenId] = _neonPartyMetadata;
      } else {
        _tokenURIs[tokenId] = _noirPartyMetadata;
      }
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPremintState() public onlyOwner {
        premintIsActive = !premintIsActive;
    }

    function setNoirPremintList(address[] calldata _addresses) public {
        for (uint256 i = 0; i < _addresses.length; i++) {
          noirPremint[_addresses[i]] = true;
        }
    }

    function setTokenMetadata(uint256 _tokenId, string calldata uri) public onlyOwner {
      _tokenURIs[_tokenId] = uri;
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC2981, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
