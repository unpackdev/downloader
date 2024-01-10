/*********************

  ＣＯＳＭＯＰＯＬＩＴＹ 🪐
    
    cosmopolity.art

**********************/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./IMintPassContract.sol";

contract Cosmopolity is IERC721Metadata, ERC721Enumerable, Ownable {
    bool public mintable;
    address payable public feeAddress;
    uint256 public immutable maxNumberOfPieces = 8000;
    uint256 public publicMintCeiling = 200;
    uint256 public publicMintCount = 0;
    uint256 public maximumMintsPerTransaction = 2;
    string public baseURI;
    uint256 public currentPrice = 1.0 ether;
    bool public baseURILocked;
    string public contractURI;
    address public stylizerContractAddress;
    address _mintPassAddress;

    struct TokenGenesisInfo {
        address originContractAddress;
        uint256 initialTokenCount;
    }

    // duplicate initial token info for quick lookup on the client side
    mapping(uint256 => TokenGenesisInfo) public tokenGenesisInfo;

    constructor(
        string memory name,
        string memory symbol,
        address payable _feeAddress,
        string memory initBaseURI
    ) ERC721(name, symbol) {
        feeAddress = _feeAddress;
        baseURI = initBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mintMultiple(address to, uint256 numberOfTokens) public payable {
        require(
            msg.value == currentPrice * numberOfTokens,
            "Must send in the correct amount to mint Cosmopolity token(s)."
        );
        publicMintCount += numberOfTokens;
        require(
            publicMintCount <= publicMintCeiling,
            "Current public mint limit reached."
        );
        _mintMultiple(to, numberOfTokens);
    }

    function mintMultipleWithMintPasses(uint256[] memory mintPassTokenIds)
        public
        payable
    {
        IMintPass mintPassContract = IMintPass(_mintPassAddress);
        require(
            mintPassContract.isMintPassSalesActive() == true,
            "Mint pass sale is not active."
        );
        mintPassContract.expend(mintPassTokenIds, msg.value);
        _mintMultiple(msg.sender, mintPassTokenIds.length);
    }

    function _mintMultiple(address to, uint256 numberOfTokens) private {
        // mint
        require(mintable == true, "Minting is not active.");
        require(
            piecesLeft() >= numberOfTokens,
            "Not enough tokens left to mint."
        );
        require(
            numberOfTokens <= maximumMintsPerTransaction,
            "Minting too many."
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            // figure out the token id
            uint256 newTokenId = totalSupply() + 1;
            _mintAssigningInitialTokens(to, newTokenId);
        }
    }

    function _mintAssigningInitialTokens(address to, uint256 newTokenId)
        private
    {
        uint256 newOwnerTokenCount = balanceOf(to) + 1;
        tokenGenesisInfo[newTokenId] = TokenGenesisInfo(to, newOwnerTokenCount);
        _mint(to, newTokenId);
    }

    function tokenExists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function piecesLeft() public view returns (uint256) {
        return maxNumberOfPieces - totalSupply();
    }

    /***** Owner Operations *****/

    // TODO: artist proof mint function. make sure can only be called by owner
    // and only be called once

    function ownerSetBaseURI(string memory _newBaseURI) public onlyOwner {
        require(baseURILocked == false, "baseURI is permenantly locked.");
        baseURI = _newBaseURI;
    }

    function ownerSetFeeAddress(address payable _newAddress) public onlyOwner {
        feeAddress = _newAddress;
    }

    function ownerSetMintable(bool _mintable) public onlyOwner {
        mintable = _mintable;
    }

    function ownerSetStylizerContractAddress(address _addr) public onlyOwner {
        stylizerContractAddress = _addr;
    }

    function ownerSetAuctionContractAddress(address _addr) public onlyOwner {
        _mintPassAddress = _addr;
    }

    function ownerSetPublicMintCeiling(uint256 _newMintCeiling)
        public
        onlyOwner
    {
        publicMintCeiling = _newMintCeiling;
    }

    function ownerSetMaximumMintsPerTransaction(uint256 max) public onlyOwner {
        maximumMintsPerTransaction = max;
    }

    function ownerWithdrawETH() public onlyOwner {
        Address.sendValue(feeAddress, address(this).balance);
    }

    function ownerSetCurrentPrice(uint256 _price) public onlyOwner {
        currentPrice = _price;
    }

    function ownerDangerouslyPermanentlyLockBaseURI() public onlyOwner {
        // DANGER: this will permanently lock the baseURI
        baseURILocked = true;
    }

    function ownerSetContractURI(string memory _newContractURI)
        public
        onlyOwner
    {
        contractURI = _newContractURI;
    }

    /***** End of Owner Operations *****/
}
