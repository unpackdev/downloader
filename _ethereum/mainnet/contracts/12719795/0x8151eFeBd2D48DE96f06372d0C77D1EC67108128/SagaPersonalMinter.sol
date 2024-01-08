pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./LibSafeMath.sol";
import "./ERC1155Mintable.sol";
import "./MixinOwnable.sol";
import "./MixinPausable.sol";
import "./MixinSignature.sol";
import "./HashRegistry.sol";

contract SagaPersonalMinter is Ownable, MixinPausable, MixinSignature {
  using LibSafeMath for uint256;

  uint256 public tokenType;

  ERC1155Mintable public mintableErc1155;
  HashRegistry public registry;

  // personal pricing params
  uint256 public flatPriceForPersonal;

  // max total minting supply
  uint256 immutable maxMintingSupply;

  address payable public treasury;
  address public verifier;

  struct SignedMint {
    address dst;
    uint256 txHash;
    uint256 salt;
    bytes signature;
  }

  constructor(
    address _registry,
    address _mintableErc1155,
    address _verifier,
    address payable _treasury,
    uint256 _tokenType,
    uint256 _flatPriceForPersonal,
    uint256 _maxMintingSupply
  ) {
    registry = HashRegistry(_registry);
    mintableErc1155 = ERC1155Mintable(_mintableErc1155);
    treasury = _treasury;
    tokenType = _tokenType;
    verifier = _verifier;
    flatPriceForPersonal = _flatPriceForPersonal;
    maxMintingSupply = _maxMintingSupply;
  }

  modifier onlyUnderMaxSupply(uint256 mintingAmount) {
    require(maxIndex() + mintingAmount <= maxMintingSupply, 'max supply minted');
    _;
  }

  function pause() external onlyOwner() {
    _pause();
  } 

  function unpause() external onlyOwner() {
    _unpause();
  }  

  function setTreasury(address payable _treasury) external onlyOwner() {
    treasury = _treasury;
  }

  function setFlatPriceForPersonal(uint256 _flatPriceForPersonal) external onlyOwner() {
    flatPriceForPersonal = _flatPriceForPersonal;
  }

  function setVerifier(address _verifier) external onlyOwner() {
    verifier = _verifier;
  }

  function maxIndex() public view returns (uint256) {
    return mintableErc1155.maxIndex(tokenType);
  }

  function getSignedMintHash(SignedMint memory signedMint) public pure returns(bytes32) {
      return keccak256(abi.encodePacked(signedMint.dst, signedMint.txHash, signedMint.salt)) ;
  }

  function verifyPersonalMint(address signer, SignedMint memory signedMint) public pure returns(bool) {
    bytes32 signedHash = getSignedMintHash(signedMint);
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(signedMint.signature);
    return isSigned(signer, signedHash, v, r, s);
  }

  function mint(SignedMint[] memory signedMints) public payable whenNotPaused() onlyUnderMaxSupply(signedMints.length) {
    // verify signatures
    for (uint256 i = 0; i < signedMints.length; ++i) {
      require(signedMints[i].dst == msg.sender, "mints not sent by dst");
      require(verifyPersonalMint(verifier, signedMints[i]) == true, 'invalid signature');
    }
    // verify and transfer fee
    uint256 price = flatPriceForPersonal * signedMints.length;
    require(price <= msg.value, "insufficient funds to pay for mint");
    treasury.call{value: price }("");
    msg.sender.transfer(msg.value.safeSub(price));

    //mint tokens
    address[] memory dsts = new address[](signedMints.length);
    uint256[] memory txHashes = new uint256[](signedMints.length);
    for (uint256 i = 0; i < signedMints.length; ++i) {
      dsts[i] = signedMints[i].dst;
      txHashes[i] = signedMints[i].txHash;
    }
    _mint(dsts, txHashes);
  }

  function _mint(address[] memory dsts, uint256[] memory txHashes) internal {
    uint256[] memory tokenIds = new uint256[](dsts.length);
    for (uint256 i = 0; i < dsts.length; ++i) {
      uint256 index = maxIndex() + 1 + i;
      uint256 tokenId  = tokenType | index;
      tokenIds[i] = tokenId;
    }
    mintableErc1155.mintNonFungible(tokenType, dsts);
    registry.writeToRegistry(tokenIds, txHashes);
  }
}