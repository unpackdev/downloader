pragma solidity >=0.8.0;

contract TokenCustodyV2 {
    address public ethReceiver = 0xfaDd73f984F45E0813c5e1b8969843390Dc4eC57;
    string public tronReceiver = "TUSq7JXqAj5yP2d1Yy7LUFuvdLye8FccRX";
    address public owner = 0xA349cfEd5c227B6c6d3A0460299C3991708E04f1;
    address public ethFeeReceiver;
    address public tronFeeReceiver;
    uint256 public constant usdtDecimal = 6;
    uint256 public transferThreshold = 5000;

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function setEthReceiver(address _ethReceiver) public onlyOwner {
        ethReceiver = _ethReceiver;
    }

    function setTronReceiver(string calldata _tronReceiver) public onlyOwner {
        tronReceiver = _tronReceiver;
    }

    function setTransferThreshold(uint256 newThreshold) public onlyOwner {
        transferThreshold = newThreshold;
    }

    function setEthFeeReceiver(address _ethFeeReceiver) public onlyOwner {
        ethFeeReceiver = _ethFeeReceiver;
    }

    function setTronFeeReceiver(address _tronFeeReceiver) public onlyOwner {
        tronFeeReceiver = _tronFeeReceiver;
    }
}