// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Strings.sol";
import "./IERC721.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";
import "./Counters.sol";
import "./IFxRoot.sol";

contract SuperNormalV3 is ERC721Upgradeable, OwnableUpgradeable, DefaultOperatorFiltererUpgradeable {
    using Counters for Counters.Counter;

    address public minterAddress;
    address lockerAddress;

    bool public claimLive;
    string baseURI;

    mapping(uint256 => bool) tradelockedTokens;

    Counters.Counter private _tokenIdCounter;

    address public fxRootAddress;

    function initialize() public initializer {
        __ERC721_init("SuperNormal", "ZIPS");
        __Ownable_init();
        __DefaultOperatorFilterer_init();
        setGallery("ipfs://QmfMjK37DkqrVUjNPYYbJHDdspMM1T4vpvWhwpaRVPJjcP/");
    }

    modifier onlyMinter() {
        require(msg.sender == minterAddress, "Only minter address can call this function");
        _;
    }

    modifier onlyLocker() {
        require(msg.sender == lockerAddress);
        _;
    }

    function addToTradeLock(uint256[] calldata tokens) external onlyLocker {
        for (uint256 i; i < tokens.length;) {
            tradelockedTokens[tokens[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function removeFromTradeLock(uint256[] calldata tokens) external onlyLocker {
        for (uint256 i; i < tokens.length;) {
            tradelockedTokens[tokens[i]] = false;
            unchecked {
                ++i;
            }
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    function mint(address to, uint256 tokenId) external onlyMinter {
        require(claimLive, "Claiming is paused or not started");

        IFxRoot(fxRootAddress).sendMessageToChild(tokenId, to, true);
        _mintInternal(to, tokenId);
    }

    function _mintInternal(address _to, uint256 _tokenId) internal {
        _mint(_to, _tokenId);
        _tokenIdCounter.increment();
    }

    function setMinterAddress(address newMinterAddress) external onlyOwner {
        minterAddress = newMinterAddress;
    }

    function setLockerAddress(address newLockerAddress) external onlyOwner {
        lockerAddress = newLockerAddress;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function setGallery(string memory _gallery) public onlyOwner {
        baseURI = _gallery;
    }

    function claimSwitch() public onlyOwner {
        claimLive = !claimLive;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        if (!tradelockedTokens[tokenId]) {
            IFxRoot(fxRootAddress).sendMessageToChild(tokenId, to, false);
            super.transferFrom(from, to, tokenId);
        } else {
            revert("Token locked");
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)public override onlyAllowedOperator(from) {
        IFxRoot(fxRootAddress).sendMessageToChild(tokenId, to, false);
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function isClaimed(uint256 tokenId) external view returns (bool tokenExists) {
        return _exists(tokenId);
    }

    function tokensOfWallet(address wallet) public view returns (uint256[] memory) {
        require(balanceOf(wallet) > 0, "This wallet doesnt hold any tokens.");
        uint256 tokenCount = balanceOf(wallet);
        uint256[] memory result = new uint256[](tokenCount);
        uint256 index = 0;

        for (uint256 tokenId = 1; tokenId < 8889; ++tokenId) {
            if (index == tokenCount) break;

            if (_ownerOf(tokenId) == wallet) {
                result[index] = tokenId;
                ++index;
            }
        }

        return result;
    }

    function tokenOfOwnerByIndex(address wallet, uint256 index) public view returns (uint256 tokenId) {
        require(index < balanceOf(wallet), "Owner index out of bounds");
        return tokensOfWallet(wallet)[index];
    }

    function burnToken(uint256[] calldata tokenIDs) external {
        for (uint256 i; i < tokenIDs.length;) {
            uint256 tokenID = tokenIDs[i];
            require(msg.sender == ownerOf(tokenID));
            _burn(tokenID);
            _tokenIdCounter.decrement();
            unchecked {
                ++i;
            }
        }
    }

    function setFxRootAddress(address _fxRootAddress) public onlyOwner{
        fxRootAddress = _fxRootAddress;
    }

}
