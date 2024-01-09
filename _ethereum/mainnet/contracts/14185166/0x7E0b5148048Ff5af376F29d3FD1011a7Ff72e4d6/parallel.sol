// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./ECDSA.sol";
import "./ERC2981ContractWideRoyalties.sol";

/// @title ELYX Genesis Parallel collection smart contract
/// @author Dev by Arenzel (@arenzel_eth)
/// @notice Parallel collection, 1 111 declinations of Elyx (digital ambassador for the United Nations, see https://unric.org/en/elyx/)
contract Parallel is ERC1155, Ownable, ERC2981ContractWideRoyalties, Pausable {

  /*** ----------------------- CONFIGS ----------------------- ***/

  /// @notice Name + symbol + total supply, Token data to be displayed on etherscan

  string public name = "ELYX | Genesis | Para11e1";
  string public symbol = "LLLL";

  /// @notice Max amount of token to be ever minted
  /// @dev In lower case to be compliant with Etherscan...
  uint public constant totalSupply = 1111;

  /// @notice Token price for public sale
  uint public price = 0.1111 ether;

  /// @notice Max amount of tokens/transaction
  uint public maxAmountPerTransaction = 5;

  // @notice Artist wallet (ELYXyak.eth)
  address private constant ELYXYAK_WALLET = 0xD31a8fbcA285eAa3B5BcD2f5973FC05296382640;

  /// @notice Royalties: 10% for ELYXyak.eth (artist)
  /// @dev Using 2 decimals notation: 10000 = 100, 0 = 0
  uint private constant ELYXYAK_ROYALTIES = 1000;


  /*** ----------------------- SUPPLY - GENERAL ----------------------- ***/

  /// @notice Token supply for founders and pre-sales.

  uint private constant FOUNDER_SUPPLY = 111;           /// @notice For artists + devs + core team
  uint private constant PRESALE_PHYGITAL_SUPPLY = 111;  /// @notice For phygital collectors who bought the printed painting
  uint private constant GREENLIST_SUPPLY = 222;         /// @notice Registration through offline signatures
  uint private constant PUBLIC_SALE_SUPPLY = 667;       /// @notice For everyone at drop


  /// @notice To calculate remaining supplies we need to know the first ID of each subset

  uint private constant FIRST_FOUNDER_ID = 1;
  uint private constant FIRST_PRESALE_PHYGITAL_ID = 112;
  uint private constant FIRST_GREENLIST_ID = 223;
  uint private constant FIRST_PUBLIC_SALE_ID = 445;


  /// @notice Keeping track of subset of the total token supply

  using Counters for Counters.Counter;
  Counters.Counter private founderTokenCounter;
  Counters.Counter private greenlistTokenCounter;
  Counters.Counter private publicSaleTokenCounter;


  /// @notice Remaining supplies functions

  function founderTokenLeft() public view returns (uint) {
    return FOUNDER_SUPPLY - founderTokenCounter.current();
  }

  function greenlistTokenLeft() public view returns (uint) {
    return GREENLIST_SUPPLY - greenlistTokenCounter.current();
  }

  function publicSaleTokenLeft() public view returns (uint) {
    return PUBLIC_SALE_SUPPLY - publicSaleTokenCounter.current();
  }


  /// @notice Next IDs functions

  function nextFounderTokenId() private view returns (uint) {
    return FIRST_FOUNDER_ID + founderTokenCounter.current();
  }

  function nextGreenlistTokenId() private view returns (uint) {
    return FIRST_GREENLIST_ID + greenlistTokenCounter.current();
  }

  function nextPublicSaleTokenId() private view returns (uint) {
    return FIRST_PUBLIC_SALE_ID + publicSaleTokenCounter.current();
  }


  /*** ----------------------- SUPPLY - PHYGITAL ----------------------- ***/

  /// @dev Because the phygital collector tokens won't be minted in order,
  /// we need to keep track of the already minted ones
  mapping (uint => address) private phygitalTokenIds;

  /// @notice Never trust user input: we ensure the user sends a tokenId that is inside the range of phygical tokens
  /// @dev Return true if the tokenId is in range
  function validPhygitalTokenId(uint _tokenId) private pure returns (bool) {
    return _tokenId >= FIRST_PRESALE_PHYGITAL_ID && _tokenId < FIRST_GREENLIST_ID;
  }


  /*** ----------------------- CONSTRUCTOR ----------------------- ***/

  constructor() ERC1155("ipfs://QmbMcxBEsVgwP3yZDijj7wUwiLJHbGbCXmFe8DotMnup4T/{id}.json") {
    _setRoyalties(ELYXYAK_WALLET, ELYXYAK_ROYALTIES);
  }


  /*** ----------------------- MINT FUNCTIONS ----------------------- ***/

  /// @notice This smart contract has 4 mint functions based on the 4 token subsets of the supply

  /// @notice Mint function for founders.
  function founderMint(uint _amount, address _to) external onlyOwner {
    require(founderTokenLeft() > 0, "FOUNDER_TOKEN_SOLD_OUT: There is no more founder token left.");
    require(founderTokenLeft() - _amount >= 0, "INSUFFICIENT_FOUNDER_TOKEN_LEFT: Not enough founder token left");

    for (uint256 index = 0; index < _amount; index++) {
      uint _tokenId = nextFounderTokenId();
      founderTokenCounter.increment();

      _mint(_to, _tokenId, 1, "");
    }
  }

  /// @notice Mint function for phygital collector (physical painting + nft) during the initial exhibition. The NFT must match the painting.
  /// @param _tokenIds list of Token ID converted from 4 digits string to uint by frontend
  function phygitalMint(uint[] memory _tokenIds, bytes memory _signature) external whenNotPaused {
    require(signatureIsValid(_tokenIds, _signature), "INVALID_PHYGITAL_SIGNATURE: please check address and tokenIds");

    for (uint index = 0; index < _tokenIds.length; index++) {
      uint tokenId = _tokenIds[index];
      require(validPhygitalTokenId(tokenId), "INVALID_TOKEN_ID: invalid phygital token ID");
      require(phygitalTokenIds[tokenId] == address(0), "UNAVAILABLE_TOKEN: this NFT is already minted.");

      phygitalTokenIds[tokenId] = msg.sender;

      _mint(msg.sender, tokenId, 1, "");
    }
  }

  /// @notice Mint function for green listed collectors.
  function greenlistMint(uint _amount, bytes memory _signature) external payable whenNotPaused {
    require(signatureIsValid(_signature), "INVALID_GREENLIST_SIGNATURE: are you sure your address is greenlisted?");
    require(greenlistTokenLeft() > 0, "GREENLIST_TOKEN_SOLD_OUT: no more greenlist token left.");
    require(greenlistTokenLeft() - _amount >= 0, "INSUFFICIENT_GREENLIST_TOKEN_LEFT: not enough token left");
    require(_amount <= maxAmountPerTransaction, "TOKEN_PER_TRANSACTION_LIMIT_EXCEEDED: amount of token exceeds the max amount of tokens per transaction limit");
    require(msg.value == price * _amount, "INCORRECT_PAYMENT_AMOUNT: Ooops! An incorrect quantity of ETH was sent! Please check the price of this NFT. :)");

    for (uint256 index = 0; index < _amount; index++) {
      uint _tokenId = nextGreenlistTokenId();
      greenlistTokenCounter.increment();

      _mint(msg.sender, _tokenId, 1, "");
    }
  }

  /// @notice Mint function for the public sale.
  function publicMint(uint _amount) external payable whenNotPaused {
    require(publicSaleTokenLeft() > 0, "PUBLIC_SALE_TOKEN_SOLD_OUT: no more token available, sorry.");
    require(publicSaleTokenLeft() - _amount >= 0, "INSUFFICIENT_PUBLIC_SALE_TOKEN_LEFT: not enough token left");
    require(_amount <= maxAmountPerTransaction, "TOKEN_PER_TRANSACTION_LIMIT_EXCEEDED: amount of token exceeds the max amount of tokens per transaction limit");
    require(msg.value == price * _amount, "INCORRECT_PAYMENT_AMOUNT: Ooops! An incorrect quantity of ETH was sent! Please check the price of this NFT. :)");

    for (uint256 index = 0; index < _amount; index++) {
      uint _tokenId = nextPublicSaleTokenId();
      publicSaleTokenCounter.increment();

      _mint(msg.sender, _tokenId, 1, "");
    }
  }


  /*** ----------------------- BURN FUNCTION ----------------------- ***/

  /// @notice Giving the ability for a owner to destroy its token(s).
  /// @dev We use this method as an API to ERC-1155 _burn
  function burn(uint _tokenId) external whenNotPaused {
      _burn(msg.sender, _tokenId, 1);
  }


  /*** ----------------------- CONFIG FUNCTIONS ----------------------- ***/

  function setName(string memory _name) external onlyOwner {
    name = _name;
  }

  function setSymbol(string memory _symbol) external onlyOwner {
    symbol = _symbol;
  }

  function setPrice(uint _price) external onlyOwner {
    price = _price;
  }

  function setMaxAmountPerTransaction(uint _amount) external onlyOwner {
    maxAmountPerTransaction = _amount;
  }


  /*** ----------------------- UTILITY FUNCTIONS ----------------------- ***/

  /// @notice To display contract-level metadata on OpenSea
  function contractURI() public pure returns (string memory) {
    return "ipfs://QmW3mACVdGoepRQP4cttKYNZRuP7U8cemHpyQw5Hu687X7";
  }

  /// @notice Withdraw eth from the contract to the owner's wallet
  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }


  /*** ----------------------- SIGNATURE FUNCTIONS ----------------------- ***/

  /// @notice We use offchain signature for our greenlists

  /// @dev Public key of the wallet used to generate signatures
  address private constant ELYX_SIGNER_WALLET = 0x348c2FfB9Ba0431BC40118BbbeB968a6d1122212;

  /// @notice Phygital list signature validation
  function signatureIsValid(
    uint[] memory _tokenIds,
    bytes memory _signature
  ) private view returns (bool) {
    uint tokenIdsSum = getSumFor(_tokenIds);
    bytes32 _signedMessageHash = ECDSA.toEthSignedMessageHash(
      keccak256(abi.encodePacked(
        tokenIdsSum,
        msg.sender,
        address(this)
      ))
    );

    address recoveredAddress = ECDSA.recover(_signedMessageHash, _signature);

    return recoveredAddress == ELYX_SIGNER_WALLET;
  }

  /// @notice Greenlist signature validation
  function signatureIsValid(
    bytes memory _signature
  ) private view returns (bool) {
    bytes32 _signedMessageHash = ECDSA.toEthSignedMessageHash(
      keccak256(abi.encodePacked(
        msg.sender,
        address(this)
      ))
    );

    address recoveredAddress = ECDSA.recover(_signedMessageHash, _signature);

    return recoveredAddress == ELYX_SIGNER_WALLET;
  }


  /*** ----------------------- EMERGENCY FUNCTIONS ----------------------- ***/

  /// @notice Block execution of public mint/burn function
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Resuming activity: back to mint business!
  function unpause() external onlyOwner {
    _unpause();
  }


  /*** ----------------------- TECHNICAL FUNCTIONS ----------------------- ***/

  /// @dev As both ERC1155 and ERC2981Base include supportsInterface we need to override both.
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981Base) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /// @dev Function to return sum of elements of dynamic array, used for signature computation
  function getSumFor(uint[] memory _array) private pure returns (uint) {
    uint i;
    uint sum = 0;

    for (i = 0; i < _array.length; i++) {
      sum = sum + _array[i];
    }

    return sum;
  }

}