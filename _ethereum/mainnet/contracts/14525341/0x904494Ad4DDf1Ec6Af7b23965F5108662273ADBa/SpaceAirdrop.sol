//SPDX-License-Identifier: MIT License
pragma solidity ^0.8.0;

import "./console.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
interface DateTimeAPI {
        /*
         *  Abstract contract for interfacing with the DateTime contract.
         */
        function isLeapYear(uint16 year) external returns (bool);
        function getYear(uint timestamp)  external returns (uint16);
        function getMonth(uint timestamp) external returns (uint8);
        function getDay(uint timestamp)  external returns (uint8);
        function getHour(uint timestamp) external returns (uint8);
        function getMinute(uint timestamp)  external returns (uint8);
        function getSecond(uint timestamp) external returns (uint8);
        function getWeekday(uint timestamp)  external returns (uint8);
        function toTimestamp(uint16 year, uint8 month, uint8 day) external returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) external returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) external returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) external returns (uint timestamp);
}
contract SpaceAirdrop is Initializable,AccessControlUpgradeable,
	ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using StringsUpgradeable for uint256;
    DateTimeAPI converter;
    uint256 public maxSupply;
    uint256 public claimFee;
    address public dispatcher;
    address public tokenAddress;
    event DispatcherChanged(address newDispatcher);
    event MaxSupplyChanged(uint256 maxSupply);
    event Claimed(address user,uint256 amount);
    event UpdateFee(uint256 fee);
    event Withdraw(uint256 amount,address account);

    function initialize(address _dispatcher,uint256 _maxSupply,uint256 _claimFee,address _tokenAddress, address _TimeApi) external initializer {
        dispatcher =_dispatcher;
        maxSupply=_maxSupply;
        tokenAddress=_tokenAddress;
        claimFee= _claimFee;
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _dispatcher);
        converter =DateTimeAPI(_TimeApi);
    }

    function claimToken(uint256 _amount,bytes32 _password) public payable nonReentrant {
        require(msg.value>=claimFee,"Insufficient value for the tx");
        string memory data = string(abi.encodePacked(StringsUpgradeable.toString(converter.getYear(block.timestamp)),StringsUpgradeable.toString(converter.getMonth(block.timestamp)),StringsUpgradeable.toString(converter.getDay(block.timestamp))));
        require(sha256(abi.encodePacked(data))==_password,"Wrong password!!");
        require(_amount<=maxSupply,"Amount should be less than supply");
        IERC20(tokenAddress).transferFrom(dispatcher,msg.sender,_amount);
        emit Claimed(msg.sender,_amount);
    }

    ///@notice admin's functions

    function changeDispatcher (address _newDispatcher) onlyRole(DEFAULT_ADMIN_ROLE) external{
        dispatcher=_newDispatcher;
        grantRole(DEFAULT_ADMIN_ROLE, _newDispatcher);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        emit DispatcherChanged(dispatcher);
    }

     function changeClaimFee (uint256 _newFee) onlyRole(DEFAULT_ADMIN_ROLE) external{
        claimFee=_newFee;
        emit UpdateFee(_newFee);
    }

    function changeMaxSupply (uint256 _newMaxSupply) onlyRole(DEFAULT_ADMIN_ROLE) external {
        maxSupply=_newMaxSupply;
        emit MaxSupplyChanged(maxSupply);
    }
    function withdraw(uint256 _amount,address _account) onlyRole(DEFAULT_ADMIN_ROLE) external nonReentrant  {
        payable(_account).transfer(_amount);
        emit Withdraw(_amount,_account);
    }
    receive() external payable {}
}
