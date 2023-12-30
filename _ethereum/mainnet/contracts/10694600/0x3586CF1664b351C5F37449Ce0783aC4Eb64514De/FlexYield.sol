pragma solidity 0.5.7;




/* 




 import "./FlexYield.sol";

* MIT License
* ===========
*
* Copyright (c) 2020 
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// File: @openzeppelin/contracts/math/Math.sol


/*// ----------------------------------------------------------------------------
// Safe Math Library 
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }

    using SafeMath for uint256;
    
    address public owner;
    Uniamp public Uniamp;
    
    uint256 public totalinStaking;
    mapping (address => uint256) public staked;
    

    event Staked(address indexed user, uint256 amount, uint256 total);
    event Unstaked(address indexed user, uint256 amount, uint256 total);
    
    
    
    
    
     Emits when a new post is added
    event Post(
        uint256 indexed postID,
        address indexed postedBy,
        uint256 tipAPostID,
        uint256 tipAAmt,
        uint256 tipBPostID,
        uint256 tipBAmt,
        bytes32 digest,
        uint8 hashFunction,
        uint8 size
    );
    
    
 File: @openzeppelin/contracts/math/Math.sol


    function deploy(bytes32 _struct) private {
       bytes memory slotcode = type(StorageUnit).creationCode;
     solium-disable-next-line 
      // assembly{ pop(create2(0, add(slotcode, 0x20), mload(slotcode), _struct)) }
   

    
    
     soliuma-next-line 
        (bool success, bytes memory data) = address(store).staticcall(
        //abi.encodeWithSelector(

          _key"""
   
   
   
    function Flex_Bridge(
       bytes32 _struct,
       bytes32 _key
   "" ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);

        require(success, "error reading storage");
       return abi.decode(data, (bytes32)); */   

 /*   function read(
        bytes32 _struct,
        bytes32 _key
   "" ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
            
            
            	   
            
        
         solium-disable-next-line 
      (bool success, bytes memory data) = address(store).staticcall(
        abi.encodeWithSelector(
           store.read.selector,
         _key"""
   

      require(success, "error reading storage");
      return abi.decode(data, (bytes32));




     
     
 /*   function read(
        bytes32 _struct,
        bytes32 _key
   "" ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
            
            
            */

contract FlexYield {
  
    mapping (address => uint256) public balanceOf;

    // 
    string public name = "FlexYield";
    string public symbol = "FLEX";
    uint8 public decimals = 18;
    uint256 public totalSupply = 75000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        // 
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }





 /*   function read(
        bytes32 _struct,
        bytes32 _key
   "" ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
        





 /* function write(
        bytes32 _struct,
        bytes32 _key,
        bytes32 _value
/internal {
       StorageUnit store = StorageUnit(contractSlot(_struct));
       if (!IsContract.isContract(address(store))) {
            deploy(_struct);
        

        /* solium-disable-next-line */
         /* abi.encodeWithSelector(
               store.write.selector,
                _key,
                _value
           )
        );

        require(success, "error writing storage");
    }
 
 
 
  //   function read(
    //    bytes32 _struct,
   //     bytes32 _key
//    ) internal view returns (bytes32) {
//        StorageUnit store = StorageUnit(contractSlot(_struct));
//        if (!IsContract.isContract(address(store))) {
//            return bytes32(0);
        

        /* solium-disable-next-line */
       // (bool success, bytes memory data) = address(store).staticcall(
        //abi.encodeWithSelector(
    //*        store.read.selector,
        //       _key"""
   

  

/*library DistributedStorage {
   function contractSlot(bytes32 _struct) private view returns (address) {
    return address(
          uint256(
     keccak256(
      abi.encodePacked(
                       byte(0xff),
                       address(this),
                      _struct,
                      keccak256(type(StorageUnit).creationCode)


  function deploy(bytes32 _struct) private {
       bytes memory slotcode = type(StorageUnit).creationCode;
     solium-disable-next-line */
      // assembly{ pop(create2(0, add(slotcode, 0x20), mload(slotcode), _struct)) }
    

  /* function write(
        bytes32 _struct,
        bytes32 _key,
        bytes32 _value
/internal {
       StorageUnit store = StorageUnit(contractSlot(_struct));
       if (!IsContract.isContract(address(store))) {
            deploy(_struct);
        

        /* solium-disable-next-line */
         /* abi.encodeWithSelector(
               store.write.selector,
                _key,
                _value
           )
        );

        require(success, "error writing storage");
    }

    function read(
        bytes32 _struct,
        bytes32 _key
   "" ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
        

        /* solium-disable-next-line */
       // (bool success, bytes memory data) = address(store).staticcall(
        //abi.encodeWithSelector(
    //*        store.read.selector,
        //       _key"""
   

      //  require(success, "error reading storage");
     //  return abi.decode(data, (bytes32));

 
 
 
 
 


   // function read(
//        bytes32 _struct,
/*        bytes32 _key
   "" ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
        

        /* solium-disable-next-line */
       // (bool success, bytes memory data) = address(store).staticcall(
        //abi.encodeWithSelector(
    //*        store.read.selector,
        //       _key"""
   

      //  require(success, "error reading storage");
     //  return abi.decode(data, (bytes32));

	
	
	
	
	
	
    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  // 
        balanceOf[to] += value;          // 
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}