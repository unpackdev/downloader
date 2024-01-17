//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./ECDSA.sol";

contract Immutacord is
  ERC721,
  ERC721Enumerable,
  ERC721URIStorage,
  Pausable,
  Ownable,
  ERC721Burnable
{
  using Counters for Counters.Counter;
  using ECDSA for bytes32;

  Counters.Counter private _tokenIdCounter;

  mapping(string => uint256) private _messagesByHash;
  uint256 public MINT_PRICE = 0.01 ether;
  uint256 public FREE_MESSAGES = 1000;
  address private signer;

  constructor(address _signer) ERC721('Immutacord', 'IMC') {
    signer = _signer;
    // Make sure we start from 1, not from 0
    _tokenIdCounter.increment();
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function setSigner(address _signer) external onlyOwner {
    signer = _signer;
  }

  function verify(
    string memory _hashedMessageId,
    string memory _cid,
    bytes memory _signature,
    address _signer
  ) private pure returns (bool) {
    return
      keccak256(abi.encodePacked(_hashedMessageId, _cid))
        .toEthSignedMessageHash()
        .recover(_signature) == _signer;
  }

  function mint(
    string calldata _hashedMessageId,
    string calldata _cid,
    bytes calldata _signature
  ) external payable whenNotPaused {
    require(
      _messagesByHash[_hashedMessageId] == 0,
      'This image has been minted'
    );

    // Verify signature
    require(
      verify(_hashedMessageId, _cid, _signature, signer),
      'Invalid signature'
    );

    uint256 tokenId = _tokenIdCounter.current();

    if (tokenId > FREE_MESSAGES) {
      // Transaction must have at enough value (any more is considered a tip)
      require(msg.value >= MINT_PRICE, 'Not enough ether sent');
    }

    _tokenIdCounter.increment();
    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, string.concat('ipfs://', _cid));

    _messagesByHash[_hashedMessageId] = tokenId;
  }

  function setMintPrice(uint256 _mintPrice) external onlyOwner {
    MINT_PRICE = _mintPrice;
  }

  function setFreeMessages(uint256 _freeMessages) external onlyOwner {
    FREE_MESSAGES = _freeMessages;
  }

  function getMessageByHash(string calldata _hash)
    external
    view
    returns (uint256)
  {
    require(_messagesByHash[_hash] > 0, 'No message with this hash');

    return _messagesByHash[_hash];
  }

  function withdraw() external onlyOwner {
    (bool success, ) = payable(msg.sender).call{ value: address(this).balance }(
      ''
    );
    require(success, 'transfer failed');
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  // The following functions are overrides required by Solidity.

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
