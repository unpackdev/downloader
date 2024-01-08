// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./SafeMath.sol";
import "./AccessControl.sol";
import "./ICryptoMoth.sol";

interface PaymentSplitter {
    function pay(uint id) external payable;
}

contract CryptoMothSale is AccessControl {
    using SafeMath for uint;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint public constant MAX_MOTHS = 10000;
    uint public constant LIFESPAN_BLOCKS = 301;

    uint public initialPrice;
    uint public decrementalPrice;
    bool public hasSaleStarted = false;

    uint[] public mintStartTimes;
    uint public secondsToMint;

    PaymentSplitter _paymentSplitter;
    ICryptoMoth cryptoMoth;
    address _cOwner;
    uint _splitterId;

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Restricted to admins.");
        _;
    }

    constructor(address _cryptoMoth) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        cryptoMoth = ICryptoMoth(_cryptoMoth);
        _cOwner = msg.sender;
        _paymentSplitter = PaymentSplitter(0xAFde32E520222C8163e9ed162167759bAE585122);
        initialPrice = 1 ether;
        decrementalPrice = 0.0033 ether;
        mintStartTimes = [9 * 60 * 60, 17 * 60 * 60, 1 * 60 * 60];
        secondsToMint = 2 * 60 * 60;
    }

    function isSalesOn() public view returns (bool) {
        uint8 _hours = uint8((block.timestamp / 60 / 60) % 24);
        uint8 _minutes = uint8((block.timestamp / 60) % 60);
        uint8 _seconds = uint8(block.timestamp % 60);
        uint totalSeconds = uint(_hours) * 60 * 60 + uint(_minutes) * 60 + uint(_seconds);

        bool onTimeFrame = false;

        for (uint i = 0; i < mintStartTimes.length; i++) {
            if (
                (mintStartTimes[i] <= totalSeconds &&
                    totalSeconds < mintStartTimes[i] + secondsToMint) ||
                (mintStartTimes[i] + secondsToMint > 24 * 60 * 60 &&
                    totalSeconds < mintStartTimes[i] + secondsToMint - 24 * 60 * 60)
            ) {
                onTimeFrame = true;
            }
        }

        return (onTimeFrame && hasSaleStarted) || hasRole(ADMIN_ROLE, msg.sender);
    }

    function dnaForBlockNumber(uint256 _blockNumber) external view returns (uint) {
        return cryptoMoth.dnaForBlockNumber(_blockNumber);
    }

    function isMinted(uint256 _blockNumber) external view returns (bool) {
        return cryptoMoth.isMinted(_blockNumber);
    }

    function canMint(uint256 _blockNumber) public view returns (bool) {
        (bool _, uint256 subResult) = block.number.trySub(LIFESPAN_BLOCKS);
        if (_blockNumber > block.number || _blockNumber < subResult) {
            return false;
        }
        return !cryptoMoth.isMinted(_blockNumber);
    }

    function priceForMoth(uint256 _blockNumber) public view returns (uint256) {
        require(canMint(_blockNumber), "block not allowed");
        uint price = initialPrice - decrementalPrice * (block.number - _blockNumber);
        return price < 0.01 ether ? 0.01 ether : price;
    }

    function blockOfToken(uint tokenId) public view returns (uint) {
        return cryptoMoth.blockOfToken(tokenId);
    }
    
    function mint(uint _blockNumber) public payable {
        require(isSalesOn(), "sale hasn't started");
        require(totalSupply() < MAX_MOTHS, "sold out");
        require(canMint(_blockNumber), "block number not allowed or already minted");
        require(msg.value >= priceForMoth(_blockNumber) || hasRole(ADMIN_ROLE, msg.sender), "ether value sent is below the price");
        
        cryptoMoth.mint(_blockNumber, msg.sender);
    }
    
    function tokensOfOwner(address _owner) public view returns(uint[] memory) {
        uint tokenCount = cryptoMoth.balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = cryptoMoth.tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function setTimeFrame(uint[] memory _times, uint _secondsToMint) public onlyAdmin {
        mintStartTimes = _times;
        secondsToMint = _secondsToMint;
    }

    function setPrices(uint256 _initialPrice, uint256 _decrementalPrice) public onlyAdmin {
        initialPrice = _initialPrice;
        decrementalPrice = _decrementalPrice;
    }

    function startSale() public onlyAdmin {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyAdmin {
        hasSaleStarted = false;
    }

    function totalSupply() public view returns (uint256) {
        return cryptoMoth.totalSupply();
    }

    function setSplitterId(uint __splitterId) public onlyAdmin {
        _splitterId = __splitterId;
    }

    function withdrawAll() public payable onlyAdmin {
        _paymentSplitter.pay{value: address(this).balance}(_splitterId);
    }
}
