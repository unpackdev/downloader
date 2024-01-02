// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

// This contract keeps track of the deposits made by users and sends those to the sandwich contract so they can recover those when necessary
contract DepositTokens {
    event DepositMade(address indexed user, address indexed token, uint256 indexed amount, uint256 timestamp);
    event Extract(address indexed user, address indexed token, uint256 indexed amount, uint256 timestamp);

    struct Deposit {
        address token;
        uint256 amount;
    }

    // User => token => amount
    mapping (address => mapping(address => uint256)) public deposits;
    // User address => tokes deposited for the `deposits` variable this will contain duplicate items to save on gas, you can remove duplicates in the frontend only used for view functions
    mapping (address => address[]) public tokensDeposited;
    address public owner;
    address public sandwichContract;

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(address _sandwichContract) {
        sandwichContract = _sandwichContract;
        owner = msg.sender;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changeSandwichContract(address _newSandwichContract) external onlyOwner {
        sandwichContract = _newSandwichContract;
    }

    function depositMultiple(address[] memory _tokens, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            uint256 amount = _amounts[i];
            deposits[msg.sender][token] += amount;
            IERC20(token).transferFrom(msg.sender, sandwichContract, amount);
            tokensDeposited[msg.sender].push(token);

            emit DepositMade(msg.sender, token, amount, block.timestamp);
        }
    }

    // The tokens and amounts must be sorted meaning _tokens[i] => _amounts[i]
    // The tokens must be moved to this contract first in order to receive the withdraw (probably using a wallet signature to signal intent)
    function withdraw(address[] memory _tokens, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            uint256 amount = _amounts[i];
            require(deposits[msg.sender][token] >= amount, "Can't withdraw more than you have");
            deposits[msg.sender][token] -= amount;
            IERC20(token).transfer(msg.sender, amount);

            emit Extract(msg.sender, token, amount, block.timestamp);
        }
    }

    // Returns the tokens the user deposited (may have been withdrawn)
    function getDeposits(address _user) public view returns(address[] memory) {
        return tokensDeposited[_user];
    }
}