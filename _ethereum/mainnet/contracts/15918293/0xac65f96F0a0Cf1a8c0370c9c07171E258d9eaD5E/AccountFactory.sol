// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "./console.sol";
import "./ImmutableProxy.sol";
import "./AccountGuard.sol";
import "./AccountImplementation.sol";
import "./IProxyRegistry.sol";
import "./ManagerLike.sol";
import "./IServiceRegistry.sol";
import "./Constants.sol";
import "./Clones.sol";
import "./console.sol";

contract AccountFactory is Constants {

    address public immutable proxyTemplate;
    AccountGuard public guard;
    uint256 public accountsGlobalCounter;

    //mapping(uint256 => address) public accounts;

    constructor(
        address _guard
    ) {
        guard = AccountGuard(_guard);
        guard.initializeFactory();
        address adr = address(new AccountImplementation(guard));
        proxyTemplate = address(new ImmutableProxy(adr));
        accountsGlobalCounter = 0;
    }

    function createAccount() public returns (address clone) {
        clone = createAccount(msg.sender);
        return clone;
    }

    function createAccount(address user) public returns (address) {
        accountsGlobalCounter++;
        address clone = Clones.clone(proxyTemplate);
        guard.permit(user, clone, true);
        emit AccountCreated(clone, user, accountsGlobalCounter);
        //TODO: decide if we want this information onchain
        //accounts[accountsGlobalCounter] = clone;
        return clone;
    }

    event AccountCreated(address proxy, address indexed user, uint256 indexed vaultId);
}
