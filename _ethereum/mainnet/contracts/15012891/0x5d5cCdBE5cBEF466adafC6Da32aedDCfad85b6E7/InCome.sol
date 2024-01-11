pragma solidity ^0.8.0;

import "./IRootManger.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IinComeContract.sol";
import "./ContextUpgradeable.sol";
contract Income is IinComeContract , ContextUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address immutable public TORN_CONTRACT;
    address immutable public ROOT_MANAGER;


    /** ---------- constructor ---------- **/
    constructor(
        address _tornContract,
        address _root_manager
    ) {
        TORN_CONTRACT = _tornContract;
        ROOT_MANAGER = _root_manager;
    }

    /** ---------- modifier ---------- **/
    modifier onlyOperator() {
        require(msg.sender == IRootManger(ROOT_MANAGER).operator(), "Caller is not operator");
        _;
    }


    event distribute_torn(address,uint256);
    function distributeTorn(uint256 _amount) external onlyOperator {
        //require(IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this)) >= _amount, 'Insufficient balance');
        address _depositAddress = IRootManger(ROOT_MANAGER).depositContract();
        //require(_depositAddress != address(0), 'Invalid deposit address');
        IRootManger(ROOT_MANAGER).addIncome(_amount);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(TORN_CONTRACT),_depositAddress, _amount);
        emit distribute_torn(_depositAddress,_amount);
    }


    receive() external payable {

    }


}
