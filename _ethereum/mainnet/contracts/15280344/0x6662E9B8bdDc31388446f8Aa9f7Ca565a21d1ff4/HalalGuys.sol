//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";
import "./ERC721.sol";

contract HalalGuys is ERC721, ERC2981, Ownable {
  using SafeMath for uint256;

  uint256 public PRICE = 0 ether;
  bool public locked = false;

  uint256 private _counter;

  bool private PAUSE = false;
  
  string public baseTokenURI;

  bytes32 public merkleRoot;

  event PauseEvent(bool pause);
  event LockedEvent();
  event WelcomeToHalalGuys(uint256 indexed id);

  mapping(bytes32 => address) internal _usedCodes;

  constructor(string memory _defaultBaseURI, bytes32 _root) ERC721("HalalGuys", "HG") {
    setBaseURI(_defaultBaseURI);
    setMerkleRoot(_root);
    _setDefaultRoyalty(address(this), 1000);
  }

  /**
    * @dev Returns whether `tokenId` exists.
    *
    * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
    *
    * Tokens start existing when they are minted (`_mint`),
    * and stop existing when they are burned (`_burn`).
    */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _ownerOf[tokenId] != address(0);
  }

  /**
    * @dev Returns whether `spender` is allowed to manage `tokenId`.
    *
    * Requirements:
    *
    * - `tokenId` must exist.
    */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = _ownerOf[tokenId];
    return (spender == owner || getApproved[tokenId] == spender || isApprovedForAll[owner][spender]);
  }

  /**
  * @dev Throws if the contract is already locked
  */
  modifier notLocked() {
    require(!locked, "Contract already locked.");
    _;
  }

  function lock() public notLocked {
    locked = true;
    emit LockedEvent();
  }

  modifier saleIsOpen {
    require(!PAUSE, "Sales not open");
    _;
  }

  function setBaseURI(string memory _baseTokenURI) public onlyOwner notLocked {
    baseTokenURI = _baseTokenURI;
  }

  function _baseURI() internal view virtual returns (string memory) {
    return baseTokenURI;
  }

  /**
  * @dev Returns the tokenURI if exists
  * See {IERC721Metadata-tokenURI} for more details.
  */
  function tokenURI(uint256 _tokenId) public view virtual override(ERC721) returns (string memory) {
    return getTokenURI(_tokenId);
  }

  function getTokenURI(uint256 _tokenId) public view returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    require(_tokenId <= _totalSupply(), "ERC721Metadata: URI query for nonexistent token");
    string memory base = baseTokenURI;

    return bytes(base).length > 0 ? string( abi.encodePacked(base, uintToString(_tokenId), ".json") ) : "";
  }

  function _totalSupply() internal view returns (uint) {
    // return _tokenIds.current();
    return _counter;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply();
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex
   */
  function tokenByIndex(uint256 index) public view virtual returns (uint256) {
    require(_exists(index), "approved query for nonexistent token");
    return index;
  }

  /**
  * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
  */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256 token) {
      require(index < _balanceOf[owner], "owner index out of bounds");
      uint256 count;
      for (uint256 i; i < _counter; i++) {
        if (_ownerOf[i] == owner) {
          if (count == index) return i;
          else count++;
        }
      }
      require(false, "owner index out of bounds");
  }

  function mint(bytes32[] calldata _proof, bytes32 _code) public payable saleIsOpen {
    require(checkValidity(_proof, _code), "Code is invalid");
    
    _usedCodes[_code] = msg.sender;
    _counter++;

    _safeMint(msg.sender, _counter - 1);

    emit WelcomeToHalalGuys(_counter - 1);
  }

  function burn(uint256 tokenId) public virtual {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
    _burn(tokenId);
  }

  function price(uint256 _count) public view returns (uint256) {
    return PRICE.mul(_count);
  }

  function setPause(bool _pause) public onlyOwner {
    PAUSE = _pause;
    emit PauseEvent(PAUSE);
  }

  /**
    @notice Sets the contract-wide royalty info.
    */
  function setRoyaltyInfo(uint96 feeBasisPoints) external onlyOwner {
      _setDefaultRoyalty(address(this), feeBasisPoints);
  }

  function setMerkleRoot(bytes32 _root) public onlyOwner {
    require(merkleRoot != _root, "root already set");
    merkleRoot = _root;
  }

  /**
  * @dev Sets the prices for minting - in case of cataclysmic price movements
  */
  function setPrice(uint256 _price) external onlyOwner notLocked {
    require(_price >= 0, "Invalid prices.");
    PRICE = _price;
  }

  function checkValidity(bytes32[] calldata _merkleProof, bytes32 _code) public view returns (bool isValid) {
    require(MerkleProof.verify(_merkleProof, merkleRoot, _code), "Incorrect proof");
    require(_usedCodes[_code] == address(0), "used code");
    
    return true;
  }

  /**
    @dev Required override.
  */
  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721, ERC2981)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
    uint8 i = 0;
    while(i < 32 && _bytes32[i] != 0) {
        i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
        bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }

  function uintToBytes(uint v) pure private returns (bytes32 ret) {
    if (v == 0) {
        ret = '0';
    }
    else {
        while (v > 0) {
            ret = bytes32(uint(ret) / (2 ** 8));
            ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
            v /= 10;
        }
    }
    return ret;
  }

  function uintToString(uint v) pure private returns (string memory ret) {
    return bytes32ToString(uintToBytes(v));
  }

  /**
  * @dev Do not allow renouncing ownership
  */
  function renounceOwnership() public override(Ownable) onlyOwner {}
}