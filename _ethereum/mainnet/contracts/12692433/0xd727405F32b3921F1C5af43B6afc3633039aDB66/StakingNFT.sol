// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";

contract StakingNFT is ERC721, Ownable, ReentrancyGuard {

    mapping(address => bool) private _minterAddresses;

    Counters.Counter private _tokenIdTracker;
    struct StakeTokenData {
        uint256 startAt;
        uint256 stakeAmount;
        uint16 rewardPercent;
        address minterAddress;
    }
    mapping(uint256 => StakeTokenData) private _stakeTokens;

    event AddToMinterList(address indexed minterAddress);
    event RemoveFromMinterList(address indexed minterAddress);

    event StakeTokenCreated(
        uint256 tokenId,
        uint256 startAt,
        uint256 stakeAmount,
        uint16 rewardPercent,
        address minterAddress
    );

    constructor (
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
    }

    function isMinterAddress(address minterAddress_) public view returns (bool) {
        return _minterAddresses[minterAddress_];
    }

    function checkTokenExistence(uint256 tokenId_) public view returns (bool) {
        return _exists(tokenId_);
    }

    function getStakeTokenData(uint256 tokenId_)
        public
        view
        returns (
            address ownerAddress,
            uint256 startAt,
            uint256 stakeAmount,
            uint16 rewardPercent,
            address minterAddress
        )
    {
        if (!checkTokenExistence(tokenId_)) {
            return (address(0), 0, 0, 0, address(0));
        }
        StakeTokenData memory tokenData = _stakeTokens[tokenId_];
        return (
            ownerOf(tokenId_),
            tokenData.startAt,
            tokenData.stakeAmount,
            tokenData.rewardPercent,
            tokenData.minterAddress
        );
    }

    function mintToken(
        address addressTo_,
        uint256 stakeAmount_,
        uint16 rewardPercent_
    )
        public
        nonReentrant
        returns (uint256)
    {
        require(addressTo_ != address(0), "StakingNFT: Invalid address to");
        require(stakeAmount_ != 0, "StakingNFT: Invalid stake amount");
        require(rewardPercent_ != 0, "StakingNFT: Invalid reward percent");
        require(_minterAddresses[_msgSender()], "StakingNFT: msgSender has no permissions");

        Counters.increment(_tokenIdTracker);
        uint256 tokenId = Counters.current(_tokenIdTracker);

        _safeMint(addressTo_, tokenId);

        StakeTokenData memory tokenData;
        tokenData.startAt = block.timestamp;
        tokenData.stakeAmount = stakeAmount_;
        tokenData.rewardPercent = rewardPercent_;
        tokenData.minterAddress = _msgSender();
        _stakeTokens[tokenId] = tokenData;

        emit StakeTokenCreated(
            tokenId,
            tokenData.startAt,
            tokenData.stakeAmount,
            tokenData.rewardPercent,
            tokenData.minterAddress
        );

        return tokenId;
    }

    function transfer(address to_, uint256 tokenId_) public nonReentrant returns (bool) {
        require(ownerOf(tokenId_) == _msgSender(), "StakingNFT: Not token owner");
        _transfer(_msgSender(), to_, tokenId_);
        return true;
    }

    function burnToken(uint256 tokenId_) public nonReentrant returns (bool) {
        require(ownerOf(tokenId_) == _msgSender(), "StakingNFT: Not token owner");
        _burn(tokenId_);
        return true;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    function setTokenURI(uint256 tokenId_, string memory tokenURI_) external onlyOwner {
        _setTokenURI(tokenId_, tokenURI_);
    }

    function addToMinterList(address minterAddress_) external onlyOwner {
        _minterAddresses[minterAddress_] = true;
        emit AddToMinterList(minterAddress_);
    }

    function removeFromMinterList(address minterAddress_) external onlyOwner {
        _minterAddresses[minterAddress_] = false;
        emit RemoveFromMinterList(minterAddress_);
    }
}
