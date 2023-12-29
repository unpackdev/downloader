// Just Another $hit Coin 
//
// No purpose. No value. It's just another shitcoin.
//
// Website: https://pleasegiveme.money
//
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20PresetMinterPauserUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./TransparentUpgradeableProxy.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";

contract JustAnotherShitCoin is Initializable, ERC20PresetMinterPauserUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    
    address public _owner;

    // Mapping to track operator permissions
    mapping(address => bool) private _operators;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialAccount) public initializer {
        // 1,000,000 tokens with 18 decimal places
        uint256 initialSupply = 1000000 * 10**decimals(); 
        __ERC20_init("Just Another $hit Coin", "POOP");
        __Ownable_init();
        __Pausable_init();
        _operators[initialAccount] = true;
        // Mint 0.1 % of maxSupply for The Broke Guy
        _mint(initialAccount, initialSupply);

    }

     receive() external payable whenNotPaused {
        // 1 billion tokens max. All good things must come to an end.
        uint256 maxSupply = 1_000_000_000 * 10**decimals();
        // Setting minimum transaction amount to stop Augustus Gloop from eating all the tokens
        uint minEther = 2e15;  
        // Gimme my ETH or you gets no tokens!
        require(msg.value >= minEther, "Oops! The amount sent is below the minimum requirement.");
        // Getting (psuedo) random number for token amount
        uint256 randomAmount = getRandomAmount(msg.sender);
        uint256 mintAmount = randomAmount * 10**decimals();
        // You can never have enough decimals.
        require(totalSupply() + mintAmount <= maxSupply * 10**decimals(), "Sorry. The supply of tokens has been exhausted");
        //Over transaction minimum? Check. Under max supply? Check. Sending tokens.
        _mint(msg.sender, mintAmount);
     }
  
    // I know. It's NOT random but if you have the time, energy, resources, and
    // you care enough to guess the number then you REALLY need to get a life.
    function getRandomAmount(address sender) private view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            sender,
            blockhash(block.number - 1)
        ))) % 901;
        // Number from 100 to 1000
        return random + 100; 
     } 
    
    // Why are you all in my business?
    function owner() override public view returns (address) {
        return _owner;
     }
   
    // To pause...
    function pause() override public onlyOperator whenNotPaused {
        _pause();
     }
    
    // ...or not to pause... that is the function
    function unpause() override public onlyOperator whenPaused {
        _unpause();
     }

     // Are you my friend?
    modifier onlyOperator() {
        require(isOperator(msg.sender), "Stranger danger! I don't know you!");
        _;
     }

    // Who dis? New token.
    function isOperator(address account) public view returns (bool) {
        return _operators[account];
     }
 
    // How to add friends and family
    function addOperator(address operator) external onlyOperator whenNotPaused {
        require(owner() == msg.sender || _operators[msg.sender], "Stranger danger! I don't know you!");
        _operators[operator] = true;
     }
    
    // How to kick people out of the cool club
    function removeOperator(address operator) external onlyOperator whenNotPaused {
        _operators[operator] = false;
     }

    // Broke no more. I'm rich bitch!!!
    function withdraw() external whenNotPaused {
        require(owner() == msg.sender || _operators[msg.sender], "Stranger danger! I don't know you!");
        payable(msg.sender).transfer(address(this).balance);
     }
}