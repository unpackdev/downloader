// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./DSMath.sol";
import "./AccessManager.sol";

/// @author Swarm Markets
/// @title Asset Token Data for Asset Token Contract
/// @notice Contract to manage the interest rate on the Asset Token contract
contract AssetTokenData is AccessManager {
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
        require(_maxQtyOfAuthorizationLists > 0, "AssetTokenData: maxQtyOfAuthorizationLists must be > 0");
        require(_maxQtyOfAuthorizationLists < 100, "AssetTokenData: maxQtyOfAuthorizationLists must be < 100");

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
    function setInterestRate(address _tokenAddress, uint256 _interestRate, bool _positiveInterest) external {
        onlyStoredToken(_tokenAddress);
        onlyIssuerOrGuardian(_tokenAddress, _msgSender());
        // @note the value is in percent per seconds

        // 20 digits - THIS IS 100% ANUAL
        require(_interestRate <= 21979553151, "AssetTokenData: interestRate must be <= 21979553151");
        emit InterestRateStored(_tokenAddress, _msgSender(), _interestRate, _positiveInterest);
        update(_tokenAddress);
        tokensData[_tokenAddress].interestRate = _interestRate;
        tokensData[_tokenAddress].positiveInterest = _positiveInterest;
    }

    /// @notice Update the Structure counting the blocks since the last update and calculating the rate
    /// @param _tokenAddress address of the current token being managed
    function update(address _tokenAddress) public {
        onlyStoredToken(_tokenAddress);

        uint256 _period = block.timestamp - tokensData[_tokenAddress].lastUpdate;
        uint previousRate = tokensData[_tokenAddress].rate;
        uint256 _newRate;

        if (tokensData[_tokenAddress].positiveInterest) {
            _newRate =
                (previousRate * DSMath.rpow(DECIMALS + tokensData[_tokenAddress].interestRate, _period, DECIMALS)) /
                DECIMALS;
        } else {
            _newRate =
                (previousRate * DSMath.rpow(DECIMALS - tokensData[_tokenAddress].interestRate, _period, DECIMALS)) /
                DECIMALS;
        }

        tokensData[_tokenAddress].rate = _newRate;
        tokensData[_tokenAddress].lastUpdate = block.timestamp;

        emit RateUpdated(_tokenAddress, _msgSender(), _newRate, tokensData[_tokenAddress].positiveInterest);
    }
}
