// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "./Address.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IConfig.sol";
import "./IOracle.sol";

contract Config is Ownable, IConfig, ReentrancyGuard {
    using Address for address;

    struct QuoteCurrency {
        uint256 id;
        address currency;
        uint256 currencyDecimal;
        address oracle;
        uint256 oracleDecimal;
    }

    // add protocol fee
    int128 public totalFeePercentage = 100000;
    int128 public protocolFee;
    address public protocolTreasury;

    // Global curve operational state
    bool public globalFrozen = false;

    // mapping quote currencies
    mapping(uint256 => QuoteCurrency) public quoteCurrencies;
    mapping(uint256 => bool) public isQuoteAdded;
    mapping(address => bool) public isQuoteUsed;
    mapping(address => bool) public isOracleUsed;

    event GlobalFrozenSet(bool isFrozen);
    event TreasuryUpdated(address indexed newTreasury);
    event ProtocolFeeUpdated(address indexed treasury, int128 indexed fee);
    event NewQuoteAdded(address indexed quote, uint256 quoteDecimal, address indexed oracle, uint256 oracleDecimal);

    constructor(int128 _protocolFee, address _treasury) {
        require(totalFeePercentage >= _protocolFee, "CurveFactory/fee-cant-be-over-100%");
        require(_treasury != address(0), "CurveFactory/zero-address");
        protocolFee = _protocolFee;
        protocolTreasury = _treasury;
    }

    function getGlobalFrozenState() external view virtual override returns (bool) {
        return globalFrozen;
    }

    function getProtocolFee() external view virtual override returns (int128) {
        return protocolFee;
    }

    function getProtocolTreasury() external view virtual override returns (address) {
        return protocolTreasury;
    }

    function setGlobalFrozen(bool _toFreezeOrNotToFreeze) external virtual override onlyOwner {
        emit GlobalFrozenSet(_toFreezeOrNotToFreeze);

        globalFrozen = _toFreezeOrNotToFreeze;
    }

    function updateProtocolTreasury(address _newTreasury) external virtual override onlyOwner nonReentrant {
        require(_newTreasury != protocolTreasury, "CurveFactory/same-treasury-address");
        require(_newTreasury != address(0), "CurveFactory/zero-address");
        protocolTreasury = _newTreasury;
        emit TreasuryUpdated(protocolTreasury);
    }

    function updateProtocolFee(int128 _newFee) external virtual override onlyOwner nonReentrant {
        require(totalFeePercentage >= _newFee, "CurveFactory/fee-cant-be-over-100%");
        require(_newFee != protocolFee, "CurveFactory/same-protocol-fee");
        protocolFee = _newFee;
        emit ProtocolFeeUpdated(protocolTreasury, protocolFee);
    }
}
