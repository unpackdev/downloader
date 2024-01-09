// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//------------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//------------------------------------------------------------------------------
//________________________________________________________________   .¿yy¿.   __
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM```````/MMM\\\\\  \\$$$$$$S/  .
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM``   `/  yyyy    ` _____J$$$*^^*/%#//
//MMMMMMMMMMMMMMMMMMMYYYMMM````      `\/  .¿yü  /  $ùpüüü%%% | ``|//|` __
//MMMMMYYYYMMMMMMM/`     `| ___.¿yüy¿.  .d$$$$  /  $$$$SSSSM |   | ||  MMNNNNNNM
//M/``      ``\/`  .¿ù%%/.  |.d$$$$$$$b.$$$*°^  /  o$$$  __  |   | ||  MMMMMMMMM
//M   .¿yy¿.     .dX$$$$$$7.|$$$$"^"$$$$$$o`  /MM  o$$$  MM  |   | ||  MMYYYYYYM
//  \\$$$$$$S/  .S$$o"^"4$$$$$$$` _ `SSSSS\        ____  MM  |___|_||  MM  ____
// J$$$*^^*/%#//oSSS`    YSSSSSS  /  pyyyüüü%%%XXXÙ$$$$  MM  pyyyyyyy, `` ,$$$o
//.$$$` ___     pyyyyyyyyyyyy//+  /  $$$$$$SSSSSSSÙM$$$. `` .S&&T$T$$$byyd$$$$\
//\$$7  ``     //o$$SSXMMSSSS  |  /  $$/&&X  _  ___ %$$$byyd$$$X\$`/S$$$$$$$S\
//o$$l   .\\YS$$X>$X  _  ___|  |  /  $$/%$$b.,.d$$$\`7$$$$$$$$7`.$   `"***"`  __
//o$$l  __  7$$$X>$$b.,.d$$$\  |  /  $$.`7$$$$$$$$%`  `*+SX+*|_\\$  /.     ..\MM
//o$$L  MM  !$$$$\$$$$$$$$$%|__|  /  $$// `*+XX*\'`  `____           ` `/MMMMMMM
///$$X, `` ,S$$$$\ `*+XX*\'`____  /  %SXX .      .,   NERV   ___.¿yüy¿.   /MMMMM
// 7$$$byyd$$$>$X\  .,,_    $$$$  `    ___ .y%%ü¿.  _______  $.d$$$$$$$S.  `MMMM
// `/S$$$$$$$\\$J`.\\$$$ :  $\`.¿yüy¿. `\\  $$$$$$S.//XXSSo  $$$$$"^"$$$$.  /MMM
//y   `"**"`"Xo$7J$$$$$\    $.d$$$$$$$b.    ^``/$$$$.`$$$$o  $$$$\ _ 'SSSo  /MMM
//M/.__   .,\Y$$$\\$$O` _/  $d$$$*°\ pyyyüüü%%%W $$$o.$$$$/  S$$$. `  S$To   MMM
//MMMM`  \$P*$$X+ b$$l  MM  $$$$` _  $$$$$$SSSSM $$$X.$T&&X  o$$$. `  S$To   MMM
//MMMX`  $<.\X\` -X$$l  MM  $$$$  /  $$/&&X      X$$$/$/X$$dyS$$>. `  S$X%/  `MM
//MMMM/   `"`  . -$$$l  MM  yyyy  /  $$/%$$b.__.d$$$$/$.'7$$$$$$$. `  %SXXX.  MM
//MMMMM//   ./M  .<$$S, `` ,S$$>  /  $$.`7$$$$$$$$$$$/S//_'*+%%XX\ `._       /MM
//MMMMMMMMMMMMM\  /$$$$byyd$$$$\  /  $$// `*+XX+*XXXX      ,.      .\MMMMMMMMMMM
//GENETIC/MMMMM\.  /$$$$$$$$$$\|  /  %SXX  ,_  .      .\MMMMMMMMMMMMMMMMMMMMMMMM
//CHAIN/MMMMMMMM/__  `*+YY+*`_\|  /_______//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//------------------------------------------------------------------------------
// Genetic Chain: GeneticChain721
//------------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//------------------------------------------------------------------------------

import "./Ownable.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";
import "./ERC721SequentialB.sol";
import "./ERC721SeqEnumerableB.sol";
import "./State.sol";

//------------------------------------------------------------------------------
// helper contracts
//------------------------------------------------------------------------------

contract OwnableDelegateProxy {}

//------------------------------------------------------------------------------

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

//------------------------------------------------------------------------------
// GeneticChain721
//------------------------------------------------------------------------------

/**
 * @title GeneticChain721
 *
 * ERC721 contract with various features:
 *  - lower-gas implmentation
 *  - low-gas generative token hash
 *  - opensea proxy setup
 *  - simple funds withdrawl
 */
