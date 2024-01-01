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

    function transferFrom(address sender, address recipient, uint256 amount) external;


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

    function initialize(uint _feeRate, address feeReceiveAddress, TokenAddress[] calldata tokens) public initializer {
        __Ownable_init();
        feeRate = _feeRate;
        feeReceiver = feeReceiveAddress;
        for (uint i = 0; i < tokens.length; i++) {
            setTokenContract(tokens[i]._token, tokens[i]._address);
        }
    }

    function setTokenContract(string calldata token, address _contract) public onlyOwner {
        require(supportTokens[token] == address(0), "Token had been added");
        tokenNames.push(token);
        supportTokens[token] = _contract;
    }

    function updateTokenContract(string calldata token, address contractAddress) external onlyOwner {
        require(supportTokens[token] != contractAddress && supportTokens[token] != address(0) && contractAddress != address(0));
        supportTokens[token] = contractAddress;
    }

    function removeTokenContract(string calldata token, address _contract) public onlyOwner {
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

    error InvalidRequest(address caller);
    error InvalidAmount(address caller, uint amount);
    error TokenNotSupport(address caller, string tokenName);
    error FailedToTransfer(address caller, address recipient);
    error InvalidBalanceOrAllowance(address caller, uint amount);

    function _1PayNetwork(uint amount, address recipient, string calldata tokenName, string memory note) external {
        if (amount <= 0) revert InvalidAmount(msg.sender, amount);
        if (!(msg.sender != address(0) && feeReceiver != address(0)
        && recipient != address(0) && recipient != msg.sender)) revert InvalidRequest(msg.sender);
        address tokenContractInfo = supportTokens[tokenName];
        if (tokenContractInfo == address(0)) revert TokenNotSupport(msg.sender, tokenName);
        // Check allowance
        IERC20 targetContract = IERC20(tokenContractInfo);
        uint feeAmount = (amount * feeRate) / (100 * 100);
        uint sendAmount = amount - feeAmount;
        // Transfer
        targetContract.transferFrom(msg.sender, recipient, sendAmount);
        targetContract.transferFrom(msg.sender, feeReceiver, feeAmount);
        // Save history
        emit Pay(msg.sender, recipient, amount, feeAmount, tokenName, tokenContractInfo, note);
    }
}
