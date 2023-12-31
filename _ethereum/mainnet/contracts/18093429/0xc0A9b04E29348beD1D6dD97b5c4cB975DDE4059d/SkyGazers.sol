// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./TimeToken.sol";

contract SkyGazers is ERC721Enumerable, AccessControl {
    TimeToken public immutable timeToken;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return
            ERC721Enumerable.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    constructor(
        string memory name,
        string memory symbol,
        TimeToken t
    ) ERC721(name, symbol) {
        timeToken = t;
        _setupRole(OWNER_ROLE, msg.sender);
    }

    uint256 public startIndexNFT;
    address minter;
    string public URIroot;

    // uint256 public immutable MAX_SUPPLY = 9997;

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    function setMinter(address _CurveSaleMinter) public {
        require(hasRole(OWNER_ROLE, msg.sender), "Caller is not owner");
        _setupRole(MINTER_ROLE, _CurveSaleMinter);
    }

    function removeMinter(address _CurveSaleMinter) public {
        require(hasRole(OWNER_ROLE, msg.sender), "Caller is not owner");
        _revokeRole(MINTER_ROLE, _CurveSaleMinter);
    }

    function setURIroot(string calldata _uriRoot) public {
        require(hasRole(OWNER_ROLE, msg.sender), "Caller is not owner");
        URIroot = _uriRoot;
    }

    function mintItem(address owner, uint256 id) public returns (uint256) {
        require(hasRole(MINTER_ROLE, msg.sender), "Not allowed to mint");
        _mint(owner, id);
        return id;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
        // set timetoken balances for sender + recipient at moment of transfer
        timeToken.setInitialBalances(from, to);
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "id does not exist");
        return string(abi.encodePacked(URIroot, Strings.toString(id), ".json"));
    }
}
