// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ITopDogBeachClub.sol";
import "./ISNAXToken.sol";

import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/**
 * @title TCBC contract v1
 * @author @darkp0rt
 */
contract TopDogPortalizer is ERC721Enumerable, IERC721Receiver, Ownable, ReentrancyGuard {   
    enum WhitelistedPortalizerStatus { Invalid, Unclaimed, Claimed }
    struct PortalizedDog { address portalizer; uint256 datePortalized; bool isSet; }

    uint256 private constant MAX_BURN = 500;
    uint256 private constant PREREG_MAX_BURN = 1;
    uint256 private constant PUBLIC_MAX_BURN = 3;

    string private _baseTokenURI;
    address private _tdbcAddress;
    address private _snaxAddress;
    bool private _publicPortalizationIsOpen = false;
    bool private _preRegPortalizationPeriodIsOpen = false;
    mapping (uint256 => PortalizedDog) private _doggosInPortal;
    mapping (address => uint256) private _walletPortalizationReservedSNAX;
    mapping (address => WhitelistedPortalizerStatus) private _whitelistedPortalizers;
    
    event DogPortalized(uint256 dogId);

    constructor (
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address tdbcAddress,
        address snaxAddress) ERC721(name, symbol)
    {
        _baseTokenURI = baseTokenURI;
        _tdbcAddress = tdbcAddress;
        _snaxAddress = snaxAddress;
    }

    function togglePublicPortalizationPeriod() external onlyOwner {
        require(_preRegPortalizationPeriodIsOpen, "Pre-reggers first");

        _publicPortalizationIsOpen = !_publicPortalizationIsOpen;
    }

    function togglePreRegPortalizationPeriod() external onlyOwner {
        _preRegPortalizationPeriodIsOpen = !_preRegPortalizationPeriodIsOpen;
    }

    function publicPortalizationPeriodIsOpen() external view returns (bool status) {
        return _publicPortalizationIsOpen;
    }

    function preRegPortalizationPeriodIsOpen() external view returns (bool status) {
        return _preRegPortalizationPeriodIsOpen;
    }

    function setBaseTokenURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function addWhitelistedPortalizers(address[] memory whitelistedPortalizers) external onlyOwner {
        for (uint256 i = 0; i < whitelistedPortalizers.length; i++) {
            _whitelistedPortalizers[whitelistedPortalizers[i]] = WhitelistedPortalizerStatus.Unclaimed;
        }
    }

    function preRegPortalize(uint256[] memory doggos) external nonReentrant() {
        require(_preRegPortalizationPeriodIsOpen, "Portal is not open yet");
        require((totalSupply() + doggos.length) <= MAX_BURN, "Portal is full");
        require(_whitelistedPortalizers[msg.sender] != WhitelistedPortalizerStatus.Claimed, "You've already portalized doggos");
        require(_whitelistedPortalizers[msg.sender] == WhitelistedPortalizerStatus.Unclaimed, "You are not whitelisted. Wait for public portalization.");
        require((balanceOf(msg.sender) + doggos.length) <= PREREG_MAX_BURN, "You can't portalize that many dogs");

        _portalizeDoggos(doggos);
        _whitelistedPortalizers[msg.sender] = WhitelistedPortalizerStatus.Claimed;
    }

    function publicPortalize(uint256[] memory doggos) external nonReentrant() {
        require(_publicPortalizationIsOpen, "Portal is not open yet");
        require((totalSupply() + doggos.length) <= MAX_BURN, "Portal is full");
        require((balanceOf(msg.sender) + doggos.length) <= (PREREG_MAX_BURN + PUBLIC_MAX_BURN), "You can't portalize that many dogs");

        _portalizeDoggos(doggos);
    }

    // called by the minting code if the dog tag mints a cat that can't be upgraded
    // ultra rare chance of this happening
    function returnGoodBoy(uint256 doggoId) external onlyOwner {
        require(_doggosInPortal[doggoId].isSet, "Dog has not been portalized");

        address portalizer = _doggosInPortal[doggoId].portalizer;
        ITopDogBeachClub(_tdbcAddress).safeTransferFrom(address(this), portalizer, doggoId);

        delete _doggosInPortal[doggoId];
    }

    // used to mint tags for Jayson and stolen doggos
    function unJoeify() external onlyOwner {
        _safeMint(0x03F58F0cc44Be4AbC68b2DF93C58514bb1196Dc3, 5500);
        _safeMint(0xAc05F9f58e873222CAE11661A29743371F6d1F6c, 3106);
    }

    function _portalizeDoggos(uint256[] memory doggos) private {
        for (uint256 i = 0; i < doggos.length; i++) {
            uint256 doggoId = doggos[i];
            _portalizeDoggo(doggoId);
        }

        _reserveSNAXForDoggos(doggos);
    }

    // you evil bastards
    function _portalizeDoggo(uint256 doggoId) private {
        require(ITopDogBeachClub(_tdbcAddress).ownerOf(doggoId) == msg.sender, "You are not the owner of that doggo");
        require(!_doggosInPortal[doggoId].isSet, "Dog has already been portalized");

        ITopDogBeachClub(_tdbcAddress).safeTransferFrom(msg.sender, address(this), doggoId); // portal contract will hold doggo

        _doggosInPortal[doggoId] = PortalizedDog(msg.sender, block.timestamp, true);
        _safeMint(msg.sender, doggoId);
    }

    function _reserveSNAXForDoggos(uint256[] memory doggos) private {
        _walletPortalizationReservedSNAX[msg.sender] = ISNAXToken(_snaxAddress).totalAccumulated(doggos);
    }

    function getPortalizationDate(uint256 tokenId) external view returns (uint256) {
        return _doggosInPortal[tokenId].datePortalized;
    }

    function isDogPortalized(uint256 tokenId) external view returns (bool) {
        return _doggosInPortal[tokenId].isSet;
    }

    function snaxReserved(address wallet) external view returns (uint256) {
        return _walletPortalizationReservedSNAX[wallet];
    }

    function isWhitelistedPortalizer(address wallet) external view returns (bool) {
        return _whitelistedPortalizers[wallet] != WhitelistedPortalizerStatus.Invalid;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}