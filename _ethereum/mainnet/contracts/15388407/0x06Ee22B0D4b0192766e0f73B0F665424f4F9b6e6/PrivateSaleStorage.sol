//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

import "./IERC20.sol";

/// @title The storage of StakeProxy
contract PrivateSaleStorage {

    struct UserInfoAmount {
        uint256 inputamount;
        uint256 totaloutputamount;
        uint256 getAmount;
        address inputAddress;
    }

    struct WhiteList {
        uint256 amount;
    }
    
    address public getTokenOwner;       //받은 ton을 받을 주소
    uint256 public totalGetAmount;      //총 TON받은양
    uint256 public totalSaleAmount;     //총 판매토큰

    uint256 public saleStartTime;           //sale시작 시간
    uint256 public saleEndTime;             //sale끝 시간

    uint256 public saleTokenPrice;  //판매토큰가격
    uint256 public getTokenPrice;   //받는토큰가격(TON)

    IERC20 public saleToken;        //판매할 token주소
    IERC20 public getToken;         //TON 주소

    address public wton;             //WTON 주소

    uint256 public totalAllocatedAmount;
    uint16 public totalClaimCounts;

    uint256[] public claimTimes;
    uint256[] public claimPercents; 

    mapping (address => UserInfoAmount) public usersAmount;
    mapping (address => WhiteList) public usersWhite;

    /// @dev flag for pause proxy
    bool public pauseProxy;

    bool public pauseSetting;

    /// @dev implementation of proxy index
    mapping(uint256 => address) public proxyImplementation;
    mapping(address => bool) public aliveImplementation;
    mapping(bytes4 => address) public selectorImplementation;
}
