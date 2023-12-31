// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

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
  ____  _   _ ____  _____   ____  ____  ___ ____ ___ _   _  ____ 
 |  _ \| | | |  _ \| ____| | __ )|  _ \|_ _| __ )_ _| \ | |/ ___|
 | |_) | | | | |_) |  _|   |  _ \| |_) || ||  _ \| ||  \| | |  _ 
 |  __/| |_| |  _ <| |___  | |_) |  _ < | || |_) | || |\  | |_| |
 |_|    \___/|_| \_\_____| |____/|_| \_\___|____/___|_| \_|\____|
                                                                 
  Twitter: https://twitter.com/fraudeth_gg
  Telegram: http://t.me/fraudportal
  Website: https://fraudeth.gg
  Docs: https://docs.fraudeth.gg

*/

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IFraudToken.sol";
import "./IBribeToken.sol";

contract PureBribing is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    // FRAUD
    IFraudToken public fraud;
    // Bribe
    IBribeToken public bribe;

    struct User {
        address addr;
        uint256 amount;
        uint256 lastDeposit;
        uint256 totalEarned;
    }

    uint256 public keeperFee  = 0.001 ether;
    uint256 public lastDistribution;
    address public keeper;

    bool public emergencyMode = false;

    mapping(address => User) public users;

    User[5] public leaderboard;

    event FeeWithdrawn(address indexed user, uint256 amount);

    constructor(IBribeToken _bribe, IFraudToken _fraud) Ownable() ReentrancyGuard() {
        bribe = _bribe;
        fraud = _fraud;
    }

    function deposit(uint256 _amount) public payable nonReentrant {
        require(msg.value >= keeperFee, "Not enough ETH to pay keeper fees");
        require(_amount <= bribe.balanceOf(msg.sender), "Not enough bribe tokens");
        require(emergencyMode == false, "Contract is in emergency mode, deposits not allowed");
        bribe.burn(msg.sender, _amount);

        if (lastDistribution > users[msg.sender].lastDeposit) {
            users[msg.sender].amount = 0;
        }

        users[msg.sender].amount = users[msg.sender].amount.add(_amount);
        users[msg.sender].addr = msg.sender;
        users[msg.sender].lastDeposit = block.timestamp;

        for (uint256 i = 0; i < 5; i++) {
            if (users[msg.sender].amount > leaderboard[i].amount) {
                for (uint256 j = 4; j > i; j--) {
                    leaderboard[j] = leaderboard[j-1];
                }
                leaderboard[i] = users[msg.sender];
                return;
            }
        }
    }

    function distributeFraud() public {
        require(msg.sender == keeper, "Only keeper can call this function");
        require(emergencyMode == false, "Contract is in emergency mode, distribution not allowed");
        uint256 amount = fraud.balanceOf(address(this));
        require(amount > 0, "No fraud tokens to distribute");
        uint256 amountPerUser = amount.div(5);
        for (uint256 i = 0; i < 5; i++) {
            require(fraud.transfer(leaderboard[i].addr, amountPerUser), "Transfer failed");
            leaderboard[i].totalEarned = leaderboard[i].totalEarned.add(amountPerUser);
        }
        // reset leaderboard
        for (uint256 i = 0; i < 5; i++) {
            leaderboard[i].amount = 0;
        }
        lastDistribution = block.timestamp;
    }

    function setKeeperFee(uint256 _fee) public onlyOwner {
        keeperFee = _fee;
    }

    function setKeeper(address _keeper) public onlyOwner {
        keeper = _keeper;
    }

    function withdrawFee() public onlyOwner {
        uint256 ethBalance = address(this).balance;
        payable(msg.sender).transfer(ethBalance);
        emit FeeWithdrawn(msg.sender, ethBalance);
    }

    function getUserAmount(address _user) public view returns (uint256) {
        return users[_user].amount;
    }
    function toggleEmergency() external onlyOwner {
        emergencyMode = !emergencyMode;
    }

    // Rescue tokens
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        require(to != address(0), "Rescue to the zero address");
        require(token != address(0), "Rescue of the zero address");
        
        // transfer to
        SafeERC20.safeTransfer(IERC20(token),to, amount);
    }
    receive() external payable {}
}
