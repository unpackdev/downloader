//      _______________________________________________      
//     /\                                              \     
// (O)===)><><><><><><><><><><><><><><><><><><><><><><><)=(O)
//     \/'''''''''''''''''''''''''''''''''''''''''''''''/     
//     (      ,-,-.   ,-,-.   ,-,-.   ,-,-.   ,-,-.    (     
//      )    / (_o \ /.( +.\ / (_o \ /.( +.\ / (_o \    )      
//     (     \ o ) / \ {. */ \ o ) / \ {. */ \ o ) /   (     
//      )     `-'-'   `-`-'   `-'-'   `-`-'   `-'-'     )    
//     (  _.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._. (     
//      ) _.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._.  )         
//     (  _.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._. (
//      )                  /)      (\                   )    
//     (                 ,-\/)    (\/-,                (
//      )                -----    -----                 )
//     (                 (o °)    (° o)                (
//      ) _.-=-._.-=-. m / V \ == / V \ m.-=-._.-=-._.  )
//     (                (     )  (     )               (
//      )                -m-m-   _-m-m-   _ _           )
//     (  ____ _   _  ____    __| |_ __ _<_> | ____ _  (
//      ) |   ' ) ' )|    )  |__   _/ _` | | |/ / _` |  )
//     (  |--- / / / |---<  ×   | || ( | | |  <  (_| | (
//      ) |   (_(_/  |____)     |_| \__,_|_|_|\_\__,_|  )
//     (                                               (           
//      ) _.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._.  )
//     (  _.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._. (           
//      )     ,-,-.   ,-,-.   ,-,-.   ,-,-.   ,-,-.     )     
//     (     / (_o \ /.( +.\ / (_o \ /.( +.\ / (_o \   (      
//      )    \ o ) / \ {. */ \ o ) / \ {. */ \ o ) /    )     
//     (      `-'-'   `-`-'   `-'-'   `-`-'   `-'-'    (          
//     /\'''''''''''''''''''''''''''''''''''''''''''''''\
// (O)===)><><><><><><><><><><><><><><><><><><><><><><><)=(O) 

// SPDX-License-Identifier: GPL 3.0

pragma solidity ^0.8.4;

import "./ERC721Royalty.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

error SaleIsLocked();
error SaleIsNotOpenToThisState();
error RaffleMintLimitReached();
error AllowlistMintLimitReached();
error AllTokensSold();
error AddressExceedsMintLimitPerAddress();
error TransactionValueMoreThanSetPrice();
error TransactionValueLessThanSetPrice();
error FWBBalanceOfFailed();
error NewAllocationSameAsBefore();
error NewTotalSupplyLessThanCurrentNumberOfMintedTokens();
error UnableToChangeAllocationStateIsCompleted();
error WithdrawalFailed();
error RequiresValidSignature();

