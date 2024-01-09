// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./ERC1155Holder.sol";
import "./Address.sol";
import "./IERC1155.sol";

contract FLUFDynamicMarketplace is ERC1155Holder, ReentrancyGuard, Ownable {
  using ECDSA for bytes32;
  using Address for address;

  struct Sales {
    address contractAddress; // The contractAddresses
    uint256[] ids; // The tokenIds
    uint256[] amounts; // The quantity of each token to transfer
    uint256 price;
  }

  mapping(uint256 => Sales) public availableSales;
  uint256 public saleNonce = 0; // The nonce of the current sale, starts with 0;
  mapping(uint256 => mapping(bytes => bool)) public usedToken; // Whether the SALT Token has been consumed
  mapping(uint256 => mapping(address => bool)) public addressMinted; // Whether this address has already minted during this sale

  enum State {
    Closed,
    PrivateSale,
    PublicSale
  }

  State private _state;
  address private _signer;

  constructor(address signer) {
    _signer = signer;
  }

  function setSaleToClosed() public onlyOwner {
    _state = State.Closed;
  }

  function setSaleToPrivate() public onlyOwner {
    _state = State.PrivateSale;
  }

  function setSaleToPublic() public onlyOwner {
    _state = State.PublicSale;
  }

  function listNewSale(
    address _contractAddress,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    uint256 _price
  ) public onlyOwner {
    saleNonce = saleNonce + 1;
    availableSales[saleNonce].contractAddress = _contractAddress;
    availableSales[saleNonce].ids = _ids;
    availableSales[saleNonce].amounts = _amounts;
    availableSales[saleNonce].price = _price;
  }

  function updateSaleNonce(uint256 _nonce) public onlyOwner {
    saleNonce = _nonce;
  }

  function updateSigner(address __signer) public onlyOwner {
    _signer = __signer;
  }

  function _hash(string calldata salt, address _address)
    public
    view
    returns (bytes32)
  {
    return keccak256(abi.encode(salt, address(this), _address));
  }

  function _verify(bytes32 hash, bytes memory token)
    public
    view
    returns (bool)
  {
    return (_recover(hash, token) == _signer);
  }

  function _recover(bytes32 hash, bytes memory token)
    public
    pure
    returns (address)
  {
    return hash.toEthSignedMessageHash().recover(token);
  }

  function grantTokens(address _to) internal {
    uint256[] memory ids = availableSales[saleNonce].ids;
    uint256[] memory amounts = availableSales[saleNonce].amounts;
    address contractAddress = availableSales[saleNonce].contractAddress;
    IERC1155(contractAddress).safeBatchTransferFrom(
      address(this),
      _to,
      ids,
      amounts,
      "0x0"
    );
  }

  function mint(string calldata salt, bytes calldata token)
    external
    payable
    nonReentrant
  {
    require(_state != State.Closed, "Sale is not active");
    require(
      !Address.isContract(msg.sender),
      "Contracts are not allowed to mint."
    );
    uint256 price = availableSales[saleNonce].price;
    require(msg.value >= price, "Ether value sent is incorrect.");
    require(!usedToken[saleNonce][token], "The token has been used.");
    if (_state == State.PrivateSale) {
      require(
        !addressMinted[saleNonce][msg.sender],
        "This address has already minted during private sale."
      );
    }
    require(_verify(_hash(salt, msg.sender), token), "Invalid token.");
    usedToken[saleNonce][token] = true;
    if (_state == State.PrivateSale) {
      addressMinted[saleNonce][msg.sender] = true;
    }
    grantTokens(msg.sender);
  }

  function withdrawAll(address recipient) public onlyOwner {
    uint256 balance = address(this).balance;
    payable(recipient).transfer(balance);
  }

  function withdrawAllViaCall(address payable _to) public onlyOwner {
    uint256 balance = address(this).balance;
    (bool sent, bytes memory data) = _to.call{value: balance}("");
    require(sent, "Failed to send Ether");
  }

  function emergencyWithdrawTokens(
    address _to,
    uint256[] memory ids,
    uint256[] memory amounts,
    address contractAddress
  ) public onlyOwner {
    IERC1155(contractAddress).safeBatchTransferFrom(
      address(this),
      _to,
      ids,
      amounts,
      "0x0"
    );
  }
}
