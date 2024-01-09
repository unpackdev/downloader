// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./MerkleProof.sol";

import "./ERC721Nameable.sol";
import "./Royalty.sol";

interface IWatu {
  function updateReward(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function getReward(address to) external;
}

contract Tekyan is ERC721, ERC721Enumerable, ERC721Nameable, Royalty, Ownable {
  enum Status {
    Close,
    Presale,
    Sale,
    Breed
  }

  uint256 public constant TOTAL = 10_000;
  uint256 public constant FIRST_TRIBE = 1_000;
  uint256 public constant FIRST_TRIBE_PRICE = 0.07 ether;
  uint256 public constant FIRST_TRIBE_MAX_MINT = 2;
  uint256 public constant FIRST_TRIBE_PRESALE = 700;
  uint256 public constant FIRST_TRIBE_PRESALE_PRICE = 0.06 ether;
  uint256 public BREED_PRICE = 500 ether; // $WATU
  uint256 public reservedMinted;
  uint256 public presaleMinted;

  Status public status;

  bytes32 public root;

  address public WATU_ADDRESS;
  address public TEAM_ADDRESS;

  mapping(address => uint256) public presalePurchases;
  mapping(address => uint256) public purchases;

  string public PROVENANCE;

  string private _contractURI;
  string private _tokenBaseURI;

  constructor() ERC721("Tekyan Tribe", "TEKYAN") {}

  function presale(
    uint256 quantity,
    uint256 allowance,
    bytes32[] calldata proof
  ) public payable {
    require(status == Status.Presale, "PRESALE_CLOSED");
    uint256 _totalSupply = totalSupply();
    require(_totalSupply + quantity <= FIRST_TRIBE, "EXCEED_STOCK");
    require(
      presaleMinted + quantity <= FIRST_TRIBE_PRESALE - reservedMinted,
      "EXCEED_PRESALE_STOCK"
    );
    require(
      _verify(_leaf(msg.sender, allowance), proof),
      "INVALID_MERKLE_PROOF"
    );
    require(
      presalePurchases[msg.sender] + quantity <= allowance,
      "EXCEED_ALLOWANCE"
    );
    require(
      msg.value == FIRST_TRIBE_PRESALE_PRICE * quantity,
      "INSUFFICIENT_ETH"
    );

    presalePurchases[msg.sender] += quantity;

    for (uint256 i; i < quantity; i++) {
      presaleMinted++;
      _safeMint(msg.sender, _totalSupply++);
    }
  }

  function mint(uint256 quantity) public payable {
    require(status == Status.Sale, "SALE_CLOSED");
    require(
      purchases[msg.sender] + quantity <= FIRST_TRIBE_MAX_MINT,
      "EXCEED_MAX_MINT"
    );
    uint256 _totalSupply = totalSupply();
    require(_totalSupply + quantity <= FIRST_TRIBE, "EXCEED_STOCK");
    require(msg.value == FIRST_TRIBE_PRICE * quantity, "INSUFFICIENT_ETH");

    purchases[msg.sender] += quantity;

    for (uint256 i; i < quantity; i++) {
      _safeMint(msg.sender, _totalSupply++);
    }
  }

  function breed(uint256 even, uint256 odd) public {
    require(status == Status.Breed, "BREED_CLOSED");
    uint256 _totalSupply = totalSupply();
    require(_totalSupply + 1 <= TOTAL, "EXCEED_STOCK");
    require(even < 1000 && odd < 1000, "ONLY_FIRST_TRIBE");
    uint256 evenRemain = even % 2;
    uint256 oddRemain = odd % 2;
    require(evenRemain == 0 && oddRemain != 0, "NEED_EVEN_AND_ODD");
    require(
      ownerOf(even) == msg.sender && ownerOf(odd) == msg.sender,
      "NOT_YOUR_OWN"
    );

    ERC20Burnable(WATU_ADDRESS).burnFrom(msg.sender, BREED_PRICE);

    _safeMint(msg.sender, _totalSupply++);
  }

  function getReward() public {
    IWatu(WATU_ADDRESS).updateReward(msg.sender, address(0), 0);
    IWatu(WATU_ADDRESS).getReward(msg.sender);
  }

  function changeName(uint256 tokenId, string memory newName) public override {
    ERC20Burnable(WATU_ADDRESS).burnFrom(msg.sender, NAME_CHANGE_PRICE);
    super.changeName(tokenId, newName);
  }

  function balanceOfFirstTribe(address owner) public view returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");

    uint256 count;
    for (uint256 i; i < _owners.length; i++) {
      if (i < 1000 && owner == _owners[i]) count++;
    }

    return count;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function gift(address[] calldata receivers, uint256[] calldata amounts)
    external
    onlyOwner
  {
    uint256 _totalSupply = totalSupply();
    require(_totalSupply <= FIRST_TRIBE, "EXCEED_STOCK");

    for (uint256 i; i < receivers.length; i++) {
      for (uint256 j; j < amounts[i]; j++) {
        reservedMinted++;
        _safeMint(receivers[i], _totalSupply++);
      }
    }
  }

  function setStatus(Status _status) external onlyOwner {
    status = _status;
  }

  function setContractURI(string memory uri) external onlyOwner {
    _contractURI = uri;
  }

  function setBaseURI(string memory uri) external onlyOwner {
    _tokenBaseURI = uri;
  }

  function setWatuAddress(address tokenAddress) external onlyOwner {
    WATU_ADDRESS = tokenAddress;
  }

  function setRoyaltyAddress(address royalty, uint256 value)
    external
    onlyOwner
  {
    TEAM_ADDRESS = royalty;
    _setRoyalty(royalty, value);
  }

  function setBreedPrice(uint256 price) external onlyOwner {
    BREED_PRICE = price;
  }

  function setNameChangePrice(uint256 price) external override onlyOwner {
    NAME_CHANGE_PRICE = price;
  }

  function setProvenance(string memory provenance) external onlyOwner {
    PROVENANCE = provenance;
  }

  function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    root = merkleRoot;
  }

  function withdraw() external onlyOwner {
    Address.sendValue(payable(TEAM_ADDRESS), address(this).balance);
  }

  function _leaf(address account, uint256 allowance)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(account, allowance));
  }

  function _verify(bytes32 leaf, bytes32[] memory proof)
    internal
    view
    returns (bool)
  {
    return MerkleProof.verify(proof, root, leaf);
  }

  // The following functions are overrides required by Solidity.

  function _baseURI() internal view override returns (string memory) {
    return _tokenBaseURI;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721) {
    if (tokenId < 1000) {
      IWatu(WATU_ADDRESS).updateReward(from, to, tokenId);
    }

    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, Royalty)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
