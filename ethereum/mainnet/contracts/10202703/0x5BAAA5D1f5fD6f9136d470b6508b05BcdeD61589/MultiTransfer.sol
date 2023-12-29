pragma solidity ^0.5.5;

interface IMakerPriceFeed {
  function read() external view returns (bytes32);
}

contract MultiTransfer {
    address owner;
    address oracle;
    
    constructor (address _oracle) public {
        owner = msg.sender;
        oracle = _oracle;
    }
    
    function changeOracleAddress(
        address _oracle
    )
    public
    {
        require(msg.sender == owner);
        oracle = _oracle;
        
    }
    
    function multiTransferETH(
        address[] memory to,
        uint256[] memory amounts
    )
    public
    payable
    {
        require(to.length == amounts.length);
        uint256 total = msg.value;
        for(uint256 i = 0; i < to.length; i++) {
            require(total >= amounts[i]);
            address(uint160(to[i])).transfer(amounts[i]);
            total -= amounts[i];
        }
        msg.sender.transfer(total);
    }
    
    function multiTransferUSD(
        address[] memory to,
        uint256[] memory amounts
    )
    public
    payable
    {
        require(to.length == amounts.length);
        uint256 total = msg.value;
        uint256 price = 10**36 / uint256(IMakerPriceFeed(oracle).read());
        uint256 toSent;
        
        for(uint256 i = 0; i < to.length; i++) {
            toSent = amounts[i] * price;
            require(total >= toSent);
            address(uint160(to[i])).transfer(toSent);
            total -= toSent;
        }
        msg.sender.transfer(total);
    }
}