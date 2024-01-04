// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ReentrancyGuard.sol";
import "./Math.sol";

import "./TAEY.sol";
import "./IwETH9.sol";
import "./IyvwETHv2.sol";

contract ArtSteward is ReentrancyGuard {
    using Math for uint256;

    /**************************************
                     FIELDS
    ***************************************/

    IERC721 public art;
    address public owner;
    address public artist;

    uint256 public purchasePrice;
    uint256 public sellPrice;

    mapping(address => uint256) public funds;
    mapping(address => uint256) public totalEarnings;

    IwETH9 private wETH9 = IwETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IyvwETHv2 private yvwETHv2 = IyvwETHv2(0xa9fE4601811213c340e850ea305481afF02f5b28);

    /**************************************
                     EVENTS
    ***************************************/

    event Bought(
        address indexed previousOwner,
        address indexed newOwner,
        uint256 purchasePrice,
        uint256 newSellPrice
    );
    event PriceChanged(address indexed currentOwner, uint256 oldPrice, uint256 newPrice);
    event YieldCollected(address indexed currentOwner, uint256 ownerYield, uint256 artistYield);

    /**************************************
                  CONSTRUCTOR
    ***************************************/

    constructor(address _artist) {
        art = new TAEY();
        owner = _artist;
        artist = _artist;
    }

    receive() external payable {
        // Needed for unwrapping wETH
    }

    /***************************************
                     ACTIONS
    ****************************************/

    function buy(uint256 _newSellPrice) external payable nonReentrant {
        uint256 newDeposit = _getDeposit(sellPrice, _newSellPrice);

        // Make sure the buyer has the needed funds
        require(msg.value == sellPrice + newDeposit, "Incorrect amount");

        // Collect any yield for the current owner and the artist
        _collectYield();

        // After collecting the yield, the remaining shares denote the current owner's deposit
        uint256 currentDepositShares = yvwETHv2.balanceOf(address(this));
        funds[owner] += _withdrawFromVault(currentDepositShares);

        // Share the sell price between the owner and the artist
        uint256 ownerShare = (sellPrice * 95) / 100;
        funds[owner] += ownerShare;
        uint256 artistShare = sellPrice - ownerShare;
        funds[artist] += artistShare;
        totalEarnings[artist] += artistShare;

        // Deposit the new owner's deposit
        _depositToVault(newDeposit);

        // Push any outstanding funds
        _sendFunds(owner);
        _sendFunds(artist);

        emit Bought(owner, msg.sender, sellPrice, _newSellPrice);

        // Adjust ownership parameters
        owner = msg.sender;
        purchasePrice = sellPrice;
        sellPrice = _newSellPrice;
    }

    function setPrice(uint256 _newSellPrice) external payable nonReentrant {
        require(msg.sender == owner, "Unauthorized");

        if (_newSellPrice > sellPrice) {
            // If the new sell price is higher than the old one, more deposit is needed
            uint256 neededDeposit = _newSellPrice - sellPrice;
            require(msg.value == neededDeposit, "Incorrect amount");
            _depositToVault(neededDeposit);
        } else if (_newSellPrice < sellPrice) {
            // Else, we need to return part of the current deposit
            uint256 depositShares = _getCurrentDepositShares();
            uint256 surplusShares = ((sellPrice - _newSellPrice) * 1e18) / yvwETHv2.pricePerShare();
            funds[owner] += _withdrawFromVault(depositShares.min(surplusShares));
        }

        emit PriceChanged(owner, sellPrice, _newSellPrice);
        sellPrice = _newSellPrice;

        // Push any outstanding funds
        _sendFunds(owner);
    }

    function collectYield() public nonReentrant {
        require(msg.sender == owner || msg.sender == artist, "Unauthorized");
        _collectYield();

        // Push any outstanding funds
        _sendFunds(owner);
        _sendFunds(artist);
    }

    function pullFunds() public nonReentrant {
        _sendFunds(msg.sender);
    }

    /***************************************
                      VIEWS
    ****************************************/

    function getCurrentYield() external view returns (uint256) {
        uint256 totalShares = yvwETHv2.balanceOf(address(this));
        uint256 depositShares = _getCurrentDepositShares();
        if (totalShares > depositShares) {
            uint256 yieldShares = totalShares - depositShares;
            uint256 yield = (yieldShares * yvwETHv2.pricePerShare()) / 1e18;
            return yield;
        }
        return 0;
    }

    /***************************************
                     HELPERS
    ****************************************/

    function _collectYield() internal {
        uint256 totalShares = yvwETHv2.balanceOf(address(this));
        uint256 depositShares = _getCurrentDepositShares();
        if (totalShares > depositShares) {
            // Any shares not belonging to the deposit correspond to yield
            uint256 yieldShares = totalShares - depositShares;
            uint256 yield = _withdrawFromVault(yieldShares);

            // Split the yield between the owner and the artist
            uint256 ownerShare = yield / 2;
            funds[owner] += ownerShare;
            totalEarnings[owner] += ownerShare;
            uint256 artistShare = yield - ownerShare;
            funds[artist] += artistShare;
            totalEarnings[artist] += artistShare;

            emit YieldCollected(owner, ownerShare, artistShare);
        }
    }

    function _sendFunds(address _recipient) internal {
        // Try sending the funds to the recipient, or else put them in an escrow
        uint256 fundsAvailable = funds[_recipient];
        funds[_recipient] = 0;
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _recipient.call{value: fundsAvailable, gas: 10000}("");
        if (!success) {
            funds[_recipient] = fundsAvailable;
        }
    }

    function _getDeposit(uint256 _purchasePrice, uint256 _sellPrice)
        internal
        pure
        returns (uint256)
    {
        // The deposit represents the difference between the purchase and sell price
        return _sellPrice > _purchasePrice ? _sellPrice - _purchasePrice : 0;
    }

    function _getCurrentDepositShares() internal view returns (uint256) {
        uint256 deposit = _getDeposit(purchasePrice, sellPrice);

        uint256 totalShares = yvwETHv2.balanceOf(address(this));
        uint256 depositShares = (deposit * 1e18) / yvwETHv2.pricePerShare();

        // Handle the case of a negative yield when we would lose money on the deposit
        return totalShares.min(depositShares);
    }

    function _depositToVault(uint256 _amount) internal returns (uint256) {
        wETH9.deposit{value: _amount}();
        wETH9.approve(address(yvwETHv2), _amount);
        return yvwETHv2.deposit(_amount);
    }

    function _withdrawFromVault(uint256 _shares) internal returns (uint256) {
        uint256 redeemed = yvwETHv2.withdraw(_shares);
        wETH9.withdraw(redeemed);
        return redeemed;
    }

    /***************************************
                     TESTING
    ****************************************/

    // Only for testing purposes, make sure to remove on deployment!

    // function setWETH9(address _wETH9) external {
    //     wETH9 = IwETH9(_wETH9);
    // }

    // function setYvwETHv2(address _yvwETHv2) external {
    //     yvwETHv2 = IyvwETHv2(_yvwETHv2);
    // }
}
