
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract CAC is Ownable {

    using SafeERC20 for IERC20;
    IERC20 public token;

    struct User {
        string account;
        address user;
        bool isCanDeposit;
    }

    mapping(string => User) public users;
    mapping(address => string) public AddressToAccount;


    event DepositUSDT(address indexed user, string account, uint256 value);
    event SentUSDT(address indexed to, uint256 value);
    event ChangeStatus(string indexed account, bool isCanDeposit);
    event NewUser(string indexed account, address add);


    constructor( address ownerAddress, address tokenAddress) public {
        // 公司帳號
        string memory companyAccount = "cactop";

        // 初始化Owner
        User memory user = User({
            account: companyAccount,
            user: ownerAddress,
            isCanDeposit: true
        });
        users[companyAccount] = user;
        AddressToAccount[ownerAddress] = companyAccount;
        // 初始化token
        token = IERC20(tokenAddress);
    }

    // 入金
    function depositUSDT(string calldata account, uint256 value) external {
        require(bytes(account).length >= 4 && bytes(account).length <= 10, "The length of the account should be between 4 and 10" );
        require(isCanRegistration(account, msg.sender) || users[account].user == msg.sender , "your account and address is not match.");
        require((value%100) == 0, "deposit usdt need Multiples of 100.");
        require(token.balanceOf(msg.sender) >= value, "usdt balance is not enough.");
        require(token.allowance(msg.sender, address(this)) >= value, "token allowance is not enough.");

        // account未註冊 && address未註冊
        if(isCanRegistration(account, msg.sender)) {
             User memory user = User({
                account: account,
                user: msg.sender,
                isCanDeposit: true
            });
            users[account] = user;
            AddressToAccount[msg.sender] = account;
        }

        require(users[account].isCanDeposit == true, "this account can't deposit");
        token.safeTransferFrom(msg.sender, address(this), value);
        emit DepositUSDT(msg.sender, account, value);
    }

    // 出金
    function sendUSDT(string calldata account, uint256 value) external onlyOwner {
        require(isAccountExists(account), "The account does not exist");
        token.safeTransfer(users[account].user, value);
        emit SentUSDT(users[account].user, value);
    }

    // 更改isCanDeposit狀態
    function changeCanDepositStatus(string calldata account, bool isCanDeposit) external onlyOwner {
        require(users[account].isCanDeposit != isCanDeposit, "Already in this isCanDeposit states");
        users[account].isCanDeposit = isCanDeposit;
        emit ChangeStatus(account, isCanDeposit);
    } 

    // 建立新user
    function newUser(string calldata account, address add) external onlyOwner {
        // 初始化Owner
        User memory user = User({
            account: account,
            user: add,
            isCanDeposit: true
        });
        users[account] = user;
        AddressToAccount[add] = account;
    }
    function updateUserAddress(string calldata account,  address userAddress) external onlyOwner {
        require(isAccountExists(account), "The account does not exist");
        require(users[account].user !=userAddress , "The account address is exist");
        delete AddressToAccount[users[account].user]; 
        users[account].user = userAddress;
        AddressToAccount[userAddress] = account;
    }
    // ID存在
    function isAccountExists(string calldata account) private view returns (bool) {
        return users[account].user != address(0);
    }

    // ID存在，且Address匹配
    function isUserAddressMatchs(string calldata account, address user) private view returns (bool) {
        return (isAccountExists(account) &&  users[account].user != user);
    }

    // IsCanRegistration
    function isCanRegistration(string calldata account, address user) private view returns (bool) {
        return users[account].user == address(0) && bytes(AddressToAccount[msg.sender]).length == 0;
    }
}
