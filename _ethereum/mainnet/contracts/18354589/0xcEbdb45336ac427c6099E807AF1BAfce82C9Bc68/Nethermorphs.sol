// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./AccessControl.sol";


contract Nethermorphs is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint public maxTotalSupply;
    uint public raresFrom;

    string public baseURI;

    uint private _regularsMinted = 0;
    uint private _raresMinted = 0;

    constructor(uint maxTotalSupply_, uint raresFrom_) ERC721("Nethermorphs", "NETH") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        maxTotalSupply = maxTotalSupply_;
        raresFrom = raresFrom_;
    }

    function mint(address to, uint regularQty, uint rareQty) public onlyRole(MINTER_ROLE) {
        require(_regularsMinted + regularQty <= raresFrom, "Nethermorphs: Max regular supply reached");
        require(_raresMinted + rareQty <= maxTotalSupply - raresFrom, "Nethermorphs: Max rare supply reached");

        if (regularQty > 0) {
            for (uint i = 0; i < regularQty; i++) {
                _safeMint(to, _regularsMinted + 1);
                _regularsMinted++;
            }
        }

        if (rareQty > 0) {
            for (uint i = 0; i < rareQty; i++) {
                _safeMint(to, raresFrom + _raresMinted + 1);
                _raresMinted++;
            }
        }
    }

    function mintId(address to, uint id) public onlyRole(MINTER_ROLE) {
        require(id > 0 && id <= maxTotalSupply, "Nethermorphs: Invalid id");
        require(!_exists(id), "Nethermorphs: Token already minted");

        if (id <= raresFrom) {
            _regularsMinted++;
        } else {
            _raresMinted++;
        }

        _safeMint(to, id);
    }

    function regularsMinted() external view returns (uint) {
        return _regularsMinted;
    }

    function raresMinted() external view returns (uint) {
        return _raresMinted;
    }

    function setBaseURI(string memory baseURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;
    }

    function _baseURI()
    internal
    view
    override
    returns (string memory)
    {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
