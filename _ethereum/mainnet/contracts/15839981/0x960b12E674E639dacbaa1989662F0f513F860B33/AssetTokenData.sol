// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./DSMath.sol";
import "./AccessManager.sol";

/// @author Swarm Markets
/// @title Asset Token Data for Asset Token Contract
/// @notice Contract to manage the interest rate on the Asset Token contract
contract AssetTokenData is AccessManager {
    using SafeMath for uint256;

    /// @notice Emitted when the interest rate is set
    event InterestRateStored(
        address indexed _tokenAddress,
        address indexed _caller,
        uint256 _interestRate,
        bool _positiveInterest
    );

    /// @notice Emitted when the rate gets updated
    event RateUpdated(address indexed _tokenAddress, address indexed _caller, uint256 _newRate, bool _positiveInterest);

    /// @notice Constructor
    /// @param _maxQtyOfAuthorizationLists max qty for addresses to be added in the authorization list
    constructor(uint256 _maxQtyOfAuthorizationLists) {
        require(_maxQtyOfAuthorizationLists > 0, "Small MaxQty of AuthList");
        require(_maxQtyOfAuthorizationLists < 100, "Large MaxQty of AuthList");

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        maxQtyOfAuthorizationLists = _maxQtyOfAuthorizationLists;
    }

    /// @notice Gets the interest rate and positive/negative interest value
    /// @param _tokenAddress address of the current token being managed
    /// @return uint256 the interest rate
    /// @return bool true if it is positive interest, false if it is not
    function getInterestRate(address _tokenAddress) external view returns (uint256, bool) {
        onlyStoredToken(_tokenAddress);
        return (tokensData[_tokenAddress].interestRate, tokensData[_tokenAddress].positiveInterest);
    }

    /// @notice Gets the current rate
    /// @param _tokenAddress address of the current token being managed
    /// @return uint256 the rate
    function getCurrentRate(address _tokenAddress) external view returns (uint256) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].rate;
    }

    /// @notice Gets the timestamp of the last update
    /// @param _tokenAddress address of the current token being managed
    /// @return uint256 the last update in block.timestamp format
    function getLastUpdate(address _tokenAddress) external view returns (uint256) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].lastUpdate;
    }

    /// @notice Sets the new intereset rate
    /// @param _tokenAddress address of the current token being managed
    /// @param _interestRate the value to be set
    /// @param _positiveInterest if it's a negative or positive interest
    function setInterestRate(
        address _tokenAddress,
        uint256 _interestRate,
        bool _positiveInterest
    ) external {
        onlyStoredToken(_tokenAddress);
        onlyIssuerOrGuardian(_tokenAddress, _msgSender());
        // @note the value is in percent per seconds

        // 20 digits - THIS IS 100% ANUAL
        require(_interestRate <= 21979553151239153027, "CRK: Rate is too high");
        emit InterestRateStored(_tokenAddress, _msgSender(), _interestRate, _positiveInterest);
        update(_tokenAddress);
        tokensData[_tokenAddress].interestRate = _interestRate;
        tokensData[_tokenAddress].positiveInterest = _positiveInterest;
    }

    /// @notice Update the Structure counting the blocks since the last update and calculating the rate
    /// @param _tokenAddress address of the current token being managed
    function update(address _tokenAddress) public {
        onlyStoredToken(_tokenAddress);
        uint256 _period = (block.timestamp).sub(tokensData[_tokenAddress].lastUpdate);
        uint256 _newRate;

        if (tokensData[_tokenAddress].positiveInterest) {
            _newRate = tokensData[_tokenAddress]
                .rate
                .mul(DSMath.rpow(DECIMALS.add(tokensData[_tokenAddress].interestRate), _period))
                .div(DECIMALS);
        } else {
            _newRate = tokensData[_tokenAddress]
                .rate
                .mul(DSMath.rpow(DECIMALS.sub(tokensData[_tokenAddress].interestRate), _period))
                .div(DECIMALS);
        }

        tokensData[_tokenAddress].rate = _newRate;
        tokensData[_tokenAddress].lastUpdate = block.timestamp;

        emit RateUpdated(_tokenAddress, _msgSender(), _newRate, tokensData[_tokenAddress].positiveInterest);
    }
}
