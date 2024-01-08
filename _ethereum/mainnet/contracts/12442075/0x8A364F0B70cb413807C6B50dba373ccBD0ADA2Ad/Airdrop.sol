/* Please read and review the Terms and Conditions governing this
   Merkle Drop by visiting the Trustlines Foundation homepage. Any
   interaction with this smart contract, including but not limited to
   claiming Trustlines Network Tokens, is subject to these Terms and
   Conditions.
 */

pragma solidity >=0.4.22 <0.9.0;


//import "./ERC20Interface.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract Airdrop is Ownable {

    bytes32 public root;
    IERC20 public _token;

    uint public initialBalance;
    uint public remainingValue;  // The total of not withdrawn entitlements, not considering decay
    uint public spentTokens;  // The total tokens spent by the contract

    mapping (address => bool) public withdrawn;

    event Withdraw(address recipient, uint value);

    constructor(IERC20 token, uint _initialBalance, bytes32 _root) public {
        // The _initialBalance should be equal to the sum of airdropped tokens
        _token = token;
        initialBalance = _initialBalance;
        remainingValue = _initialBalance;
        root = _root;
    }
    
    function closeAirdrop() public onlyOwner {
        require(_token.transfer(msg.sender, remainingValue));
        emit Withdraw(msg.sender, remainingValue);
    }

    function withdraw(bytes32[] memory proof) public {
        require(verifyEntitled(msg.sender, proof), "The proof could not be verified.");
        require(! withdrawn[msg.sender], "You have already withdrawn your entitled token.");

        uint valueToSend = 300000000000000000000;
        require(_token.balanceOf(address(this)) >= valueToSend, "The AirDrop does not have tokens to drop yet / anymore.");

        withdrawn[msg.sender] = true;
        remainingValue -= valueToSend;
        spentTokens += valueToSend;

        require(_token.transfer(msg.sender, valueToSend));
        emit Withdraw(msg.sender, valueToSend);
    }

    function verifyEntitled(address recipient, bytes32[] memory proof) public view returns (bool) {
        // We need to pack the 20 bytes address to the 32 bytes value
        // to match with the proof made with the python merkle-drop package
        bytes32 leaf = keccak256(abi.encodePacked(recipient));
        return verifyProof(leaf, proof);
    }

    function verifyProof(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        bytes32 currentHash = leaf;

        for (uint i = 0; i < proof.length; i += 1) {
            currentHash = parentHash(currentHash, proof[i]);
        }

        return currentHash == root;
    }

    function parentHash(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        if (a < b) {
            return keccak256(abi.encode(a, b));
        } else {
            return keccak256(abi.encode(b, a));
        }
    }

}
