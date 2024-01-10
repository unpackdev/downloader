// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";
import "./Address.sol";
import "./Counters.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";
import "./ERC2981.sol";
import "./ERC721A.sol";

// ██████╗ ██████╗ ██╗███╗   ███╗███████╗
// ██╔══██╗██╔══██╗██║████╗ ████║██╔════╝
// ██████╔╝██████╔╝██║██╔████╔██║█████╗
// ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██╔══╝
// ██║     ██║  ██║██║██║ ╚═╝ ██║███████╗
// ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝╚══════╝

//  █████╗ ██████╗ ███████╗
// ██╔══██╗██╔══██╗██╔════╝
// ███████║██████╔╝█████╗
// ██╔══██║██╔═══╝ ██╔══╝
// ██║  ██║██║     ███████╗
// ╚═╝  ╚═╝╚═╝     ╚══════╝

//  █████╗ ████████╗██╗  ██╗██╗     ███████╗████████╗███████╗███████╗
// ██╔══██╗╚══██╔══╝██║  ██║██║     ██╔════╝╚══██╔══╝██╔════╝██╔════╝
// ███████║   ██║   ███████║██║     █████╗     ██║   █████╗  ███████╗
// ██╔══██║   ██║   ██╔══██║██║     ██╔══╝     ██║   ██╔══╝  ╚════██║
// ██║  ██║   ██║   ██║  ██║███████╗███████╗   ██║   ███████╗███████║
// ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝   ╚══════╝╚══════╝
//
//
//
contract PrimeApeAthletes is ERC721A, ERC2981, Ownable, PaymentSplitter {
  using Strings for uint256;
  using Counters for Counters.Counter;

  enum Sale {
    NoSale,
    PreSale,
    PublicSale
  }

  uint256 public immutable price = 70000000000000000; //0,07 ETH

  uint256 public maxMintSupply = 10_000;

  uint256 public limitPerWallet = 15;

  bytes32 public ogPresaleRoot;

  uint256 public ogPresaleMaxMint = 5;

  bytes32 public normalPresaleRoot;

  uint256 public normalPresaleMaxMint = 3;

  string public baseURI;

  Sale public state = Sale.NoSale;

  mapping(address => uint256) public claimed;

  event PAAMinted(uint256 balance, address owner);

  string public contractURI =
    'https://ipfs.io/ipfs/QmRLwTPR1Le3Pi5kvgHmFTzSmiHomBSoybtnbTdqBvXi4Q';

  uint256[] private _teamShares = [90, 10];

  address[] private _team = [
    0x94D5459df3d5133E37B6F337584941469199d84c,
    0xBD584cE590B7dcdbB93b11e095d9E1D5880B44d9
  ];

  constructor()
    ERC721A('PrimeApeAthletes', 'PAA')
    PaymentSplitter(_team, _teamShares)
  {
    _setDefaultRoyalty(_team[0], 600);
    _transferOwnership(_team[0]);
    baseURI = 'ipfs://QmPoA4W1NLbDB6ZHU2osHX3G5CD5VetzvrMG11SBKsqKDU/';
  }

  function enablePresale(bytes32 _presaleNormalRoot, bytes32 _presaleOGRoot)
    public
    onlyOwner
  {
    state = Sale.PreSale;

    ogPresaleRoot = _presaleOGRoot;
    normalPresaleRoot = _presaleNormalRoot;
  }

  function enablePublic() public onlyOwner {
    state = Sale.PublicSale;
  }

  function setBaseURI(string calldata _tokenBaseURI) external onlyOwner {
    baseURI = _tokenBaseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function saleIsActive() public view returns (bool) {
    return state == Sale.PublicSale;
  }

  function presaleIsActive() public view returns (bool) {
    return state == Sale.PreSale;
  }

  function exists(uint256 id) public view returns (bool) {
    return _exists(id);
  }

  function mint(uint64 _amount) external payable {
    require(state == Sale.PublicSale, 'Public sale not enabled.');
    require(_amount > 0, 'Zero amount.');
    require(
      msg.value >= (price * _amount),
      'You need to send proper amount of eth.'
    );
    require(
      totalSupply() + _amount <= maxMintSupply,
      'Purchase would exceed max supply of tokens.'
    );
    require(
      claimed[_msgSender()] + _amount <= limitPerWallet,
      'Purchase exceeds max allowed.'
    );

    _safeMint(_msgSender(), _amount);
    claimed[_msgSender()] += _amount;

    emit PAAMinted(_amount, _msgSender());
  }

  function presale(
    uint64 _amount,
    bool og,
    bytes32[] calldata proof
  ) external payable {
    require(state == Sale.PreSale, 'Presale not enabled.');
    require(_amount > 0, 'zero amount');

    require(
      verify(_msgSender(), proof, og ? ogPresaleRoot : normalPresaleRoot),
      'Not selected for the presale.'
    );

    uint256 maxMintAmount = og ? ogPresaleMaxMint : normalPresaleMaxMint;
    require(_amount <= maxMintAmount, 'max mint amount');

    require(
      msg.value >= (price * _amount),
      'You need to send proper amount of eth.'
    );
    require(
      totalSupply() + _amount <= maxMintSupply,
      'Purchase would exceed max supply of tokens.'
    );

    require(
      claimed[_msgSender()] + _amount <= maxMintAmount,
      'Purchase exceeds max allowed'
    );

    _safeMint(_msgSender(), _amount);
    claimed[_msgSender()] += _amount;

    emit PAAMinted(_amount, _msgSender());
  }

  function burn() external onlyOwner {
    maxMintSupply = totalSupply();
  }

  /**
   * @dev See {IERC165-tokenURI}.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), 'nonexistent token');
    string memory uri = _baseURI();

    if (bytes(uri).length == 0) {
      return '';
    }
    return string(abi.encodePacked(uri, tokenId.toString(), '.json'));
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev will set default royalty info.
   */
  function setDefaultRoyalty(address receiver, uint96 feeNumerator)
    public
    onlyOwner
  {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  /**
   * @dev will set token royalty.
   */
  function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) public onlyOwner {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  function setContractURI(string calldata _contractURI) public onlyOwner {
    contractURI = _contractURI;
  }

  function setLimitPerWallet(uint256 _limitPerWallet) public onlyOwner {
    limitPerWallet = _limitPerWallet;
  }

  function setPresaleMaxMint(
    uint256 _ogPresaleMaxMint,
    uint256 _normalPresaleMaxMint
  ) public onlyOwner {
    ogPresaleMaxMint = _ogPresaleMaxMint;
    normalPresaleMaxMint = _normalPresaleMaxMint;
  }

  function verify(
    address account,
    bytes32[] memory proof,
    bytes32 root
  ) internal pure returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(account));
    return MerkleProof.verify(proof, root, leaf);
  }
}
