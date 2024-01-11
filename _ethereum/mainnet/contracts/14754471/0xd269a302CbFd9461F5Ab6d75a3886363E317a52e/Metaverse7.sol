// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SignatureChecker.sol";
import "./MerkleProof.sol";
import "./ECDSA.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./IERC4494.sol";
import "./IERC2981.sol";


contract Metaverse7 is ERC721A, IERC2981, IERC4494, ReentrancyGuard, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  /// @dev Value is equal to keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;
  bytes32 internal immutable nameHash;
  bytes32 internal immutable versionHash;
  uint256 internal immutable INITIAL_CHAIN_ID;
  bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

  Counters.Counter private _tokenIds;
  mapping(uint256 => string) private _tokenURIs;
  mapping(uint256 => uint256) private _nonces;
  mapping(address => uint256) public minted;
  mapping(address => uint256) public publicMinted;
  mapping(address => bool) public founderClaimed;

  uint256 private PRICE = 0.1 ether;
  uint256 private PRESALE_PRICE = 0.07 ether;
  uint256 private MAX_PER_ADDRESS;
  uint256 private MAX_PER_ADDRESS_PUBLIC;
  uint256 private immutable MAX_SUPPLY;
  bytes32 private founderRoot;
  bytes32 private presaleRoot;
  bool public presaleFlag;
  bool public founderFlag;
  bool public publicFlag;
  string private baseURI;
  string private preRevealURI;
  string private _suffix = ".json";
  uint256 private toReveal;

  /// @notice rate and scale are the royalty rate vars
  /// @notice in the default values, there would be a 3% tax on a 18 decimal asset
  /// @dev rate: the scaled rate (divide by scale to determine traditional percentage)
  uint256 private rate = 5_000;
  /// @dev scale: how much to divide amount * rate buy
  uint256 private scale = 1e5;

  event PreRevealURIUpdated(string uri);
  event BaseURIUpdated(string uri);
  event FounderMerkleRootUpdated(bytes32 root);
  event PresaleMerkleRootUpdated(bytes32 root);
  event RevealNumberUpdated(uint256 amount);
  event RoyaltyRateUpdated(uint256 amount);
  event FlagSwitched(bool state);
  event PublicPriceUpdated(uint256 price);
  event PresalePriceUpdated(uint256 price);
  event MaxPerAddressUpdated(uint256 quantity);


  error WithdrawEthFailed();

  constructor(
    string memory name, 
    string memory symbol, 
    string memory version,
    uint256 tokenSupply,
    bytes32 _foundersRoot
  ) 
    ERC721A(name, symbol)
  {
    nameHash = keccak256(bytes(name));
    versionHash = keccak256(bytes(version));
    MAX_SUPPLY = tokenSupply;

    founderRoot = _foundersRoot;

    INITIAL_CHAIN_ID = block.chainid;
    INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
  }

  function _startTokenId() internal pure override returns (uint256) {
      return 1;
  }

  function tokenURI(uint256 tokenId) public override view returns(string memory) {
    require(_exists(tokenId), "URI query for nonexistent token");

    if (bytes(baseURI).length == 0) {
      return preRevealURI;

    } else {
      if (tokenId <= toReveal){
        return string(abi.encodePacked(baseURI, tokenId.toString(), _suffix)); 
      }
      else return preRevealURI;
    }
  }

  function getCreator(uint256 tokenId) public view returns(address) {
    require(ERC721A._exists(tokenId), "getCreator: nonexistent token");
    return owner();
  }

  function switchFounderFlag(bool state) public onlyOwner {
    string memory boolString = state == true ? "true" : "false";
    require(founderFlag != state, string(abi.encodePacked("Phase Status already ", boolString)));
    founderFlag = state;
    emit FlagSwitched(state);
  }

  function switchPresaleFlag(bool state) public onlyOwner {
    string memory boolString = state == true ? "true" : "false";
    require(presaleFlag != state, string(abi.encodePacked("Phase Status already ", boolString)));
    presaleFlag = state;
    emit FlagSwitched(state);
  }

  function switchPublicFlag(bool state) public onlyOwner {
    string memory boolString = state == true ? "true" : "false";
    require(publicFlag != state, string(abi.encodePacked("Phase Status already ", boolString)));
    publicFlag = state;
    emit FlagSwitched(state);
  }

  function setRoyaltyRate(uint256 _rate) external onlyOwner {
    rate = _rate;
    emit RoyaltyRateUpdated(_rate);
  }

  function setPreRevealURI(string memory uri) external onlyOwner {
    preRevealURI = uri;
    emit PreRevealURIUpdated(uri);
  }

  function setBaseURI(string memory uri) external onlyOwner {
    baseURI = uri;
    emit BaseURIUpdated(uri);
  }

  function setFounderMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    founderRoot = _merkleRoot;
    emit FounderMerkleRootUpdated(_merkleRoot);
  }

  function setPresaleMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    presaleRoot = _merkleRoot;
    emit PresaleMerkleRootUpdated(_merkleRoot);
  }

  function setPresaleMaxPerAddress(uint256 quantity) external onlyOwner {
    MAX_PER_ADDRESS = quantity;
    emit MaxPerAddressUpdated(quantity);
  }

  function setPublicMaxPerAddress(uint256 quantity) external onlyOwner {
    MAX_PER_ADDRESS_PUBLIC = quantity;
    emit MaxPerAddressUpdated(quantity);
  }

  function setPresalePrice(uint256 price) external onlyOwner {
    require(price > 0.01 ether, "PRICE TOO LOW");
    PRESALE_PRICE = price;
    emit PresalePriceUpdated(price);
  }

  function setPublicPrice(uint256 price) external onlyOwner {
    require(price > 0.01 ether, "PRICE TOO LOW");
    PRICE = price;
    emit PublicPriceUpdated(price);
  }

  function setRevealNumber(uint256 amount) external onlyOwner {
    toReveal = amount;
    emit RevealNumberUpdated(amount);
  }

  function withdrawFunds() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    if (!os) revert WithdrawEthFailed();
  }


  // NOTE: in current structure, must mint entire allotted quantity in one mint
  function founderMint(address to, uint256 quantity, bytes32[] calldata proof) public payable {
    require(founderFlag, "founder mint is not Active");
    require(quantity + totalSupply() <= MAX_SUPPLY, "Insuficient Token Supply");
    require(MerkleProof.verify(proof, founderRoot, keccak256(abi.encodePacked(msg.sender, quantity))), 
      "Invalid merkle proof"
    );
    require(founderClaimed[msg.sender] == false, "Tokens have already been Minted");

    founderClaimed[msg.sender] = true;
    _safeMint(to, quantity, "");
    
  }

  function presaleMint(address to, uint256 quantity, bytes32[] calldata proof) public payable nonReentrant {
    require(presaleFlag, "presale Mint is not Active");
    require(quantity + totalSupply() <= MAX_SUPPLY, "Insuficient Token Supply");
    require(msg.value >= PRESALE_PRICE * quantity, "prslMint:insufficient ETH");
    require(MerkleProof.verify(proof, presaleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid merkle proof");
    if (MAX_PER_ADDRESS > 0){
      require(quantity + minted[msg.sender] <= MAX_PER_ADDRESS, "amount exceeds max");
    } 

    minted[msg.sender] += quantity;
    _safeMint(to, quantity, "");

    (bool success,) = owner().call{ value: msg.value }("");
    require(success, "mint:ETH transfer failed");
    }

  function mint(address to, uint256 quantity) public payable nonReentrant {
    require(publicFlag, "public sale not Active");
    require(quantity + totalSupply() <= MAX_SUPPLY, "Insuficient Token Supply");
    require(msg.value >= PRICE * quantity, "mint:insufficient ETH");
    if (MAX_PER_ADDRESS_PUBLIC > 0) {
      require(quantity + publicMinted[msg.sender] <= MAX_PER_ADDRESS_PUBLIC, "mint:exceeds max per address");
    }

    publicMinted[msg.sender] += quantity;
    _safeMint(to, quantity);

    (bool success, ) = owner().call{value: msg.value}("");
    require(success, "mint:ETH transfer failed");
  }

  function transferWithPermit(
    address from,
    address to,
    uint256 tokenId,
    uint256 deadline,
    bytes memory sig
  ) public {
    permit(to, tokenId, deadline, sig);
    safeTransferFrom(from, to, tokenId, "");
  }

  function _baseURI() internal view override returns(string memory) {
    return baseURI;
  }

  // permit stuff
  function nonces(uint256 tokenId) external view returns(uint256) {
    require(_exists(tokenId), 'nonces: query for nonexistent token');
    return _nonce(tokenId);
  }

  /// @notice gets the global royalty rate
  /// @dev divide rate by scale to get the percentage taken as royalties
  /// @return a tuple of (rate, scale)
  function getRoyaltyRate() external view returns (uint256, uint256) {
      return (rate, scale);
  }

  /// @notice Given an NFT and the amount of a price, returns pertinent royalty information
  /// @dev This function is specified in EIP-2981
  /// @param _salePrice the amount the NFT is being sold for
  /// @return the address to send the royalties to, and the amount to send
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
      external
      view
      returns (address, uint256)
  {
      uint256 royaltyAmount = (_salePrice * rate) / scale;
      return (owner(), royaltyAmount);
  }

  function DOMAIN_SEPARATOR() public view returns (bytes32) {
    return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
  }

  function permit(
    address spender,
    uint256 tokenId,
    uint256 deadline,
    bytes memory sig
  ) public override {
    require(block.timestamp <= deadline, 'Permit expired');

    bytes32 digest =
      ECDSA.toTypedDataHash(
        DOMAIN_SEPARATOR(),
        keccak256(
          abi.encode(
            PERMIT_TYPEHASH,
            spender,
            tokenId,
            _nonces[tokenId],
            deadline
          )
        )
      );

    (address recoveredAddress,) = ECDSA.tryRecover(digest, sig);
    address owner = ownerOf(tokenId);

    require(recoveredAddress != address(0), 'Invalid signature');
    require(spender != owner, 'ERC721Permit: approval to current owner');
    if(owner != recoveredAddress){
      require(
        // checks for both EIP2098 sigs and EIP1271 approvals
        SignatureChecker.isValidSignatureNow(
          owner,
          digest,
          sig
        ),
        "ERC721Permit: unauthorized"
      );
    }

    approve(spender, tokenId);
  }

  function computeDomainSeparator() internal view returns(bytes32) {
    return keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        nameHash,
        versionHash,
        block.chainid,
        address(this)
      )
    );
  }

  function _transfer(address from, address to, uint256 tokenId) internal override {
    ERC721A._transfer(from, to, tokenId);
    if(from != address(0)) {
      _nonces[tokenId]++;
    }
  }

  function _getChainId() internal view returns(uint256 chainId) {
    return block.chainid;
  }

  function _nonce(uint256 tokenId) internal view returns(uint256) {
    return _nonces[tokenId];
  }

}