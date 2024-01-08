// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";

// This contract handles swapping to and from xDVD, DAOventures's vip token
contract xDVD is ERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct User {
        uint256 tier;
        uint256 amountDeposited;
    }

    IERC20Upgradeable public dvd;

    uint256[] public tierAmount;
    mapping(address => User) user;

    event Deposit(address indexed user, uint256 DVDAmount, uint256 xDVDAmount);
    event Withdraw(address indexed user, uint256 DVDAmount, uint256 xDVDAmount);

    //Define the DVD token contract
    function initialize(address _dvd, string memory _name, string memory _symbol, uint[] memory _tierAmounts) external initializer {
        __ERC20_init(_name, _symbol);
        dvd = IERC20Upgradeable(_dvd);
        tierAmount = _tierAmounts; 
    }

    // Pay some DVDs. Earn some shares. Locks DVD and mints xDVD
    function deposit(uint256 _amount) public {
        // Gets the amount of DVD locked in the contract
        uint256 totalDVD = dvd.balanceOf(address(this));
        // Gets the amount of xDVD in existence
        uint256 totalShares = totalSupply();
        uint256 what;
        // If no xDVD exists, mint it 1:1 to the amount put in
        if (totalShares == 0) {
            what = _amount;
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of xDVD the DVD is worth. The ratio will change overtime
        else {
            what = _amount.mul(totalShares).div(totalDVD);
            _mint(msg.sender, what);
        }
        // Lock the DVD in the contract
        dvd.safeTransferFrom(msg.sender, address(this), _amount);

        user[msg.sender].amountDeposited = user[msg.sender].amountDeposited.add(
            _amount
        );
        user[msg.sender].tier = calculateTier(user[msg.sender].amountDeposited);

        emit Deposit(msg.sender, _amount, what);
    }

    // Claim back your DVDs. Unclocks the staked + gained DVD and burns xDVD
    function withdraw(uint256 _share) public {
        // Gets the amount of xDVD in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of DVD the xDVD is worth
        uint256 what = _share.mul(dvd.balanceOf(address(this))).div(
            totalShares
        );

        uint256 _depositedAmount = user[msg.sender]
        .amountDeposited
        .mul(_share)
        .div(balanceOf(msg.sender));

        
        user[msg.sender].amountDeposited = user[msg.sender]
            .amountDeposited
            .sub(_depositedAmount);
            
        user[msg.sender].tier = calculateTier(
                user[msg.sender].amountDeposited
            );
        

        _burn(msg.sender, _share);
        dvd.safeTransfer(msg.sender, what);

        emit Withdraw(msg.sender, what, _share);
    }

    function calculateTier(uint256 _depositedAmount)
        internal
        view
        returns (uint256)
    {   
        if (_depositedAmount == 0){
            return 0; //no tier bonus
        } else if (_depositedAmount <= tierAmount[0]) {
            //less than or equal to 1000
            return 1;
        } else if (_depositedAmount <= tierAmount[1]) {
            //less than or equal to 10_000
            return 2;
        } else if (_depositedAmount <= tierAmount[2]) {
            //less than or equal to 50_000
            return 3;
        } else if (_depositedAmount <= tierAmount[3]) {
            //less than or equal to 100_000
            return 4;
        } else {
            return 5;
        }
    }

    function getTier(address _addr)
        public
        view
        returns (uint256 _tier, uint256 _depositedAmount)
    {
        _tier = user[_addr].tier;
        _depositedAmount = user[_addr].amountDeposited;
    }

    uint256[47] private __gap;
}
