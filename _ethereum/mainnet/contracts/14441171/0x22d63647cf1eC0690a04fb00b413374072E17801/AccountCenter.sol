// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";

interface OpDefaultInterface {
    function enable(address user) external;

    function setAccountCenter(address _accountCenter) external;
}

interface IRewardCenter {
    function claimOpenAccountReward(address EOA, address dsa) external;
}

contract AccountCenter is Ownable {
    // totally account count
    uint256 public accountCount;

    // Account Type ID count
    uint256 public accountTypeCount;

    // open account reward center
    address rewardCenter;

    // Account Type ID -> accountProxyTemplateAddress
    mapping(uint256 => address) accountProxyTemplate;

    // EOA -> AccountType -> SmartAccount
    mapping(address => mapping(uint256 => address)) accountBook;

    // Account Type ID -> account count in this type
    mapping(uint256 => uint256) accountOfTypeCount;

    // SmartAccount -> EOA
    mapping(address => address) eoaBook;

    // SmartAccount -> TypeID
    mapping(address => uint256) SmartAccountType;

    mapping(uint256 => address) accountIDtoAddress;

    event AddNewAccountType(uint256 accountTypeID, address acountProxyAddress);
    event UpdateAccountType(uint256 accountTypeID, address acountProxyAddress);
    event CreateAccount(address EOA, address account, uint256 accountTypeID);

    function addNewAccountType(address acountProxyAddress) external onlyOwner {
        require(
            acountProxyAddress != address(0),
            "CHFRY: acountProxyAddress should not be 0"
        );
        accountTypeCount = accountTypeCount + 1;
        accountProxyTemplate[accountTypeCount] = acountProxyAddress;
        emit AddNewAccountType(accountTypeCount, acountProxyAddress);
    }

    function setRewardCenter(address _rewardCenter) external onlyOwner {
        require(
            _rewardCenter != address(0),
            "CHFRY: rewardCenter should not be 0"
        );
        rewardCenter = _rewardCenter;
    }

    function updateAccountType(
        address acountProxyAddress,
        uint256 accountTypeID
    ) external onlyOwner {
        require(
            acountProxyAddress != address(0),
            "CHFRY: acountProxyAddress should not be 0"
        );
        require(
            accountProxyTemplate[accountTypeID] != address(0),
            "CHFRY: account Type not exist"
        );
        accountProxyTemplate[accountTypeID] = acountProxyAddress;
        emit UpdateAccountType(accountTypeID, acountProxyAddress);
    }

    function createAccount(uint256 accountTypeID)
        external
        returns (address _account)
    {
        require(
            accountTypeID <= accountTypeCount,
            "CHFRY: Invalid account Type ID"
        );
        require(
            accountBook[msg.sender][accountTypeID] == address(0),
            "CHFRY: account exist"
        );
        _account = cloneAccountProxy(accountTypeID);
        accountBook[msg.sender][accountTypeID] = _account;
        accountCount = accountCount + 1;
        accountIDtoAddress[accountCount] = _account;
        accountOfTypeCount[accountTypeID] =
            accountOfTypeCount[accountTypeID] +
            1;
        eoaBook[_account] = msg.sender;
        SmartAccountType[_account] = accountTypeID;
        OpDefaultInterface(_account).setAccountCenter(address(this));
        OpDefaultInterface(_account).enable(msg.sender);
        if (rewardCenter != address(0)) {
            IRewardCenter(rewardCenter).claimOpenAccountReward(
                msg.sender,
                _account
            );
        }

        emit CreateAccount(msg.sender, _account, accountTypeID);
    }

    function getAccount(uint256 accountTypeID)
        external
        view
        returns (address _account)
    {
        _account = accountBook[msg.sender][accountTypeID];
        require(
            accountBook[msg.sender][accountTypeID] != address(0),
            "account not exist"
        );
    }

    function getAccountByTypeID(address EOA, uint256 accountTypeID)
        external
        view
        returns (address _account)
    {
        _account = accountBook[EOA][accountTypeID];
    }

    function getAccountTypeCount()
        external
        view
        returns (uint256 _accountTypeCount)
    {
        _accountTypeCount = accountTypeCount;
    }

    function getEOA(address account) external view returns (address _eoa) {
        require(account != address(0), "CHFRY: address should not be 0");
        _eoa = eoaBook[account];
    }

    function isSmartAccount(address _address)
        external
        view
        returns (bool _isAccount)
    {
        require(_address != address(0), "CHFRY: address should not be 0");
        if (eoaBook[_address] == address(0)) {
            _isAccount = false;
        } else {
            _isAccount = true;
        }
    }

    function isSmartAccountofTypeN(address _address, uint256 accountTypeID)
        external
        view
        returns (bool _isAccount)
    {
        require(_address != address(0), "CHFRY: address should not be 0");
        if (SmartAccountType[_address] == accountTypeID) {
            _isAccount = true;
        } else {
            _isAccount = false;
        }
    }

    function getAccountCountOfTypeN(uint256 accountTypeID)
        external
        view
        returns (uint256 count)
    {
        count = accountOfTypeCount[accountTypeID];
    }

    function cloneAccountProxy(uint256 accountTypeID)
        internal
        returns (address accountAddress)
    {
        address accountProxyTemplateAddress = accountProxyTemplate[
            accountTypeID
        ];
        
        require(
            accountProxyTemplateAddress != address(0),
            "CHFRY: accountProxyTemplateAddress not found"
        );

        bytes20 targetBytes = bytes20(accountProxyTemplateAddress);

        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            accountAddress := create(0, clone, 0x37)
        }
    }
}
