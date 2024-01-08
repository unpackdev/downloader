pragma solidity 0.4.24;

import "./UnsafeAragonApp.sol";
import "./DepositableStorage.sol";


contract AragonVaultMock is UnsafeAragonApp, DepositableStorage {
    event LogFund(address sender, uint256 amount);

    function initialize() external {
        initialized();
        setDepositable(true);
    }

    function () external payable {
        emit LogFund(msg.sender, msg.value);
    }
}
