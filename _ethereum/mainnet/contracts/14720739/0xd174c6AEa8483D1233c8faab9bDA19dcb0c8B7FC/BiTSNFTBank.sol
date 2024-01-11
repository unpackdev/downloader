// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./BiTSNFTMint.sol";
import "./BiTSNFTURI.sol";
import "./BiTSNFTUtils.sol";

/// @title BiTS Bank - Mint and Redeem BiTS
/// @author dydxcrypt@protonmail.com
contract BiTSNFTBank is Ownable, Pausable {
    /// Token Counter
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    /// Deposit token
    IERC20Metadata public immutable depositToken;
    uint private immutable _depositTokenDecimals;
    /// Mint and URI contracts
    BiTSNFTMint public immutable saMint;
    BiTSNFTURI public immutable saURI;
    uint public mintpremiumPct;
    /// TokenId mappings
    mapping(uint256 => bytes32) public userTextHashToTokenId;
    mapping(uint256 => uint256) public depositAmountToTokenId;
    /// Frontend URL
    string public webUrl = "https://bitsnft.xyz";
    /// Events
    event MintTokenId(address indexed sender, uint256 tokenId);
    event BurnTokenId(address indexed sender, uint256 tokenId);

    constructor(address _depositToken, uint8 _premiumPercent, string memory _mintName, string memory _mintSymbol) {
        depositToken = IERC20Metadata(_depositToken);
        saMint = new BiTSNFTMint(_mintName, _mintSymbol);
        saURI = new BiTSNFTURI(_mintName, string.concat(_mintName,". Redeemable for ", depositToken.symbol()), depositToken.symbol(), _mintSymbol);
        _depositTokenDecimals = (10 ** depositToken.decimals());
        _premiumPercent <= 10? mintpremiumPct = _premiumPercent : mintpremiumPct = 10;
    }

    function pause() public onlyOwner {
        _pause();
        saMint.pause();
    }

    function unpause() public onlyOwner {
        _unpause();
        saMint.unpause();
    }

    function transferMintOwnership(address newOwner) public onlyOwner {
        saMint.transferOwnership(newOwner);
        saURI.transferOwnership(newOwner);
    }

    function setMintPremiumPct(uint8 _premiumPercent) public onlyOwner {
        _premiumPercent <= 10? mintpremiumPct = _premiumPercent : mintpremiumPct = 10;
    }

    function setWebUrl(string memory _webUrl) public onlyOwner {
        webUrl = _webUrl;
    }

    function mintDeposit(string memory _userText, DepositUnits _depositUnit) public whenNotPaused {
        /// Increment tokenId
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        /// Get Unit. Set stringlimit and amount.
        require(uint8(_depositUnit) <= 4,"Choose btw 0 and 4"); 

        /// Check user text not empty and within limits.
        require(bytes(_userText).length > 0, string.concat("Message string empty!"));     
  
        /// Set SVG MetaData
        SVGMeta memory _svgMeta = setMetaByUnit(_depositUnit);

        /// Meta Checks
        require(bytes(_userText).length <= _svgMeta.stringLimit, string.concat("Max ",Strings.toString(_svgMeta.stringLimit)," chars!"));
        string memory _userTextUpper = toUpper(_userText);
        require(userTextExists(_userTextUpper) != true, "Text taken!");
        userTextHashToTokenId[tokenId] = keccak256(abi.encodePacked(_userTextUpper));        

        
        /// msg.sender has to approve this contract to spend token first
        uint256 _mintPremium = (_svgMeta.depositAmount * mintpremiumPct)/100;
        uint256 _transferAmount = _svgMeta.depositAmount + _mintPremium;
        require(depositToken.allowance(msg.sender, address(this)) >= _transferAmount, "Check allowance");
        require(_transferAmount > 0,"Zero");

        /// Store mapping of tokenid to depositamount
        depositAmountToTokenId[tokenId] = _svgMeta.depositAmount;

        /// Transfer Deposit to Bank
        depositToken.transferFrom(msg.sender, address(this), _transferAmount);
        /// Send Premium to Owner
        depositToken.transfer(owner(), _mintPremium);

        /// Mint and Issue Deed
        TokenMeta memory _tokenMeta = TokenMeta(_userTextUpper, tokenId, _svgMeta.depositAmount);
        

        saMint.safeMint(msg.sender, tokenId, saURI.createTokenURI(_tokenMeta, _svgMeta, _depositUnit));      
        /// Emit event
        emit MintTokenId(msg.sender, tokenId);
    }

    
    function redeemDeposit(uint256 _tokenId) public whenNotPaused {
        /// Burn Deed
        /// msg.sender has to approve this contract to burn token first

        /// verify current token owner is calling
        require(msg.sender == saMint.ownerOf(_tokenId),"Not owner!");
        saMint.burn(_tokenId);
  
        /// Refund Deposit
        require(depositAmountToTokenId[_tokenId] <= depositToken.balanceOf(address(this)), "Depleted!");
        depositToken.transfer(msg.sender, depositAmountToTokenId[_tokenId]);
        /// remove usertext and deposit mapping
        delete userTextHashToTokenId[_tokenId];
        delete depositAmountToTokenId[_tokenId];
        /// Emit event
        emit BurnTokenId(msg.sender, _tokenId);
   
    }

    function setMetaByUnit(DepositUnits _depositUnit) private view returns(SVGMeta memory) {
    SVGMeta memory _svgMeta;
     if (DepositUnits.MILLI == _depositUnit) {
         _svgMeta.depositAmount =  _depositTokenDecimals/1000;
         _svgMeta.stringLimit = 4;
         _svgMeta.backgroundHue = "#8B8B8B";
         _svgMeta.strokeHue = "#4B4B4B";
         _svgMeta.depositUnitInString = "0.001";
         _svgMeta.depositUnitName = "MILLI";
         _svgMeta.svgLogo = "";
     }
     if (DepositUnits.CENTI == _depositUnit) {
         _svgMeta.depositAmount = _depositTokenDecimals/100;
         _svgMeta.stringLimit = 8;
         _svgMeta.backgroundHue = "#278AFF";
         _svgMeta.strokeHue = "#274A84";
         _svgMeta.depositUnitInString = "0.01";
         _svgMeta.depositUnitName = "CENTI";
         _svgMeta.svgLogo = "";
     }
     if (DepositUnits.DECI == _depositUnit) {
         _svgMeta.depositAmount = _depositTokenDecimals/10;
         _svgMeta.stringLimit = 16;
         _svgMeta.backgroundHue = "#DF6908";
         _svgMeta.strokeHue = "#763B11";
         _svgMeta.depositUnitInString = "0.1";
         _svgMeta.depositUnitName = "";
         _svgMeta.svgLogo = DeciSVGLogo;
     }
     if (DepositUnits.ONE == _depositUnit) {
         _svgMeta.depositAmount = _depositTokenDecimals;
         _svgMeta.stringLimit = 32;
         _svgMeta.backgroundHue = "#FF4628";
         _svgMeta.strokeHue = "#931B0C";
         _svgMeta.depositUnitInString = "1";
         _svgMeta.depositUnitName = "";
         _svgMeta.svgLogo = OneSVGLogo;
     }
     if (DepositUnits.DECA == _depositUnit) {
         _svgMeta.depositAmount = _depositTokenDecimals*10;
         _svgMeta.stringLimit = 64;
         _svgMeta.backgroundHue = "#000000";
         _svgMeta.strokeHue = "#eeb32b";
         _svgMeta.depositUnitInString = "10";
         _svgMeta.depositUnitName = "";
         _svgMeta.svgLogo = DecaSVGLogo;
     }

     return _svgMeta;

    }

    function userTextExists(string memory _userTextUpper) public view returns (bool) {
        bool result = false;
        uint _totalSupply = _tokenIdCounter.current();

        for (uint256 i=0; i < _totalSupply; ++i) {
            if (
                userTextHashToTokenId[i] == keccak256(abi.encodePacked(_userTextUpper))
            ) {
                result = true;
            }
        }
        return result;
    }

    function toUpper(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        uint length = _baseBytes.length;
        for (uint i=0; i < length; ++i) {
            if (_baseBytes[i] >= 0x61 && _baseBytes[i] <= 0x7A) {
                _baseBytes[i] = bytes1(uint8(_baseBytes[i]) - 32);
            }
        }
        return string(_baseBytes);
    }


}
