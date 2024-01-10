// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./ERC1155Holder.sol";
import "./Address.sol";
import "./IERC1155.sol";
import "./IERC721.sol";

contract FLUFDynamicMarketplace is ERC1155Holder, ReentrancyGuard, Ownable {
  using ECDSA for bytes32;
  using MerkleProof for bytes32[];
  using Address for address;

  address public flufAddress;
  address public partybearsAddress;
  address public thingiesAddress;

  struct Sales {
    address contractAddress; // The contractAddresses
    uint256[] ids; // The tokenIds
    uint256[] amounts; // The quantity of each token to transfer
    uint256 price;
  }

  mapping(uint256 => Sales) public availableSales;
  uint256 public saleNonce = 0; // The nonce of the current sale, starts with 0;
  bytes32 private root; // Root of Merkle
  mapping(uint256 => mapping(bytes => bool)) public usedToken; // Whether the SALT Token has been consumed
  mapping(uint256 => mapping(address => bool)) public addressMinted; // Whether this address has already minted during this sale
  mapping(uint256 => mapping(address => bool)) private _mintedInBlock;

  enum State {
    Closed,
    PrivateSale,
    PublicSale
  }

  State private _state;
  address private _signer;

  constructor(
    address signer,
    bytes32 _newRoot,
    address _flufAddress,
    address _partybearsAddress,
    address _thingiesAddress
  ) {
    _signer = signer;
    root = _newRoot;
    flufAddress = _flufAddress;
    partybearsAddress = _partybearsAddress;
    thingiesAddress = _thingiesAddress;
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

  function setRoot(bytes32 _newRoot) public onlyOwner {
    root = _newRoot;
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

  function setFlufAddress(address _flufAddress) public onlyOwner {
    flufAddress = _flufAddress;
  }

  function setPartybearsAddress(address _partybearsAddress) public onlyOwner {
    partybearsAddress = _partybearsAddress;
  }

  function setThingiesAddress(address _thingiesAddress) public onlyOwner {
    thingiesAddress = _thingiesAddress;
  }

  function isEcosystemOwner(address _address) public view returns (bool) {
    uint256 fluf = IERC721(flufAddress).balanceOf(_address);
    if (fluf > 0) {
      return true;
    }
    uint256 pb = IERC721(partybearsAddress).balanceOf(_address);
    if (pb > 0) {
      return true;
    }
    uint256 thingies = IERC721(thingiesAddress).balanceOf(_address);
    if (thingies > 0) {
      return true;
    }
    return false;
  }

  function hasStock(uint256 _saleNonce) public view returns (bool) {
    uint256 bal = IERC1155(availableSales[_saleNonce].contractAddress)
      .balanceOf(address(this), availableSales[_saleNonce].ids[0]);
    if (bal > 0) {
      return true;
    } else {
      return false;
    }
  }

  function publicMint(string calldata salt, bytes calldata token)
    external
    payable
    nonReentrant
  {
    require(hasStock(saleNonce) == true, "Out of stock");
    require(_state == State.PublicSale, "Publicsale is not active");
    require(
      isEcosystemOwner(msg.sender) == true,
      "You dont own any of the ecosystem tokens"
    );
    require(msg.sender == tx.origin, "Mint from contract not allowed");
    require(
      !Address.isContract(msg.sender),
      "Contracts are not allowed to mint."
    );
    uint256 price = availableSales[saleNonce].price;
    require(msg.value >= price, "Ether value sent is incorrect.");
    require(!usedToken[saleNonce][token], "The token has been used.");
    require(_verify(_hash(salt, msg.sender), token), "Invalid token.");
    require(
      _mintedInBlock[block.number][msg.sender] == false,
      "already minted in this block"
    );
    usedToken[saleNonce][token] = true;
    _mintedInBlock[block.number][msg.sender] = true;
    grantTokens(msg.sender);
  }

  function privateMint(bytes32[] memory _proof) external payable nonReentrant {
    require(hasStock(saleNonce) == true, "Out of stock");
    require(_state == State.PrivateSale, "Private Sale is not active.");
    require(msg.sender == tx.origin, "Mint from contract not allowed");
    require(
      !Address.isContract(msg.sender),
      "Contracts are not allowed to mint."
    );
    uint256 price = availableSales[saleNonce].price;
    require(msg.value >= price, "Ether value sent is incorrect.");
    require(
      !addressMinted[saleNonce][msg.sender],
      "This address has already minted during private sale."
    );

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(_proof.verify(root, leaf), "invalid proof");

    addressMinted[saleNonce][msg.sender] = true;

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
