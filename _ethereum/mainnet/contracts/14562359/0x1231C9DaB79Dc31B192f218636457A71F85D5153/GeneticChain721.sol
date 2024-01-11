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
 *  - low-gas generative token hash
 *  - protected controlled burns
 *  - opensea proxy setup
 *  - simple funds withdrawl
 *  - approval locking disabling secondary marketplace listings
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
    string constant private __name   = "Crusties";
    string constant private __symbol = "CRUSTIES";

    // metadata
    uint256 constant public projectId  = 14;
    string constant public artist      = "Samuele Giordano";
    string constant public description = "Friendly crustaceans taking over the open sea.";

    // mint price
    uint256 constant public publicPrice = .05 ether;

    // allocations
    uint256 constant public maxPublic = 5;

    // verification address
    address constant private _wlSigner    = 0xF9021628355D6c995AD4131C9627A0a085CA0c38;
    address constant private _claimSigner = 0xF51f16A65936d352B5380486d31Cf44cC11DFbf1;

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

    modifier approvedOrOwner(address operator, uint256 tokenId) {
        require(_isApprovedOrOwner(operator, tokenId));
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

    modifier approvalsEnabled() {
        require(_state._approvals == 1, "approvals disabled");
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
     * Check if contract is allowing approvals.
     */
    function approvalsDisabled()
        public
        view
        returns (bool)
    {
        return _state._approvals == 0;
    }

    //-------------------------------------------------------------------------

    /**
     * Get total gallery has minted.
     */
    function galleryMinted()
        public
        view
        returns (uint256)
    {
        return _state._gallery;
    }

    //-------------------------------------------------------------------------

    /**
     * Get total artist has minted.
     */
    function artistMinted()
        public
        view
        returns (uint256)
    {
        return _state._artist;
    }

    //-------------------------------------------------------------------------

    /**
     * Get total public has minted.
     */
    function publicMinted()
        public
        view
        returns (uint256)
    {
        return _state._public;
    }

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
        public onlyOwner
    {
        require(!_burnerAddress[burner], "address already registered");
        _burnerAddress[burner] = true;
    }

    //-------------------------------------------------------------------------

    /**
     * Remove burner address.
     */
    function revokeBurnerAddress(address burner)
        public onlyOwner
    {
        require(_burnerAddress[burner], "address not registered");
        delete _burnerAddress[burner];
    }

    //-------------------------------------------------------------------------
    // admin
    //-------------------------------------------------------------------------

    /**
     * Lock contract.  Disable public/member minting.
     */
    function lockContract()
        public
        onlyOwner
    {
        _state.setLocked(1);
    }

    //-------------------------------------------------------------------------

    /**
     * Enable public minting.
     */
    function enablePublicMint()
        public
        onlyOwner
    {
        _state.setLive(1);
    }

    //-------------------------------------------------------------------------

    /**
     * Enable approvals.
     */
    function enableApprovals()
        public
        onlyOwner
    {
        _state.setAllowApprovals(1);
    }

    //-------------------------------------------------------------------------
    // security
    //-------------------------------------------------------------------------

    /**
     * Validate hash contains input data.
     */
    function validateHash(bytes32 msgHash, address sender,
            uint256 allocation, uint256 count)
        private
        pure
        returns(bool)
    {
        return ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(sender, allocation, count))) == msgHash;
    }

    //-------------------------------------------------------------------------

    /**
     * Validate message was signed by signer.
     */
    function validateSigner(bytes32 msgHash, bytes memory signature,
            address signer)
        private
        pure
        returns(bool)
    {
        return msgHash.recover(signature) == signer;
    }

    //-------------------------------------------------------------------------
    // minting
    //-------------------------------------------------------------------------

    /**
     * Allow anyone to mint tokens for the right price.
     */
    function mint(uint256 count)
        payable
        public
        notLocked
    {
        require(_state._live == 1, "public mint not live");
        require(count <= maxPublic, "exceed allocation");
        require(publicPrice * count == msg.value, "insufficient funds");
        require(_state._public + count <= publicMax, "exceed public supply");
        _state.addPublic(count);
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(msg.sender);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * Mint count tokens using securely signed message.
     */
    function secureMint(bytes32 msgHash, bytes calldata signature,
            uint256 allocation, uint256 count)
        payable
        external
        notLocked
    {
        require(publicPrice * count == msg.value, "insufficient funds");
        require(_state._public + count <= publicMax, "exceed public supply");
        require(_mints[msg.sender] + count <= allocation, "exceed allocation");
        require(validateSigner(msgHash, signature, _wlSigner), "invalid signer");
        require(validateHash(msgHash, msg.sender, allocation, count), "invalid hash");
        _state.addPublic(count);
        unchecked {
            _mints[msg.sender] += count;
        }
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(msg.sender);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * Allow spiral holders to claim.
     */
    function claim(bytes32 msgHash, bytes calldata signature,
            uint256 allocation, uint256 count)
        external
        notLocked
    {
        require(_state._public + count <= publicMax, "exceed public supply");
        require(_mints[msg.sender] + count <= allocation, "exceed allocation");
        require(validateSigner(msgHash, signature, _claimSigner), "invalid signer");
        require(validateHash(msgHash, msg.sender, allocation, count), "invalid hash");
        _state.addPublic(count);
        unchecked {
            _mints[msg.sender] += count;
        }
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(msg.sender);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Mint token to given addresses.
     * @param wallets addresses to mint tokens to
     */
    function airdrop(address[] calldata wallets)
        public
        onlyOwner
    {
        uint256 count = wallets.length;
        require(_state._public + count <= publicMax, "exceed public supply");
        _state.addPublic(count);
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(wallets[i]);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Mints a token to an address.
     * @param wallet address of the future owner of the token
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
     * @dev Mints a token to an address.
     * @param wallet address of the future owner of the token
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
     * @dev Burns `tokenId`. See {ERC721-_burn}.
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
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId)
        override(ERC721Sequential, IERC721)
        public
        approvalsEnabled
    {
         super.approve(to, tokenId);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        override(ERC721Sequential, IERC721)
        public
        approvalsEnabled
    {
        super.setApprovalForAll(operator, approved);
    }

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
        if (approvalsDisabled()) {
            return false;
        }

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
