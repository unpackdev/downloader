// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./ERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract GrumpyCatBridge is Context, ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using Address for address;

    mapping(address => bool) public claimed;
    mapping(address => uint256) public depositedAmount;
    mapping(address => uint256) public claimedAmount;

    ERC20 public GrumpyCat;
    ERC20 public newContract;

    bool public acceptingDeposits;

    event Deposit(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event UnbridgedWithdrawal(uint256 amount);

    constructor() ERC20 ("GrumpyCat Bridge", "GrumpyCat Bridge") payable Ownable(msg.sender) {
        GrumpyCat = ERC20(0xd8E2D95C8614F28169757cD6445a71c291dEc5bF);
        acceptingDeposits = true;
    }

    receive() external payable {

    }

    function setNewContract(address _newContractAddress) external onlyOwner {
        newContract = ERC20(_newContractAddress);
    }

    function deposit() public nonReentrant {
        require(acceptingDeposits, "Deposits are no longer accepted");
        uint256 _amount = GrumpyCat.balanceOf(msg.sender);
        require(depositedAmount[msg.sender] == 0, "Tokens already deposited");
        require(_amount > 0, "No tokens to deposit");

        GrumpyCat.safeTransferFrom(msg.sender, address(this), _amount);
        depositedAmount[msg.sender] = _amount;

        emit Deposit(msg.sender, _amount);
    }

    function claim() public nonReentrant {
        require(!claimed[msg.sender], "Tokens already claimed");
        require(address(newContract) != address(0), "New contract not set");

        uint256 _amount = depositedAmount[msg.sender];
        claimed[msg.sender] = true;
        claimedAmount[msg.sender] = _amount;

        newContract.safeTransfer(msg.sender, _amount);

        emit Claim(msg.sender, _amount);
    }

    function withdrawUnbridgedTokens() external onlyOwner {
        uint256 _amount = newContract.balanceOf(address(this));
        acceptingDeposits = false;

        newContract.safeTransfer(owner(), _amount);

        emit UnbridgedWithdrawal(_amount);
    }

    function toggleDeposits() external onlyOwner {
        acceptingDeposits = !acceptingDeposits;
    }
}