contract TaikaFWB is ERC721Royalty, Ownable, ReentrancyGuard {
  using ECDSA for bytes32;

  enum SaleState {
    LOCKED,
    RAFFLE,
    ALLOWLIST,
    PUBLIC
  }

  SaleState public saleState = SaleState.LOCKED;

  uint256 public numberOfMintedTokens;
  uint256 public mintLimitPerAddress = 1;

  uint256 public mintAllocationRaffle = 100;
  uint256 public mintAllocationAllowlist = 250;
  uint256 public mintAllocationPublic = 50;

  mapping(SaleState => uint256) public cumulativeAllocationMap;
  mapping(address => uint256) public mintsPerAddress;

  uint256 public mintPriceRaffle = 0.0 ether;
  uint256 public mintPriceAllowlist = 0.08 ether;
  uint256 public mintPricePublic = 0.08 ether;

  uint256 public minimumFWBRequired = 5;

  address public authorizerSigner = 0x1c22eB3c39D631bDB4d6ec6F1390003E57dE093D;
  address public fwbContract = 0x35bD01FC9d6D5D81CA9E055Db88Dc49aa2c699A8;

  address public splitAddress;
  uint96 public royaltyFraction = 500;

  string public tokenBaseURI;
  string public tokenURISuffix = '';

  event Mint(address indexed buyer, uint256 price, uint256 indexed tokenId);

  constructor(
    string memory name,
    string memory symbol,
    string memory _tokenBaseURI,
    address _splitAddress
  ) ERC721(name, symbol) {
    tokenBaseURI = _tokenBaseURI;
    splitAddress = _splitAddress;

    updateCumulativeAllocationMap();

    _setDefaultRoyalty(splitAddress, royaltyFraction);
  }

  // ███████████████████████████████████████
  //
  // MODIFIERS
  // - STATE VAR VALIDATION
  // - SALE VALIDATION
  //
  // ███████████████████████████████████████

  modifier isAllocationSafe(uint256 newLimit, uint256 oldLimit) {
    _; // Do the updates first and then check

    if (cumulativeAllocationMap[SaleState.PUBLIC] < numberOfMintedTokens) {
      revert NewTotalSupplyLessThanCurrentNumberOfMintedTokens();
    }

    if (newLimit == oldLimit) {
      revert NewAllocationSameAsBefore();
    }
  }

  modifier isSaleValid(SaleState targetState, address receiver) {
    if (msg.sender != owner() && saleState == SaleState.LOCKED) {
      revert SaleIsLocked();
    }

    if (msg.sender != owner() && saleState != targetState) {
      revert SaleIsNotOpenToThisState();
    }

    if (numberOfMintedTokens >= cumulativeAllocationMap[targetState]) {
      if (targetState == SaleState.RAFFLE) {
        revert RaffleMintLimitReached();
      }
      if (targetState == SaleState.ALLOWLIST) {
        revert AllowlistMintLimitReached();
      }
      if (targetState == SaleState.PUBLIC) {
        revert AllTokensSold();
      }
    }

    if (
      msg.sender != owner() && mintsPerAddress[receiver] >= mintLimitPerAddress
    ) {
      revert AddressExceedsMintLimitPerAddress();
    }

    _;
  }

  modifier isValueValid(uint256 targetPrice) {
    if (msg.sender != owner() && msg.value < targetPrice) {
      revert TransactionValueLessThanSetPrice();
    }

    if (msg.sender != owner() && msg.value > targetPrice) {
      revert TransactionValueMoreThanSetPrice();
    }

    _;
  }



  // ███████████████████████████████████████
  //
  // PRIVATES / INTERNALS / OVERRIDES
  //
  // ███████████████████████████████████████

  function updateCumulativeAllocationMap() private {
    cumulativeAllocationMap[SaleState.RAFFLE] = mintAllocationRaffle;

    cumulativeAllocationMap[SaleState.ALLOWLIST] =
      mintAllocationRaffle +
      mintAllocationAllowlist;

    cumulativeAllocationMap[SaleState.PUBLIC] =
      mintAllocationRaffle +
      mintAllocationAllowlist +
      mintAllocationPublic;
  }

  function _baseURI() internal view override returns (string memory) {
    return tokenBaseURI;
  }

  function _mintPiece(address toAddress) private {
    emit Mint(msg.sender, msg.value, numberOfMintedTokens);
    _safeMint(toAddress, numberOfMintedTokens);
  }

  // ███████████████████████████████████████
  //
  // ONLYOWNER METHODS
  // - SETTERS FOR STATE VARS
  // - SETTERS FOR ROYALTY
  // - SETTERS FOR EXTERNAL ADDS
  // - BALANCE COLLECTION
  // - ADDRESS AIRDROP
  //
  // ███████████████████████████████████████

  function lockSale() public onlyOwner {
    saleState = SaleState.LOCKED;
  }

  function unlockSaleToRaffle() public onlyOwner {
    saleState = SaleState.RAFFLE;
  }

  function unlockSaleToAllowlist() public onlyOwner {
    saleState = SaleState.ALLOWLIST;
  }

  function unlockSaleToPublic() public onlyOwner {
    saleState = SaleState.PUBLIC;
  }

  function setMintLimitPerAddress(uint256 newLimit) public onlyOwner {
    mintLimitPerAddress = newLimit;
  }

  function setMintAllocationRaffle(uint256 newRaffleAllocation)
    public
    onlyOwner
    isAllocationSafe(newRaffleAllocation, mintAllocationRaffle)
  {
    // Can change allocation when contract is
    // saleSate = [LOCKED, FWB]
    if (saleState == SaleState.ALLOWLIST || saleState == SaleState.PUBLIC) {
      revert UnableToChangeAllocationStateIsCompleted();
    }

    mintAllocationRaffle = newRaffleAllocation;
    updateCumulativeAllocationMap();
  }

  function setMintAllocationAllowlist(uint256 newAllowlistAllocation)
    public
    onlyOwner
    isAllocationSafe(newAllowlistAllocation, mintAllocationAllowlist)
  {
    // Can change allocation when contract is
    // saleSate = [LOCKED, FWB, ALLOWLIST]
    if (saleState == SaleState.PUBLIC) {
      revert UnableToChangeAllocationStateIsCompleted();
    }

    mintAllocationAllowlist = newAllowlistAllocation;
    updateCumulativeAllocationMap();
  }

  function setMintAllocationPublic(uint256 newPublicAllocation)
    public
    onlyOwner
    isAllocationSafe(newPublicAllocation, mintAllocationPublic)
  {
    mintAllocationPublic = newPublicAllocation;
    updateCumulativeAllocationMap();
  }

  /**
   * @notice Set mint price for FWB holders
   * @param newPrice new price
   */
  function setMintPriceRaffle(uint256 newPrice) public onlyOwner {
    mintPriceRaffle = newPrice;
  }

  /**
   * @notice Set mint price for allowlist addresses
   * @param newPrice new price
   */
  function setMintPriceAllowlist(uint256 newPrice) public onlyOwner {
    mintPriceAllowlist = newPrice;
  }

  /**
   * @notice Set mint price for the public
   * @param newPrice new price
   */
  function setMintPricePublic(uint256 newPrice) public onlyOwner {
    mintPricePublic = newPrice;
  }

  /**
   * @notice Set new minimum FWB ERC20 tokens required to mint
   * @dev Minimum is set as integer, not WEI
   * @param newMin new minimum as integer
   */
  function setMinimumFWBRequired(uint256 newMin) public onlyOwner {
    minimumFWBRequired = newMin;
  }

  /**
   * @notice Set the public address of allowlist authorizer
   * authorizer is responsible for signing the msg.sender
   * with their private key.
   * @param newSignerAddress new signer address
   */
  function setAuthorizerSigner(address newSignerAddress) public onlyOwner {
    authorizerSigner = newSignerAddress;
  }

  /**
   * @notice Set the contract address to check for FWB ERC20 tokens
   * @param newContractAddress new contract address
   */
  function setFWBContract(address newContractAddress) public onlyOwner {
    fwbContract = newContractAddress;
  }

  /**
   * @notice Set the 0xSplit address
   * @dev IMPORTANT: If you use this function you need to
   * call setDefaultRoyalty to update the royalty recipient.
   * @param newSplitAddress new 0xSplit address
   */
  function setSplitAddress(address newSplitAddress) public onlyOwner {
    splitAddress = newSplitAddress;
  }

  /**
   * @notice Set the default royalty in basis points
   * @dev Value in basis points e.g. 5% => 500
   * @param recipient new royalty recipient
   * @param fraction new royalty fraction in basis points
   */
  function setDefaultRoyalty(address recipient, uint96 fraction)
    public
    onlyOwner
  {
    royaltyFraction = fraction;
    _setDefaultRoyalty(recipient, fraction);
  }

  /**
   * @notice Set the royalty of a specific token
   * @dev Value in basis points e.g. 5% => 500
   * @param tokenId tokenID of interest
   * @param recipient new royalty recipient
   * @param fraction new royalty fraction in basis points
   */
  function setTokenRoyalty(
    uint256 tokenId,
    address recipient,
    uint96 fraction
  ) public onlyOwner {
    _setTokenRoyalty(tokenId, recipient, fraction);
  }

  function deleteDefaultRoyalty() public onlyOwner {
    royaltyFraction = 0;
    _deleteDefaultRoyalty();
  }

  function setTokenBaseURI(string memory newBaseURI) public onlyOwner {
    tokenBaseURI = newBaseURI;
  }

  function setTokenURISuffix(string memory newTokenURISuffix) public onlyOwner {
    tokenURISuffix = newTokenURISuffix;
  }

  function collect() public onlyOwner {
    (bool res, ) = payable(splitAddress).call{value: address(this).balance}('');

    if (res == false) {
      revert WithdrawalFailed();
    }
  }

  /**
   * @notice Gifts the receiver a token
   * @param receiver address of the receiving party
   */
  function gift(address receiver)
    public
    onlyOwner
    isSaleValid(SaleState.PUBLIC, receiver)
  {
    mintsPerAddress[receiver] += 1;
    numberOfMintedTokens += 1;
    _mintPiece(receiver);
  }

  // ███████████████████████████████████████
  //
  // PUBLICS / GETTERS
  //
  // ███████████████████████████████████████

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    string memory tokenURIBasename = super.tokenURI(tokenId);

    return
      bytes(tokenURIBasename).length > 0
        ? string(abi.encodePacked(tokenURIBasename, tokenURISuffix))
        : '';
  }

  function tokensLeft() public view returns (uint256) {
    return cumulativeAllocationMap[SaleState.PUBLIC] - numberOfMintedTokens;
  }

  function totalSupply() public view returns (uint256) {
    return cumulativeAllocationMap[SaleState.PUBLIC];
  }

  function exists(uint256 tokenId) public view returns (bool) {
    return _exists(tokenId);
  }

  function fwbBalanceOfAddress(address account) public view returns (uint256) {
    (bool success, bytes memory res) = fwbContract.staticcall(
      abi.encodeWithSignature('balanceOf(address)', account)
    );

    if (success == false) {
      revert FWBBalanceOfFailed();
    }

    return abi.decode(res, (uint256));
  }

  // ███████████████████████████████████████
  //
  // ECDSA / CRYPTOGRAPHY
  //
  // ███████████████████████████████████████

  function senderHash() public view returns (bytes32) {
    bytes32 hash = keccak256(abi.encodePacked(msg.sender));
    return hash;
  }

  function getSigner(bytes memory signature) public view returns (address) {
    return senderHash().toEthSignedMessageHash().recover(signature);
  }

  // ███████████████████████████████████████
  //
  // MINTING FUNCTIONS
  //
  // ███████████████████████████████████████

  function mintRaffle(bytes memory signature)
    public
    payable
    isSaleValid(SaleState.RAFFLE, msg.sender)
    isValueValid(mintPriceRaffle)
  {
    if (getSigner(signature) != authorizerSigner) {
      revert RequiresValidSignature();
    }

    mintsPerAddress[msg.sender] += 1;
    numberOfMintedTokens += 1;
    _mintPiece(msg.sender);
  }

  function mintAllowlist(bytes memory signature)
    public
    payable
    isSaleValid(SaleState.ALLOWLIST, msg.sender)
    isValueValid(mintPriceAllowlist)
  {
    if (fwbBalanceOfAddress(msg.sender) < minimumFWBRequired * (1 ether)) {
      if (getSigner(signature) != authorizerSigner) {
        revert RequiresValidSignature();
      }
    }

    mintsPerAddress[msg.sender] += 1;
    numberOfMintedTokens += 1;
    _mintPiece(msg.sender);
  }

  function mintPublic(bytes memory signature)
    public
    payable
    isSaleValid(SaleState.PUBLIC, msg.sender)
    isValueValid(mintPricePublic)
  {
    if (getSigner(signature) != authorizerSigner) {
      revert RequiresValidSignature();
    }

    mintsPerAddress[msg.sender] += 1;
    numberOfMintedTokens += 1;
    _mintPiece(msg.sender);
  }
}
