pragma solidity >=0.4.21 <0.7.1;

interface LiquidityPool {
    function borrow(address _token,uint256 _amount,bytes calldata _data) external;
}

contract testKeeper {
    address public owner;
    address public borrowProxy;
    address payable public liquidityPool;

    modifier onlyOwner {
        if (msg.sender == owner) {
            _;
        }
    }

    modifier onlyBorrowProxy {
        if (msg.sender == borrowProxy) {
            _;
        }
    }

    constructor() public {
        owner = msg.sender;
        borrowProxy = 0x82151CA501c81108d032C490E25f804787BEF3b8;
        liquidityPool = 0x4C8cC29226F97d92eC2D299bC14EDF16bAD436b7;
    }

    receive() external payable {
        //do nothing
    }

    function withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
    
    function execute(address _dest, uint256 _value, bytes memory _data) public payable onlyOwner {
        (bool s, bytes memory b) = _dest.call{value: _value}(_data);
    }    

    function setBorrowProxy(address _newBorrowProxy) external onlyOwner {
        borrowProxy = _newBorrowProxy;
    }

    function setLiquidityPool(address payable _newLiquidityPool) external onlyOwner {
        liquidityPool = _newLiquidityPool;
    }

    function keep(uint256 _amountToBorrow, uint256 _amountOfProfitToReturn) external onlyOwner{
        require(_amountOfProfitToReturn > 0, "profit is zero");
        require(address(this).balance > _amountOfProfitToReturn,"balance is too low");

        LiquidityPool(liquidityPool).borrow(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE), _amountToBorrow, abi.encodeWithSelector(this.keeperCallback.selector, _amountToBorrow, _amountOfProfitToReturn));
    }

    function keeperCallback(uint256 _amountBorrowed, uint256 _amountOfProfitToReturn) external onlyBorrowProxy {
        assert(address(this).balance >= _amountOfProfitToReturn + _amountBorrowed);
        assert(_amountOfProfitToReturn > 0);
        
        liquidityPool.call{value: _amountBorrowed + _amountOfProfitToReturn}("");
    }
}