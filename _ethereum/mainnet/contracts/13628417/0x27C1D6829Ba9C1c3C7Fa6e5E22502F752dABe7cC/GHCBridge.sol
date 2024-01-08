// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
//import "./console.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract GHCBridge is Ownable {
    using SafeMath for uint256;

    address payable public admin;               // Admin account/server that calls withdrawTo
    ERC20 public token;                         // Token that will be withdrawn/deposited. This should be a GHC token.
    address payable public addrDeveloper;       // Developer address (for developer commision)
    uint256 public developerCommission = 1;     // Developer commission amount (1%)
    uint256 public gasTax = 10000000000000000;  // Gas tax (ETH or BNB) to collect in order to fund bridge transactions.

    /** Nonce to prevent duplicate transactions */
    uint public nonce;
    mapping(uint => bool) public processedNonces;

    /** Event that is emitted for a deposit or a withdraw */
    enum Action { Deposit, Withdrawal }
    event Transfer(address from, address to, uint amount, uint nonce, Action indexed action);
    event TransferToDev(uint256 amount);

    /** Constructor */
    constructor(address _admin, address _token, address _devAddress) {
        admin = payable(_admin);
        token = ERC20(_token);
        addrDeveloper = payable(_devAddress);

        // Make the admin the owner of the bridge...
        transferOwnership(admin);
    }

    /** Updates admin address */
    function setAdminAddress(address _admin) public onlyOwner {
        admin = payable(_admin);
    }

    /** Updates developer address */
    function setDeveloperAddress(address _addrDeveloper) public onlyOwner {
        addrDeveloper = payable(_addrDeveloper);
    }

    /** Updates developer commission percentage */
    function setGasTax(uint256 _gasTax) public onlyOwner {
        require(_gasTax >= 0, "Gas tax must be >= 0");
        gasTax = _gasTax;
    }

    /** Updates developer commission percentage */
    function setDeveloperCommission(uint256 _developerCommission) public onlyOwner {
        require(_developerCommission >= 0, "Developer commission must be >= 0");
        developerCommission = _developerCommission;
    }

    /** if for some reason BNB or ETH builds up in this contract, remove it **/
    function withdrawBaseCurrency(uint256 amount) public onlyOwner {
        (bool success, ) = addrDeveloper.call{ value: amount }("");
        require(success, "Withdrawal of ETH failed.");
    }

    /** Returns the balance in the Bridge */
    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }    

    /** Deposit {amount} tokens into the vault */
    function depositFrom(uint256 amount) public payable {
        require(amount > 0, "Amount must be > 0 to deposit");
        require(token.balanceOf(msg.sender) >= amount, "Cannot deposit more than your balance");
        require(msg.value >= gasTax, "Must pay bridge fee"); // require a BNB or ETH fee of 0.01
        
        (bool success, ) = admin.call{ value: address(this).balance }("");
        require(success, "Forwarding of ETH failed.");

        uint256 devFee = (amount.mul(developerCommission)).div(100);
        if (devFee > 0) {
            amount = amount.sub(devFee);
            token.transferFrom(msg.sender, addrDeveloper, devFee);
            emit TransferToDev(devFee);
        }
        
        // Transfer remaining tokens from the {from} address to the {admin} address...
        token.transferFrom(msg.sender, address(this), amount);
        emit Transfer(msg.sender, address(this), amount, nonce, Action.Deposit);
        nonce++;
    }

    /** Withdraw {amount} tokens from the vault and send to {to} */
    function withdrawTo(address to, uint256 amount, uint otherChainNonce) public {
        require(msg.sender == admin, "Only admin may withdraw from the vault");
        require(token.balanceOf(address(this)) >= amount, "Cannot withdraw more than the vault balance");
        require(processedNonces[otherChainNonce] == false, 'transfer already processed');
        processedNonces[otherChainNonce] = true;

        // Transfer remaining tokens from the {admin} address to the {to} address...
        token.transfer(to, amount);
        emit Transfer(admin, to, amount, otherChainNonce, Action.Withdrawal);
    }

    /** Emergency Withdraw {amount} tokens from the vault and send to {to} */
    function emergencyWithdraw(address to, uint256 amount) public onlyOwner{
        require(token.balanceOf(address(this)) >= amount, "Cannot withdraw more than the vault balance");
        // Transfer remaining tokens from the {admin} address to the {to} address...
        token.transfer(to, amount);
        emit Transfer(admin, to, amount, 0, Action.Withdrawal);
    }

    fallback() external payable {
    }
    
    receive() external payable {
    }
}