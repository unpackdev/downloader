// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
//     __  ___  _____ _                     _
//  /\ \ \/ __\/__   (_)_ __ ___   ___  ___| |__   __ _ _ __ ___  ___
//  /  \/ / _\    / /\/ | '_ ` _ \ / _ \/ __| '_ \ / _` | '__/ _ \/ __|
// / /\  / /     / /  | | | | | | |  __/\__ \ | | | (_| | | |  __/\__ \
// \_\ \/\/      \/   |_|_| |_| |_|\___||___/_| |_|\__,_|_|  \___||___/


import "./ERC721Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./console.sol";
import "./NFTimeshareMonth.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

// TODO: should this actually be an ERC721 or its own thing?
// TODO: make an interface for contracts
// TODO: make upgradeable through openzeppelin
// TODO: emit some Events
contract NFTimeshare is Initializable, ERC721EnumerableUpgradeable, ERC721HolderUpgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using BokkyPooBahsDateTimeLibrary for uint256;

    CountersUpgradeable.Counter private _tokenIds;
    NFTimeshareMonth private _NFTimeshareMonths;

    mapping (address => mapping (uint256 => uint256)) private _tokenIdForUnderlying;
    mapping (uint256 => UnderlyingNFT)                private _wrappedNFTs;

    struct UnderlyingNFT {
        address _contractAddr;
        uint256 _tokenId;
    }

    event Deposit(
      address indexed holder,
      address indexed sender,
      address indexed recipient,
      address wrapped_contract,
      uint256 wrapped_tokenId,
      uint256 timeshareTokenId
    );
    event Redeem(
      address indexed sender,
      address indexed recipient,
      address unwrapped_contract,
      uint256 unwrapped_tokenId,
      uint256 timeshareTokenId
    );




    function initialize() public initializer {
      __Context_init_unchained();
      __ERC165_init_unchained();
      __Ownable_init_unchained();
      __ERC721_init("Timeshare", "SHARE");
      __ERC721Enumerable_init_unchained();
      __ERC721Holder_init_unchained();
    }

    /* CORE LOGIC: DEPOSIT an NFT for TimeshareMonths, or REDEEM it back from TimeshareMonths*/

    // given an an NFT (contract + tokenId), wrap it and mint it into timeshares.
    // this contract must be approved to operate it. _to must be able to receive erc721s.
    // @param _underlying the NFT contract address... 0xabc...
    // @param _underlyingTokenId token Id for use w external NFT contract
    // @param _from account currently owns the NFT
    // @param _to account that will receive the timesharemonths
    function deposit(address _underlying, uint256 _underlyingTokenId, address _from, address _to) public needsTimeshareMonths {
        require(_underlying != address(_NFTimeshareMonths), "Deposit: Cant make timeshares out of timeshares");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(address(this), newTokenId);

        _tokenIdForUnderlying[_underlying][_underlyingTokenId] = newTokenId;
        _wrappedNFTs[newTokenId] = UnderlyingNFT(_underlying, _underlyingTokenId);

        _NFTimeshareMonths.makeTimesharesFor(newTokenId, _to);

        IERC721Upgradeable(_underlying).safeTransferFrom(_from, address(this), _underlyingTokenId);
        emit Deposit(_from, msg.sender, _to, _underlying, _underlyingTokenId, newTokenId);
    }

    // redeem a wrapped NFT for the underlying NFT if you own all the timeshares.
    // @param tokenId -- the tokenId (in NFTimeshare's mapping) of the Timeshare
    // @param _to -- account that will receive the unwrapped external nft
    // @note you can look up the timeshare TokenId with getTokenIdForUnderlyingNFT
    function redeem(uint256 tokenId, address _to) public virtual needsTimeshareMonths {
        UnderlyingNFT memory underlyingNFT = _wrappedNFTs[tokenId];
        require(underlyingNFT._contractAddr != address(0) && underlyingNFT._tokenId != 0, "Redeem Timeshare: Nonexistent tokenId");

        delete _tokenIdForUnderlying[underlyingNFT._contractAddr][underlyingNFT._tokenId];
        delete _wrappedNFTs[tokenId];


        _NFTimeshareMonths.burnTimeshareMonthsFor(msg.sender, tokenId);
        _burn(tokenId);

        IERC721Upgradeable(underlyingNFT._contractAddr).safeTransferFrom(address(this), _to, underlyingNFT._tokenId);

        emit Redeem(msg.sender, _to, underlyingNFT._contractAddr, underlyingNFT._tokenId, tokenId);

    }

    /* Account for CURRENT OWNERSHIP given the month. Note this
    differs from typical ERC721 balanceOf / ownerOf */
    function balanceOf(address owner) public view virtual override needsTimeshareMonths returns (uint256){
        uint256 numTSMonthsOwned = _NFTimeshareMonths.balanceOf(owner);
        uint256 curMonth = block.timestamp.getMonth()-1;
        uint256 activeTimeshares = 0;
        for (uint256 i = 0; i < numTSMonthsOwned; i++) {
            uint256 monthTokenId  = _NFTimeshareMonths.tokenOfOwnerByIndex(owner, i);
            uint256 monthForToken = _NFTimeshareMonths.month(monthTokenId); // 0-indexed
            if (monthForToken == curMonth) {
                activeTimeshares++;
            }
        }
        return activeTimeshares;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        uint256 curMonth = block.timestamp.getMonth()-1;
        uint256[12] memory timeshareMonths = _NFTimeshareMonths.getTimeshareMonths(tokenId); // 0-indexed
        return _NFTimeshareMonths.ownerOf(timeshareMonths[curMonth]);
    }


    /*NFT METADATA methods*/
    function contractURI() public view returns (string memory) {
      return "http://www.nftimeshares.fun/timeshareprojectmetadata";
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return "http://www.nftimeshares.fun/timeshare/";
    }
    function underlyingTokenURI(uint256 tokenId) public view virtual needsTimeshareMonths returns (string memory) {
        UnderlyingNFT memory underlying = _wrappedNFTs[tokenId];
        string memory retval = IERC721MetadataUpgradeable(underlying._contractAddr).tokenURI(underlying._tokenId);
        return retval;
    }

    /* Dealing with wrapped tokens */
    function getWrappedNFT(uint256 tokenId) public view returns (address, uint256) {
        require(_exists(tokenId), "Timeshare: asked for wrappedNFT of nonexistent token");
        UnderlyingNFT memory underlying = _wrappedNFTs[tokenId];
        return (underlying._contractAddr, underlying._tokenId);
    }
    function getTokenIdForUnderlyingNFT(address addr, uint256 externalTokenId) public view returns (uint256) {
      return _tokenIdForUnderlying[addr][externalTokenId];
    }

    function setNFTimeshareMonthAddress(address _addr) public onlyOwner {
        _NFTimeshareMonths = NFTimeshareMonth(_addr);
    }

    function getNFTimeshareMonthAddress() public view returns (address) {
      return address(_NFTimeshareMonths);
    }


    function _exists(uint256 tokenId) internal view virtual override returns (bool) {
      return (_wrappedNFTs[tokenId]._contractAddr != address(0));
    }


    modifier needsTimeshareMonths {
        require(address(_NFTimeshareMonths) != address(0x0), "NFTimeshare contract address hasn't been set up");
        _;
    }



    /* OVERRIDDEN DISALLOWED METHODS. YOU TRADE TIMESHAREMONTHS, NOT TIMESHARES*/
    modifier disallowed {
        require(false, "Disallowed operation on NFTimeshare");
        _;
    }

    function safeTransferFrom(address /*from*/, address /*to*/, uint256 /*tokenId*/) public override disallowed {
        return;
    }

    function transferFrom(address /*from*/, address /*to*/, uint256 /*tokenId*/) public override disallowed {
        return;
    }

    function approve(address /*to*/, uint256 /*tokenId*/) public virtual override disallowed {
        return;
    }

    function getApproved(uint256 /*tokenId*/) public view virtual override disallowed returns (address)  {
        return address(0);
    }
    function setApprovalForAll(address /*operator*/, bool /*_approved*/) public virtual override disallowed {
        return;
    }
    function isApprovedForAll(address /*owner*/, address /*operator*/) public view virtual override disallowed returns (bool) {
        return false;
    }
    function safeTransferFrom(address /*from*/, address /*to*/, uint256 /*tokenId*/, bytes memory /*data*/) public virtual override disallowed {
        return;
    }

}
