// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC721Enumerable.sol";

import "./InternalWhitelistControl.sol";
import "./WallStreetArt.sol";
import "./WST.sol";
import "./WSTMining.sol";

// WSASeller distributes calls
// WSASeller stores rewards
contract WSASeller is InternalWhitelistControl {

    using SafeMath for uint256;
    using Strings for uint256;

    address public wallstreetartNFT;
    address public wallstreetartToken;
    address public wstMining;

    uint256 public PRICE;
    uint256 public START_TIME;
    uint256 public MAX_SUPPLY;
    uint256 public SUPPLY_AMOUNT;
    uint256 public LIMIT_PER_ADDRESS;

    // owner => number of mint
    mapping(address => uint256) public mintRecords;

    event Purchase(address indexed who, uint256 indexed tokenId);

    constructor(
        address _wallstreetartNFT,
        address _wallstreetartToken,
        address _wstMining,
        uint256 _price,
        uint256 _startTime,
        uint256 _supplyAmount,
        uint256 _limitPerAddr
    ) {
        require(block.timestamp <= _startTime, "InvalidTime");
        require(_supplyAmount > 0, "InvalidSupply");

        wallstreetartNFT = _wallstreetartNFT;
        wallstreetartToken = _wallstreetartToken;
        wstMining = _wstMining;

        PRICE = _price;
        START_TIME = _startTime;
        LIMIT_PER_ADDRESS = _limitPerAddr;
        SUPPLY_AMOUNT = _supplyAmount;
        MAX_SUPPLY = _supplyAmount.add(WallStreetArt(wallstreetartNFT).totalSupply());
    }

    function setWstMining(address _wstMining) external onlyOwner {
        require(_wstMining != address(0), "ZeroAddress");
        wstMining = _wstMining;
    }

    function mint(uint256 amount) external payable {

        uint256 totalSup = WallStreetArt(wallstreetartNFT).totalSupply();
        
        require(START_TIME <= block.timestamp, "WaitForSaleStarts");
        require((totalSup).add(amount) <= MAX_SUPPLY, "SoldOut");
        require((PRICE).mul(amount) <= msg.value, "AmountTooLow");
        require((mintRecords[msg.sender]).add(amount) <= LIMIT_PER_ADDRESS, 'MintLimitReached');
        
        mintRecords[msg.sender] = mintRecords[msg.sender].add(amount);

        uint256 [] memory tokenIds = new uint256[](amount);

        for(uint256 i = 0; i < amount; i++){
            WallStreetArt(wallstreetartNFT).mint(
                msg.sender,
                totalSup
            );
            tokenIds[i] = totalSup;
            totalSup = WallStreetArt(wallstreetartNFT).totalSupply();
        }

        WSTMining(wstMining).stake(tokenIds);
        emit Purchase(msg.sender, totalSup);
    }

    /**
    * @dev Withdraw ether from this contract (Callable by owner only)
    */
    function withdraw(
        address token, 
        uint256 amount, 
        address payable beneficiary
    ) onlyOwner public {
        if(token == address(0)) {
            beneficiary.transfer(amount);
        }
        else{
            IERC20(token).transfer(beneficiary, amount);
        }
    }
}