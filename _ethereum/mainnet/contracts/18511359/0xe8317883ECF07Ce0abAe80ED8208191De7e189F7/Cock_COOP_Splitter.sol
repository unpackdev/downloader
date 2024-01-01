// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Cock_COOP_Splitter {
    address public owner;

    // Initialize ratios and wallet addresses as  state variables
    uint256 public xbcCoopRatio;
    uint256 public bakaawRatio;
    uint256 public futureBirdsRatio;

    address payable public xbcCoopAddress;
    address payable public bakaawAddress;
    address payable public futureBirdsAddress;

    uint256 public constant MASTER_RATIO_DIVISOR = 1000;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner.");
        _;
    }

    constructor() {
        owner = msg.sender;
        // Set initial hardcoded values
        xbcCoopRatio = 750; // Ratio for XBC Coop
        bakaawRatio = 125; // Ratio for Bakaaw
        futureBirdsRatio = 125; // Ratio for Future Birds

        xbcCoopAddress = payable(0x6eB5A3fE3A73f8FddCc05714285d14B9770437e0); // XBC Coop Address
        bakaawAddress = payable(0xE01c9dE5751b9f8EcE6F2D1B28B6444f0b0A3D14); // Bakaaw Address
        futureBirdsAddress = payable(0xE01c9dE5751b9f8EcE6F2D1B28B6444f0b0A3D14); // Future Birds Address
    }

    receive() external payable {}

    // Update the fee ratios
    function updateRatios( uint256 newBakaawRatio, uint256 newFutureBirdsRatio) public onlyOwner {
        uint256 totalRatio = xbcCoopRatio + newBakaawRatio + newFutureBirdsRatio;
        require(totalRatio == MASTER_RATIO_DIVISOR, "Total ratio must be 1000.");
        
        bakaawRatio = newBakaawRatio;
        futureBirdsRatio = newFutureBirdsRatio;
    }

    // Update the wallet addresses
    function updateWalletAddresses(address payable newBakaaw, address payable newFutureBirds) public onlyOwner {
        bakaawAddress = newBakaaw;
        futureBirdsAddress = newFutureBirds;
    }

    // Split ETH between XBC Coop, Bakaaw, and Future birds
    function splitETH() public {
        uint256 balance = address(this).balance;

        uint256 xbcCoopShare = (balance * xbcCoopRatio) / MASTER_RATIO_DIVISOR;
        uint256 bakaawShare = (balance * bakaawRatio) / MASTER_RATIO_DIVISOR;
        uint256 futureBirdsShare = balance - xbcCoopShare - bakaawShare; // Remainder to avoid rounding errors

        _safeTransfer(xbcCoopAddress, xbcCoopShare);
        _safeTransfer(bakaawAddress, bakaawShare);
        _safeTransfer(futureBirdsAddress, futureBirdsShare);
    }

    function _safeTransfer(address payable recipient, uint256 amount) private {
        (bool success, ) = recipient.call{value: amount, gas: 40000}("");
        require(success, "Transfer failed");
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}