// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Counters.sol";

contract DracoNFT is ERC721Enumerable, Ownable, ReentrancyGuard {

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // Smart contract status
  enum MintStatus {
    CLOSED,
    PRESALE1,
    PRESALE2,
    PUBLIC
  }
  MintStatus public status = MintStatus.CLOSED;

  // ERC721 params
  string private _name = "DracoNFT";
  string private _symbol = "DRACO";
  string private _baseTokenURI = "https://mint.draconft.io/api/metadata/";

  // Collection params
  uint256 public TOTAL_SUPPLY = 10333;
  uint256 public RESERVED = 333;
  uint256 public PRESALE1_SUPPLY = 500;
  uint256 public PRESALE2_SUPPLY = 4500;
  uint256 public remaining_supply = TOTAL_SUPPLY - RESERVED;
  uint256 public remaining_reserved = RESERVED;
  uint256 public presale1_supply = PRESALE1_SUPPLY;
  uint256 public presale2_supply = PRESALE2_SUPPLY;

  uint256 private price = 0.09 ether;
  uint256[4] private MAX_PER_STATUS = [0, 2, 3, 20];

  address payable public addr1 = payable(0x59966F2590Cd638c351f8541d082d109603a465D); // 20%
  address payable public addr2 = payable(0xF42C7AECA097Aff686792db174f1B1E35996d3b7); // 2%
  address payable public addr3 = payable(0x48850Bad2D26eb1416E5d58B93403a66f186A992); // 78%

  // Amount minted
  mapping(address => uint256[4]) private _amountMinted;

  // Merkle tree
  bytes32 public merkleRoot1 =
    0x6d40b0662761b50c41b6b007692c06df798da8bae345ad2161be3ff55b2677da;
  bytes32 public merkleRoot2 =
    0x6d40b0662761b50c41b6b007692c06df798da8bae345ad2161be3ff55b2677da;

  // Event declaration
  event ChangedStatusEvent(uint256 newStatus);
  event ChangedBaseURIEvent(string newURI);
  event ChangedMerkleRoot(bytes32 newMerkleRoot1,bytes32 newMerkleRoot2);

  // Modifier to check claiming requirements
  modifier qtyValidation(uint256 _qty) {
    require(msg.sender == tx.origin);
    require(status != MintStatus.CLOSED, "Minting is closed");
    require(remaining_supply > 0, "Collection is sold out");
    require(_qty <= remaining_supply, "Not enough NFTs available");
    require(_qty > 0, "NFTs amount must be greater than zero");
    require(
      _qty <=
        MAX_PER_STATUS[uint256(status)],
      "Exceeded the max amount of mintable NFT"
    );
    require(msg.value == price * _qty, "Ether sent is not correct");
    _;
  }

  // Constructor
  constructor()
    ERC721(_name, _symbol)
  {
    ownerMint(7);
  }

  function ownerMint(uint256 _qty) public onlyOwner{
    require(_qty <= remaining_reserved, "Not enough NFTs available");
    remaining_reserved -= _qty;
    for (uint256 i = 0; i< _qty; i++){
      _tokenIds.increment();
      _safeMint(msg.sender, _tokenIds.current());
    }
  }

  // Pre-sale mint
  function presaleMint(uint256 _qty, bytes32[] calldata _proof)
    external
    payable
    nonReentrant
    qtyValidation(_qty)
  {
    require(status == MintStatus.PRESALE1 || status == MintStatus.PRESALE2, "Status is not presale");
    require(
      _qty + _amountMinted[msg.sender][uint256(status)] <=
        MAX_PER_STATUS[uint256(status)],
      "Exceeded the max amount of mintable NFT"
    );

    if(status == MintStatus.PRESALE1){
        require(
          MerkleProof.verify(
            _proof,
            merkleRoot1,
            keccak256(abi.encodePacked(msg.sender))
          ),
          "You are not in the first phase of the presale"
        );
        require(_qty <= presale1_supply, "Not enough NFTs available");
        presale1_supply -= _qty;
    } else if (status == MintStatus.PRESALE2){
        require(
          MerkleProof.verify(
            _proof,
            merkleRoot2,
            keccak256(abi.encodePacked(msg.sender))
          ),
          "You are not in the second phase of the presale"
        );
        require(_qty <= presale2_supply, "Not enough NFTs available");
        presale2_supply -= _qty;
    }
    
    _privateMint(_qty);
  }

  //  Public Mint
  function publicMint(uint256 _qty)
    external
    payable
    nonReentrant
    qtyValidation(_qty)
  {
    require(status == MintStatus.PUBLIC, "Status is not public");
    _privateMint(_qty);
  }

  function _privateMint(uint256 _qty) private {
    _amountMinted[msg.sender][uint256(status)] += _qty;
    remaining_supply -= _qty;
    for (uint256 i = 0; i< _qty; i++){
      _tokenIds.increment();
      _safeMint(msg.sender, _tokenIds.current());
    }
  }

  // Burn
  function burn(uint256 tokenId) public {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
    _burn(tokenId);
  }

  // Getters
  function tokenExists(uint256 _id) public view returns (bool) {
    return _exists(_id);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);

    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function getStatus()
    external
    view
    returns (
      string memory status_,
      uint256 qty_,
      uint256 price_,
      uint256 counter_
    )
  {
    uint256 mintedInStatus = _amountMinted[msg.sender][uint256(status)];
    uint256 maxStatus = MAX_PER_STATUS[uint256(status)];
    uint256 _remainingToMint = maxStatus - mintedInStatus;
    uint256 _price = price;

    if (remaining_supply == 0) {
      return ("SOLD_OUT", 0, _price, 0);
    }

    if (status == MintStatus.PUBLIC) {
      return ("PUBLIC", maxStatus, _price, remaining_supply);
    } else if (status == MintStatus.PRESALE1) {
      return ("PRESALE1", _remainingToMint, _price, presale1_supply);
    } else if (status == MintStatus.PRESALE2) {
      return ("PRESALE2", _remainingToMint, _price, presale2_supply);
    } else {
      return ("CLOSED", _remainingToMint, _price, remaining_supply);
    }
  }

  function _baseURI()
    internal
    view
    virtual
    override(ERC721)
    returns (string memory)
  {
    return _baseTokenURI;
  }

  // Setters
  function setStatus(uint8 _status) external onlyOwner {
    // _status -> 0: CLOSED, 1: PRESALE1, 2: PRESALE2, 3: PUBLIC
    require(
      _status >= 0 && _status <= 3,
      "Mint status must be between 0 and 3"
    );
    status = MintStatus(_status);
    emit ChangedStatusEvent(_status);
  }

  function setBaseURI(string memory _URI) external onlyOwner {
    _baseTokenURI = _URI;
    emit ChangedBaseURIEvent(_URI);
  }

  function setMerkleRoot(bytes32 _merkleRoot1, bytes32 _merkleRoot2) external onlyOwner {
    merkleRoot1 = _merkleRoot1;
    merkleRoot2 = _merkleRoot2;
    emit ChangedMerkleRoot(_merkleRoot1, _merkleRoot2);
  }

  function setAddr(address _addr1, address _addr2, address _addr3) external onlyOwner{
    require(_addr1 != address(0) && _addr2 != address(0) && _addr3 != address(0), "One of the address is the butn address");
    addr1 = payable(_addr1);
    addr2 = payable(_addr2);
    addr3 = payable(_addr3);
  }

  // Withdraw function
  function withdrawAll()
    external
    payable
    nonReentrant
    onlyOwner
  {
    require(address(this).balance != 0, "Balance is zero");
    uint balance = address(this).balance;
    payable(addr1).transfer(balance*20/100);
    payable(addr2).transfer(balance*2/100);
    payable(addr3).transfer(address(this).balance);
  }
}