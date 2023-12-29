// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Ownable.sol";
import "./Context.sol";
import "./Counters.sol";

contract pfYDF is Context, Ownable {
  using Counters for Counters.Counter;

  address public perpetualFutures;

  mapping(uint256 => address) _owners;
  Counters.Counter _ids;

  // array of all the NFT token IDs owned by a user
  mapping(address => uint256[]) public allUserOwned;
  // the index in the token ID array at allUserOwned to save gas on operations
  mapping(uint256 => uint256) public ownedIndex;

  mapping(uint256 => uint256) public tokenMintedAt;

  event Burn(uint256 indexed tokenId, address indexed owner);
  event Mint(uint256 indexed tokenId, address indexed owner);

  modifier onlyPerps() {
    require(_msgSender() == perpetualFutures, 'only perps');
    _;
  }

  constructor() {
    perpetualFutures = _msgSender();
  }

  function mint(address owner) external onlyPerps returns (uint256) {
    _ids.increment();
    _mint(owner, _ids.current());
    tokenMintedAt[_ids.current()] = block.timestamp;
    emit Mint(_ids.current(), owner);
    return _ids.current();
  }

  function burn(uint256 _tokenId) external onlyPerps {
    address _user = ownerOf(_tokenId);
    require(_exists(_tokenId));
    _burn(_tokenId);
    emit Burn(_tokenId, _user);
  }

  function getLastMintedTokenId() external view returns (uint256) {
    return _ids.current();
  }

  function doesTokenExist(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  function setPerpetualFutures(address _perps) external onlyOwner {
    perpetualFutures = _perps;
  }

  function getAllUserOwned(address _user)
    external
    view
    returns (uint256[] memory)
  {
    return allUserOwned[_user];
  }

  function ownerOf(uint256 _tokenId) public view returns (address) {
    require(_owners[_tokenId] != address(0));
    return _owners[_tokenId];
  }

  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0) && _owners[_tokenId] == address(0));
    _owners[_tokenId] = _to;
    _afterTokenTransfer(address(0), _to, _tokenId);
  }

  function _burn(uint256 _tokenId) internal {
    address _user = _owners[_tokenId];
    require(_owners[_tokenId] != address(0));
    delete _owners[_tokenId];
    _afterTokenTransfer(_user, address(0), _tokenId);
  }

  function _exists(uint256 _tokenId) internal view returns (bool) {
    return _owners[_tokenId] != address(0);
  }

  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal {
    // if from == address(0), token is being minted
    if (_from != address(0)) {
      uint256 _currIndex = ownedIndex[_tokenId];
      uint256 _tokenIdMovingIndices = allUserOwned[_from][
        allUserOwned[_from].length - 1
      ];
      allUserOwned[_from][_currIndex] = allUserOwned[_from][
        allUserOwned[_from].length - 1
      ];
      allUserOwned[_from].pop();
      ownedIndex[_tokenIdMovingIndices] = _currIndex;
    }

    // if to == address(0), token is being burned
    if (_to != address(0)) {
      ownedIndex[_tokenId] = allUserOwned[_to].length;
      allUserOwned[_to].push(_tokenId);
    }
  }
}
