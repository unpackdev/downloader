// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./Pausable.sol";
import "./ERC2981.sol";
import "./ERC721AQueryable.sol";

/*
RocketMan
2022
*/

contract RocketMan is ERC721AQueryable, ERC2981, Ownable, Pausable {
  using Strings for uint256;
  using SafeMath for uint256;

  // Supply details
  uint256 public constant TOTAL_MAX_SUPPLY = 8000;
  uint256 public teamReserve = 50;
  uint256 public teamMinted = 0;
  uint256 public totalFreeMints = 2000;

  // Launch date/time
  uint256 public preSaleTime = 1657724400; // Wed, July 11, 2022 at 11:00:00 AM EST
  uint256 public publicSaleTime = 1657726200; // Wed, July 11, 2022 at 11:30:00 AM EST

  // Free mint limits
  uint256 public maxFreeMintPerWallet = 1;
  // Track total free mint for collection
  uint256 public freeMintCount = 0;
  // Track free mint amount per wallet
  mapping(address => uint256) public freeMintClaimed;

  // Track total mint amount per wallet
  mapping(address => uint256) public mintedWallet;

  // Pre sale
  uint256 public preSalePrice = .015 ether;
  uint256 public preSaleFreeSupply = 2000;
  uint256 public preSaleTxLimit = 3;
  uint256 public preSaleFreeMinted;
  bytes32 public merkleRoot;

  // Public sale
  uint256 public publicTokenPrice = .015 ether;
  uint256 public maxPublicMintPerWallet = 3;

  // Token URI info
  // Contract URI for OS (must be full URI to JSON metadata file)
  string _contractURI;

  // Public Reveal Status (false = placeHolderURI, true = _baseTokenURI)
  bool public tokenRevealStatus = false;

  // Base tokenURI after reveal (must include traling /)
  string private _baseTokenURI;

  // Image Placeholder URI (must be full URI to JSON metadata file)
  string public placeHolderURI;

  constructor(string memory intialContractURI, string memory _placeHolderURI) ERC721A('RocketMan', 'RKMN') {
    _setDefaultRoyalty(msg.sender, 750);
    _contractURI = intialContractURI;
    placeHolderURI = _placeHolderURI;
  }

  // Modifiers
  modifier callerIsUser() {
    require(tx.origin == msg.sender, 'RocketMan: The caller is another contract');
    _;
  }

  modifier underMaxSupply(uint256 _quantity) {
    require(
      _totalMinted() + _quantity <= (TOTAL_MAX_SUPPLY - teamReserve) + teamMinted,
      'RocketMan: Purchase would exceed max supply'
    );
    _;
  }

  // Mint functions
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function mint(uint256 _quantity) external payable callerIsUser underMaxSupply(_quantity) {
    require(balanceOf(msg.sender) < maxPublicMintPerWallet, "RocketMan: Caller's token amount exceeds the limit.");
    require(block.timestamp > publicSaleTime, 'RocketMan: Public sale not yet started');
    if (freeMintCount >= totalFreeMints) {
      require(msg.value >= _quantity * publicTokenPrice, 'RocketMan: Not enough ETH');
      _mint(msg.sender, _quantity);
    } else if (freeMintClaimed[msg.sender] < maxFreeMintPerWallet) {
      uint256 _mintableFreeQuantity = maxFreeMintPerWallet - freeMintClaimed[msg.sender];
      if (_quantity <= _mintableFreeQuantity) {
        freeMintCount += _quantity;
        freeMintClaimed[msg.sender] += _quantity;
      } else {
        freeMintCount += _mintableFreeQuantity;
        freeMintClaimed[msg.sender] += _mintableFreeQuantity;
        require(msg.value >= (_quantity - _mintableFreeQuantity) * publicTokenPrice, 'RocketMan: Not enough ETH');
      }
      _mint(msg.sender, _quantity);
    } else {
      require(msg.value >= (_quantity * publicTokenPrice), 'RocketMan: Not enough ETH');
      _mint(msg.sender, _quantity);
    }
    mintedWallet[msg.sender] += _quantity;
  }

  /**
   * @notice Mint via preSale merkle tree
   * @dev Only callable if public sale has not started
   * @param _quantity number of NFTs to mint in this transaction
   * @param maxQuantity max quantity the msg.sender is allowed to mint
   * @param _merkleProof merkle proof for msg.sender
   */

  function merkleMint(
    uint256 _quantity,
    uint256 maxQuantity,
    bytes32[] memory _merkleProof
  ) public payable whenNotPaused underMaxSupply(_quantity) {
    require(block.timestamp >= preSaleTime && block.timestamp <= publicSaleTime, 'RocketMan: Pre-sale not running');
    require(_quantity <= preSaleTxLimit, 'RocketMan: Mint token amount exceed tx limit.');

    bytes32 node = keccak256(abi.encode(msg.sender, maxQuantity));
    require(MerkleProof.verify(_merkleProof, merkleRoot, node), 'MerkleMint: Address not eligible for mint');

    if (preSaleFreeMinted < preSaleFreeSupply) {
      if (freeMintClaimed[msg.sender] < maxFreeMintPerWallet) {
        require(msg.value >= preSalePrice.mul(_quantity.sub(1)), 'RocketMan: Payment amount is not enoguth.');
        freeMintClaimed[msg.sender] = freeMintClaimed[msg.sender] + 1;
      } else {
        require(msg.value >= preSalePrice.mul(_quantity), 'RocketMan: Payment amount is not enough.');
      }
    }

    require(balanceOf(msg.sender) + _quantity <= maxQuantity, 'MerkleMint: Mint would exceed max allowed');

    _mint(msg.sender, _quantity);

    preSaleFreeMinted += _quantity;
    mintedWallet[msg.sender] += _quantity;
  }

  function mintTeamReserveToWallet(address _wallet, uint256 _quantity) external onlyOwner underMaxSupply(_quantity) {
    require(teamMinted + _quantity <= teamReserve, 'RocketMain: Team Mint Amount exceed Team Reserve Amount.');
    _mint(_wallet, _quantity);
    teamMinted += _quantity;
  }

  function mintTeamReserveToWallets(address[] memory _wallets, uint256[] memory _quantity) external onlyOwner {
    require(_wallets.length == _quantity.length, 'RocketMain: Team Mints Info is not correct.');
    for (uint256 i = 0; i < _wallets.length; i++) {
      require(teamMinted + _quantity[i] <= teamReserve, 'RocketMan: Team Mint Amount exceed Team Max Reserve Amount.');
      _mint(_wallets[i], _quantity[i]);
      teamMinted += _quantity[i];
    }
    require(teamMinted < TOTAL_MAX_SUPPLY, 'RocketMain: Team mint quantity exceeds Max supply');
  }

  // General functions

  function maxSupply() public pure returns (uint256) {
    return TOTAL_MAX_SUPPLY;
  }

  function getSaleStatus() public view returns (string memory) {
    if (block.timestamp > publicSaleTime) {
      return 'public';
    } else if (block.timestamp >= preSaleTime && block.timestamp <= publicSaleTime) {
      return 'presale';
    } else {
      return 'paused';
    }
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  // Token URI functions
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    if (tokenRevealStatus) {
      string memory baseURI = _baseURI();
      return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    } else {
      return placeHolderURI;
    }
  }

  // Only Owner Fucntions

  function setFreeMintCount(uint256 _count) external onlyOwner {
    totalFreeMints = _count;
  }

  function setTeamReserve(uint256 _count) external onlyOwner {
    teamReserve = _count;
  }

  function setMaxFreeMintPerWallet(uint256 _count) external onlyOwner {
    maxFreeMintPerWallet = _count;
  }

  function setMaxPublicMintPerWallet(uint256 _count) external onlyOwner {
    maxPublicMintPerWallet = _count;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  // Storefront metadata
  // https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory _URI) external onlyOwner {
    _contractURI = _URI;
  }

  function setMerkleRoot(bytes32 _hash) external onlyOwner {
    merkleRoot = _hash;
  }

  function setPreSalePrice(uint256 price) external onlyOwner {
    preSalePrice = price;
  }

  function setPublicTokenPrice(uint256 price) external onlyOwner {
    publicTokenPrice = price;
  }

  function setPreSaleTxLimit(uint256 txLimit) external onlyOwner {
    preSaleTxLimit = txLimit;
  }

  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  function withdrawFunds() external onlyOwner {
    require(address(this).balance > 0);
    (bool success, ) = msg.sender.call{ value: address(this).balance }('');
    require(success, 'RocketMan: Transfer failed.');
  }

  function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
    require(address(this).balance > 0);
    (bool success, ) = _address.call{ value: amount }('');
    require(success, 'RocketMan: Transfer failed.');
  }

  function setDefaultRoyalty(uint96 _royalty) external onlyOwner {
    _setDefaultRoyalty(msg.sender, _royalty);
  }

  function setPreSaleTime(uint256 _preSaleTime) external onlyOwner {
    preSaleTime = _preSaleTime;
  }

  function setPublicSaleTime(uint256 _publicSaleTime) external onlyOwner {
    publicSaleTime = _publicSaleTime;
  }

  function setPlaceholderURI(string memory _uri) public onlyOwner {
    placeHolderURI = _uri;
  }

  function togglePublicReveal() external onlyOwner {
    tokenRevealStatus = !tokenRevealStatus;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, IERC721A, ERC2981)
    returns (bool)
  {
    // The interface IDs are constants representing the first 4 bytes of the XOR of
    // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
    // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
    return
      interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
      interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
      interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
  }
}
