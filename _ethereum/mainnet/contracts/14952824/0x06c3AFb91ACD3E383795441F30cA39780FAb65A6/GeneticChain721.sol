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
import "./ECDSA.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";
import "./ERC721Sequential.sol";
import "./ERC721SeqEnumerable.sol";
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
 *  - low-gas implmentation
 *  - off-chain whitelist verify (secure minting)
 *  - dynamic token allocation
 *  - artist allocation
 *  - gallery allocation
 *  - protected controlled burns
 *  - opensea proxy setup
 */
abstract contract GeneticChain721 is
    ContextMixin,
    ERC721SeqEnumerable,
    NativeMetaTransaction,
    Ownable
{
    using ECDSA for bytes32;
    using State for State.Data;

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    // erc721 metadata
    string constant private __name   = "Skell Yeah";
    string constant private __symbol = "SKELLYEAH";

    // verification address
    address constant private _signer = 0xc1f40b4438d66a736E9246c0c0B3fD5354F1402a;

    // token limits
    uint256 public immutable publicMax;
    uint256 public immutable artistMax;
    uint256 public immutable galleryMax;

    // opensea proxy
    address private immutable _proxyRegistryAddress;

    // contract state
    State.Data private _state;

    // roles
    mapping (address => bool) private _burnerAddress;
    address private _artistAddress = 0x00f630965f882298219edBB1B96e0409EC6C8698;

    // track mint count per address
    mapping (address => uint256) private _mints;

    //-------------------------------------------------------------------------
    // modifiers
    //-------------------------------------------------------------------------

    modifier validTokenId(uint256 tokenId) {
        require(_exists(tokenId), "invalid token");
        _;
    }

    //-------------------------------------------------------------------------

    modifier isArtist() {
        require(_msgSender() == _artistAddress, "caller not artist");
        _;
    }

    //-------------------------------------------------------------------------

    modifier isBurner() {
        require(_burnerAddress[_msgSender()], "caller not burner");
        _;
    }

    //-------------------------------------------------------------------------

    modifier notLocked() {
        require(_state._locked == 0, "contract is locked");
        _;
    }

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        uint256[3] memory tokenMax_,
        address proxyRegistryAddress)
        ERC721Sequential(__name, __symbol)
    {
        publicMax             = tokenMax_[0];
        artistMax             = tokenMax_[1];
        galleryMax            = tokenMax_[2];
        _proxyRegistryAddress = proxyRegistryAddress;

        _initializeEIP712(__name);
        _state.setMaxPublic(1);

        // start tokens at 1 index
        _owners.push();
    }

    //-------------------------------------------------------------------------
    // accessors
    //-------------------------------------------------------------------------

    /**
     * Check if public minting is live.
     */
    function publicLive()
        public
        view
        returns (bool)
    {
        return _state._live == 1;
    }

    //-------------------------------------------------------------------------

    /**
     * Check if contract is locked.
     */
    function isLocked()
        public
        view
        returns (bool)
    {
        return _state._locked == 1;
    }

    //-------------------------------------------------------------------------

    /**
     * Get total gallery has minted.
     */
    function galleryMinted()
        public view
        returns (uint256)
    {
        return _state._gallery;
    }

    //-------------------------------------------------------------------------

    /**
     * Get total artist has minted.
     */
    function artistMinted()
        public view
        returns (uint256)
    {
        return _state._artist;
    }

    //-------------------------------------------------------------------------

    /**
     * Get total public has minted.
     */
    function publicMinted()
        public view
        returns (uint256)
    {
        return _state._public;
    }

    //-------------------------------------------------------------------------

    /**
     * Get max count allowed to mint per transaction.
     */
    function maxPublic()
        public view
        returns (uint256)
    {
        return _state._maxPublic;
    }

    //-------------------------------------------------------------------------
    // admin
    //-------------------------------------------------------------------------

    /**
     * Set artist address.
     */
    function setArtistAddress(address artistAddress)
        public
        onlyOwner
    {
        _artistAddress = artistAddress;
    }

    //-------------------------------------------------------------------------

    /**
     * Authorize artist address.
     */
    function registerBurnerAddress(address burner)
        public
        onlyOwner
    {
        require(!_burnerAddress[burner], "address already registered");
        _burnerAddress[burner] = true;
    }

    //-------------------------------------------------------------------------

    /**
     * Remove burner address.
     */
    function revokeBurnerAddress(address burner)
        public
        onlyOwner
    {
        require(_burnerAddress[burner], "address not registered");
        delete _burnerAddress[burner];
    }

    //-------------------------------------------------------------------------

    /**
     * Enable/disable public/member minting.
     */
    function toggleLock()
        public
        onlyOwner
    {
        _state.setLocked(_state._locked == 0 ? 1 : 0);
    }

    //-------------------------------------------------------------------------

    /**
     * Enable/disable public minting.
     */
    function togglePublicMint()
        public
        onlyOwner
    {
        _state.setLive(_state._live == 0 ? 1 : 0);
    }

    //-------------------------------------------------------------------------

    /**
     * Set max public mint per transaction.
     */
    function setMaxPublic(uint256 max)
        public
        onlyOwner
    {
        _state.setMaxPublic(max);
    }

    //-------------------------------------------------------------------------
    // security
    //-------------------------------------------------------------------------

    /**
     * Generate hash from input data.
     */
    function generateHash(uint256 allocation, uint256 count)
        private view
        returns(bytes32)
    {
        return ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(address(this), msg.sender, allocation, count)));
    }

    //-------------------------------------------------------------------------

    /**
     * Validate message was signed by signer.
     */
    function validateSigner(bytes32 msgHash, bytes memory signature, address signer)
        private pure
        returns(bool)
    {
        return msgHash.recover(signature) == signer;
    }

    //-------------------------------------------------------------------------
    // minting
    //-------------------------------------------------------------------------

    /**
     * Allow anyone to mint tokens.
     */
    function mint(uint256 count)
        public
        notLocked
    {
        require(_state._live == 1, "public mint not live");
        require(count <= _state._maxPublic, "exceed allocation");
        require(_state._public + count <= publicMax, "exceed public supply");

        // track public supply
        _state.addPublic(count);

        // mint
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(msg.sender);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * Mint count tokens using securely signed message.
     */
    function secureMint(bytes calldata signature, uint256 allocation, uint256 count)
        external
        notLocked
    {
        bytes32 msgHash = generateHash(allocation, count);
        require(_state._public + count <= publicMax, "exceed public supply");
        require(_mints[msg.sender] + count <= allocation, "exceed allocation");
        require(validateSigner(msgHash, signature, _signer), "invalid sig");

        // track public supply
        _state.addPublic(count);

        // track user mints
        unchecked {
            _mints[msg.sender] += count;
        }

        // mint
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(msg.sender);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Mint from gallery's token allocation.
     */
    function galleryMintTo(address wallet, uint256 count)
        public
        onlyOwner
    {
        require(_state._gallery + count <= galleryMax, "exceed gallery supply");
        _state.addGallery(count);
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(wallet);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Mint from artist's token allocation.
     */
    function artistMintTo(address wallet, uint256 count)
        public
        isArtist
    {
        require(_state._artist + count <= artistMax, "exceed artist supply");
        _state.addArtist(count);
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(wallet);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Allow extending contract for later burns. See {ERC721-_burn}.
     */
    function burn(uint256 tokenId)
        public
        isBurner
    {
        _burn(tokenId);
    }

    //-------------------------------------------------------------------------
    // money
    //-------------------------------------------------------------------------

    /**
     * Pull money out of this contract.
     */
    function withdraw(address to, uint256 amount)
        public
        onlyOwner
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
        override(ERC721Sequential, IERC721)
        public
        view
        returns (bool)
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
        override
        internal
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

}
