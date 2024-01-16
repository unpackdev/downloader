//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Base64.sol";
import "./Counters.sol";
import "./Strings.sol";
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
  address private signer;

  // Events
  event MessageMinted(address minter, string _hash);

  constructor(address _signer) ERC721('Immutacord', 'IMC') {
    signer = _signer;
    // Make sure we start from 1, not from 0
    _tokenIdCounter.increment();
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function setSigner(address _signer) public onlyOwner {
    signer = _signer;
  }

  function verify(
    string memory _hashedMessageId,
    string memory _cid,
    string memory _discordServerId,
    string memory _discordServerName,
    string memory _messageAuthorId,
    string memory _messageAuthorName,
    bytes memory _signature,
    address _signer
  ) private pure returns (bool) {
    return
      keccak256(
        abi.encodePacked(
          _hashedMessageId,
          _cid,
          _discordServerId,
          _discordServerName,
          _messageAuthorId,
          _messageAuthorName
        )
      ).toEthSignedMessageHash().recover(_signature) == _signer;
  }

  function mint(
    string memory _hashedMessageId,
    string memory _cid,
    string memory _discordServerId,
    string memory _discordServerName,
    string memory _messageAuthorId,
    string memory _messageAuthorName,
    bytes memory _signature
  ) public payable whenNotPaused {
    require(
      _messagesByHash[_hashedMessageId] == 0,
      'This image has already been minted'
    );

    // Verify signature
    require(
      verify(
        _hashedMessageId,
        _cid,
        _discordServerId,
        _discordServerName,
        _messageAuthorId,
        _messageAuthorName,
        _signature,
        signer
      ),
      'Invalid signature'
    );

    // Transaction must have at enough value (any more is considered a tip)
    require(msg.value >= MINT_PRICE, 'Not enough ether sent');

    uint256 tokenId = _tokenIdCounter.current();

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Discord message from ',
            _messageAuthorName,
            '", "description": "This token represents a message a user sent in discord, made immutable on the blockchain forever!", "image": "ipfs://',
            _cid,
            '", "attributes": [{ "trait_type": "Discord server ID", "value": "',
            _discordServerId,
            '" }, { "trait_type": "Discord server name", "value": "',
            _discordServerName,
            '" }, { "trait_type": "Message author ID", "value": "',
            _messageAuthorId,
            '" }, { "trait_type": "Message author name", "value": "',
            _messageAuthorName,
            '" } ]}'
          )
        )
      )
    );

    string memory _tokenURI = string(
      abi.encodePacked('data:application/json;base64,', json)
    );

    _tokenIdCounter.increment();
    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, _tokenURI);

    _messagesByHash[_hashedMessageId] = tokenId;

    emit MessageMinted(msg.sender, _hashedMessageId);
  }

  function setMintPrice(uint256 _mintPrice) public onlyOwner {
    MINT_PRICE = _mintPrice;
  }

  function getMessageByHash(string memory _hash) public view returns (uint256) {
    require(_messagesByHash[_hash] > 0, 'No message with this hash');

    return _messagesByHash[_hash];
  }

  function withdraw() public onlyOwner {
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
