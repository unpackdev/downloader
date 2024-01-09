// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";

interface SafeGuardWhiteList {
    function isWhiteListed(address callee) external view returns (bool);
}

contract CallAgent is Ownable {
    using SafeERC20 for IERC20;
    address constant NULL = 0x0000000000000000000000000000000000000000;
    bool private initialized = false;
    address private _admin;
    // If white list contract is null. local whitelist filter will be used.
    address public whiteListContract = NULL;
    mapping(address => bool) filter;
    // todo add method to modify signaturedb
    mapping(bytes4 => uint256) signatures;

    // When operator changed.
    event adminChanged(address newAdmin);
    //  When operator triggered emergency
    event paused();
    // When switched to white list contract.
    event whiteListChanged(address newWhiteList);

    modifier requireAdmin() {
        require(owner() == msg.sender || admin() == msg.sender, "denied");
        _;
    }

    function ChangeAdmin(address newAdmin) public onlyOwner {
        _admin = newAdmin;
        emit adminChanged(newAdmin);
    }

    function ChangeWhiteList(address newWhiteList) public onlyOwner {
        // todo: check if the external contract is legal whitelist.
        whiteListContract = newWhiteList;
        emit whiteListChanged(newWhiteList);
    }

    // Add local target address.
    // Available when whitelist contract is null
    function addLocalWhiteList(address[] memory callee) public onlyOwner {
        for (uint256 i = 0; i < callee.length; i++) {
            filter[callee[i]] = true;
        }
    }

    function removeLocalWhiteList(address[] memory callee) public onlyOwner {
        for (uint256 i = 0; i < callee.length; i++) {
            filter[callee[i]] = false;
        }
    }

    function checkWhiteList(address callee) public view returns (bool) {
        if(whiteListContract == NULL) {
            return filter[callee];
        } 
        return SafeGuardWhiteList(whiteListContract).isWhiteListed(callee);
    }

    function initialize(address owner, address admin_) public {
        require(!initialized, "Already Initialized");
        Ownable._transferOwnership(owner);
        _admin = admin_;
        initialized = true;
    }

    function admin() public view returns (address) {
        return _admin;
    }

    // Owner withdrawal ethereum.
    function withdrawEth(uint256 amount, address payable out) public onlyOwner {
        out.transfer(amount);
    }

    function withdrawErc20(uint256 amount, address erc20, address out) public onlyOwner {
        IERC20(erc20).safeTransfer(out, amount);
    }

    function emergencyPause() public requireAdmin {
        _admin = 0x0000000000000000000000000000000000000000;
        emit paused();
    }

    // Add filtered signatures
    // src: function signature
    // address_filter: where address begins
    // Example:
    //        src: 0xa9059cbb(Transfer)
    //        address_filter: 4 (in ABI Encode of transfer(address, uint256), address begins at hex 0x4 location)
    function addSignature(bytes4[] memory src, uint256[] memory address_filter) public onlyOwner {
        for (uint256 i = 0; i < src.length; i++) {
            signatures[src[i]] = address_filter[i];
        }
    }

    function removeSignature(bytes4[] memory src) public onlyOwner {
        for (uint256 i = 0; i < src.length; i++) {
            signatures[src[i]] = 0;
        }
    }

    function toBytes4(bytes memory payload) internal pure returns (bytes4 b) {
        assembly {
            b := mload(add(payload, 0x20))
        }
    }

    function toAddress(bytes memory payload) internal pure returns (address b) {
        assembly {
            b := mload(add(payload, 0x20))
        }
    }

    function callAgent(address callee, uint256 ethAmount, bytes calldata payload) public requireAdmin returns (bool, bytes memory) {
        if(ethAmount != 0) {
            if(!checkWhiteList(callee)) {
                revert("no whitelist");
            }
        } else {
            bytes4 signature = toBytes4(payload[:4]);
            uint256 p = signatures[signature];
            if(p > 0) {
                address addr = toAddress(payload[p:p + 32]);
                if(!checkWhiteList(addr)) {
                    revert("no whitelist");
                }
            }
        }
        return callee.call{value: ethAmount}(payload);
    }

    receive() external payable {}
    fallback() external payable {}

}
