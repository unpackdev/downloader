// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";

interface IScrapVOne {
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

interface IScrapStaking {
    function viewRewards(address _user) external view returns(uint256);
    function updateReward(address _user) external;
}

contract ScrapHub is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable, PausableUpgradeable {
    
    mapping(address => uint256) public userScrapBalance;
    mapping(address => bool) public managers;
    mapping(address => bool) public taxExcluded;
    mapping(address => uint256) public userGlobalSpend;

    IScrapStaking public ScrapStaking;

    uint256 public sellFee;
    uint256 public buyFee;
    bool public taxStatus;
    address public LPAddress;
    address private constant SCRAP_BURN_ADDRESS = 0x0000000000000000000000000000000000000001;
    IScrapVOne public constant SCRAP_V_ONE = IScrapVOne(0xEEdcd8448bC38A6f43A3aa18651F44782c318fD0);


    event ScrapSpent(address spender, uint256 amount);

    modifier updateYield(address _user, uint256 _amount) {
        if(_amount > userScrapBalance[_user]) ScrapStaking.updateReward(msg.sender);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        __ERC20_init("Scrap2.0", "SCRAP2.0");
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

/*
    ==== ERC20 Functions ====
*/

    function burn(address _from, uint _amount) external {
        require(managers[msg.sender] == true, "This address is not allowed to interact with the contract");
        _burn(_from, _amount);
        userGlobalSpend[_from] += _amount;
    }

    function mintTreasury(uint _amount) external onlyOwner {
        _mint(msg.sender, _amount);
    }

    function mintBalanceToToken(uint _amount) external updateYield(msg.sender, _amount) {
        userScrapBalance[msg.sender] -= _amount;
        _mint(msg.sender, _amount);
    }

    function tokenToBalance(uint _amount) external {
        _burn(msg.sender, _amount);
        userScrapBalance[msg.sender] += _amount;
    }

/*
    ==== SCRAPV2 Balance Updates ====
*/

    function increaseScrapBalance(address _address, uint256 _amount) external  {
        require(managers[msg.sender] == true, "This address is not allowed to interact with the contract");
        userScrapBalance[_address] += _amount;
    }

    function decreaseScrapBalance(address _address, uint256 _amount) external {
        require(managers[msg.sender] == true, "This address is not allowed to interact with the contract");
        userScrapBalance[_address] -= _amount;
        userGlobalSpend[_address] += _amount;
    }

    function spendScrap(uint256 _amount) public updateYield(msg.sender, _amount) {
        userScrapBalance[msg.sender] -= _amount;
        userGlobalSpend[msg.sender] += _amount;
        emit ScrapSpent(msg.sender, _amount);
    }

    function tradeScrap(address _to, uint256  _amount) public updateYield(msg.sender, _amount) {
        require(_amount >= userScrapBalance[msg.sender], "Your SCRAP balance is Insufficient");
        userScrapBalance[msg.sender] -= _amount;
        userScrapBalance[_to] += _amount;
    }

    function totalSpendable(address _user) public view returns(uint256) {
        uint256 totalBalance = userScrapBalance[_user];
        totalBalance += ScrapStaking.viewRewards(_user);
        return totalBalance;
    }

/*
    ==== SCRAPV1 Migration Functions ====
*/

    function migrateToToken(uint256 _amount) external {
        SCRAP_V_ONE.transferFrom(msg.sender, SCRAP_BURN_ADDRESS, _amount);
        _mint(msg.sender, _amount);
    }

    function migrateToBalance(uint256 _amount) external {
        uint256 balance = SCRAP_V_ONE.balanceOf(msg.sender);
        require( balance >= _amount, "Insufficient Balance");
        SCRAP_V_ONE.transferFrom(msg.sender, SCRAP_BURN_ADDRESS, _amount);
        userScrapBalance[msg.sender] += _amount;
    }

/*
    ==== Internal Tax Functions ====
*/

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override{   
        if (taxStatus = false || (from != LPAddress && to != LPAddress)) {
            super._transfer(from,to,amount);
        }
        else if (from == LPAddress) {
            uint256 taxAmount = (amount * buyFee) / 1000;
            super._burn(from,taxAmount);
            super._transfer(from,to,(amount - taxAmount));
        }
        else if (to == LPAddress) {
            uint256 taxAmount = (amount * sellFee) / 1000;
            super._burn(from,taxAmount);
            super._transfer(from,to,(amount - taxAmount));
        }
    }


/*
    ==== Admin Functions ====
*/

    /*function setScrapVOne(address _address) external onlyOwner {
        ScrapVOne = IScrapVOne(_address);
    }*/

    function setScrapStaking(address _address) external onlyOwner {
        ScrapStaking = IScrapStaking(_address);
    }

    function setLPAddress(address _address) external onlyOwner {
        LPAddress = _address;
    }

    function addManager(address _address) external onlyOwner {
        managers[_address] = true;
    }

    function removeManager(address _address) external onlyOwner {
        managers[_address] = false;
    }

    function setSellFee(uint256 _fee) external onlyOwner {
        sellFee = _fee;
    }

    function setBuyFee(uint256 _fee) external onlyOwner {
        buyFee = _fee;
    }

    function toggleTax(bool _taxStatus) external onlyOwner {
        taxStatus = _taxStatus;
    }

}