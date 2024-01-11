// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";

/// @title The Splits Implementation Contract
/// @author kumareth@monument.app & dig@monument.app
/// @notice This contract shall be deployed everytime a user mints an artifact. This contract will manage the split sharing of royalty fee that it receives.
contract Splits is Initializable, ReentrancyGuardUpgradeable {
    mapping(address => uint256) public royalties;

    address[] public splitters;
    uint256[] public permyriads;

    constructor () {
        //
    }

    /// @notice Constructor function for the Splits Contract Instances
    /// @dev Takes in the array of Splitters and Permyriads, fills the storage, to set the Split rules accordingly.
    /// @param _splitters An array of addresses that shall be entitled to some permyriad share of the total royalty supplied to the contract, from the market, preferrably.
    /// @param _permyriads An array of numbers that represent permyriads, all its elements must add up to a total of 10000, and must be in order of splitters supplied during construction of the contract.
    function initialize(
        address[] memory _splitters,
        uint256[] memory _permyriads
    )
        public 
        payable
        initializer
    {
        require(_splitters.length == _permyriads.length);

        uint256 _totalPermyriad;

        uint256 splittersLength = _splitters.length;

        for (uint256 i = 0; i < splittersLength; i++) {
            require(_splitters[i] != address(0));
            require(_permyriads[i] > 0);
            require(_permyriads[i] <= 10000);
            _totalPermyriad += _permyriads[i];
        }

        require(_totalPermyriad == 10000, "Total permyriad must be 10000");

        for (uint256 i = 0; i < splittersLength; i++) {
            royalties[_splitters[i]] = _permyriads[i];
        }

        splitters = _splitters;
        permyriads = _permyriads;
    }

    /// @notice Get Balance of the Split Contract
    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

    // Events
    event ReceivedFunds(
        address indexed by,
        uint256 fundsInwei,
        uint256 timestamp
    );
    event SentSplit(
        address indexed from,
        address indexed to,
        uint256 fundsInwei,
        uint256 timestamp
    );
    event Withdrew (
        address indexed actionedBy,
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );

    /// @notice Allow this contract to split funds everytime it receives it
    fallback() external virtual payable {
        emit ReceivedFunds(msg.sender, msg.value, block.timestamp);
        distributeFunds();
    }

    /// @notice Allow this contract to split funds everytime it receives it
    receive() external virtual payable {
        emit ReceivedFunds(msg.sender, msg.value, block.timestamp);
        distributeFunds();
    }

    /// @notice if x = 100, & y = 1000 & scale = 10000, that should return 1% of 1000 that is 10.
    /// @dev Calculates x parts per scale for y, read this for more info: https://ethereum.stackexchange.com/a/79736
    /// @param x Parts per Scale
    /// @param y Number to calculate on
    /// @param scale Scale on which to make the calculations
    function mulScale (uint256 x, uint256 y, uint128 scale)
    internal
    pure 
    returns (uint256) {
        uint256 a = x / scale;
        uint256 b = x % scale;
        uint256 c = y / scale;
        uint256 d = y % scale;

        return a * c * scale + a * d + b * c + b * d / scale;
    }

    /// @notice This is a payable function that distributes whatever amount it gets, to all the addresses in the splitters array, according to their royalty permyriad share set in royalties mapping.
    function distributeFunds() public nonReentrant payable {
        uint256 balance = msg.value;

        require(balance > 0, "zero balance");

        emit ReceivedFunds (msg.sender, balance, block.timestamp);

        uint256 splittersLength = splitters.length;
        for (uint256 i = 0; i < splittersLength; i++) {
            uint256 value = mulScale(permyriads[i], balance, 10000);

            (bool success, ) = payable(splitters[i]).call{value: value}("");
            require(success, "Transfer failed");

            emit SentSplit (msg.sender, splitters[i], value, block.timestamp);
        }
    }

    /// @notice Takes in an address and returns how much permyriad share of the total royalty the address was originally entitled to.
    /// @param _address Address whose royalty precentage share information to fetch.
    /// @return uint256 - Permyriad Royalty the address was originally entitled to.
    function royaltySplitInfo(address _address) external view returns (uint256) {
        uint256 royaltyPermyriad = royalties[_address];
        return royaltyPermyriad;
    }
}