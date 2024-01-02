// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: wns-v2/registrar.sol



pragma solidity 0.8.20;

interface WnsRegistryInterface {
    function owner() external view returns (address);
    function getWnsAddress(string memory _label) external view returns (address);
    function setRecord(bytes32 _hash, uint256 _tokenId, string memory _name) external;
    function setRecord(uint256 _tokenId, string memory _name) external;
    function getRecord(bytes32 _hash) external view returns (uint256);
    
}

interface WnsErc721Interface {
    function mintErc721(address to) external;
    function getNextTokenId() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);

}

contract Computation {
    function computeNamehash(string memory _name) public pure returns (bytes32 namehash) {
        namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked('eth')))
        );
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
    }
}

abstract contract Signatures {

    struct Register {
        string name;
        string extension;
        address registrant;
        uint256 cost;
        uint256 expiration;
        address[] splitAddresses;
        uint256[] splitAmounts;
    }
     
   function verifySignature(Register memory _register, bytes memory sig) internal pure returns(address) {
        bytes32 message = keccak256(abi.encode(_register.name, _register.extension, _register.registrant, _register.cost, _register.expiration, _register.splitAddresses, _register.splitAmounts));
        return recoverSigner(message, sig);
   }

   function recoverSigner(bytes32 message, bytes memory sig)
       public
       pure
       returns (address)
     {
       uint8 v;
       bytes32 r;
       bytes32 s;
       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
   }

   function splitSignature(bytes memory sig)
       internal
       pure
       returns (uint8, bytes32, bytes32)
     {
       require(sig.length == 65);

       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }
 
       return (v, r, s);
   }
}


