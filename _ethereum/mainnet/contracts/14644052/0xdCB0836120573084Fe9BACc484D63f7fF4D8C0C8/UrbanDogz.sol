// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ERC2981.sol";


contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract UrbanDogz is Ownable, ERC721A, ReentrancyGuard,ERC2981 {

  using Strings for uint256;

  // Variables

    // Sale config
    uint256 public maxSupply = 500;
    uint256 public price = 120000000000000000;
    uint256 public preSalePrice = 80000000000000000;
    uint256 public maxMintAmountPerTxPreSale = 1;
    uint256 public maxPerWalletPreSale = 1;
    uint256 public maxMintAmountPerTx = 10;
    bool public paused = true;
    bool public onlyWhitelist = true;

    // Metadata
    string private _baseTokenURI;

    // Whitelist
    bytes32 private merkleRoot;
 
    // Proxies
    address public proxyRegistryAddress;

    //The OpenSea Proxy Registry addresses are:
    //Rinkeby: 0x1E525EEAF261cA41b809884CBDE9DD9E1619573A
    //Mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1

  //Constructor
  constructor(string memory _name, string memory 
  _symbol,address _proxyRegistryAddress,address royaltyReceiver,
  uint96 royaltyFee) 
  ERC721A(_name, _symbol)
    {
      proxyRegistryAddress = _proxyRegistryAddress;
      _setDefaultRoyalty(royaltyReceiver, royaltyFee);

    }

  // Metadata
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  // Whitelist
  function setMerkleRoot(bytes32 _root) public onlyOwner {
      merkleRoot = _root;
    }


  //Sale config
  function pause(bool _state) public onlyOwner {
      paused = _state;
    }

  function setOnlyWhitelist(bool _state) public onlyOwner {
        onlyWhitelist = _state;
    }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setMaxPerWalletPreSale(uint256 _maxPerWalletPreSale) public onlyOwner {
    maxPerWalletPreSale = _maxPerWalletPreSale;
  }

  function setMaxMintAmountPerTxPreSale(uint256 _maxMintAmountPerTxPreSale) public onlyOwner {
    maxMintAmountPerTxPreSale = _maxMintAmountPerTxPreSale;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setPreSalePrice(uint256 _preSalePrice) public onlyOwner {
    preSalePrice = _preSalePrice;
  }


  function verify(
    bytes32[] calldata merkleProof,
    address sender
  ) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(sender));
    return MerkleProof.verify(merkleProof, merkleRoot, leaf);
  }

  function whitelistMint(uint256 quantity, bytes32[] calldata _merkleProof) external payable{
    uint256 currentSupply = totalSupply();
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(!paused, 'Minting paused');
    require(onlyWhitelist, "Whitelist minting is not active or has already ended");
    require(msg.value > 0, "Must send ETH to mint.");
    require(currentSupply <= maxSupply, "Sold out.");
    require(currentSupply + quantity <= maxSupply, "Requested quantity would exceed total supply.");
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "User is not in the whitelist");
    require(balanceOf(msg.sender) < maxPerWalletPreSale,"Exceeds wallet limit for presale");
    require(quantity <= maxMintAmountPerTxPreSale, "Exceeds presale txn limit");
    require(preSalePrice * quantity <= msg.value, "ETH sent is incorrect.");
      _safeMint(msg.sender, quantity);
  }


  function publicMint(uint256 quantity) external payable{
    uint256 currentSupply = totalSupply();
    require(!paused, 'Minting paused');
    require(msg.value > 0, "Must send ETH to mint.");
    require(currentSupply <= maxSupply, "Sold out.");
    require(quantity <= maxMintAmountPerTx, "Exceeds txn limit");
    require(price * quantity <= msg.value, "ETH sent is incorrect.");
      _safeMint(msg.sender, quantity);
  }

  // For dev use only
  function reserve(address _address, uint256 _quantity) public onlyOwner {
      _safeMint(_address, _quantity);
    }


  // Withdraw
  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed."); 
  }

  /**
   * Override isApprovedForAll to whitelist contracts.
   */
  function isApprovedForAll(address owner, address operator)
      public
      view
      override
      returns (bool)
    {
      // Whitelist OpenSea proxy contract for easy trading.
      OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
      if (address(proxyRegistry.proxies(owner)) == operator || proxyToApproved[operator]) return true;
      return super.isApprovedForAll(owner, operator);
    }

  function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
      proxyRegistryAddress = _proxyRegistryAddress;
    }

  // Whitelist another contracts to enable gas-less approving.
  mapping(address=>bool) public proxyToApproved;

  function flipProxyState(address proxyAddress) public onlyOwner {
    proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
  }

  // Royalties
  function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
  @notice Sets the contract-wide royalty info.
  */

  function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner
    {
      _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool)
    {
      return super.supportsInterface(interfaceId);
    }

}