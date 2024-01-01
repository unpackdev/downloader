// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Enable ABI encoder v2
pragma abicoder v2;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract OnePay is Initializable, OwnableUpgradeable {

    event Pay(address indexed from, address indexed to, uint amount, uint fee, string token, address targetContract, string note);
    event ErrorNotEnoughAllowanceAmount(uint indexed _allowedAmount, uint indexed _needAmount);

    struct TokenAddress {
        string _token;
        address _address;
    }

    struct PayItem {
        uint timestamp;
        uint amount;
        uint fee;
        string token;
        string note;
        address sender;
    }

    mapping(address => PayItem[]) payHistory;

    string[] tokenNames;
    mapping(string => address) supportTokens;

    address feeReceiver;

    // 1% => set feeRate: 1 * 100 = 100
    // 0.5% => set feeRate: 0.5 * 100 = 50
    // 0.05% => set feeRate: 0.05 * 100 = 5
    uint feeRate;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint _feeRate, address feeReceiveAddress, TokenAddress[] memory tokens) public initializer {
        __Ownable_init();
        feeRate = _feeRate;
        feeReceiver = feeReceiveAddress;
        for (uint i = 0; i < tokens.length; i++) {
            setTokenContract(tokens[i]._token, tokens[i]._address);
        }
    }

    function setTokenContract(string memory token, address _contract) public onlyOwner {
        require(supportTokens[token] == address(0), "Token had been added");
        tokenNames.push(token);
        supportTokens[token] = _contract;
    }

    function removeTokenContract(string memory token, address _contract) public onlyOwner {
        require(_contract != address(0) && supportTokens[token] == _contract, "Invalid token");
        // Check exist to remove from supportTokens
        int foundIndex = - 1;
        for (uint i = 0; i < tokenNames.length; i++) {
            if (keccak256(abi.encodePacked(tokenNames[i])) == keccak256(abi.encodePacked(token))) {
                foundIndex = int(i);
                break;
            }
        }
        require(foundIndex != - 1, "Token not found");
        // Remove
        delete supportTokens[token];
        tokenNames[uint(foundIndex)] = tokenNames[tokenNames.length - 1];
        tokenNames.pop();
    }

    function setFeeReceiverAddress(address _address) public onlyOwner {
        require(_address != address(0), "Invalid address");
        feeReceiver = _address;
    }

    function getFeeReceiverAddress() public view returns (address) {
        return feeReceiver;
    }

    function setFeeRate(uint _feeRate) public onlyOwner {
        require(_feeRate != feeRate, "Invalid value");
        feeRate = _feeRate;
    }

    function getFeeRate() public view returns (uint) {
        return feeRate;
    }

    function getSupportTokens() public view returns (TokenAddress[] memory) {
        TokenAddress[] memory results = new TokenAddress[](tokenNames.length);

        for (uint i = 0; i < tokenNames.length; i++) {
            address tokenAddress = supportTokens[tokenNames[i]];
            results[i] = TokenAddress({_address : tokenAddress, _token : tokenNames[i]});
        }
        return results;
    }

    function getTokenAddress(string memory _name) external view returns (address) {
        return supportTokens[_name];
    }

    function getPayHistory(address payer, uint fromIndex, uint length) public view returns (PayItem[] memory) {
        require(payHistory[payer].length > 0, "Invalid payer");
        require(fromIndex >= 0 && length > 0 && length <= 100, "Invalid value");

        // Check if length of history is less than request length, then set request length as history length minus from
        PayItem[] memory _payerHistory = payHistory[payer];
        if (fromIndex + length >= _payerHistory.length) {
            length = _payerHistory.length - fromIndex;
        }
        PayItem[] memory history = new PayItem[](length);
        for (uint i = 0; i < (length); i++) {
            uint index = i + fromIndex;
            history[i] = _payerHistory[index];
        }

        return history;
    }

    function getPayHistoryCount(address payer) public view returns (uint) {
        return payHistory[payer].length;
    }

    function _1PayNetwork(uint amount, address recipient, string memory tokenName, string memory note) external {
        require(amount > 0, "Invalid amount");
        require(recipient != address(0) && recipient != msg.sender, "Invalid recipient");
        require(feeReceiver != address(0) && msg.sender != address(0), "Invalid request");
        address tokenContractInfo = supportTokens[tokenName];
        require(tokenContractInfo != address(0), "This token is not support");

        IERC20 targetContract = IERC20(tokenContractInfo);

        require(targetContract.balanceOf(msg.sender) >= amount, "Not enough balance");

        uint feeAmount = (amount * feeRate) / (100 * 100);
        uint sendAmount = amount - feeAmount;

        // Check allowance
        uint256 allowedAmount = targetContract.allowance(msg.sender, address(this));
        require(allowedAmount >= amount, "Allowance not enough");

        // Get fee
        (bool feeResult) = targetContract.transferFrom(msg.sender, feeReceiver, feeAmount);
        require(feeResult, "Failed to get fee.");

        // Make transfer
        (bool paymentResult) = targetContract.transferFrom(msg.sender, recipient, sendAmount);
        require(paymentResult, "Failed to transfer to recipient.");

        // Save history
         payHistory[recipient].push(PayItem({ timestamp: block.timestamp, amount: amount, fee: feeAmount, token: tokenName, note: note, sender: msg.sender }));

        emit Pay(msg.sender, recipient, amount, feeAmount, tokenName, tokenContractInfo, note);
    }
}
