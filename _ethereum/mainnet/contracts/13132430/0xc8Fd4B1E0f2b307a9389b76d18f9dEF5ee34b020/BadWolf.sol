// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
                                    .   .
        ...',;;;,..           .:lodllodx0d.     .;llc:;,..
   .codxxOKkoollokO:        .lOxo:.  .:KMK,      .lXOccllllc,.
   .,,'..o0;    .oNx.      .dXl.      ;KMX;       cNx.    .ckx.
         lKc .,oO0d'       ,Kk.      .xWMX:       oWd.     'k0,
        .dN0k0NN0l'.       ,K0'     .oNMMX:      .kWk:;:lok0O;
       .lKWOc,,;:codxd:.   .xNk.   .oNXKWX;     .oKX0Okxdoc,.
        .dNl       .'xXl    'kNKkdd0WKcc0O,      .....
        .dNl       .,kXl     .;odxxdl'  ..
        .xNc   .,cdO0k:.
     ...:0WOodxxxdl;.                                  .lddooc.
   .:ddooolc;'..                          .            dKo;,'.
                     ':.                .lo.          .O0'
                    .xx.  .;cll:,.      ,0d           ;XXocc:.
                    cKl  :kd;;o0N0:     oXc           cNKxooc.
            .;'    .O0, ;0o.   ,d0O.   .OK;           dNo
      ;;    lKk,   oNo  d0'    .;k0'   ;XO.          .kN:
      ox.   lK0:  ,0K, .x0'    ,xKk.   lNx.          '0K,
      oO'   ;X0' .dNo.  lXd.  ,OWXc   .xWo.  .....   ,Kk.
      lK;   :XXc ,K0'   .xX0dkXKOc.   .xNOdddddoo:.  ;Ko
      cKc  :kkK0lxXc     .;cll:.       .'.....       .,.
      ;Ko.lk:.cXWWO.
      '0KOx,  .lXXc
      .dKo.     ..
       ..

  MadJelly: Bad Wolf - A narrative NFT adventure world ...

  @madjellyHQ
  @duchessbetsy
  @jasepostscript
  @daweedeth
  @supermakebeleeb

 */

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";

contract BadWolf is Context, ERC721Enumerable, ERC721Burnable, Ownable, ReentrancyGuard {
  address internal duchessBetsy = 0x19661d0bfb4aD2FD1086cf6Bc1bCda0ad5A7797B;
  address internal jase = 0xc2467e844a1FF5947a8E75B5beEcA4a5bC31A1Ef;
  address internal daweed = 0xd4850927a6e3f30E2e3C3b14D98131Cf8e2D9634;
  address internal superMakeBelieve = 0x4E9fD21519Cf3D1FeA8c0deBbB9F91814A3D0d62;

  string public BAD_WOLF_PROVENANCE;
  string private _baseTokenURI;

  bool private _isSaleActive = false;
  bool private _hasPromoTokens = false;

  uint public constant BW_PRICE = 55500000000000000; // 0.0555 eth
  uint public constant MAX_BW_SUPPLY = 5555;
  uint public promoTokens = 29;
  uint[MAX_BW_SUPPLY] private badWolves;
  uint private nonce = 0;

  mapping (uint256 => uint256) private _badWolfBirthDate;

  constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
		_baseTokenURI = baseTokenURI;
  }

  function mintBadWolf(uint _count) external payable nonReentrant() {
    require(_isSaleActive == true, "Sale must be active");
    require(totalSupply() < MAX_BW_SUPPLY, "No more Bad Wolves");
    require(_count > 0 && _count <= 20, "Must mint from 1 to 20 Bad Wolves");
    require(_count <= MAX_BW_SUPPLY - totalSupply(), "Not enough Bad Wolves left to mint");
    require(msg.value >= _price(_count), "Value below price");

    uint i;
    uint id;

    for(i = 0; i < _count; i++){
      id = randomIndex();
      _safeMint(msg.sender, id);
      _badWolfBirthDate[id - 1] = block.timestamp;
    }
  }

  function mintPromoBadWolf(uint _count) external onlyOwner {
    require(_isSaleActive == false, "Sale has started");
    require(promoTokens > 0, "0 promos left to mint");

    uint i;
    uint id;

    for(i = 0; i < _count; i++){
      if (promoTokens > 0) {
        id = randomIndex();
        _safeMint(owner(), id);
        promoTokens--;
        _badWolfBirthDate[id - 1] = block.timestamp;
      }
    }
  }

  function getBadWolfBirthdate(uint _tokenId) external view returns (uint) {
    require(_exists(_tokenId), "This Bad Wolf is not born");

    return _badWolfBirthDate[_tokenId - 1];
  }

  function tokensOfOwner(address _user) external view returns (uint[] memory ownerTokens) {
    uint tokenCount = balanceOf(_user);

    if (tokenCount == 0) {
      return new uint[](0);
    } else {
      uint[] memory output = new uint[](tokenCount);

      for (uint index = 0; index < tokenCount; index++) {
        output[index] = tokenOfOwnerByIndex(_user, index);
      }

      return output;
    }
  }

  // Credits to derpy birbs who credited Meebits
  function randomIndex() private returns (uint) {
    uint totalSize = MAX_BW_SUPPLY - totalSupply();
    uint index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
    uint value = 0;

    if (badWolves[index] != 0) {
      value = badWolves[index];
    } else {
      value = index;
    }

    if (badWolves[totalSize - 1] == 0) {
      badWolves[index] = totalSize - 1;
    } else {
      badWolves[index] = badWolves[totalSize - 1];
    }

    nonce++;
    return value + 1;
  }

  function hasSaleStarted() external view returns (bool) {
    return _isSaleActive;
  }

  function _price(uint _count) internal pure returns (uint256) {
    return BW_PRICE * _count;
  }

  function setBaseURI(string memory _baseUri) external onlyOwner {
    _baseTokenURI = _baseUri;
  }

  function withdrawAll() external payable {
    uint256 balance = address(this).balance;
    require(balance > 0,  "Empty balance");
    _withdraw(duchessBetsy, (balance * 25) / 100);
    _withdraw(jase, (balance * 22) / 100);
    _withdraw(daweed, (balance * 20) / 100);
    _withdraw(superMakeBelieve, (balance * 33) / 100);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed");
  }

  function toggleSale() external onlyOwner {
    _isSaleActive = !_isSaleActive;
  }

  function setProvenanceHash(string memory provenanceHash) public onlyOwner {
      BAD_WOLF_PROVENANCE = provenanceHash;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "This Bad Wolf is not born");

    return string(abi.encodePacked(_baseTokenURI, uintToBytes(tokenId)));
  }

  function _beforeTokenTransfer(address from, address to, uint tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function uintToBytes(uint v) private pure returns (bytes32 ret) {
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
}
