pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./MathUpgradeable.sol";



interface IHead {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}


contract faucet is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {

	using AddressUpgradeable for address;

	IERC20Upgradeable public headFractional;
    IHead public gHead;

    event  Deposit(address indexed dst, uint256 wad);
    event  Withdrawal(address indexed src, uint wad);

    bool public rescueEnabled;
    uint256 public totalDeposits;
    uint256 public maxHead;
    uint256 public claimedHead;
 
	mapping(address => uint256) public deposits;
    mapping (address => bool)    private whitelistedContracts;  
    
    function initialize() initializer public {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        _pause();
        maxHead = 100 * 10**6  * 10**18; // 100 million
        rescueEnabled = false; 
    }

    function setInit(address _headFractional, address _gHead) public onlyOwner {

        headFractional = IERC20Upgradeable(_headFractional);
        gHead = IHead(_gHead);

    }

	function deposit(uint256 amount) external blockExternalContracts whenNotPaused nonReentrant() {

        address msgSender = _msgSender();
        require(!msgSender.isContract(), "Contracts are not allowed");
        require(headFractional.balanceOf(msgSender) >= amount, "Not enough fractional $HEAD tokens in wallet - 2");

    	totalDeposits += amount;
		deposits[msgSender] += amount;

		headFractional.transferFrom(msgSender, address(this), amount);
        gHead.mint(msgSender, amount);

        emit Deposit(msgSender, amount);

	}


    function withdraw(uint256 amount) external blockExternalContracts whenNotPaused nonReentrant() {
        address msgSender = _msgSender();
        uint256 userDeposits = deposits[msgSender];
        
       
        require(!msgSender.isContract(), "Contracts are not allowed");
        require(gHead.balanceOf(msgSender) >= amount, "Not enough game $HEAD tokens in wallet - 3");
        require(claimedHead + amount <= maxHead + userDeposits , "All available $HEAD has been claimed");
        require(headFractional.balanceOf(address(this)) >= amount, "Not enough fractional $HEAD in the contract");
        require(headFractional.balanceOf(address(this)) >= totalDeposits, "Not enough fractional $HEAD to cover the reserves");
        claimedHead += amount;

        totalDeposits -= MathUpgradeable.min(amount, userDeposits) ;
		deposits[msgSender] -= MathUpgradeable.min(amount, userDeposits) ;

        gHead.burn(msgSender, amount);
        headFractional.transfer(msgSender, amount);

        
        emit Withdrawal(msgSender, amount);


    }

    function rescue() external blockExternalContracts nonReentrant() {
        address msgSender = _msgSender();
        require(!msgSender.isContract(), "Contracts are not allowed");
        require(tx.origin == msgSender, "Only EOA");
        require(rescueEnabled, "RESCUE DISABLED");

        uint256 amount = deposits[msgSender];
        headFractional.transfer(msgSender, amount);
        emit Withdrawal(msgSender, deposits[msgSender]);

    } 

    /** Admin Functions */

    function changeMaxHead(uint256 _newMax) external onlyOwner {
        maxHead = _newMax * 10**18; 

    }

    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    function withdrawTokens() external onlyOwner {
        uint256 tokenSupply = headFractional.balanceOf(address(this));
        headFractional.transfer(msg.sender, tokenSupply-totalDeposits);
    }


    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    modifier blockExternalContracts() {
        if (tx.origin != msg.sender) {
        require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
        _;
        
        } else {

        _;

        }
    
    }

}

