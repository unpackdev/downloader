// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract EpicWizardCatFamiliars is Ownable, ERC721Enumerable {
  ERC721 public wizardsContract;

  bool public isMintActive;
  string public baseURI;

  constructor(ERC721 _wizards, bool _isMintActive, string memory _newURI) ERC721("EpicWizardCatFamiliars", "EWCF") {
    wizardsContract = _wizards;
    isMintActive = _isMintActive;
    baseURI = _newURI;
  }

  function setIsMintActive(bool _isMintActive) public onlyOwner {
    isMintActive = _isMintActive;
  }

  function mint(uint _wizardID) public {
    require(isMintActive, "EWCF: Mint is not active");

    bool _alreadyMinted = _exists(_wizardID);
    require(!_alreadyMinted, "EWCF: This familiar has already been summoned!");

    bool _ownsWizard = wizardsContract.ownerOf(_wizardID) == _msgSender();
    require(_ownsWizard, "EWCF: You must own the wizard to summon their familiar!");

    _safeMint(_msgSender(), _wizardID);
  }

  function familiarsOfOwner(address owner) public view returns (uint[] memory) {
    uint balance = balanceOf(owner);
    uint[] memory wallet = new uint[](balance);

    for (uint i = 0; i < balance; i++) {
      wallet[i] = tokenOfOwnerByIndex(owner, i);
    }

    return wallet;
  }

  function exists(uint id) public view returns (bool) {
    return _exists(id);
  }

  function setBaseURI(string memory _newURI)
    public
    onlyOwner
  {
    baseURI = _newURI;
  }

  function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
