/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2020-2021 SCEME SAS
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";
import "./ERC20PresetMinterPauserUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./Blacklistable.sol";

contract EURLToken is 
            Initializable, 
            ERC20PresetMinterPauserUpgradeable, 
            ERC20PermitUpgradeable, 
            Blacklistable, 
            UUPSUpgradeable {
    

    bytes32 public constant ADMIN = keccak256('ADMIN');
    bytes32 public constant MASTER_MINTER = keccak256('MASTER_MINTER');

    mapping(address => uint256) public minterAllowed;

    address private _trustedForwarder;
    address private _feesFaucet;

    uint256 private _txfeeRate;
    uint256 private _gaslessBasefee;

    uint8 constant DECIMALS = 6;
    uint256 constant FEE_RATIO = 10000;

    event Mint(address indexed minter, address indexed to, uint256 amount);
    event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
    event FeeFaucetUpdated(address newFeeFaucet);
    event TxFeeRateUpdated(uint256 newTxFeeRate);
    event GaslessBasefeeUpdated(uint256 newGaslessBasefee);
    event TrustedForwarderUpdated(address newTrustedForwarder);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC20PresetMinterPauser_init("LUGH", "EURL");
        __ERC20Permit_init("LUGH");
        __UUPSUpgradeable_init();
        __Ownable_init();

        _setRoleAdmin(MINTER_ROLE, MASTER_MINTER);
        _setupRole(ADMIN, address(0));
        _setupRole(MASTER_MINTER, address(0));

        _txfeeRate = 0;
        _gaslessBasefee = 0;
    }

    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev Function to update the admin
     * @param newAdmin The address of the admin
     */
    function setAdministrator(address newAdmin) onlyOwner
      public virtual
    {
         revokeRole(ADMIN, getRoleMember(ADMIN, 0));
         revokeRole(PAUSER_ROLE, getRoleMember(PAUSER_ROLE, 0));  
         grantRole(ADMIN, newAdmin);
         grantRole(PAUSER_ROLE, newAdmin);
         updateBlacklister(newAdmin);
    }

    /**
      * @dev Function to update the masterMinter
      * @param newMasterMinter The address of the masterMinter
      */
    function setMasterMinter(address newMasterMinter)
      public virtual
    {
        revokeRole(MASTER_MINTER, getRoleMember(MASTER_MINTER, 0)); 
        grantRole(MASTER_MINTER, newMasterMinter);
    }

    /**
      * @dev Function to update the DEFAULT_ADMIN_ROLE 
      * @param newOwner The address of the owner
      */
    function setOwner(address newOwner)
        public virtual
    { 
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);//_owner
        revokeRole(DEFAULT_ADMIN_ROLE, getRoleMember(DEFAULT_ADMIN_ROLE, 0));
    }
    
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(DEFAULT_ADMIN_ROLE)
        override
    {}

    /**
     * @dev Function to set feesFaucet
     * @param feesFaucet New feesFaucet address
     */
    function setFeeFaucet(address feesFaucet) public onlyRole(ADMIN){
        require(feesFaucet != address(0), "EURL: new feesFaucet can't be address 0");
        _feesFaucet = feesFaucet;
        emit FeeFaucetUpdated(feesFaucet);
    }


    /**
     * @dev Function to update tx fee rate
     * @param newRate The address of the minter
     */
    function updateTxFeeRate(uint256 newRate) public onlyRole(ADMIN){
        require(newRate <= FEE_RATIO, "EURL: new rate too high"); //out of 10000
        _txfeeRate = newRate;
        emit TxFeeRateUpdated(_txfeeRate);
    }

    /**
     * @dev Function to update tx fee rate
     */
    function getTxFeeRate() public view returns(uint256){
        return _txfeeRate;
    }

    /**
     * @dev Function to calculate fees
     * @param txAmount amount of the transaction in eurl
     */
    function calculateTxFee(uint256 txAmount) public view returns(uint256){
        return txAmount * _txfeeRate / FEE_RATIO;
    }

    /**
     * @dev Function to trigger tx fee payment to feesFaucet (internal)
     * @param from The address of the payer
     * @param txAmount amount of the transaction in eurl
     */
    function _payTxFee(address from, uint256 txAmount) internal returns(bool) {
        uint256 txFees = calculateTxFee(txAmount);
        require(balanceOf(from) >= txFees + txAmount, "EURL: tx fees");
        if (_feesFaucet != address(0)){
            _transfer(from, _feesFaucet, txFees); 
        } 
        return true;
    }

    /**
     * @dev Function to update gasless tx basefee 
     * @param newBaseFee new gasless basefee amount
     */
    function updateGaslessBasefee(uint256 newBaseFee) public onlyRole(ADMIN){
        _gaslessBasefee = newBaseFee;
        emit GaslessBasefeeUpdated(newBaseFee);
    }

    /**
     * @dev Function to get gasless basefee
     */
    function getGaslessBasefee() public view returns(uint256){
        return _gaslessBasefee;
    }

    /**
     * @dev Function to trigger gaslessBasefee payment from payer to paymaster
     * Can only be called from trustedForwarder
     * @param payer Address of basefee payer (meta-tx signer)
     * @param paymaster Address of paymester (meta-tx executer)
     */
    function payGaslessBasefee(address payer, address paymaster) external {
        require(isTrustedForwarder(msg.sender), 
                "EURL: only trustedForwarder can process gasless basefee payment");
        require(balanceOf(_msgSender()) >= _gaslessBasefee, 
                "EURL: balance too low, can't pay gasless basefee");
        uint256 feeRate = _txfeeRate;
        _txfeeRate = 0;
        _transfer(payer, paymaster, _gaslessBasefee);
        _txfeeRate = feeRate;
    }


    /**
     * @dev Function to add/update a new minter
     * @param minter The address of the minter
     * @param minterAllowedAmount The minting amount allowed for the minter
     */
    function addMinter(address minter, uint256 minterAllowedAmount)
      public virtual
    {
        minterAllowed[minter] = minterAllowedAmount;
        grantRole(MINTER_ROLE, minter);
    }

    /**
     * @dev Function to remove a minter
     * @param minter The address of the minter to remove
     */
    function removeMinter(address minter)
     public virtual
    {
        minterAllowed[minter] = 0;
        revokeRole(MINTER_ROLE, minter);
    }

    /**
     * @dev Function to update the minting allowance of a minter
     * @param minter The address of the minter
     * @param minterAllowedAmount The new minting amount allowed for the minter
     */
    function updateMintingAllowance(address minter, uint256 minterAllowedAmount)
     public virtual onlyRole(MASTER_MINTER)
    {
        minterAllowed[minter] = minterAllowedAmount;
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint. Must be less than or equal
     * to the minterAllowance of the caller.
     */
    function mint(address to, uint256 amount)
        public
        whenNotPaused
        notBlacklisted(to)
        override
    {
        require((hasRole(MASTER_MINTER, msg.sender) || hasRole(MINTER_ROLE, msg.sender)), "EURL: not allowed to mint");
        require(amount > 0, "EURL: mint amount not greater than 0");

        // MINTER_ROLE allowance management
        if(hasRole(MINTER_ROLE, msg.sender)) {
            uint256 mintingAllowedAmount = minterAllowed[msg.sender];
            require(
                amount <= mintingAllowedAmount,
                "EURL: mint amount exceeds minterAllowance"
            );
            minterAllowed[msg.sender] = mintingAllowedAmount - amount ;
        }

        _mint(to, amount);
        emit Mint(msg.sender, to, amount);
    }

    
    /**
     * @dev allows a minter to burn some of its own tokens
     * Validates that caller is a minter and that sender is not blacklisted
     * amount is less than or equal to the minter's account balance
     * @param amount uint256 the amount of tokens to be burned
     */
    function burn(uint256 amount)
        public virtual override
        whenNotPaused
        onlyRole(MINTER_ROLE)
        notBlacklisted(msg.sender)
    {
        _burn(msg.sender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override(ERC20Upgradeable, ERC20PresetMinterPauserUpgradeable)
    {
        require(
            !blacklisted[from],
            "Blacklistable: account is blacklisted"
        );
        if(_txfeeRate > 0 && to != _feesFaucet) _payTxFee(from, amount);
        
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev force a transfer from any account to any account
     * Validates that caller is the admin
     * @param from address the account from which to send
     * @param to address the account that will receive the tokens
     * @param amount uint256 the amount of token to send 
     */
    function forceTransfer(address from, address to, uint256 amount)
        public virtual onlyRole(ADMIN)
    {
        _transfer(from, to, amount);
    }

    /**
     * @dev Function to update trustedForwarder
     * @param trustedForwarder Address of new trustedForwarder
     */
    function setTrustedForwarder(address trustedForwarder) public onlyRole(ADMIN) {
        require(trustedForwarder != address(0), "EURL: new trustedForwarder can't be address 0");
        _trustedForwarder = trustedForwarder;
        emit TrustedForwarderUpdated(_trustedForwarder);
    }

    /**
     * @dev Function to check if caller is a trusted Forwarder
     * @param forwarder The address of the forwarder
     */
    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}