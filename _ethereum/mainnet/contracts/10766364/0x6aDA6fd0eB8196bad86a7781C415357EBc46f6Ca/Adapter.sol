pragma solidity = 0.5.17;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract owned {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnerShip(address newOwer) public onlyOwner {
        require(newOwer!=address(0));
        owner = newOwer;
    }

}

contract Gateway {
    
    function mintASM(address crosschainDestination, uint256 _amount, uint256 nonce, uint8 v, bytes32 r, bytes32 s )  public;
    function burn(address msgSender, address crosschainDestination, uint256 _amount) public;
    function transferFrom(address _from, address _to, uint256 _value) public;
    
}

contract Adapter is owned{
    
    using Address for address;
    
    Gateway public gateway = Gateway(0x51192938A661E4fA3ee47c7774153f14A68739f9);
    address public avmASMToken = address(0xc55bFF23465a03E5fB17D324342D9Ec12cAF9dB3);
    address public signAddr = address(0xD196c8cFc946dA1E67539Ea7646AdC3fB0d3F4aF);

    address owner;
    mapping(bytes32 => bool) usedHash;
    
    constructor () public payable{
        owner = msg.sender;
    }
    
    function mint(address crosschainDestination, uint256 _amount, uint256 nonce, uint8 v, bytes32 r, bytes32 s ) public returns (bool success) {
        
        require(!crosschainDestination.isContract());
        bytes32 msgHash = getHash(crosschainDestination, _amount, nonce);
        require(!usedHash[msgHash]);
        require(RecoverAddress(msgHash, v, r, s, signAddr));
        usedHash[msgHash]=true;
        gateway.mintASM(crosschainDestination, _amount, nonce, v, r, s);
        success = true;
    }

    function burn(address crosschainDestination, uint256 _amount) public returns  (bool success){
        
        gateway.burn(msg.sender, crosschainDestination, _amount);
        success = true;
    }
    

    function setGateway(address newGateway) public onlyOwner returns (bool) {
        require(newGateway!=address(0));
        gateway = Gateway(newGateway);
    }
    
    function getHash(address signAddr, uint256 amount, uint256 nonce) public view returns (bytes32) {
        return keccak256(abi.encode(address(this), avmASMToken, signAddr, amount, nonce));
    }
    
    function RecoverAddress(bytes32 msgHash, uint8 v, bytes32 r, bytes32 s,address addr) internal returns (bool) {
        return ecrecover(msgHash, v, r, s)==addr;
    }
}