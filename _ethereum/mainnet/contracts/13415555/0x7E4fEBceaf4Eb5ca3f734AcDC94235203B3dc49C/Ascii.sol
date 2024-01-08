// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./console.sol";
import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./Meta.sol";
/****************************************************************************************************
*
*  Ascii API
*   - cooldown([<charCode>, <charCode>, ...])
*     - Get the current cooldown time for a character sequence
*   - lastMinted([<charCode>, <charCode>, ...])
*     - Get the last minted timestamp for a character sequence
*   - tokens([<charCode>, <charCode>, ... ])
*     - Get all the tokenIds that have the same character sequence
*   - data(tokenId)
*     - Get the character sequence for a tokenId
*   - next([<charCode>, <charCode>, ...])
*     - Get how much cooldown time is left until the next available mint
*   - tokenURI(tokenId)
*     - Get the tokenURI (base64 encoded data-uri)
*   - build([<tokenId>, <tokenId>, ...], [<charCode>, <charCode>, ...])
*     - Mint a character or a character sequence
*
****************************************************************************************************/
contract Ascii is Initializable, OwnableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable, UUPSUpgradeable {
  mapping(bytes => uint) private _cooldown;
  mapping(bytes => uint) private _lastMinted;
  mapping(bytes => uint[]) private _tokens;
  mapping(uint => uint24[]) private _data;
  uint id;
  uint tick;
  event Build(address indexed _from, uint indexed _input, uint indexed _output);
  function initialize(string memory name, string memory symbol, uint _tick) initializer public {
    __ERC721_init(name, symbol);
    __ERC721Enumerable_init();
    __Ownable_init();
    tick = _tick; // clock tick unit in seconds
    id = 1;       // the first token starts with id of 1
  }
  function cooldown(uint24[] calldata chars) public view returns (uint) {
    return _cooldown[_pack(chars)];
  }
  function lastMinted(uint24[] calldata chars) public view returns (uint) {
    return _lastMinted[_pack(chars)];
  }
  function tokens(uint24[] calldata chars) public view returns (uint[] memory) {
    return _tokens[_pack(chars)];
  }
  function data(uint tokenId) public view returns (uint24[] memory) {
    return _data[tokenId];
  }
  function next(uint24[] calldata chars) public view returns (uint) {
    // when is the next available minting time?
    bytes memory packed = _pack(chars);
    uint n = _lastMinted[packed] + _cooldown[packed];  // last minted time + cooldown time
    return (n > block.timestamp ? n-block.timestamp : 0);
  }
  //function build(uint[] calldata tokenIds, uint[] calldata chars, string calldata _uri) public payable {
  function build(uint[] calldata tokenIds, uint24[] calldata chars) public payable {
    /****************************************************************************************************
    *
    *    Case 1: Minting a sequence of characters using multiple tokens you own (tokenIds.length > 0)
    *      - Paremt tokenIds must exist (tokenIds array is not empty)
    *      - Multiple items in the "chars" array
    *      - Example:
    *        build(
    *          [<tokenId>, <tokenId>, ..],
    *          [charCode("h"), charCode("e"), charCode("l"), charCode("l"), charCode("o")],
    *          <ipfs token uri>
    *        )
    *
    *    Case 2: Minting a single character (tokenIds.length == 0)
    *      - No parent tokenIds (empty tokenIds array)
    *      - One item in "chars" array (made up of character code for the character)
    *      - Example:
    *        build(
    *          [],
    *          [charCode("h")],
    *          <ipfs token uri>
    *        )
    *
    ****************************************************************************************************/
    bytes memory _packed = _pack(chars);
    if (tokenIds.length > 0) {
      bytes memory _composed;
      for(uint i=0; i<tokenIds.length; i++) {
        require(ownerOf(tokenIds[i]) == msg.sender, "must own components");                   // check that the sender owns all the tokens
        _composed = abi.encodePacked(_composed, _data[tokenIds[i]]);                          // compose the character sequence using the supplied tokenIds
        emit Build(msg.sender, tokenIds[i], id);                                              // emit Build event to create an edge from previous token
      }
      require(keccak256(_composed) == keccak256(_packed), "invalid components");              // compare with the requested character sequence (_packed) with the composed sequence (_composed)
    } else {
      require(chars[0] >=0 && chars[0] <= 0x10FFFF, "not unicode");                           // unicode range check
      emit Build(msg.sender, 0, id);                                                          // emit Build event from node 0 to the new node
    }
    require(block.timestamp > _lastMinted[_packed] + _cooldown[_packed], "cooldown needed");  // cooldown time validation
    _safeMint(msg.sender, id);                                                                // mint token
    _tokens[_packed].push(id);                                                                // _tokens consists of all tokenIds that have the character sequence
    _lastMinted[_packed] = block.timestamp;                                                   // last mint time for a character sequence
    _cooldown[_packed] += (tick * chars.length);                                              // cooldown time for a character sequence
    _data[id] = chars;                                                                        // set the character sequence for the token
    id++;                                                                                     // increment the tokenId
  }
  function _pack(uint24[] calldata chars) internal pure returns (bytes memory) {
    return abi.encodePacked(chars);
  }
  function tokenURI(uint tokenId) public view override(ERC721Upgradeable) returns (string memory) {
    return Meta.generate(_data[tokenId]);
  }
  function _beforeTokenTransfer(address from, address to, uint tokenId) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
  {
      super._beforeTokenTransfer(from, to, tokenId);
  }
  function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
  function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}
}
