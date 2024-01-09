// SPDX-License-Identifier: MIT
/// @title: Mathematics Presents: No Pork On My Fork
/// @author: DropHero LLC
pragma solidity ^0.8.9;

import "./ERC721Burnable.sol";
import "./AccessControlEnumerable.sol";
import "./Pausable.sol";

contract MathematicsNFT is ERC721Burnable, AccessControlEnumerable, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant RESERVED_MINTER_ROLE = keccak256("RESERVED_MINTER_ROLE");
    uint16 public MAX_SUPPLY = 11_111;

    // We often update these two fields together. Using uint16 allows us to
    // take advantage of the gas savings from tight data packing
    uint16 _totalSupply = 0;
    uint16 _lastId = 0;
    uint16 _remainingReserved = 120;

    string _baseURIValue;

    constructor(string memory baseURI_) ERC721("No Pork On My Fork", "NOPORK") {
        _baseURIValue = baseURI_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory newBase) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseURIValue = newBase;
    }

    function totalSupply() public view returns(uint16) {
        return _totalSupply;
    }

    function remainingReservedSupply() public view returns(uint16) {
        return _remainingReserved;
    }

    function mintTokens(uint16 numberOfTokens, address to) external
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {
        require(
            numberOfTokens > 0, "MINUMUM_MINT_OF_ONE"
        );

        uint256 lastId = _lastId;
        uint256 maxId = lastId + numberOfTokens;

        require(
            maxId + _remainingReserved <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED"
        );

        // This is essentially a for() loop but is optimizing for gas use
        // by memoizing the maxId field to prevent the ADD operation on each iteration
        while (lastId < maxId) {
            _safeMint(to, ++lastId);
        }

        _lastId += numberOfTokens;
        _totalSupply += numberOfTokens;
    }

    function mintReserved(uint16 numberOfTokens, address to) external
        onlyRole(RESERVED_MINTER_ROLE)
        whenNotPaused
    {
        require(
            numberOfTokens > 0, "MINUMUM_MINT_OF_ONE"
        );

        uint256 lastId = _lastId;
        uint256 maxId = lastId + numberOfTokens;

        require(
            maxId <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED"
        );

        require(
            numberOfTokens <= _remainingReserved, "MAX_RESERVES_EXCEEDED"
        );

        // This is essentially a for() loop but is optimizing for gas use
        // by memoizing the maxId field to prevent the ADD operation on each iteration
        while (lastId < maxId) {
            _safeMint(to, ++lastId);
        }

        _lastId += numberOfTokens;
        _totalSupply += numberOfTokens;
        _remainingReserved -= numberOfTokens;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (to == address(0)) {
            _totalSupply -= 1;
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
