//   ____  _____  ____  ____  __  
//  (  _ \(  _  )(  _ \(_  _)/. | 
//   )___/ )(_)(  )   /  )( (_  _)
//  (__)  (_____)(_)\_) (__)  (_) 
//

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2; // required to accept structs as function parameters

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./Counters.sol";

contract Snapshot is ERC721URIStorage, EIP712, Ownable {
  struct PORT4voucher {
    string uri;
    bool isFree;
    bytes signature;
  }

  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  Counters.Counter private _freeSnapshots;

  string private constant PORT4_DOMAIN = "PORT4-SNAPSHOT";
  string private constant PORT4_VERSION = "1.0";
  address public PORT4_SIGNER;

  uint private constant basePrice = 200000000 gwei; // 0.2 eth

  mapping(bytes32 => bool) redeemedVouchers; 
  mapping(uint256 => string) private _tokenURIs;

  constructor(address owner, address signer)
  ERC721("PORT4 Blueprint Snapshots", "PORT4") 
  EIP712(PORT4_DOMAIN, PORT4_VERSION) {
    PORT4_SIGNER = signer;
    transferOwnership(owner);
  }

  /// @notice Redeems an PORT4voucher for a PORT4 SNAPSHOT NFT
  /// @param voucher A signed PORT4voucher that describes the NFT to be redeemed.
  function redeem(PORT4voucher calldata voucher) public payable returns (uint256) {
    address redeemer = msg.sender;
    // get the address of the signer and make sure signature is valid
    address signer = _verify(voucher);
    require(PORT4_SIGNER == signer, "Signature invalid or unauthorized");
    require((msg.value >= basePrice) || voucher.isFree, "Insufficient funds to redeem");
    
    // we guarantee that only 50 snapshots can be given away for less than the base price
    if (msg.value < basePrice) {
      require(_freeSnapshots.current() < 50, "Max number of free Snapshots have been minted already");
      _freeSnapshots.increment();
    }

    bytes32 signatureHash = keccak256(voucher.signature);
    require(redeemedVouchers[signatureHash] == false, "Voucher has already been redeemed");

    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();

    // only 1000 snapshots can be minted
    require(newItemId <= 1000, "Max number of Snapshots have been minted already");

    // first assign the token to the owner, to establish provenance on-chain
    // then transfer the token to the redeemer
    _mint(owner(), newItemId);
    _setTokenURI(newItemId, voucher.uri);
    _transfer(owner(), redeemer, newItemId);

    redeemedVouchers[signatureHash] = true;
    return newItemId;
  }

  function setSigner(address newSigner) public onlyOwner {
    PORT4_SIGNER = newSigner;
  }

  /// @notice Transfers full contract balance to PORT4 gnosis safe.
  function withdraw() public onlyOwner {
    uint amount = address(this).balance;
    payable(owner()).transfer(amount);
  }

  /// @notice Returns a hash of the given PORT4voucher, according to EIP712.
  /// @param voucher A PORT4voucher to hash.
  function _hash(PORT4voucher calldata voucher) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256("PORT4voucher(string uri,bool isFree)"),
      keccak256(bytes(voucher.uri)),
      voucher.isFree
    )));
  }

  /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
  /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
  /// @param voucher a PORT4Voucher describing an unminted Snapshot.
  function _verify(PORT4voucher calldata voucher) internal view returns (address) {
    bytes32 digest = _hash(voucher);
    return ECDSA.recover(digest, voucher.signature);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721) returns (bool) {
    return ERC721.supportsInterface(interfaceId);
  }
}