/***
                                   .;cooolc'.                                   
                                 .:dxkkkkkkxl;.                                 
                                ,dkkkkkkkkOOOkl.                                
                               .okkkkkkkkkkkOOk:                                
                               .okkkkkkkkkkkkkkc.                               
                               .:xkkkkkkkkkkkkd,                                
                                .;dxkkkkkkkkxo'                                 
                                  .,cdkkkxo:'.                                  
                                    .cxkxd,                                     
                                    .:xxxd,                                     
    ..................'..''''''''''',lxxxdc'''''''''''''''''',,,,,,,,,,,,'..    
  .:lloooooooooooooodddddddddddddddddxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkdc.  
 'looooooooooddddddddddddddddddxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOd' 
.;oooooooooooooddddddddddddddddddxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkOOOOOOOOOOOk: 
.;oooooooooooooooddddddddddddddddddxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkOOOOOOOk: 
 ;ooooooooooooooooooooodddddddddddddxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkOOOOOOOk: 
 ;lllooooooooooooooooolc:;;;,;;:cloddddxxxxxdolc:;;;;:cloxxkkkkkkkkkkkkkkOOOOk: 
 ;llllloooooooooool:,..          ..':ldddoc;'.          ..,:oxkkkkkkkkkkkkkOOk: 
 ;llllllooooooooc,.                  ..''.                   'cxkkkkkkkkkkkkOk: 
 ,lllllllllllll,.                                              'lkkkkkkkkkkkkk: 
 ,lllllllllllc'                                                 .cxkkkkkkkkkkx: 
 ,clllllllllc'           ..''..                 .''''.           .ckkkkkkkkkkx: 
 ,clllllllll;.         ':looool:'             'coddddoc,.         'dkkkkkkkkkx; 
 ,cclllllllc'         ,looooooool,           ,oddddddddd;         .ckkkkkkkkkx; 
 ,cccclllll:.        .coooooooooo:.         .cddddddddddl.         :xkxxxxkkkx; 
 ,ccccclcclc.         ;looooooool,           ;dddddddddd;.         :xxxxxxxxxx; 
 ,cccccccccc,         .,clollllc'             ,loddddol,.         .lxxxxxxxxxx; 
 ,cccccccccc:.          ..''''..               ..',,'..           :dxxxxxxxxxx; 
 ':cccccccccc;.                                                  ;dxxxxxxxxxxd; 
 ':ccccccccccc:'                 ....      ....                .:dxxxxxxxxxxxd; 
 ':ccccccccccccc;.             .;lll:.    'lolc'             .;lddddddddxxxxxd; 
 ':::ccccccccccccc;.            ,clc;.    .:ll:.           .;lddddddddddddddxd; 
 ':::::cccccccccccc:.            ...        ..             ,oddddddddddddddddd; 
 ':::::cccccccccccc:.                                      'oddddddddddddddddd; 
 ':::::::cccccccccc:.                                      ,oddddddddddddddddo, 
 '::::::::cccccccccc'           ................          .coodddddddddddddddo, 
 ';:::::::::::cccccc:.        .,::::::::::::::::'         ,ooooooddddddddddddo, 
 ';:::::::::::::cccc:;.        .................         'looooooooddddddddddo, 
 ';;::::::::::::::cc::;.                                'loooooooooooddddddddo, 
 ';;;:::::::::::::::::::'.                            .;looooooooooooooooooooo, 
 ';;;;:::::::::::::::::::;'.                        .,cllooooooooooooooooooooo, 
 .;;;;;;::::::::::::::::::::,..                  .';lllllllooooooooooooooooooo, 
 .;;;;;;;::::::::::::::::::::::;,'...........',;:clllllllllllooooooooooooooooo, 
 .;;;;;;;;;;:::::::::::::::::::ccccc::::::cccccccllllllllllllllooooooooooooool, 
 .;;;;;;;;;;;;;::::::::::::::::::ccccccccccccccccclllllllllllllllloooooooooool, 
 .,;;;;;;;;;;;;;;;:::::::::::::::::ccccccccccccccccclllllllllllllllllllllooool' 
 .',;;;;;;;;;;;;;;;;;:::::::::::::::::::cccccccccccccccccclllllllllllllllllll,. 
   ..'''''''''''''''''''',,,,,,,,,,,,,,,,,,,,,;;;;;;;;;;;;;;;;;;;;;:::::::;,.   
                                                                                
ApeGPT (APEGPT)
Discord: https://discord.gg/apegpt
Website: https://apegpt.app
Twitter: https://twitter.com/Ape_GPT
***/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// Allows anyone to claim a revshare rewards if they exist in a merkle root for a given period.
interface IApeGPTRevShareDistributor {
    // Returns true if the claim function is frozen
    function frozen() external view returns (bool);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 period, address addy) external view returns (bool);
    // Claim the given period amount of rewards to sender address. Reverts if the inputs are invalid.
    function claim(uint256 period, uint256 amount, bytes32[] calldata merkleProof) external;
    // Claim multiple given periods and amounts of rewards to sender address. Reverts if the inputs are invalid.
    function multiClaim(uint256[] calldata periods, uint256[] calldata amounts, bytes32[][] calldata merkleProofs) external;
    // Freezes the claim function and allow the merkleRoot to be changed.
    function freeze() external;
    // Unfreezes the claim function.
    function unfreeze() external;
    // Add/Update period with merkle root data.
    function addPeriodData(uint256 period, bytes32 _merkleRoot) external;

    //withdraw emergency functions.
    function withdrawToken(address _token, address _to) external;
    function withdrawEth(address toAddr) external;

    function totalClaimed() external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

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

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

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
        if (_status == _ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

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

contract ApeGPTRevShareDistributor is IApeGPTRevShareDistributor, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    bool public frozen;

    mapping(uint256 => mapping(address => bool)) private claimedMap;
    mapping(uint256 => bytes32) public shareByPeriodMap;
    mapping(address => uint256) public claimedByUser;
    uint256 public totalClaimed;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 period, address indexed account, uint256 amount);
    // This event is triggered whenever a new period data gets added / updated.
    event PeriodDataAdded(uint256 indexed period, bytes32 indexed merkleRoot);

    constructor() {
        frozen = false;
        totalClaimed = 0;
    }

    receive() external payable {}

    function isClaimed(uint256 period, address addy) public view returns (bool) {
        return claimedMap[period][addy];
    }

    function freeze() public onlyOwner {
        frozen = true;
    }

    function unfreeze() public onlyOwner {
        frozen = false;
    }

    function addPeriodData(uint256 period, bytes32 _merkleRoot) public onlyOwner {
        shareByPeriodMap[period] = _merkleRoot;
        emit PeriodDataAdded(period, _merkleRoot);
    }

    function _canClaim(uint256 period, uint256 amount, bytes32[] calldata merkleProof) internal view returns (bool) {
        if (isClaimed(period, msg.sender)) {
            return false;
        } else {
            bytes32 node = keccak256(abi.encodePacked(msg.sender, period, amount));
            bool canUserClaim = MerkleProof.verify(merkleProof, shareByPeriodMap[period], node);
            return canUserClaim;
        }
    }

    function claim(uint256 period, uint256 amount, bytes32[] calldata merkleProof) external nonReentrant {
        require(!frozen, "ApeGPT RevShare Distributor: Claiming is frozen.");
        require(!isClaimed(period, msg.sender), "ApeGPT RevShare Distributor: Share already claimed.");
        require(msg.sender == tx.origin, "ApeGPT RevShare Distributor: Wallet required");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "ApeGPT RevShare Distributor: Empty balance");

        // Verify the merkle proof.
        require(_canClaim(period, amount, merkleProof), "ApeGPT RevShare Distributor: Invalid proof.");

        // Update claiming data...
        claimedMap[period][msg.sender] = true;
        claimedByUser[msg.sender] = claimedByUser[msg.sender] + amount;
        totalClaimed = totalClaimed + amount;
        
        (bool sent, ) = address(msg.sender).call{value: amount}("");
        require(sent, "ApeGPT RevShare Distributor: Transfer failed.");

        emit Claimed(period, msg.sender, amount);
    }

    function multiClaim(uint256[] calldata periods, uint256[] calldata amounts, bytes32[][] calldata merkleProofs) external nonReentrant {
        // Verify that all lengths match
        uint length = periods.length;
        require(amounts.length == length && amounts.length == length && merkleProofs.length == length, "Invalid Lengths");
        require(msg.sender == tx.origin, "ApeGPT RevShare Distributor: Wallet required");
        require(!frozen, "ApeGPT RevShare Distributor: Claiming is frozen.");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "ApeGPT RevShare Distributor: Empty balance");

        for (uint256 i = 0; i < length; i++) {
            // Require that the user can claim with the information provided
            require(_canClaim(periods[i], amounts[i], merkleProofs[i]), "ApeGPT RevShare Distributor: Invalid proofs");

            // Update claiming data...
            claimedMap[periods[i]][msg.sender] = true;
            claimedByUser[msg.sender] = claimedByUser[msg.sender] + amounts[i];
            totalClaimed = totalClaimed + amounts[i];
            
            (bool sent, ) = address(msg.sender).call{value: amounts[i]}("");
            require(sent, "ApeGPT RevShare Distributor: Transfer failed.");

            emit Claimed(periods[i], msg.sender, amounts[i]);
        }
    }

    //withdraw emergency functions.
    function withdrawToken(address _token, address _to) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _contractBalance);
    }
    function withdrawEth(address toAddr) external onlyOwner {
        (bool success, ) = toAddr.call{
            value: address(this).balance
        } ("");
        require(success);
    }

}