// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IDeFiatPoints.sol";
import "./ERC20.sol";
import "./DeFiatGovernedUtils.sol";

contract DeFiatPoints is ERC20("DeFiat Points v2", "DFTPv2"), IDeFiatPoints, DeFiatGovernedUtils {
    using SafeMath for uint256;

    event DiscountUpdated(address indexed user, uint256 discount);
    event TrancheUpdated(address indexed user, uint256 tranche, uint256 pointsNeeded);
    event AllTranchesUpdated(address indexed user);
    event TokenUpdated(address indexed user, address token);
    event PointsUpdated(address indexed user, address indexed subject, uint256 amount);
    event WhitelistedUpdated(address indexed user, address indexed subject, bool whitelist);
    event RedirectionUpdated(address indexed user, address indexed subject, bool redirect);

    address public token; // DFT ERC20 Token 
    
    mapping (uint256 => uint256) public discountTranches; // mapping of DFTP needed for each discount tranche
    mapping (address => uint256) private _discounts; // mapping of users to current discount, 100 = 100%
    mapping (address => uint256) private _lastTx; // mapping of users last txn
    mapping (address => bool) private _whitelisted; // mapping of addresses who are allowed to call addPoints
    mapping (address => bool) private _redirection; // addresses where points should be redirected to tx.origin, i.e. uniswap
    
    constructor(address _governance) public {
        _setGovernance(_governance);
        _mint(msg.sender, 150000 * 1e18);
    }

    // Views

    // Discounts - View the current % discount of the _address
    function viewDiscountOf(address _address) public override view returns (uint256) {
        return _discounts[_address];
    }

    // Discounts - View the discount level the _address is eligibile for
    function viewEligibilityOf(address _address) public override view returns (uint256 tranche) {
        uint256 balance = balanceOf(_address);
        for (uint256 i = 0; i <= 9; i++) {
            if (balance >= discountTranches[i]) { 
                tranche = i;
            } else {
                return tranche;
            } 
        }
    }

    // Discounts - Check amount of points needed for _tranche
    function discountPointsNeeded(uint256 _tranche) public override view returns (uint256 pointsNeeded) {
        return (discountTranches[_tranche]);
    }

    // Points - Min amount 
    function viewTxThreshold() public override view returns (uint256) {
        return IDeFiatGov(governance).viewTxThreshold();
    }

    // Points - view whitelisted address
    function viewWhitelisted(address _address) public override view returns (bool) {
        return _whitelisted[_address];
    }

    // Points - view redirection address
    function viewRedirection(address _address) public override view returns (bool) {
        return _redirection[_address];
    }

    // State-Changing Functions

    // Discount - Update Discount internal function to control event on every update
    function _updateDiscount(address user, uint256 discount) internal {
        _discounts[user] = discount;
        emit DiscountUpdated(user, discount);
    }

    // Discount - Update your discount if balance of DFTP is high enough
    // Otherwise, throw to prevent unnecessary calls
    function updateMyDiscount() public returns (bool) {
        uint256 tranche = viewEligibilityOf(msg.sender);
        uint256 discount = tranche * 10;
        require(discount != _discounts[msg.sender], "UpdateDiscount: No discount change");

        _updateDiscount(msg.sender, discount);
    }

    // Discount - Update the user discount directly, Governance-Only
    function overrideDiscount(address user, uint256 discount) external onlyGovernor {
        require(discount <= 100, "OverrideDiscount: Must be in-bounds");
        require(_discounts[user] != discount, "OverrideDiscount: No discount change");

        _updateDiscount(user, discount);
    }
    
    // Tranches - Set an individual discount tranche
    function setDiscountTranches(uint256 tranche, uint256 pointsNeeded) external onlyGovernor {
        require(tranche < 10, "SetTranche: Maximum tranche level exceeded");
        require(discountTranches[tranche] != pointsNeeded, "SetTranche: No change detected");

        discountTranches[tranche] = pointsNeeded;
        emit TrancheUpdated(msg.sender, tranche, pointsNeeded);
    }
    
    // Tranches - Set all 10 discount tranches
    function setAll10DiscountTranches(
        uint256 _pointsNeeded1, uint256 _pointsNeeded2, uint256 _pointsNeeded3, uint256 _pointsNeeded4, 
        uint256 _pointsNeeded5, uint256 _pointsNeeded6, uint256 _pointsNeeded7, uint256 _pointsNeeded8, 
        uint256 _pointsNeeded9
    ) external onlyGovernor {
        discountTranches[0] = 0;
        discountTranches[1] = _pointsNeeded1; // 10%
        discountTranches[2] = _pointsNeeded2; // 20%
        discountTranches[3] = _pointsNeeded3; // 30%
        discountTranches[4] = _pointsNeeded4; // 40%
        discountTranches[5] = _pointsNeeded5; // 50%
        discountTranches[6] = _pointsNeeded6; // 60%
        discountTranches[7] = _pointsNeeded7; // 70%
        discountTranches[8] = _pointsNeeded8; // 80%
        discountTranches[9] = _pointsNeeded9; // 90%

        emit AllTranchesUpdated(msg.sender);
    }

    // Points - Update the user DFTP balance, Governance-Only
    function overrideLoyaltyPoints(address _address, uint256 _points) external override onlyGovernor {
        uint256 balance = balanceOf(_address);
        if (balance == _points) {
            return;
        }

        _burn(_address, balance);

        if (_points > 0) {
            _mint(_address, _points);
        }
        emit PointsUpdated(msg.sender, _address, _points);
    }
    
    // Points - Add points to the _address when the _txSize is greater than txThreshold
    // Only callable by governors
    function addPoints(address _address, uint256 _txSize, uint256 _points) external onlyGovernor {
        if (!_whitelisted[msg.sender]) {
            return;
        }
        
        if(_txSize >= viewTxThreshold() && _lastTx[tx.origin] < block.number){
            if (_redirection[_address]) {
                _mint(tx.origin, _points);
            } else {
                _mint(_address, _points);
            }
            _lastTx[tx.origin] = block.number;
        }
    }
    
    // Points - Override to force update user discount on every transfer
    // Note: minting/burning does not constitute as a transfer, so we must have the update function
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        ERC20._transfer(sender, recipient, amount);

        // force update discount if not governance
        if (IDeFiatGov(governance).viewActorLevelOf(sender) == 0) {
            uint256 tranche = viewEligibilityOf(sender);
            _discounts[sender] = tranche * 10;
        }
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

     // Gov - Set whitelist address
    function setWhitelisted(address _address, bool _whitelist) external override onlyGovernor {
        require(_whitelisted[_address] != _whitelist, "SetWhitelisted: No whitelist change");

        _whitelisted[_address] = _whitelist;
        emit WhitelistedUpdated(msg.sender, _address, _whitelist);
    }

    // Gov - Set redirection address
    function setRedirection(address _address, bool _redirect) external override onlyGovernor {
        require(_redirection[_address] != _redirect, "SetRedirection: No redirection change");

        _redirection[_address] = _redirect;
        emit RedirectionUpdated(msg.sender, _address, _redirect);
    }

    // Gov - Update the DeFiat Token address
    function setToken(address _token) external onlyGovernor {
        require(_token != token, "SetToken: No token change");

        token = _token;
        emit TokenUpdated(msg.sender, token);
    }
} 
