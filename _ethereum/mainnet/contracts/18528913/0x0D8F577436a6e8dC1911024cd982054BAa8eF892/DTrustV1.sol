// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

/// @title ERC-20 interface
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

/// @title DTRUST contract for managing dtrusts
/// @notice This contract allows for the creation and management of dtrusts
/// @dev Extends ReentrancyGuard from OpenZeppelin to prevent reentrancy attacks
contract DTRUST is ReentrancyGuard {
    using SafeMath for uint256;

    // State variables
    address settlor;
    address factoryAddress;
    address[] trustees;
    address[] beneficiaries;
    address[] tokens;
    string name;
    bool public isRevoked = false;
    
    // Mappings
    mapping(address => bool) trusteesLookup;
    mapping(address => bool) beneficiariesLookup;
    mapping(address => bool) public revokeAddressLookup;
    mapping(address => bool) tokenLookup;

    // Balances
    uint256 etherBalance = 0;
    uint256 public startFeeTime;
    uint256 public dateCreated;

    // Events
    event Paid(address indexed token, address indexed beneficiary, uint256 amount);
    event Revoked();
    event RemoveRevokableAddress(address indexed revokableAddress);
    event ReceivedEther(address indexed sender, uint256 amount);
    event DepositedEther(address indexed sender, uint256 amount);
    event DepositedToken(address indexed token, address indexed sender, uint256 amount);

    // Modifiers
    modifier isTrustee() {
        require(trusteesLookup[msg.sender], "Only a trustee can perform this action");
        _;
    }

    modifier isActive() {
        require(!isRevoked, "The contract has been revoked");
        _;
    }

    /// @notice Constructor to create a DTRUST
    /// @param _name Name of the dtrust
    /// @param _settlor Address of the settlor creating the dtrust
    /// @param _factoryAddress Address of the factory contract creating this dtrust
    /// @param _trustees Array of addresses of the trustees
    /// @param _beneficiaries Array of addresses of the beneficiaries
    /// @param _canRevokeAddresses Array of addresses that can revoke the dtrust
    constructor(
        string memory _name,
        address _settlor,
        address _factoryAddress,
        address[] memory _trustees,
        address[] memory _beneficiaries,
        address[] memory _canRevokeAddresses
    ) {
        name = _name;
        settlor = _settlor;
        factoryAddress = _factoryAddress;
        addTrustees(_trustees);
        addBeneficiaries(_beneficiaries);
        addRevokableAddresses(_canRevokeAddresses);
        dateCreated = block.timestamp;
        startFeeTime = block.timestamp;
    }

    /// @notice Fallback function to receive Ether
    receive() external payable {
        etherBalance += msg.value;
        emit DepositedEther(msg.sender, msg.value);
    }

    /// @notice Internal function to add beneficiaries to the dtrust
    /// @param _beneficiaries Array of beneficiary addresses
    function addBeneficiaries(address[] memory _beneficiaries) internal {
        for (uint i = 0; i < _beneficiaries.length; i++) {
            beneficiariesLookup[_beneficiaries[i]] = true;
            beneficiaries.push(_beneficiaries[i]);
        }
    }

    /// @notice Internal function to add addresses with revocation rights
    /// @param _canRevokeAddresses Array of addresses with permission to revoke the dtrust
    function addRevokableAddresses(address[] memory _canRevokeAddresses) internal {
        for(uint i = 0; i < _canRevokeAddresses.length; i++) {
            require(trusteesLookup[_canRevokeAddresses[i]] || _canRevokeAddresses[i] == settlor, "Address must be a trustee or the settlor");
            revokeAddressLookup[_canRevokeAddresses[i]] = true;
        }
    }

    /// @notice Internal function to add trustees to the dtrust
    /// @param _trustees Array of trustee addresses
    function addTrustees(address[] memory _trustees) internal {
        for (uint i = 0; i < _trustees.length; i++) {
            trusteesLookup[_trustees[i]] = true;
            trustees.push(_trustees[i]);
        }
    }

    /// @notice Allows a trustee to deposit Ether into the dtrust
    /// @dev Emits a DepositedEther event upon success
    function depositEth() external payable isActive { 
        require(msg.value > 0, "Deposit amount should be greater than 0");
        etherBalance += msg.value;
        emit DepositedEther(msg.sender, msg.value);
    }

    /// @notice Allows a trustee to deposit ERC-20 tokens into the dtrust
    /// @param token Address of the ERC-20 token
    /// @param amount Amount of the ERC-20 tokens to deposit
    /// @dev Emits a DepositedToken event upon success
    function depositToken(address token, uint256 amount) external isActive { 
        uint256 allowedAmount = IERC20(token).allowance(msg.sender, address(this));
        require(amount > 0, "Enter an amount greater than 0");
        require(allowedAmount >= amount, "Contract not approved to move this amount of tokens");
        
        if (!tokenLookup[token]) {
            tokenLookup[token] = true;
            tokens.push(token);
        }

        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        emit DepositedToken(token, msg.sender, amount);
    }

    /// @notice Allows trustees to make a payout from the dtrust to a beneficiary
    /// @param _token Address of the ERC-20 token
    /// @param _amount Amount of the ERC-20 tokens to payout
    /// @param _beneficiary Address of the beneficiary to receive the payout
    /// @dev Emits a Paid event upon success
    function payout(
        address _token,
        uint256 _amount,
        address _beneficiary
    ) external isTrustee isActive nonReentrant {   
        require(beneficiariesLookup[_beneficiary], "Beneficiary provided is not a beneficiary of this dtrust");
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Not enough balance of the token");
        require(IERC20(_token).transfer(_beneficiary, _amount), "Token transfer failed");
        emit Paid(_token, _beneficiary, _amount);
    }

        /// @notice Revokes the dtrust and performs payouts of remaining balances
    /// @dev Emits a Revoked event upon successful revocation
    function revokeContract() external isActive nonReentrant {
        require(revokeAddressLookup[msg.sender], "You do not have permission to revoke");
        payoutAll(tokens);
        isRevoked = true;
        emit Revoked();
    }

    /// @notice Allows trustees to payout Ether from the dtrust to a beneficiary
    /// @param _ethAmount Amount of Ether to payout
    /// @param _beneficiary Address of the beneficiary to receive the Ether
    /// @dev Emits a Paid event upon success
    function payoutEth(uint256 _ethAmount, address _beneficiary) public isTrustee isActive nonReentrant {
        require(beneficiariesLookup[_beneficiary], "Beneficiary provided is not a beneficiary of this dtrust");
        require(_ethAmount > 0, "Enter Eth amount > 0");
        require(address(this).balance >= _ethAmount, "Not enough Ether to payout");
        address payable user = payable(_beneficiary);
        user.transfer(_ethAmount);
        etherBalance -= _ethAmount;
        emit Paid(address(this), _beneficiary, _ethAmount);
    }

    /// @notice Allows trustees to payout remaining balances after the dtrust has been revoked
    /// @param _tokens Array of ERC-20 token addresses to be paid out
    /// @dev Emits Paid events for each token paid out
    function payoutRemaining(address[] memory _tokens) external isTrustee nonReentrant {
        require(isRevoked, "The dtrust must be revoked before the remaining balance can be paid out");
        payoutAll(_tokens);
    }

    /// @notice Internal function to payout all balances of Ether and tokens to the settlor
    /// @param _tokens Array of ERC-20 token addresses to be paid out
    /// @dev Emits Paid events for each token paid out
    function payoutAll(address[] memory _tokens) internal {
        if(address(this).balance > 0){
            address payable user = payable(settlor);
            user.transfer(address(this).balance);
            etherBalance -= address(this).balance;
            emit Paid(address(this), settlor, address(this).balance);
        }

        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            uint256 amount = IERC20(token).balanceOf(address(this));
            
            if(amount > 0){
                require(IERC20(token).transfer(settlor, amount), "Token transfer failed");
                emit Paid(token, settlor, amount);
            }
        }
    }

    /// @notice Allows an address with revocation rights to remove themselves from the list of revokable addresses
    /// @dev Emits a RemoveRevokableAddress event upon success
    function removeRevokableAddress() external isActive {
        require(revokeAddressLookup[msg.sender], "Address is not revokable");
        revokeAddressLookup[msg.sender] = false;
        emit RemoveRevokableAddress(msg.sender);
    }

    /// @notice Collects an annual fee for the dtrust, payable to the bank wallet
    /// @param _bankWallet Address of the bank wallet where fees are collected
    /// @param _feePercentage Annual fee percentage
    /// @dev Emits a Paid event for fee collection
    function takeAnnualFee(address _bankWallet, uint256 _feePercentage) external isActive nonReentrant {
        require(block.timestamp >= startFeeTime, "Not yet time to collect fee");
        require(msg.sender == factoryAddress, "You must be the control wallet");
        
        uint256 feeFraction = _feePercentage.mul(1e14);

        if(address(this).balance > 0 ){
            uint256 ethFee = address(this).balance.mul(feeFraction).div(1e18);
            payable(_bankWallet).transfer(ethFee);
            etherBalance -= ethFee;
            emit Paid(address(0), _bankWallet, ethFee); // address(0) denotes Ether
        }
        
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 tokenBalance = IERC20(token).balanceOf(address(this));
            if(tokenBalance > 0 ){
                uint256 tokenFee = tokenBalance.mul(feeFraction).div(1e18);
                require(IERC20(token).transfer(_bankWallet, tokenFee), "Token transfer failed");
                emit Paid(token, _bankWallet, tokenFee);
            }
        }

        startFeeTime += 365 days;
    }

    /// @notice Retrieves information about the dtrust
    /// @return name of the dtrust
    /// @return settlor of the dtrust
    /// @return list of trustees
    /// @return list of beneficiaries
    /// @return creation date of the dtrust
    /// @return start time for the next fee collection
    /// @return revocation status of the dtrust
    /// @dev This function is view-only and does not modify state
    function getTrustInfo() isActive public view returns (
        string memory,
        address, 
        address[] memory, 
        address[] memory,
        uint256,
        uint256,
        bool
    ) {
        return (name, settlor, trustees, beneficiaries, dateCreated, startFeeTime, isRevoked);
    }
}