contract WnsRegistrar is Computation, Signatures, ReentrancyGuard {

    address private WnsRegistry;
    WnsRegistryInterface wnsRegistry;

    constructor(address registry_) {
        WnsRegistry = registry_;
        wnsRegistry = WnsRegistryInterface(WnsRegistry);
    }

    function setRegistry(address _registry) public {
        require(msg.sender == wnsRegistry.owner(), "Not authorized.");
        WnsRegistry = _registry;
        wnsRegistry = WnsRegistryInterface(WnsRegistry);
    }

    bool public isActive = true;
    address wnsWallet = 0x6bD695B0A3B799b9a9F98d6596EF812Be31e1a6c;
    uint256 minLength = 3;
    uint256 maxLength = 15;

    function wnsRegister(Register[] memory register, bytes[] memory sig) public payable nonReentrant {
        bool[] memory success = _registerAll(register, sig);
        settlePayment(register, success);
    }

    function wnsRegisterWithOneShare(Register[] memory register, bytes[] memory sig) public payable nonReentrant {
        bool[] memory success = _registerAll(register, sig);
        settlePaymentWithOneShare(register, success);
    }

    function wnsRegisterWithDiffShare(Register[] memory register, bytes[] memory sig) public payable nonReentrant {
        bool[] memory success = _registerAll(register, sig);
        settlePaymentWithDiffShare(register, success);
    }

    function _registerAll(Register[] memory register, bytes[] memory sig) internal returns (bool[] memory) {
        require(isActive, "Registration must be active.");
        require(register.length == sig.length, "Invalid parameters.");
        require(calculateCost(register) <= msg.value, "Ether value is not correct.");
        
        bool[] memory success = new bool[](register.length);
        for(uint256 i=0; i<register.length; i++) {
            success[i] = _register(register[i], sig[i]);
        }

        return success;
    }

    function _register(Register memory register, bytes memory sig) internal returns (bool) {
        WnsErc721Interface wnsErc721 = WnsErc721Interface(wnsRegistry.getWnsAddress("_wnsErc721"));
        require(verifySignature(register,sig) == wnsRegistry.getWnsAddress("_wnsSigner"), "Not authorized.");
        require(register.expiration >= block.timestamp, "Expired credentials.");
        
        string memory sanitizedName = sanitizeName(register.name);
        require(isLengthValid(sanitizedName), "Invalid name");
        
        bytes32 _hash = computeNamehash(sanitizedName);
        
        if(wnsRegistry.getRecord(_hash) == 0) {
            wnsErc721.mintErc721(register.registrant);
            wnsRegistry.setRecord(_hash, wnsErc721.getNextTokenId(), string(abi.encodePacked(sanitizedName, register.extension)));
            return true;
        } else {
            return false;
        }
    }

    function calculateCost(Register[] memory register) internal pure returns (uint256) {
        uint256 cost;
        for(uint256 i=0; i<register.length; i++) {
            cost = cost + register[i].cost;
        }
        return cost;
    }

    struct MasterSplits {
        address masterAddress;
        uint256 masterAmount;
    }

    function settlePayment(Register[] memory register, bool[] memory success) internal {
        require(register.length == success.length, "Length doesn't match");

        uint256 failedCost = 0;
        for(uint256 i = 0; i < register.length; i++) {
            if(!success[i]) {
                failedCost += register[i].cost;
            }
        }

        if (failedCost > 0) {
            payable(msg.sender).transfer(failedCost);
        }

        payable(wnsWallet).transfer(address(this).balance);
    }

    function settlePaymentWithOneShare(Register[] memory register, bool[] memory success) internal {
        require(register.length == success.length, "Length doesn't match");

        uint256 failedCost = 0;
        uint256 shareCost = 0;
        address splitAddress = wnsWallet;
        for(uint256 i = 0; i < register.length; i++) {
            if(!success[i]) {
                failedCost += register[i].cost;
            } else {
                if(register[i].splitAddresses.length > 0 && register[i].splitAmounts.length > 0) {
                    shareCost += register[i].splitAmounts[0];
                    if(splitAddress != register[i].splitAddresses[0]) {
                        splitAddress = register[i].splitAddresses[0];
                    }
                }
            }
        }

        if (failedCost > 0) {
            payable(msg.sender).transfer(failedCost);
        }

        if (shareCost > 0) {
            payable(splitAddress).transfer(shareCost);
        }

        payable(wnsWallet).transfer(address(this).balance);
    }

    function settlePaymentWithDiffShare(Register[] memory register, bool[] memory success) internal {
        require(register.length == success.length, "Length doesn't match");

        uint256 failedCost = 0;
        for(uint256 i = 0; i < register.length; i++) {
            if(!success[i]) {
                failedCost += register[i].cost;
            } else {
                if(register[i].splitAddresses.length > 0 && register[i].splitAmounts.length > 0) {
                    require(register[i].splitAddresses.length == register[i].splitAmounts.length);
                    for (uint256 j = 0; j < register[i].splitAddresses.length; j++) {
                        payable(register[i].splitAddresses[j]).transfer(register[i].splitAmounts[j]);
                    }
                }
            }
        }

        if (failedCost > 0) {
            payable(msg.sender).transfer(failedCost);
        }

        payable(wnsWallet).transfer(address(this).balance);
    }

    function sanitizeName(string memory name) public pure returns (string memory) {
        bytes memory nameBytes = bytes(name);

        uint dotPosition = nameBytes.length;
        for (uint i = 0; i < nameBytes.length; i++) {
            // Convert uppercase to lowercase
            if (uint8(nameBytes[i]) >= 65 && uint8(nameBytes[i]) <= 90) {
                nameBytes[i] = bytes1(uint8(nameBytes[i]) + 32);
            }
            // Check for the dot
            if (nameBytes[i] == bytes1(".")) {
                dotPosition = i;
                break;
            }
        }

        bytes memory sanitizedBytes = new bytes(dotPosition);
        for (uint i = 0; i < dotPosition; i++) {
            sanitizedBytes[i] = nameBytes[i];
        }

        return string(sanitizedBytes);
    }

    function isLengthValid(string memory name) internal view returns (bool) {
        bytes memory nameBytes = bytes(name);
        uint length = nameBytes.length;

        return (length >= minLength && length <= maxLength);
    }

    function changeLengths(uint256 min, uint256 max) public {
        require(msg.sender == wnsRegistry.owner());
        minLength = min;
        maxLength = max;
    }

    function withdraw(address to, uint256 amount) public nonReentrant {
        require(msg.sender == wnsRegistry.owner());
        require(amount <= address(this).balance);
        payable(to).transfer(amount);
    }

    function changeWnsWallet(address newAddress) public {
        require(msg.sender == wnsRegistry.owner());
        wnsWallet = newAddress;
    }
    
    function flipActiveState() public {
        require(msg.sender == wnsRegistry.owner());
        isActive = !isActive;
    }

}