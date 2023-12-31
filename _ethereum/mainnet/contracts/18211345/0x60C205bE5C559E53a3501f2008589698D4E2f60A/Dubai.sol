// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⢦⡀⠉⠙⢦⡀⠀⠀⣀⣠⣤⣄⣀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣀⡤⠤⠴⠶⠤⠤⢽⣦⡀⠀⢹⡴⠚⠁⠀⢀⣀⣈⣳⣄⠀⠀
⠀⠀⠀⠀⠀⢠⠞⣁⡤⠴⠶⠶⣦⡄⠀⠀⠀⠀⠀⠀⠀⠶⠿⠭⠤⣄⣈⠙⠳⠀
⠀⠀⠀⠀⢠⡿⠋⠀⠀⢀⡴⠋⠁⠀⣀⡖⠛⢳⠴⠶⡄⠀⠀⠀⠀⠀⠈⠙⢦⠀
⠀⠀⠀⠀⠀⠀⠀⠀⡴⠋⣠⠴⠚⠉⠉⣧⣄⣷⡀⢀⣿⡀⠈⠙⠻⡍⠙⠲⢮⣧
⠀⠀⠀⠀⠀⠀⠀⡞⣠⠞⠁⠀⠀⠀⣰⠃⠀⣸⠉⠉⠀⠙⢦⡀⠀⠸⡄⠀⠈⠟
⠀⠀⠀⠀⠀⠀⢸⠟⠁⠀⠀⠀⠀⢠⠏⠉⢉⡇⠀⠀⠀⠀⠀⠉⠳⣄⢷⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡾⠤⠤⢼⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡇⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠉⠉⠉⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣀⣀⣀⣻⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣀⣀⡤⠤⠤⣿⠉⠉⠉⠘⣧⠤⢤⣄⣀⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢀⡤⠖⠋⠉⠀⠀⠀⠀⠀⠙⠲⠤⠤⠴⠚⠁⠀⠀⠀⠉⠉⠓⠦⣄⠀⠀⠀
⢀⡞⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⣄⠀
⠘⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠚⠀

  ____  _   _ ____    _    ___ 
 |  _ \| | | | __ )  / \  |_ _|
 | | | | | | |  _ \ / _ \  | | 
 | |_| | |_| | |_) / ___ \ | | 
 |____/ \___/|____/_/   \_\___|
                               
    Twitter: https://twitter.com/fraudeth_gg
    Telegram: http://t.me/fraudportal
    Website: https://fraudeth.gg
    Docs: https://docs.fraudeth.gg
