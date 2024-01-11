// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ECDSA.sol";

// @author: olive

////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////
///                                                                                                  ///
///                                                                                                  ///
///                                                                                                  ///
///                                                                                                  ///
///    $$\      $$\ $$$$$$$\  $$\   $$\       $$$$$$$$\ $$\           $$\                  $$\       /// 
///    $$$\    $$$ |$$  __$$\ $$ |  $$ |      \__$$  __|\__|          $$ |                 $$ |      /// 
///    $$$$\  $$$$ |$$ |  $$ |$$ |  $$ |         $$ |   $$\  $$$$$$$\ $$ |  $$\  $$$$$$\ $$$$$$\     /// 
///    $$\$$\$$ $$ |$$$$$$$\ |$$$$$$$$ |         $$ |   $$ |$$  _____|$$ | $$  |$$  __$$\\_$$  _|    /// 
///    $$ \$$$  $$ |$$  __$$\ $$  __$$ |         $$ |   $$ |$$ /      $$$$$$  / $$$$$$$$ | $$ |      ///
///    $$ |\$  /$$ |$$ |  $$ |$$ |  $$ |         $$ |   $$ |$$ |      $$  _$$<  $$   ____| $$ |$$\   ///
///    $$ | \_/ $$ |$$$$$$$  |$$ |  $$ |         $$ |   $$ |\$$$$$$$\ $$ | \$$\ \$$$$$$$\  \$$$$  |  ///
///    \__|     \__|\_______/ \__|  \__|         \__|   \__| \_______|\__|  \__| \_______|  \____/   ///
///                                                                                                  ///
///                                                                                                  ///
///                                                                                                  ///      
///                                                                                                  ///
////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////

contract MBHticket is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public MAX_ELEMENTS = 100;
    uint256 public constant START_AT = 1;

    Counters.Counter private _tokenIdTracker;

    string public sampleTokenURI;

    event welcomeToMBH(uint256 indexed id);
    event NewMaxElement(uint256 max);

    constructor(string memory _sampleURI) ERC721("Meta Bounty Hunters Ticket", "MBH Ticket"){
        setSampleURI(_sampleURI);
    }


    function setSampleURI(string memory sampleURI) public onlyOwner {
        sampleTokenURI = sampleURI;
    }

    function totalToken() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return sampleTokenURI;
    }

    function _mintAnElement(address _to, uint256 _tokenId) private {

        _tokenIdTracker.increment();
        _safeMint(_to, _tokenId);

        emit welcomeToMBH(_tokenId);
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function setMaxElement(uint256 _max) public onlyOwner{
        MAX_ELEMENTS = _max;
        emit NewMaxElement(MAX_ELEMENTS);
    }
    
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function giftMint(address[] memory _addrs, uint[] memory _tokenAmounts) public onlyOwner {
        uint totalQuantity = 0;
        uint256 total = totalToken();
        for(uint i = 0; i < _addrs.length; i ++) {
            totalQuantity += _tokenAmounts[i];
        }
        require( total + totalQuantity <= MAX_ELEMENTS, "Max limit" );
        for(uint i = 0; i < _addrs.length; i ++){
            for(uint j = 0; j < _tokenAmounts[i]; j ++){
                total ++;
                _mintAnElement(_addrs[i], total);
            }
        }
    }
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}