// SPDX-License-Identifier: MIT

/******************************************************************************\
* 0xShroom (https://github.com/0xshroom)
* Implementation of ShroomTopia's ERC721 and Sale facet
/******************************************************************************/

pragma solidity ^0.8.3;

import "./Strings.sol";
import "./IERC721Receiver.sol";
import "./Address.sol";

import "./LibERC721Mainnet.sol";

import "./LibDiamond.sol";

contract ShroomTopiaMainnet {
  using Address for address;
  using Strings for uint256;

  LibERC721Mainnet.ERC721Storage internal s;

  uint256 private constant MAX_SHROOMS = 8950;

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  event NameChange(uint256 indexed shroomID, string name);

  function initSale(
    uint256 saleCapIndex_,
    string memory baseURI_,
    address mainnetERC721Predicate_
  ) external {
    LibDiamond.enforceIsContractOwner();

    s._saleCapIndex = saleCapIndex_;
    s._baseURI = baseURI_;
    s.mainnetERC721Predicate = mainnetERC721Predicate_;
  }

  function currentPrice() public view returns (uint256) {
    uint256 currentSupply = totalSupply();

    if (currentSupply < 250) {
      return 15000000000000000; // 0 - 249     0.015 ETH
    } else if (currentSupply < 750) {
      return 30000000000000000; // 250-749:   0.03 ETH
    } else if (currentSupply < 1500) {
      return 60000000000000000; // 750-1499:   0.06 ETH
    } else if (currentSupply < 3000) {
      return 120000000000000000; // 1500-2999:   0.12 ETH
    } else if (currentSupply < 4000) {
      return 240000000000000000; // 3000-3999:   0.24 ETH
    } else if (currentSupply < 4250) {
      return 480000000000000000; // 4000-4249:   0.48 ETH
    } else if (currentSupply < 4425) {
      return 960000000000000000; // 4250-4424:   0.96 ETH
    } else {
      return 1500000000000000000; // 4425-4474:   1.5 ETH
    }
  }

  function spawnShrooms(uint256 shroomCount) external payable {
    require(totalSupply() > 750 || shroomCount <= 30, "ERC721: Can only mint 30 Shrooms/tx");
    require(totalSupply() + shroomCount < s._saleCapIndex, "ERC721: Exceeds the maximum available Shrooms");
    require(msg.value >= currentPrice() * shroomCount, "ERC721: Eth value below sale price");

    for (uint256 i = 0; i < shroomCount; i++) {
      uint256 mintIndex = totalSupply();
      _safeMint(msg.sender, mintIndex);
      s._shroomBirthDate[mintIndex] = block.timestamp;
    }
  }

  function withdrawToOwner() external {
    LibDiamond.enforceIsContractOwner();
    uint256 balance = address(this).balance;

    payable(msg.sender).transfer(balance);
  }

  function getShroomBday(uint256 tokenId) external view returns (uint256) {
    require(_exists(tokenId), "ERC721: query for nonexistent token");
    return s._shroomBirthDate[tokenId];
  }

  function getShroomName(uint256 tokenId) external view returns (string memory) {
    require(_exists(tokenId), "ERC721: query for nonexistent token");
    return s._shroomName[tokenId];
  }

  function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(_owner, index);
      }
      return result;
    }
  }

  function changeName(uint256 tokenId, string memory name_) external {
    address owner = ownerOf(tokenId);
    require(msg.sender == owner, "ERC721: caller is not the owner");

    s._shroomName[tokenId] = name_;
    emit NameChange(tokenId, name_);
  }

  function balanceOf(address _owner) public view virtual returns (uint256) {
    require(_owner != address(0), "ERC721: balance query for the zero address");

    return s._balances[_owner];
  }

  function ownerOf(uint256 tokenId) public view virtual returns (address) {
    address owner = s._owners[tokenId];
    require(owner != address(0), "ERC721: owner query for nonexistent token");

    return owner;
  }

  function name() public view virtual returns (string memory) {
    return "ShroomTopia";
  }

  function symbol() public view virtual returns (string memory) {
    return "STPIA";
  }

  function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
    return bytes(s._baseURI).length > 0 ? string(abi.encodePacked(s._baseURI, tokenId.toString())) : "";
  }

  function approve(address to, uint256 tokenId) public virtual {
    address owner = ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");

    _approve(to, tokenId);
  }

  function getApproved(uint256 tokenId) public view virtual returns (address) {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");
    return s._tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) public virtual {
    require(operator != msg.sender, "ERC721: approve to caller");
    s._operatorApprovals[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
    return s._operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual {
    require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual {
    require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
  }

  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return s._owners[tokenId] != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, "");
  }

  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _mint(to, tokenId);
    require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), "ERC721: mint to the zero address");

    _beforeTokenTransfer(address(0), to, tokenId);
    s._balances[to] += 1;
    s._owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);
  }

  function _burn(uint256 tokenId) internal virtual {
    address owner = ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    _approve(address(0), tokenId);

    s._balances[owner] -= 1;
    delete s._owners[tokenId];

    emit Transfer(owner, address(0), tokenId);
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
    require(to != address(0), "ERC721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId);

    _approve(address(0), tokenId);

    s._balances[from] -= 1;
    s._balances[to] += 1;
    s._owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  function _approve(address to, uint256 tokenId) internal virtual {
    s._tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    if (from == address(0)) {
      s._totalSupply += 1;
      _addTokenToOwnerEnumeration(to, tokenId);
    } else if (from != to) {
      _removeTokenFromOwnerEnumeration(from, tokenId);

      if (to == address(0)) s._totalSupply -= 1;
      else _addTokenToOwnerEnumeration(to, tokenId);
    }
  }

  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = balanceOf(to);
    s._ownedTokens[to][length] = tokenId;
    s._ownedTokensIndex[tokenId] = length;
  }

  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    uint256 lastTokenIndex = balanceOf(from) - 1;
    uint256 tokenIndex = s._ownedTokensIndex[tokenId];

    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = s._ownedTokens[from][lastTokenIndex];

      s._ownedTokens[from][tokenIndex] = lastTokenId;
      s._ownedTokensIndex[lastTokenId] = tokenIndex;
    }

    delete s._ownedTokensIndex[tokenId];
    delete s._ownedTokens[from][lastTokenIndex];
  }

  function totalSupply() public view virtual returns (uint256) {
    return s._totalSupply;
  }

  function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
    require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
    return s._ownedTokens[owner][index];
  }

  function mint(address user, uint256 tokenId) external {
    require(msg.sender == s.mainnetERC721Predicate, "ERC721: INSUFFICIENT_PERMISSIONS");
    _mint(user, tokenId);
  }
}
