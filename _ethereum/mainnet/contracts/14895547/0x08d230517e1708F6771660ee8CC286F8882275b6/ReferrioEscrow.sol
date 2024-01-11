//SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.13;

import "./SafeMath.sol";
import "./Address.sol";
import "./ERC20.sol";

contract ReferrioEscrow {
    using SafeMath for uint256;
    using Address for address;

    //VARIABLES
    address public referrioMasterAddress;
    mapping(address => mapping(string => Escrow)) public balances;
    mapping(string => address) public opportunityOwner;
    PayType public payType;
    SetMappingType public setMappingType;

    //ENUM
    enum PayType {
        REFERRER,
        REFEREE
    }

    enum SetMappingType {
        SAFE,
        FORCE
    }

    //STRUCT
    struct Escrow {
        uint256 amount;
        bool locked;
        bool hasDeposited;
    }

    //EVENTS
    event Received(address recipient, uint256 amount);
    event Deposited(address fromAddress, uint256 amount, string opportunityId);
    event Withdrawed(address recipient, uint256 amount);
    event PaidReferrer(string opportunityId, address recipient, uint256 amount);
    event PaidReferee(string opportunityId, address recipient, uint256 amount);
    event SetMapping(string opportunityId);
    event Cancelled(
        string opportunityId,
        address recipient,
        uint256 amountCancelled
    );

    //MODIFIERS
    modifier onlyReferrio() {
        require(
            referrioMasterAddress == msg.sender,
            "onlyReferrio: Must be a Refferio Address"
        );
        _;
    }

    constructor(address _referrioMasterAddress) {
        referrioMasterAddress = _referrioMasterAddress;
    }

    //FUNCTIONS
    // fall-back logic - direct transfers of ETH or ERC20
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function deposit(string memory _opportunityId) external payable {
        // can only deposit once
        require(
            balances[msg.sender][_opportunityId].hasDeposited != true,
            "deposit: Opportunity already exists"
        );
        // prevents blacklisted opportunityIds
        require(
            balances[msg.sender][_opportunityId].locked != true,
            "deposit: Opportunity is locked"
        );
        balances[msg.sender][_opportunityId].amount = balances[msg.sender][
            _opportunityId
        ].amount.add(msg.value); // Support only chain's token
        balances[msg.sender][_opportunityId].locked = false;
        balances[msg.sender][_opportunityId].hasDeposited = true;
        opportunityOwner[_opportunityId] = msg.sender;
        emit Deposited(msg.sender, msg.value, _opportunityId);
    }

    function getBalanceByOpportunity(string memory _opportunityId)
        external
        view
        returns (uint256)
    {
        return balances[msg.sender][_opportunityId].amount;
    }

    function getAnyBalanceByOpportunity(string memory _opportunityId)
        external
        view
        onlyReferrio
        returns (uint256)
    {
        return
            balances[opportunityOwner[_opportunityId]][_opportunityId].amount;
    }

    function getOpportunityLock(string memory _opportunityId)
        external
        view
        returns (bool)
    {
        return balances[msg.sender][_opportunityId].locked;
    }

    function getAnyOpportunityLock(string memory _opportunityId)
        external
        view
        onlyReferrio
        returns (bool)
    {
        return
            balances[opportunityOwner[_opportunityId]][_opportunityId].locked;
    }

    function getOpportunityHasDeposited(string memory _opportunityId)
        external
        view
        returns (bool)
    {
        return balances[msg.sender][_opportunityId].hasDeposited;
    }

    function getAnyOpportunityHasDeposited(string memory _opportunityId)
        external
        view
        onlyReferrio
        returns (bool)
    {
        return
            balances[opportunityOwner[_opportunityId]][_opportunityId]
                .hasDeposited;
    }

    function getOpportunityOwner(string memory _opportunityId)
        external
        view
        onlyReferrio
        returns (address)
    {
        return opportunityOwner[_opportunityId];
    }

    function setOpportunityOwner(
        string memory _opportunityId,
        address payable _address
    ) external onlyReferrio {
        // existing account details
        Escrow memory account = balances[opportunityOwner[_opportunityId]][
            _opportunityId
        ];
        uint256 existingBalance = account.amount;
        bool existingLock = account.locked;
        bool existingHasDeposited = account.hasDeposited;

        // clear existing account balance and leaving existing metadata state
        balances[opportunityOwner[_opportunityId]][_opportunityId].amount = 0;

        // migrate balances and other metadata to new address
        balances[_address][_opportunityId].amount = existingBalance;
        balances[_address][_opportunityId].locked = existingLock;
        balances[_address][_opportunityId].hasDeposited = existingHasDeposited;
        opportunityOwner[_opportunityId] = _address;
    }

    function setOpportunityLock(string memory _opportunityId, bool _state)
        external
        onlyReferrio
    {
        balances[opportunityOwner[_opportunityId]][_opportunityId]
            .locked = _state;
    }

    function setOpportunityHasDeposited(
        string memory _opportunityId,
        bool _state
    ) external onlyReferrio {
        balances[opportunityOwner[_opportunityId]][_opportunityId]
            .hasDeposited = _state;
    }

    function setReferrioMasterAddress(address _address) external onlyReferrio {
        referrioMasterAddress = _address;
    }

    function pay(
        string memory _opportunityId,
        address payable _recipient,
        uint256 _amount,
        PayType _payType
    ) external onlyReferrio {
        require(
            balances[opportunityOwner[_opportunityId]][_opportunityId].amount >=
                _amount,
            "pay: Insufficient balance"
        );
        require(
            balances[opportunityOwner[_opportunityId]][_opportunityId].locked !=
                true,
            "pay: Opportunity is locked"
        );
        (bool success, ) = _recipient.call{value: _amount}("");
        require(
            success,
            "pay: unable to send value, recipient may have reverted"
        );
        balances[opportunityOwner[_opportunityId]][_opportunityId]
            .amount = balances[opportunityOwner[_opportunityId]][_opportunityId]
            .amount
            .sub(_amount);

        if (_payType == PayType.REFERRER) {
            emit PaidReferrer(_opportunityId, _recipient, _amount);
        } else {
            emit PaidReferee(_opportunityId, _recipient, _amount);
        }
    }

    function cancel(string memory _opportunityId) external onlyReferrio {
        Escrow memory account = balances[opportunityOwner[_opportunityId]][
            _opportunityId
        ];
        require(account.locked != true, "cancel: opportunity is locked");
        address payable owner = payable(opportunityOwner[_opportunityId]);
        (bool success, ) = owner.call{value: account.amount}("");
        require(
            success,
            "cancel: unable to send value, recipient may have reverted"
        );

        balances[owner][_opportunityId].amount = 0;
        balances[owner][_opportunityId].locked = true;
        emit Cancelled(_opportunityId, owner, account.amount); // This needs to be moved to before settings the balance to 0
    }

    // MIGRATION HELPERS
    function withdrawETH(address payable _recipient, uint256 _amount)
        external
        onlyReferrio
    {
        (bool success, ) = _recipient.call{value: _amount}("");
        require(
            success,
            "withdrawETH: unable to send value, recipient may have reverted"
        );
        emit Withdrawed(_recipient, _amount);
    }

    function getBalanceETH() external view returns (uint256) {
        return address(this).balance;
    }

    function setMapping(
        address _address,
        string memory _opportunityId,
        uint256 _amount,
        SetMappingType _setMappingType
    ) external {
        if (_setMappingType == SetMappingType.FORCE) {
            balances[_address][_opportunityId].amount = balances[_address][
                _opportunityId
            ].amount.add(_amount);
            opportunityOwner[_opportunityId] = _address;
        } else {
            require(
                opportunityOwner[_opportunityId] == address(0),
                "setMapping: Balance already exists for address"
            );
            balances[_address][_opportunityId].amount = balances[_address][
                _opportunityId
            ].amount.add(_amount);
            opportunityOwner[_opportunityId] = _address;
        }
    }

    // ERC20 Accidental Transfers
    function withdrawERC20(
        ERC20 _tokenAddress,
        address payable _recipient,
        uint256 _amount
    ) external onlyReferrio {
        ERC20 token = ERC20(_tokenAddress);
        token.transfer(_recipient, _amount);
    }

    function getBalanceERC20(ERC20 _tokenAddress)
        external
        view
        onlyReferrio
        returns (uint256)
    {
        ERC20 token = ERC20(_tokenAddress);
        return token.balanceOf(address(this));
    }
}
