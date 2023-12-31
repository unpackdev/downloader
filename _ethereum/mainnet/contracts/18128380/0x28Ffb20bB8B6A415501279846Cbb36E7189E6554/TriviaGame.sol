// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract TriviaGame {
    using SafeMath for uint256;
    IERC20 token;
    address public owner;
    address public gameMaster;
    bool public playingActive = true;
    uint public currentGame = 0;
    uint public gameBet = 0;
    bool public gameActive = false;
    uint public gamePot = 0;
    address public revenueWallet;
    uint256 public revenueBps = 800;
    uint256 public burnBps = 200;

    event NewGame(uint id, address[] players, uint pot);
    event Win(address player, uint256 amount);

    constructor() {
        owner = msg.sender;
        revenueWallet = address(0x57938dF55F34b8bA723ec8af9Bec47e28a889744);
        gameMaster = address(0x93C92290b408f9BAe71BF0DB3D3Fb43f919015fD);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier onlyOwnerOrGameMaster() {
        require(msg.sender == gameMaster || msg.sender == owner, "not authorized");
        _;
    }

    receive() external payable {
    }

    
    function start(address[] memory _players, uint _bet) public onlyOwnerOrGameMaster
    {
        require(playingActive == true,"Maintenance in progress");
        require(gameActive == false,"A previous game is still running");
        require(_players.length > 1,"Not enough players");

        uint bet = _bet * 10** 9;
        for (uint16 i = 0; i < _players.length; i++) {
            require(token.allowance(_players[i], address(this)) >= bet ,"Not enough allowance");
            bool isSent = token.transferFrom(_players[i], address(this), bet);
            require(isSent, "Funds transfer failed");
        }

        gamePot = _players.length * bet;
        gameBet = bet;
        gameActive = true;

        emit NewGame(currentGame,_players,gamePot);
    }

    function end(address winner) public onlyOwnerOrGameMaster
    {
        require(playingActive == true,"Maintenance in progress");
        require(gameActive == true,"No game running");
        
        uint256 burnShare = gamePot * burnBps / 10_000;
        uint256 approxRevenueShare = gamePot * revenueBps / 10_000;

        uint256 totalWinnings = gamePot - burnShare - approxRevenueShare;
 
        bool isSent = token.transfer(winner, totalWinnings);
        require(isSent, "Funds transfer failed");
        
        token.transfer(address(0x000000000000000000000000000000000000dEaD), burnShare);

        uint256 realRevenueShare = gamePot - totalWinnings - burnShare;
        isSent = token.transfer(revenueWallet, realRevenueShare);
        require(isSent, "Revenue transfer failed");

        currentGame++;
        gameActive = false;

        emit Win(winner,totalWinnings);
    }

    function refund(address[] memory _players, uint _bet) public onlyOwnerOrGameMaster
    {
        require(playingActive == true,"Maintenance in progress");
        require(gameActive == true,"No game running");

        for (uint16 i = 0; i < _players.length; i++) {
            bool isSent = token.transfer(_players[i], _bet);
            require(isSent, "Funds transfer failed");
        }
        
        currentGame++;
        gameActive = false;
    }
    function toggleGame() external onlyOwner() {
        playingActive = !playingActive;
    }
    function updateRevenueWallet(address _wallet) external onlyOwner {
        revenueWallet = _wallet;
    }

    function updateRevenueBps(uint amount) external onlyOwner {
        revenueBps = amount;
    }

    function updateBurnBps(uint amount) external onlyOwner {
        burnBps = amount;
    }

    function setTokenAddress(address payable _tokenAddress) external onlyOwner() {
       token = IERC20(address(_tokenAddress));
    }

    function setGMAddress(address _gameMaster) external onlyOwner() {
       gameMaster = _gameMaster;
    }

    function withdrawStuckETH() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance } ("");
        require(success, "Transfer failed.");
    }

    function withdrawStuckToken() external onlyOwner {
        uint balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


}