abstract contract GeneticChain721 is
    ContextMixin,
    ERC721SeqEnumerableB,
    NativeMetaTransaction,
    Ownable
{
    using State for State.Data;

    //-------------------------------------------------------------------------
    // events
    //-------------------------------------------------------------------------

    // track original pass ids
    event RainbowSplit(address indexed owner, uint256 tokenId, uint256 spiralId);

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    // token data
    uint256 private immutable _seed;

    // opensea proxy
    address private immutable _proxyRegistryAddress;

    // spiral address
    address internal immutable _spirals;

    // spiral tokenIds
    uint16[] internal _spiralIds;

    // minted ids
    mapping(uint16 => bool) private mintedIds;

    // contract state
    State.Data private _state;

    //-------------------------------------------------------------------------
    // modifiers
    //-------------------------------------------------------------------------

    modifier validTokenId(uint256 tokenId) {
        require(_exists(tokenId), "invalid token");
        _;
    }

    //-------------------------------------------------------------------------

    modifier notLocked() {
        require(_state._locked == 0, "contract is locked");
        _;
    }

    //-------------------------------------------------------------------------

    modifier availableId(uint16 spiralId) {
        require(!mintedIds[spiralId], 'already minted');
        _;
    }

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        address spirals,
        uint256 seed,
        address proxyRegistryAddress)
        ERC721SequentialB("Rainbow7 Pass", "GCP8")
    {
        _spirals              = spirals;
        _seed                 = seed;
        _proxyRegistryAddress = proxyRegistryAddress;
        _initializeEIP712("Rainbow7 Pass");

        // start tokens at 1 index
        _owners.push();
        _spiralIds.push();
    }

    //-------------------------------------------------------------------------
    // accessors
    //-------------------------------------------------------------------------

    /**
     * Lock contract.  Disable public/member minting. Disallow on-chain
     *  code/library updates.
     */
    function lockContract()
        public onlyOwner
    {
        _state.setLocked(1);
    }

    //-------------------------------------------------------------------------

    /**
     * Check if contract is locked.
     */
    function isLocked()
        public view returns (bool)
    {
        return _state._locked == 1;
    }

    //-------------------------------------------------------------------------

    /**
     * Returns entire list of spiralIds enumerated by thier tokenIds.
     */
    function spiralIds() public view returns (uint16[] memory) {
        uint16[] memory spiralIds_ = _spiralIds;
        return spiralIds_;
    }

    //-------------------------------------------------------------------------
    // minting
    //-------------------------------------------------------------------------

    /**
     * Mint R7 Pass to rainbow spiral owner.
     */
    function mint(uint16[] calldata spiralIds_)
        external
        onlyOwner
        notLocked
    {
        uint256 count = spiralIds_.length;
        for (uint256 i = 0; i < count; ++i) {
            _mint(spiralIds_[i]);
        }
    }

    //-------------------------------------------------------------------------
    // internal
    //-------------------------------------------------------------------------

    function _mint(uint16 spiralId)
        internal
        availableId(spiralId)
    {
        // track all r7 spiral ids
        _spiralIds.push(spiralId);
        mintedIds[spiralId] = true;

        // mint pass to spiral owner
        address owner   = IERC721(_spirals).ownerOf(uint256(spiralId));
        uint256 tokenId = _safeMint(owner);

        // track original pass ids
        emit RainbowSplit(owner, tokenId, uint256(spiralId));
    }

    //-------------------------------------------------------------------------
    // ERC721Metadata
    //-------------------------------------------------------------------------

    function baseTokenURI()
        virtual public view returns (string memory);

    //-------------------------------------------------------------------------

    /**
     * @dev Returns uri of a token.  Not guarenteed token exists.
     */
    function tokenURI(uint256 tokenId)
        override public view returns (string memory)
    {
        return string(abi.encodePacked(
            baseTokenURI(), "/", Strings.toString(tokenId), "/meta"));
    }

    //-------------------------------------------------------------------------
    // generative
    //-------------------------------------------------------------------------

    /**
     * @dev Low-Gas alternative to storing the hash on the chain.
     * @return generated hash associated with valid a token.
     */
    function tokenHash(uint256 tokenId)
        public view validTokenId(tokenId) returns (bytes32)
    {
      return keccak256(
          abi.encodePacked(
              _seed,
              tokenId,
              address(this)));
    }

    //-------------------------------------------------------------------------
    // money
    //-------------------------------------------------------------------------

    /**
     * Pull money out of this contract.
     */
    function withdraw(address to, uint256 amount)
        public onlyOwner
    {
        require(amount > 0, "amount empty");
        require(amount <= address(this).balance, "amount exceeds balance");
        require(to != address(0), "address null");
        payable(to).transfer(amount);
    }

    //-------------------------------------------------------------------------
    // approval
    //-------------------------------------------------------------------------

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts
     *  to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override public view returns (bool)
    {
        // whitelist OpenSea proxy contract for easy trading
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    //-------------------------------------------------------------------------

    /**
     * This is used instead of msg.sender as transactions won't be sent by
     *  the original token owner, but by OpenSea.
     */
    function _msgSender()
        override internal view returns (address sender)
    {
        return ContextMixin.msgSender();
    }

}
