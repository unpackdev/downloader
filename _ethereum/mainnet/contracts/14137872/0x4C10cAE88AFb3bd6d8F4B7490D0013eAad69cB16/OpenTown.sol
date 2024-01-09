// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract OpenTown is ERC20("$OPENTOWN", "$OT"), Ownable {
    uint256 private constant MAX_SUPPLY = 1000000000 ether;
    uint256 private constant RESERVED_SUPPLY = 400000000 ether;

    address payable public communityWallet;
    mapping(address => bool) public otpContracts;
    bool private isReserveMinted;

    event RewardPaid(address indexed by, address indexed user, uint256 amount);

    modifier onlyOTPContract() {
        require(
            otpContracts[msg.sender],
            "Can only be called by Open Town Project contract"
        );
        _;
    }

    function setOTPContract(address otpContract, bool isAllowed)
        external
        onlyOwner
    {
        otpContracts[otpContract] = isAllowed;
    }

    function getReward(address to, uint256 amount) external onlyOTPContract {
        if (isReserveMinted) {
            require(
                totalSupply() + amount <= MAX_SUPPLY,
                "Max supply exceeded"
            );
        } else {
            require(
                totalSupply() + RESERVED_SUPPLY + amount <= MAX_SUPPLY,
                "Max supply exceeded"
            );
        }

        _mint(to, amount);
        emit RewardPaid(msg.sender, to, amount);
    }

    function setCommunityWallet(address payable community) external onlyOwner {
        communityWallet = community;
    }

    function mintReserve() external onlyOwner {
        require(!isReserveMinted, "Reserve is already minted");
        require(
            communityWallet != address(0),
            "Community wallet address not set"
        );

        _mint(msg.sender, RESERVED_SUPPLY / 2);
        _mint(communityWallet, RESERVED_SUPPLY / 2);
        isReserveMinted = true;
    }

    function burn(address from, uint256 amount) external onlyOTPContract {
        _burn(from, amount);
    }

    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }
}
