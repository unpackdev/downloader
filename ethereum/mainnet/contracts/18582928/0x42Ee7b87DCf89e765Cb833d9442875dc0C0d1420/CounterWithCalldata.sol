/**
 *Submitted for verification at Etherscan.io on 2023-08-01
*/

pragma solidity ^0.8.0;

contract CounterWithCalldata{
    string public name;
    uint256 public interval;
    uint256 public counter;
    address progenitor;
    mapping(uint256=>address) public addresses;
    struct incrementReturnData {
        uint256 oldCounter;
        uint256 newCounter;
        address cDataPassed;
        uint256 timeOfExec;
    }
    event Incremented(uint256 indexed oldCounter, uint256 indexed newCounter, address indexed cDataPassed, uint256 timeOfExec);

    constructor (string memory name_, uint256 interval_, address originator){
        name = name_;
        interval = interval_;
        counter = 0;
        progenitor = originator;
    }

    function cdataToAddress(bytes calldata bytes_) private pure returns (address) {
        return address(uint160(bytes20(bytes_))); //bytes->bytes20 (address is 20 long)->uint160 (20 bytes is 160 bits)->address
    }

    function increment() public returns (incrementReturnData memory) {
        uint256 counter_ = counter + 1;
        addresses[counter] = msg.sender;
        emit Incremented(counter, counter_, msg.sender, block.timestamp);
        incrementReturnData memory retData = incrementReturnData(counter, counter_, msg.sender, block.timestamp);
        counter = counter_;
        return retData;
    }

    function incrementWithCalldata(address dataPassed) public returns (incrementReturnData memory){
        uint256 counter_ = counter + 1;
        //address dataPassed = address(0xDf4f9355572669ddbD2938AC0d7613F965e327B5);
        addresses[counter] = dataPassed;
        emit Incremented(counter, counter_, dataPassed, block.timestamp);
        incrementReturnData memory retData = incrementReturnData(counter, counter_, dataPassed, block.timestamp);
        counter = counter_;
        return retData;
    }

    function isItTimeYet() public view returns (bool shouldExecute, bytes memory cdata_) {
        //emit gotCval(cval);
        //if (cval%5 == 0){
        //    //emit ok(true);
        //    return (true, cdata);
        //}
        if (((block.number%20 != 0)&&(counter%5 == 0))||(counter%5 != 0)){
            return (true, abi.encodeWithSelector(this.incrementWithCalldata.selector, tx.origin));
        }
        else {
            return (false, abi.encodeWithSelector(this.incrementWithCalldata.selector, tx.origin));
        }
    }
}