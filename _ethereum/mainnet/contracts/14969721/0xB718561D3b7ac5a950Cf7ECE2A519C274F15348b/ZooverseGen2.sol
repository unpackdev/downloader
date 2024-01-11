// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721AUpgradeable.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./OpenSeaGasFreeListing.sol";
import "./AdminControllerUpgradeable.sol";
import "./IFactions.sol";

contract ZooverseGen2 is Initializable, ERC721AUpgradeable,  ERC721AQueryableUpgradeable, AdminControllerUpgradeable {
    string public baseURI;
    uint256 public supply;
    
    mapping(uint256 => bool) private _locked;
    mapping(uint256 => uint256) private _level;

    event LevelChanged(uint256 id, uint256 exp);

    function initialize(string calldata name, string calldata symbol) initializer public {
        __AdminController__init();
        __ERC721A_init(name, symbol);
        __ERC721AQueryable_init();
        supply = 4000;
        baseURI = "https://ipfs.io/ipfs/QmNSqm58HqNobgdkmSpUQv5H9f9hYbNAMyrWN3xD8ucvvj/";
    }

    function mint(address to, uint256 quantity) external adminOnly {
        require(totalSupply() + quantity <= supply, "Exceeds supply");
        _safeMint(to, quantity);
    }

    function getLevel(uint256 id) public view returns (uint256) {
        return _level[id];
    }

    function _baseURI() internal view override(ERC721AUpgradeable) returns (string memory) {
        return baseURI;
    }

    function setURI(string memory _uri) external adminOnly {
        baseURI = _uri;
    }

    function setSupply(uint256 _supply) public adminOnly {
        supply = _supply;
    }

    function isApprovedForAll(address _owner, address _operator) public view override(ERC721AUpgradeable, IERC721Upgradeable) returns (bool) {
        return super.isApprovedForAll(_owner, _operator) || OpenSeaGasFreeListing.isApprovedForAll(_owner, _operator) || isAdmin(msg.sender);
    }

    function setLocked(uint256 id, bool value) public adminOnly { 
        _locked[id] = value;
    }

    function mutateLevel(uint256 id, uint256 exp) public adminOnly {
        _level[id] = exp;
        emit LevelChanged(id, exp);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal whenNotPaused override(ERC721AUpgradeable) {
        require(!_locked[startTokenId], "locked");
        IFaction faction = factions.getFaction(startTokenId);
        if(address(faction) != address(0)) {
            uint256 balance = faction.balanceOf(msg.sender);
            if(balance > 0) {
                if(to == address(0)) {
                    faction.burn(from, 1 ether);
                } else {
                    faction.transferFrom(from, to, 1 ether);
                }
            }                        
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function getAux(address owner) external view returns (uint256) {
        return _getAux(owner);
    }

    function setAux(address owner, uint64 aux) external adminOnly {
        return _setAux(owner, aux);
    }

    IFactions public factions;
    function setFactions(IFactions _factions) external adminOnly {
        factions = _factions;
    }
}
