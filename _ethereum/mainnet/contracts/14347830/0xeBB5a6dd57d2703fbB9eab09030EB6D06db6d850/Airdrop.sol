// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract Airdrop is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    mapping(address => uint256) public withdrawAmounts;
    mapping(address => uint256) public withdrawnAmounts;
    address[] public withdrawnAddresses;

    address public airdropWallet;

    IERC20 public paraToken;

    bool public withdrawEnabled = false;

    event Withdrawn(
        address indexed to,
        uint256 indexed amount
    );

    constructor(
        IERC20 _paraToken,
        address _airdropWallet
    ) {
        require(address(_paraToken) != address(0), "Para address should not be zero address");
        require(_airdropWallet != address(0), "Airdrop address should not be zero address");

        paraToken = _paraToken;
        airdropWallet = _airdropWallet;
    }

    function airdropArray(address[] calldata newHolders, uint256[] calldata amounts) external onlyOwner {
        uint256 iterator = 0;

        require(newHolders.length == amounts.length, "Must be the same length");

        while(iterator < newHolders.length) {
            withdrawAmounts[newHolders[iterator]] = amounts[iterator] * 10**18;
            iterator += 1;
        }
    }

    function withdraw() external nonReentrant {
        require(withdrawEnabled == true, "Withdraw Para token is not available yet");
        require(withdrawAmounts[msg.sender] > 0, "Withdraw: Sorry, there is no new Para token for your wallet address");

        uint256 withdrawAmount = withdrawAmounts[msg.sender];

        paraToken.safeTransferFrom(airdropWallet, msg.sender, withdrawAmount);

	    withdrawAmounts[msg.sender] = withdrawAmounts[msg.sender].sub(withdrawAmount);
        withdrawnAmounts[msg.sender] = withdrawAmount;
        withdrawnAddresses.push(msg.sender);

        emit Withdrawn(msg.sender, withdrawAmount);
    }

    function setWithdrawEnabled(bool _enabled) public onlyOwner {
        withdrawEnabled = _enabled;
    }

    function getNumberOfWithdrawnPeople() public view returns (uint256) {
        return withdrawnAddresses.length;
    }

    function updateParaToken(IERC20 _paraToken) external onlyOwner {
        require(address(_paraToken) != address(0), "Para token address should not be zero address");
        paraToken = _paraToken;
    }

    function updateAirdropWallet(address newAirdropWallet) external onlyOwner {
        require(newAirdropWallet != address(0), "Airdrop Wallet address should not be zero address");
        airdropWallet = newAirdropWallet;
    }
}
