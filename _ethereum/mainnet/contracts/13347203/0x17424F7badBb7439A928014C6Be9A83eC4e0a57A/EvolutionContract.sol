// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./Strings.sol";

interface IEvolutionContract {
  function isEvolvingActive() external view returns (bool);
  function isEvolutionValid(uint256[3] memory _tokensToBurn) external returns (bool);
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function getEvolutionPrice() external view returns (uint256);
}

contract EvolutionContract is IEvolutionContract, Ownable {
  using Strings for uint256;

  bytes public bases;
  mapping(bytes1 => bytes1) public evolutionMapping;
  bytes1 public constant DIGITTO_BASE = 0x1e;

  string public _baseURI = "";
  bool private _isEvolvingActive = false;

  function isEvolvingActive() external view override returns (bool) {
    return _isEvolvingActive;
  }

  function isEvolutionValid(uint256[3] memory _tokensToBurn) external override returns (bool) {
    bytes1 firstBase = getBase(_tokensToBurn[0] - 1);
    bytes1 secondBase = getBase(_tokensToBurn[1] - 1);
    bytes1 thirdBase = getBase(_tokensToBurn[2] - 1);

    bool isValid = false;
    bytes1 base;
    if (firstBase == secondBase && firstBase == thirdBase) {
      isValid = true;
      base = firstBase;
    } else if (firstBase == DIGITTO_BASE && secondBase == thirdBase) {
      isValid = true;
      base = secondBase;
    } else if (secondBase == DIGITTO_BASE && firstBase == thirdBase) {
      isValid = true;
      base = firstBase;
    } else if (thirdBase == DIGITTO_BASE && firstBase == secondBase) {
      isValid = true;
      base = firstBase;
    }

    if (isValid) {
      bytes1 evolutionBase = evolutionMapping[base];
      if (evolutionBase == 0x00) {
        isValid = false;
      } else {
        bases.push(evolutionBase);
      }
    }

    return isValid;
  }

  function tokenURI(uint256 tokenId) external view override returns (string memory) {
    return string(abi.encodePacked(_baseURI, tokenId.toString()));
  }

  function getEvolutionPrice() external pure override returns (uint256) {
    return 0 ether;
  }

  function toggleEvolvingActive() external onlyOwner {
    _isEvolvingActive = !_isEvolvingActive;
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseURI = baseURI;
  }

  function getEvolutionMapping(bytes1 base) public view returns (bytes1) {
    return evolutionMapping[base];
  }

  function addEvolutionMappings(bytes memory originalBases, bytes memory evolvedBases) public onlyOwner {
    for (uint i = 0; i < originalBases.length; i++) {
      evolutionMapping[originalBases[i]] = evolvedBases[i];
    }
  }

  function getBase(uint256 index) public view returns (bytes1) {
    return bases[index];
  }

  function addBases(bytes memory basesToAdd) public onlyOwner {
    for (uint i = 0; i < basesToAdd.length; i++) {
      bases.push(basesToAdd[i]);
    }
  }

  function clearBases() public onlyOwner {
    bases = "";
  }
}