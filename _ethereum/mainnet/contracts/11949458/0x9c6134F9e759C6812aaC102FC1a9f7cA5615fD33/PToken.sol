// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";
import "./IPToken.sol";
import "./ERC721.sol";
import "./UnsignedSafeMath.sol";

/**
 * @title Deri Protocol non-fungible position token implementation
 */
contract PToken is IERC721, IPToken, ERC721 {

    using UnsignedSafeMath for uint256;

    // Pool address this PToken associated with
    address private _pool;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Total ever minted PToken
    uint256 private _totalMinted;

    // Total existent PToken
    uint256 private _totalSupply;

    // Mapping from tokenId to Position
    mapping (uint256 => Position) private _tokenIdPosition;

    modifier _pool_() {
        require(msg.sender == _pool, "PToken: called by non-associative pool, probably the original pool has been migrated");
        _;
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection
     */
    constructor (string memory name_, string memory symbol_, address pool_) {
        require(pool_ != address(0), "PToken: construct with 0 address pool");
        _name = name_;
        _symbol = symbol_;
        _pool = pool_;
    }

    /**
     * @dev See {IPToken}.{setPool}
     */
    function setPool(address newPool) public override {
        require(newPool != address(0), "PToken: setPool to 0 address");
        require(msg.sender == _pool, "PToken: setPool caller is not current pool");
        _pool = newPool;
    }

    /**
     * @dev See {IPToken}.{pool}
     */
    function pool() public view override returns (address) {
        return _pool;
    }

    /**
     * @dev See {IPToken}.{name}
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IPToken}.{symbol}
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IPToken}.{totalMinted}
     */
    function totalMinted() public view override returns (uint256) {
        return _totalMinted;
    }

    /**
     * @dev See {IPToken}.{totalSupply}
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IPToken}.{exists}
     */
    function exists(address owner) public view override returns (bool) {
        return _exists(owner);
    }

    /**
     * @dev See {IPToken}.{exists}
     */
    function exists(uint256 tokenId) public view override returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev See {IPToken}.{getPosition}
     */
    function getPosition(address owner) public view override returns (
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    ) {
        require(_exists(owner), "PToken: getPosition for nonexistent owner");
        Position storage p = _tokenIdPosition[_ownerTokenId[owner]];
        return (
            p.volume,
            p.cost,
            p.lastCumuFundingRate,
            p.margin,
            p.lastUpdateTimestamp
        );
    }

    /**
     * @dev See {IPToken}.{getPosition}
     */
    function getPosition(uint256 tokenId) public view override returns (
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    ) {
        require(_exists(tokenId), "PToken: getPosition for nonexistent tokenId");
        Position storage p = _tokenIdPosition[tokenId];
        return (
            p.volume,
            p.cost,
            p.lastCumuFundingRate,
            p.margin,
            p.lastUpdateTimestamp
        );
    }

    /**
     * @dev See {IPToken}.{mint}
     */
    function mint(address owner, uint256 margin) public override _pool_ {
        require(owner != address(0), "PToken: mint to 0 address");
        require(!_exists(owner), "PToken: mint to existent owner");

        _totalMinted = _totalMinted.add(1);
        _totalSupply = _totalSupply.add(1);
        uint256 tokenId = _totalMinted;
        require(!_exists(tokenId), "PToken: mint to existent tokenId");

        _ownerTokenId[owner] = tokenId;
        _tokenIdOwner[tokenId] = owner;
        Position storage p = _tokenIdPosition[tokenId];
        p.margin = margin;

        emit Transfer(address(0), owner, tokenId);
    }

    /**
     * @dev See {IPToken}.{update}
     */
    function update(
        address owner,
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    ) public override _pool_
    {
        require(_exists(owner), "PToken: update to nonexistent owner");
        Position storage p = _tokenIdPosition[_ownerTokenId[owner]];
        p.volume = volume;
        p.cost = cost;
        p.lastCumuFundingRate = lastCumuFundingRate;
        p.margin = margin;
        p.lastUpdateTimestamp = lastUpdateTimestamp;

        emit Update(owner, volume, cost, lastCumuFundingRate, margin, lastUpdateTimestamp);
    }

    /**
     * @dev See {IPToken}.{burn}
     */
    function burn(address owner) public override _pool_ {
        require(_exists(owner), "PToken: burn nonexistent owner");
        uint256 tokenId = _ownerTokenId[owner];
        Position storage p = _tokenIdPosition[tokenId];
        require(p.volume == 0, "PToken: burn non empty token");

        _totalSupply = _totalSupply.sub(1);

        // clear ownership and approvals
        delete _ownerTokenId[owner];
        delete _tokenIdOwner[tokenId];
        delete _tokenIdPosition[tokenId];
        delete _tokenIdOperator[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

}
