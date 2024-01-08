// SPDX-License-Identifier: MIT


// Settings to initialize SpacePort

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";

contract SpaceportSettings is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    EnumerableSet.AddressSet private EARLY_ACCESS_TOKENS;
    mapping(address => uint256) public EARLY_ACCESS_MAP;
    
    
    struct Settings {
        uint256 BASE_FEE; // base fee divided by 1000
        uint256 TOKEN_FEE; // token fee divided by 1000
        address payable ETH_FEE_ADDRESS;
        address payable TOKEN_FEE_ADDRESS;
        uint256 ETH_CREATION_FEE; // fee to generate a presale contract on the platform
        uint256 ROUND1_LENGTH; // length of round 1 in blocks
        uint256 MAX_SPACEPORT_LENGTH; // maximum difference between start and endblock
    }
    
    Settings public SETTINGS;
    
    constructor() public {
        SETTINGS.BASE_FEE = 50; // 5%
        SETTINGS.TOKEN_FEE = 50; // 5%
        SETTINGS.ETH_CREATION_FEE = 5e17;
        SETTINGS.ETH_FEE_ADDRESS = msg.sender;
        SETTINGS.TOKEN_FEE_ADDRESS = msg.sender;
        SETTINGS.ROUND1_LENGTH = 70; //add time block 
        SETTINGS.MAX_SPACEPORT_LENGTH = 93000;  // add time block
    }
    
    function getRound1Length () external view returns (uint256) {
        return SETTINGS.ROUND1_LENGTH;
    }

    function getMaxSpaceportLength () external view returns (uint256) {
        return SETTINGS.MAX_SPACEPORT_LENGTH;
    }
    
    function getBaseFee () external view returns (uint256) {
        return SETTINGS.BASE_FEE;
    }
    
    function getTokenFee () external view returns (uint256) {
        return SETTINGS.TOKEN_FEE;
    }
    
    function getEthCreationFee () external view returns (uint256) {
        return SETTINGS.ETH_CREATION_FEE;
    }
    
    function getEthAddress () external view returns (address payable) {
        return SETTINGS.ETH_FEE_ADDRESS;
    }
    
    function getTokenAddress () external view returns (address payable) {
        return SETTINGS.TOKEN_FEE_ADDRESS;
    }
    
    function setFeeAddresses(address payable _ethAddress, address payable _tokenFeeAddress) external onlyOwner {
        SETTINGS.ETH_FEE_ADDRESS = _ethAddress;
        SETTINGS.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
    }
    
    function setFees(uint256 _baseFee, uint256 _tokenFee, uint256 _ethCreationFee) external onlyOwner {
        SETTINGS.BASE_FEE = _baseFee;
        SETTINGS.TOKEN_FEE = _tokenFee;
        SETTINGS.ETH_CREATION_FEE = _ethCreationFee;
    }
    
    function setRound1Length(uint256 _round1Length) external onlyOwner {
        SETTINGS.ROUND1_LENGTH = _round1Length;
    }

    function setMaxSpaceportLength(uint256 _maxLength) external onlyOwner {
        SETTINGS.MAX_SPACEPORT_LENGTH = _maxLength;
    }
    
    function editEarlyAccessTokens(address _token, uint256 _holdAmount, bool _allow) external onlyOwner {
        if (_allow) {
            EARLY_ACCESS_TOKENS.add(_token);
        } else {
            EARLY_ACCESS_TOKENS.remove(_token);
        }
        EARLY_ACCESS_MAP[_token] = _holdAmount;
    }
    
    // There will never be more than 10 items in this array. Care for gas limits will be taken.
    // We are aware too many tokens in this unbounded array results in out of gas errors.
    function userHoldsSufficientRound1Token (address _user) external view returns (bool) {
        if (earlyAccessTokensLength() == 0) {
            return true;
        }
        for (uint i = 0; i < earlyAccessTokensLength(); i++) {
          (address token, uint256 amountHold) = getEarlyAccessTokenAtIndex(i);
          if (IERC20(token).balanceOf(_user) >= amountHold) {
              return true;
          }
        }
        return false;
    }
    
    function getEarlyAccessTokenAtIndex(uint256 _index) public view returns (address, uint256) {
        address tokenAddress = EARLY_ACCESS_TOKENS.at(_index);
        return (tokenAddress, EARLY_ACCESS_MAP[tokenAddress]);
    }
    
    function earlyAccessTokensLength() public view returns (uint256) {
        return EARLY_ACCESS_TOKENS.length();
    }
    
}