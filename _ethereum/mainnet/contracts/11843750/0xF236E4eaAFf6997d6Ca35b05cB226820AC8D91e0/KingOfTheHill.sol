// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./KOTH.sol";

contract KingOfTheHill is Ownable, Pausable {
    using SafeMath for uint256;
    
    KOTH private _koth; // Token address of the KOTH ERC20 token
    
    address public _wallet;
    
    address public _potOwner; // Current owner (king of the hill)
    
    uint256 public _bpOfPotToBuy;  // % of the current pot required in ETH to own it
    uint256 public _percentagePotToSeed; // % of the current pot that will be used to seed the next roung
    
    bool public _isStrengthPowerUp; // Is Strength enabled?
    bool public _isDefensePowerUp; // Is Defense enabled?
    bool public _isAgilityPowerUp; // Is Agility Enabled?
    
    uint256 public _strengthBonus; // % Extra of the Pot you win
    uint256 public _defenseBonus; // Multiplier of how expensive the pot becomes for the next person
    uint256 public _agilityBonus; // a number
    uint256 public _agilityBuyNbBlockMin;
    
    uint256 private _nbAgility; // a number
    
    uint256 public _nbBlocksWinning;
    uint256 private _nbBlockBought; // Block number the current round bought at
    
    uint256 public _pot; // Amount of wei in the pot
    uint256 public _seed; // Amount of wei to seed the next pot
    
    address public _weth = address(0x0); // ERC20 address of WETH to calculate WETH / KOTH price
    address public _kothUniPool; // KOTH uniswap pool to calculate WETH / KOTH price
    
    uint256 public _defensePerc = 10;
    uint256 public KOTH_PER_BLOCK_PRECISION = 10 ** 6;
    uint256 public _kothPerBlock = 10 * KOTH_PER_BLOCK_PRECISION; // Amount of KOTH per block for the agility bonus. Precision up to 10^6 (0.000001 KOTH)
    
    uint256 private _rake = 20;
    uint256 public _strengthPerc = 30;
    
    constructor(
        address owner,
        address wallet_
    ) {
        _pause();
        _koth = KOTH(0x0);
//        _weth = weth_;
        _wallet = wallet_;
        _bpOfPotToBuy = 100; // Percentage of the pot in ether it
        _percentagePotToSeed = 90; // Amount of the pot that is kept as the seed
        
        _nbBlocksWinning = 100; // number
        
        _strengthBonus = 100; // percentage
        _defenseBonus = 2; // number
        _agilityBonus = 1; // number
        
        _kothUniPool = msg.sender; // WARNING Change this to the KOTH uni pool once created
        transferOwnership(owner);
    }

    modifier onlyPotOwner() {
        require(
            _msgSender() == _potOwner,
            "KingOfTheHill: Only pot owner can buy bonus"
        );
        _;
    }

    modifier onlyNotPotOwner() {
        require(
            _msgSender() != _potOwner,
            "KingOfTheHill: sender mut not be the pot owner"
        );
        _;
    }

    modifier onlyRationalPercentage(uint256 percentage) {
        require(
            percentage >= 0 && percentage <= 100,
            "KingOfTheHill: percentage value is irrational"
        );
        _;
    }
    
    function setKothUniPool(address p) public onlyOwner {
        _kothUniPool = p;
    }
    
    function setRake(uint r) public onlyOwner {
        _rake = r;
    }
    
    function setDefencePerc(uint d) public onlyOwner {
        _defensePerc = d;
    }
    
    function setStrengthPerc(uint s) public onlyOwner {
        _strengthPerc = s;
    }
    
    function setKothPerBlock(uint k) public onlyOwner {
        _kothPerBlock = k;
    }
    
    function setKoth(address k) public onlyOwner {
        _koth = KOTH(k);
    }
    
    function setWeth(address w) public onlyOwner {
        _weth = w;
    }
    
    // Used for percentages 1% - 100%
    function percentageToAmount(uint256 amount, uint256 percentage) public pure returns (uint256) {
        return amount.mul(percentage).div(100);
    }
    
    // Used for basis points 0.0001% -> 100.0000%
    function basisPointToAmount(uint256 amount, uint256 percentage) public pure returns (uint256) {
        return amount.mul(percentage).div(10000);
    }

    function koth() public view returns (address) {
        return address(_koth);
    }

    function wallet() public view returns (address) {
        return _wallet;
    }

    function nbBlocksWinning() public view returns (uint256) {
        return _nbBlocksWinning;
    }

    function setNbBlocksWinning(uint256 nbBlocks) public onlyOwner() {
        require(nbBlocks > 0, "KingOfTheHill: nbBlocks must be greater than 0");
        _nbBlocksWinning = nbBlocks;
    }

    function remainingBlocks() public view returns (uint256) {
        uint256 blockPassed =
            (block.number).sub(_nbBlockBought).add(
                _nbAgility.mul(_agilityBonus)
            );
        if (_potOwner == address(0)) {
            return _nbBlocksWinning;
        } else if (blockPassed > _nbBlocksWinning) {
            return 0;
        } else {
            return _nbBlocksWinning.sub(blockPassed);
        }
    }

    function hasWinner() public view returns (bool) {
        if (_potOwner != address(0) && remainingBlocks() == 0) {
            return true;
        } else {
            return false;
        }
    }
    
    function percentagePotToBuy() public view returns (uint256) {
        return _bpOfPotToBuy;
    }

    function setPercentagePotToBuy(uint256 percentage) public onlyOwner() onlyRationalPercentage(percentage) {
        _bpOfPotToBuy = percentage;
    }
    
    function percentagePotToSeed() public view returns (uint256) {
        return _percentagePotToSeed;
    }

    function setPercentagePotToSeed(uint256 percentage) public onlyOwner() onlyRationalPercentage(percentage) {
        _percentagePotToSeed = percentage;
    }


    function setStrengthBonus(uint256 percentage) public onlyOwner() {
        //require("KingOfTheHill: Irration percentage")
        _strengthBonus = percentage;
    }
    
    function strengthBonus() public view returns (uint256) {
        return _strengthBonus;
    }

    function defenseBonus() public view returns (uint256) {
        return _defenseBonus;
    }

    function setDefenseBonus(uint256 percentage) public onlyOwner() {
        _defenseBonus = percentage;
    }

    function agilityBonus() public view returns (uint256) {
        return _agilityBonus;
    }

    function setAgilityBonus(uint256 nbBlock) public onlyOwner() {
        _agilityBonus = nbBlock;
    }

    function agilityBuyNbBlockMin() public view returns (uint256) {
        return _agilityBuyNbBlockMin;
    }

    function setAgilityBuyNbBlockMin(uint256 nbBlocks) public onlyOwner() {
        _agilityBuyNbBlockMin = nbBlocks;
    }

    function isStrengthPowerUp() public view returns (bool) {
        return _isStrengthPowerUp;
    }

    function isDefensePowerUp() public view returns (bool) {
        return _isDefensePowerUp;
    }

    function isAgilityPowerUp() public view returns (bool) {
        return _isAgilityPowerUp;
    }

    // Visible pot value is the contract balance minus the seed amount for next round
    function pot() public view returns (uint256) {
        return _pot;
    }

    function seed() public view returns (uint256) {
        return _seed;
    }
    
    /*
     * POT PRICES
     */
    
    function defensivePotCost() public view returns (uint256) {
        uint256 price = basisPointToAmount(
                _pot,
                _bpOfPotToBuy.mul(_defenseBonus)
            );
        return price;
    }
    
    function regularPotCost() public view returns (uint256) {
        return basisPointToAmount(
                _pot,
                _bpOfPotToBuy.mul(1)
            );
    }
    
    function priceOfPot() public view returns (uint256) {
        if (hasWinner()) return basisPointToAmount(_seed, _bpOfPotToBuy);
        if (_isDefensePowerUp) return defensivePotCost();
        return regularPotCost();
    }

    function prize() public view returns (uint256) {
        uint256 strBonus = 0;
        if (_isStrengthPowerUp) {
            strBonus = _strengthBonus;
        }
        return _pot.add(percentageToAmount(_pot, strBonus));
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function potOwner() public view returns (address) {
        return _potOwner;
    }
    
    /*
     * This function returns the price of KOTH in ETH
     */
    function getKOTHPrice() public view returns (uint256) {
        if (_weth == address(0x0)) return 2 * 10 ** 18;
        
        uint256 ethAmount = IERC20(_weth).balanceOf(_kothUniPool);
        uint256 kothAmount = IERC20(_koth).balanceOf(_kothUniPool).mul(10**18);
        
        return kothAmount.div(ethAmount);
    }
    
    function issueWinner() internal {
        emit Winner(_potOwner, prize());
        payable(_potOwner).transfer(prize());
        _pot = _seed;
        _seed = 0;
    }
    
    function buyPot() public payable onlyNotPotOwner() whenNotPaused() {
        require(msg.value >= priceOfPot(), "KingOfTheHill: Not enough ether for buying pot");
        
        // Pay winner and reset contract
        if (hasWinner()) {
            issueWinner();
        }
        
        // Recalculate seed
        uint256 rake = percentageToAmount(msg.value, _rake); // 20% rake
        uint256 keep = msg.value.sub(rake);
        
        uint256 toSeed = percentageToAmount(keep, _percentagePotToSeed);
        uint256 toPot = msg.value.sub(toSeed);
        
        _pot = _pot.add(toPot);
        _seed = _seed.add(toSeed);
        
        payable(_wallet).transfer(rake);
        
        // Reset block bought
        _nbBlockBought = block.number;
        
        // Reset powerups
        _isStrengthPowerUp = false;
        _isDefensePowerUp = false;
        _isAgilityPowerUp = false;
        
        _nbAgility = 0;
        _potOwner = _msgSender();
        
        emit Bought(_msgSender());
    }
    
    /*
     * STRENGTH POWER UP
     */
    
    function strengthPowerUpCost() public view returns (uint256) {
        uint256 amount = 0;
        amount = percentageToAmount(
            percentageToAmount(priceOfPot(), _strengthBonus),
            _strengthPerc
        );
        amount = amount.mul(getKOTHPrice()).div(10 ** 18);
        return amount;
    }

    function buyStrength() public onlyPotOwner() whenNotPaused() {
        require(_isStrengthPowerUp == false, "KingOfTheHill: Already bought a strength power up");
        _koth.operatorBurn(_msgSender(), strengthPowerUpCost(), "", "");
        _isStrengthPowerUp = true;
        emit StrengthActivated(strengthPowerUpCost());
    }

    /*
     * DEFENSIVE POWER UP
     */
    
    function defensePowerUpCost() public view returns (uint256) {
        uint256 amount = percentageToAmount(defensivePotCost().sub(regularPotCost()), _defensePerc);
        amount = amount.mul(getKOTHPrice()).div(10 ** 18);
        return amount;
    }
    
    function buyDefense() public onlyPotOwner() whenNotPaused() {
        require(_isDefensePowerUp == false, "KingOfTheHill: Already bought a defense power up");
        _koth.operatorBurn(_msgSender(), defensePowerUpCost(), "", "");
        _isDefensePowerUp = true;
    }

    function buyAgility(uint256 nbAgility)
        public
        onlyPotOwner()
        whenNotPaused()
    {
        require(
            _isAgilityPowerUp == false,
            "KingOfTheHill: Already bought an agility power up"
        );
        require(nbAgility > 0, "KingOfTheHill: can not buy 0 agility");
        require(
            remainingBlocks() > (_agilityBonus.mul(nbAgility)).add(3),
            "KingOfTheHill: too many agility power-up"
        );
        
        uint256 cost = _kothPerBlock.mul(10 ** uint256(_koth.decimals())).div(KOTH_PER_BLOCK_PRECISION);
        
        _koth.operatorBurn(
            _msgSender(),
            _agilityBonus.mul(nbAgility).mul(cost),
            "",
            ""
        );
        
        _nbAgility = nbAgility;
        _isAgilityPowerUp = true;
    }

    function pause() public onlyOwner() {
        _pause();
    }

    function unpause() public onlyOwner() {
        _unpause();
    }

    
    function withdraw(uint256 amount) public onlyOwner() {
        payable(owner()).transfer(amount);
    }

    receive() external payable {
        uint256 toSeed = percentageToAmount(msg.value, _percentagePotToSeed);
        uint256 toPot = msg.value.sub(toSeed);
        
        _pot = _pot.add(toPot);
        _seed = _seed.add(toSeed);
    }

    event Winner(address indexed winner, uint256 amount);
    event Bought(address indexed buyer);

    event StrengthActivated(uint256 cost);
    event DefenseActivated(uint256 cost);
    event AgilityActivated(uint256 cost);
}
