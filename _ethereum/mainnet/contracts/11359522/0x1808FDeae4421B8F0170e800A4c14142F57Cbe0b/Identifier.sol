pragma solidity ^0.5.16;

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// Deployed proxy addresses are logged
contract DSProxyFactory {
    mapping(address=>bool) public isProxy;
}
contract compound{
     address public comptroller;
}

contract Identifier {
    using Address for address;

    address public owner;
    address public oasisFactory = 0xA26e15C895EFc0616177B7c1e7270A4C7D51C997;
    address public compoundComptroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    modifier onlyOwner() {
        require(msg.sender == owner);
         _;
    }
    constructor()  public {
        owner = msg.sender;
    }
    
    
    // @sample,  proxy address
    function getSampleType(address sample) public view returns (uint256){ 
        if (!sample.isContract()) {
            return 0; // EOA address
        }
    
        if (DSProxyFactory(oasisFactory).isProxy(sample)) {
            return  3;
        }

        bool retValue;
        bytes memory retBytes;
        (retValue, retBytes) = sample.staticcall(abi.encodeWithSignature("comptroller()"));
        if (retValue && (retBytes.length > 0)) {
            address addr = abi.decode(retBytes, (address));
            if (addr == compoundComptroller) {
                return 1;
            }
        }
        return 0;
    }

    function destroy() external onlyOwner{
        selfdestruct(msg.sender);
    }
}