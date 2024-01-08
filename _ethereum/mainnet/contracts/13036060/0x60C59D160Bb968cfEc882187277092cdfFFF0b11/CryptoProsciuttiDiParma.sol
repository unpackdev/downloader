//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";

contract CryptoProsciuttiDiParma is ERC721Upgradeable, OwnableUpgradeable {
    uint256 public constant MAX_PROSCIUTTI_DI_PARMA = 10000;

    address public cryptoSalumiereDiParma;

    modifier onlySalumiereDiParma() {
        require(msg.sender == cryptoSalumiereDiParma, "Caller is not the cryptoSalumiereDiParma");
        _;
    }

    function initialize(string memory _baseUri) public initializer {
        __Ownable_init();
        __ERC721_init("Crypto Prosciutti di Parma", "CPP");
        _setBaseURI(_baseUri);
    }

    function setCryptoSalumiereDiParma(address _cryptoSalumiereDiParma) external onlyOwner {
        cryptoSalumiereDiParma = _cryptoSalumiereDiParma;
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        _setBaseURI(_baseUri);
    }

    function mint(address _to, uint256 _numberOfProsciuttiDiParma) external onlySalumiereDiParma {
        uint256 totalSupply = totalSupply();
        require(totalSupply + _numberOfProsciuttiDiParma <= MAX_PROSCIUTTI_DI_PARMA, "Impossible to mint other Crypto Prosciutti di Parma");
        for (uint256 tokenId = totalSupply; tokenId < totalSupply + _numberOfProsciuttiDiParma; tokenId++) {
            _mint(_to, tokenId);
        }
    }
}
