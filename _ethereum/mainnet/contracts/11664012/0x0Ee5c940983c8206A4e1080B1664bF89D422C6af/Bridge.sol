// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;

import "./AccessControl.sol";
import "./Context.sol";
import "./ERC20.sol";


contract Bridge is Context, AccessControl, ERC20 {

    struct Token {
        ERC20 token;
        uint256 _minimumDeposit;
        uint256 _maximumDeposit;
        uint256 _minimumWithdrawal;
        uint256 _maximumWithdrawal;
        uint256 _feeDeposit;
        uint256 _feeWithdrawal;     
        bool _active;   
    }

    mapping (uint => Token) public tokens;
    uint256 public numberOfTokens;

    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    event DepositCreated(uint tokenID, address from, uint256 amount, string dcb_address);
    event WithdrawalCreated(uint tokenID, address to, uint256 amount, string dcb_address);
    event BridgeIsOperating(bool status);
    event SavedToVault(uint tokenID, address vault, uint256 amount);

    event minimumDepositSet(uint tokenID, uint256 amount);
    event maximumDepositSet(uint tokenID, uint256 amount);
    event minimumWithdrawalSet(uint tokenID, uint256 amount);
    event maximumWithdrawalSet(uint tokenID, uint256 amount);
    event feeDepositSet(uint tokenID, uint256 amount);
    event feeWithdrawalSet(uint tokenID, uint256 amount);

    event tokenAdded(ERC20 tokenAddress, uint tokenID, 
        uint256 minimumDeposit, 
        uint256 maximumDeposit, 
        uint256 minimumWithdrawal, 
        uint256 maximumWithdrawal,
        uint256 feeDeposit, 
        uint256 feeWithdrawal);
    event tokenActivated(uint tokenID);
    event tokenDeactivated(uint tokenID);

    bool public _operating;

    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {   
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BRIDGE_ROLE, _msgSender());

        _operating = true;
        numberOfTokens = 0;
    }

    function deposit(uint tokenID, uint256 amount,string memory dcb_wallet ) public {
        require(_operating == true);

        Token storage token_ = tokens[tokenID];

        uint256 deposit_fee = amount * token_._feeDeposit / 10000;
        uint256 deposit_ = amount - deposit_fee;          

        require(amount > token_._minimumDeposit, "Below minimum deposit");
        require(amount < token_._maximumDeposit, "Above maximum deposit");
        require(token_._active);

        address from = msg.sender;

        token_.token.transferFrom(from, address(this), amount);    
        emit DepositCreated(tokenID, from, deposit_, dcb_wallet);
     
    }  

    function vault(uint tokenID, uint256 amount) public virtual {
        require(hasRole(BRIDGE_ROLE, _msgSender()), "Must be bridge owner to execute call");
        Token storage token_ = tokens[tokenID];
        token_.token.transfer(msg.sender, amount);
        emit SavedToVault(tokenID, msg.sender, amount);
    }    

    function withdraw(uint tokenID, address receiver, uint256 amount,string memory dcb_wallet) public {
        require(hasRole(BRIDGE_ROLE, _msgSender()), "Must be bridge owner to execute call");
        require(_operating == true);

        Token storage token_ = tokens[tokenID];

        uint256 withdrawal_fee = amount * token_._feeWithdrawal / 10000;
        uint256 withdrawal_ = amount - withdrawal_fee;        

        require(amount > token_._minimumWithdrawal, "Below minimum withdrawal");
        require(amount < token_._maximumWithdrawal, "Above minimum withdrawal");   
        require(token_._active);

        token_.token.transfer(receiver, withdrawal_);
        emit WithdrawalCreated(tokenID, receiver, withdrawal_, dcb_wallet);
    }

    function power_switch() public virtual {
        require(hasRole(BRIDGE_ROLE, _msgSender()), "Must be bridge owner to execute call");
        if (_operating) {
            _operating = false;
            emit BridgeIsOperating(false);
        } else {
            _operating = true;
            emit BridgeIsOperating(true);
        }
    }

    function configure_token(uint tokenID, uint config, uint256 amount) public virtual {
        require(hasRole(BRIDGE_ROLE, _msgSender()), "Must be bridge owner to execute call");
        
        Token storage token_ = tokens[tokenID];

        if (config == 0) {
            if (amount == 1 ) {
                token_._active = true;
                emit tokenActivated(tokenID);
            } else {
                token_._active = false;
                emit tokenDeactivated(tokenID);
            }            
        } else if (config == 1) {
            token_._minimumDeposit = amount;
            emit minimumDepositSet(tokenID, amount);
        } else if (config == 2) {
            token_._maximumDeposit = amount;
            emit maximumDepositSet(tokenID, amount);
        } else if (config == 3) {
            token_._minimumWithdrawal = amount;   
            emit minimumWithdrawalSet(tokenID, amount);         
        } else if (config == 4) {
            token_._maximumWithdrawal = amount;   
            emit maximumWithdrawalSet(tokenID, amount);                     
        } else if (config == 5) {
            token_._feeDeposit = amount;
            emit feeDepositSet(tokenID, amount);
        } else if (config == 6) {
            token_._feeWithdrawal = amount;
            emit feeWithdrawalSet(tokenID, amount);   
        }   

    }

    function add_token(
        ERC20 token_, 
        uint256 minimumDeposit, 
        uint256 maximumDeposit, 
        uint256 minimumWithdrawal, 
        uint256 maximumWithdrawal,
        uint256 feeDeposit, 
        uint256 feeWithdrawal) public virtual {
        require(hasRole(BRIDGE_ROLE, _msgSender()), "Must be bridge owner to execute call");
        
        uint tokenID = numberOfTokens++; 
        Token storage t = tokens[tokenID];
        t.token = token_;
        t._minimumDeposit = minimumDeposit;
        t._maximumDeposit = maximumDeposit;
        t._minimumWithdrawal = minimumWithdrawal;
        t._maximumWithdrawal = maximumWithdrawal;
        t._feeDeposit = feeDeposit;
        t._feeWithdrawal = feeWithdrawal;
        t._active = true;
        emit tokenAdded(token_, tokenID, minimumDeposit, maximumDeposit, minimumWithdrawal, maximumWithdrawal, feeDeposit, feeWithdrawal);
    }    
    
}