*/
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IFraudToken.sol";
import "./IPrivatePresale.sol";
contract Dubai is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;
        uint256 lockEndedTimestamp;
        uint256 rebaseEpoch;
    }

    IFraudToken public fraud;
    IPrivatePresale public privatePresale;
    uint256 public lockDuration = 60 hours;
    uint256 public totalStaked;
    uint256 public totalPresaleLocked;

    bool public depositsEnabled;
    bool public emergencyMode = false;

    // Info of each user.
    mapping(address => UserInfo) public userInfo;

    mapping(address => bool) public presaleClaimed;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event LogSetLockDuration(uint256 lockDuration);
    event LogSetDepositsEnabled(bool enabled);
    event WithdrawDeposit(address indexed user, uint256 amount);

    constructor(IFraudToken _fraud, bool _depositsEnabled) {
        fraud = _fraud;
        depositsEnabled = _depositsEnabled;
    }

    function setDepositsEnabled(bool _enabled) external onlyOwner {
        depositsEnabled = _enabled;
        emit LogSetDepositsEnabled(_enabled);
    }

    function deposit(uint256 _amount) public {
        require(depositsEnabled, "Deposits disabled");
        require(_amount > 0, "Invalid amount");
        require(emergencyMode == false, "Contract is in emergency mode, deposits not allowed");
        require(_amount <= fraud.balanceOf(msg.sender), "Not enough tokens");

        UserInfo storage user = userInfo[msg.sender];
        user.lockEndedTimestamp = block.timestamp.add(lockDuration);
        user.rebaseEpoch = fraud.getCurrentEpoch();

        fraud.burn(msg.sender, _amount);
        user.amount = user.amount.add(_amount);

        totalStaked = totalStaked.add(_amount);
        emit Deposit(msg.sender, _amount);
    }

    function withdrawPresaleUser() external {
        require(presaleClaimed[msg.sender] == false, "Already claimed");
        uint256 fraudInDubai = privatePresale.getAllocationFraudInDubai(msg.sender);
        uint256 claimOpenDate = privatePresale.getClaimOpenDate();
        require(claimOpenDate > 0, "Claiming not yet set");
        require(block.timestamp >= claimOpenDate.add(lockDuration), "Claiming not yet opened");
        uint256 currentEpoch = fraud.getCurrentEpoch();
        uint256 claimOpenEpoch = privatePresale.getClaimOpenEpoch();
        uint256 epochsElapsed = currentEpoch.sub(claimOpenEpoch);
        uint256 amountToMint = fraudInDubai;
        if (epochsElapsed > 10) {
            uint256 rebaseFactor = 1 ether;  
            uint256 epochRebased = epochsElapsed.sub(10);
            for (uint256 i = 0; i < epochRebased; i++) {
                rebaseFactor = rebaseFactor.mul(900).div(1000); 
            }
            amountToMint = fraudInDubai.mul(rebaseFactor).div(1 ether);
        }

        fraud.mint(address(msg.sender), amountToMint);

        presaleClaimed[msg.sender] = true;
        totalPresaleLocked = totalPresaleLocked.sub(fraudInDubai);
        emit WithdrawDeposit(msg.sender, fraudInDubai);
    }

    function withdraw(uint256 _amount) public {
        require(_amount > 0, "Invalid amount");
        uint256 currentTimestamp = block.timestamp;
        UserInfo storage user = userInfo[msg.sender];
        require(user.lockEndedTimestamp <= currentTimestamp || emergencyMode == true, "Still locked");
        require(user.amount >= _amount, "Not enough tokens");

        uint256 currentEpoch = fraud.getCurrentEpoch();
        uint256 epochsElapsed = currentEpoch.sub(user.rebaseEpoch);
        uint256 amountToMint = _amount;
        if (epochsElapsed > 10) {
            uint256 rebaseFactor = 1 ether;  
            uint256 epochRebased = epochsElapsed.sub(10);
            for (uint256 i = 0; i < epochRebased; i++) {
                rebaseFactor = rebaseFactor.mul(900).div(1000); 
            }
            amountToMint = user.amount.mul(rebaseFactor).div(1 ether);
        }

        user.amount = user.amount.sub(_amount);
        totalStaked = totalStaked.sub(_amount);
        fraud.mint(address(msg.sender), amountToMint);

        emit Withdraw(msg.sender, _amount);
    }

    function getCurrentStake(address _user) external view returns(uint256){
        UserInfo storage user = userInfo[_user];

        uint256 currentEpoch = fraud.getCurrentEpoch();
        uint256 epochsElapsed = currentEpoch.sub(user.rebaseEpoch);
        uint256 amountToMint = user.amount;

        if (epochsElapsed > 10) {
            uint256 rebaseFactor = 1 ether;  
            uint256 epochRebased = epochsElapsed.sub(10);
            for (uint256 i = 0; i < epochRebased; i++) {
                rebaseFactor = rebaseFactor.mul(900).div(1000); 
            }
            amountToMint = user.amount.mul(rebaseFactor).div(1 ether);
        }
        return amountToMint;
    }

    function setPresaleContract(IPrivatePresale _privatePresale) external onlyOwner {
        privatePresale = _privatePresale;
    }

    function setTotalPresaleLocked() external onlyOwner {
        totalPresaleLocked = privatePresale.getLockedInDubai();
    }

    function dubaiTVL() external view returns (uint256) {
        return totalStaked.add(totalPresaleLocked);
    }

    function setLockDuration(uint256 _lockDuration) external onlyOwner {
        lockDuration = _lockDuration;
    }

    function toggleEmergency() external onlyOwner {
        emergencyMode = !emergencyMode;
    }

    modifier onlyPresale() {
        require(msg.sender == address(privatePresale), "Not PrivatePresale");
        _;
    }
}
