/*
Simple Prepaid Subscription Management Contract using ERC20
2022 Platinum Labs
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@&&&%%%%%%%%%%%###########((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@&&&&&&&&&&&&%%%%%%%%%%%%########@@@@@@@@@@@@@@@(((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@&&&&&&&&&&&%%%%%%%%%%%%%%###&@@@@@@@&&&&@@@@@@@@((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@&&&&&&&&&&&%%@@@@@@@@@@@@@@@@@@@&&&&&&&&&@@@@@@@@((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@&&&&&&&&&&&&(((((((((((((((((@@@@@@@@@@@@@@@@@@
@@@@@@@@@&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@@@@@&&&&&&&&&&&&&@(((((((((((((((((@@@@@@@@@@@@@@
@@@@@@@@&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@@@@@@@@@@@&&&&&&&&&&&&@@@@(((((((((((((((@@@@@@@@@@@
@@@@@@@@&&&&&&&@@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@@@@@@@@@@@@@@@&&&&&&%%%%%%%@@@@(((((((((((((((@@@@@@@@
@@@@@@@@&&&&&&&@@@@@@@@@@@@@@&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@&&&&%%%%%%%%@@@@@(((((((((((((((@@@@@
@@@@@@@@@&&&&&&&@@@@@@@&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&%%%%%%%#@@@@(((((((((((((((@@@
@@@@@@@@@@&&&&&&&@@@@&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&########@@@@((((((((((((((@@
@@@@@@@@@@@&&&&&&&&@@@@&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%&########@@@@@@@((((((((((((((@
@@@@@@@@@@@@@@&&&&&&&@@@@@&&&&&&%%%%%%&@@@@@@@@@@@@@@@@@@@@@@@%%%%%########@@@@@@@@@@@((((((((((((((
@@@@@@@@@@@@@@@@&&&&&&&&@@@@%%%%%%%%%%%%%@@@@@@@@@@@@@@@@@@@#############@@@@@@@@@@@@@((((((((((((((
@@@@@@@@@@@@@@@@@@@&&&&&&&&@@@@%%%%%%%%%%%%@@@@@@@@@@@@@@%#########(((@@@@@@@@@@@@@@@(((((((((((((((
@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&@%%%##########@@@@@@@@@#####((((((((@@@@@@@@@@@@@@@(((((((((((((((((
@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&##########@@@@@((((((((((((@@@@@@@@@@@@@@%(((((((((((((((((((@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&%((((((((((((((((@@@@@@@@@@((((((((((((((((((((((((@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&%%%%%%%%%%%%%##########((((((((((((((((((((((((@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&%%%%%%%%%%%%%##########((((((((((((((((((&@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&%%%%%%%%%%%##########((((((((((((((@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function mint(address to, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract PLTNMPaymentProcessor is Ownable {
    IERC20 public token;
    uint256 public cyclePrice;
    uint256 public cycleIntervalUntilValidForRenewal;
    uint256 public renewableTimeBeforeExpiry;
    address private pltnmDepositoryWallet;

    string public productName;

    mapping(address => uint256) public cycleRenewableTimeStamp;
    mapping(address => uint256) public expiryForAddress;

    constructor() {
        productName = "PLATINUM TOOLS EXTENSION";
        cyclePrice = 40 * 10**18;
        cycleIntervalUntilValidForRenewal = 5 days;
        renewableTimeBeforeExpiry = 2 days;
        pltnmDepositoryWallet = msg.sender;
    }

    function setProductName(string memory _name) external onlyOwner {
        productName = _name;
    }

    function setTokenAddress(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function setDepositoryWallet(address _address) external onlyOwner {
        pltnmDepositoryWallet = _address;
    }

    function setCyclePrice(uint256 _price) external onlyOwner {
        cyclePrice = _price;
    }

    function setCycleInterVal(uint256 _interval) external onlyOwner {
        cycleIntervalUntilValidForRenewal = _interval;
    }

    function setTimeFromRenewableToExpiry(uint256 _renewableTimeToExpiry)
        external
        onlyOwner
    {
        renewableTimeBeforeExpiry = _renewableTimeToExpiry;
    }

    function getContractTotalSupply() external view returns (uint256) {
        return token.totalSupply();
    }

    function purchaseCycle() external {
        require(
            token.allowance(msg.sender, address(this)) > cyclePrice,
            "You have not approved the required amount on the token contract"
        );
        require(
            block.timestamp > cycleRenewableTimeStamp[msg.sender],
            "You have not yet reached renewal time"
        );
        require(
            token.balanceOf(msg.sender) > cyclePrice,
            "You do not have enough $PLTNM"
        );

        //burn the token
        token.transferFrom(msg.sender, pltnmDepositoryWallet, cyclePrice);

        if (expiryForAddress[msg.sender] < block.timestamp) {
            expiryForAddress[msg.sender] = block.timestamp;
        }

        cycleRenewableTimeStamp[
            msg.sender
        ] += cycleIntervalUntilValidForRenewal;
        expiryForAddress[msg.sender] =
            cycleRenewableTimeStamp[msg.sender] +
            renewableTimeBeforeExpiry;
    }

    //for third party control
    function purchaseCycleFor(address _address) external {
        require(
            token.allowance(_address, address(this)) > cyclePrice,
            "Address has not approved the required amount on the token contract"
        );
        require(
            block.timestamp > cycleRenewableTimeStamp[_address],
            "Address has not yet reached renewal time"
        );
        require(
            token.balanceOf(_address) > cyclePrice,
            "Address does not have enough $PLTNM"
        );

        //burn the token
        token.transferFrom(_address, pltnmDepositoryWallet, cyclePrice);

        if (expiryForAddress[_address] < block.timestamp) {
            expiryForAddress[_address] = block.timestamp;
        }

        cycleRenewableTimeStamp[_address] += cycleIntervalUntilValidForRenewal;
        expiryForAddress[_address] =
            cycleRenewableTimeStamp[_address] +
            renewableTimeBeforeExpiry;
    }
}
