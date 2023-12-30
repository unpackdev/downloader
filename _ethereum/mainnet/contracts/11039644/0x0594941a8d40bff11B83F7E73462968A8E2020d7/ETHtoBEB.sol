/**
 *Submitted for verification at Etherscan.io on 2020-10-05
*/

pragma solidity =0.6.6;
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
contract ETHtoBEB {
    address public   onwer;
    address public   WETH;
    mapping (address=>bool)public senderLooks;
    mapping(uint=>uint)public UsersDays;
    constructor(address _WETH) public {
        onwer = msg.sender;
        WETH=_WETH;
    }
    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }
    //Authorized additional address
    function AdditionalAddress(address addr)public{
        require(onwer==msg.sender,"Not contract administrator");
        senderLooks[addr]=true;
    }
    function CreateContract(uint _lsh)public payable{
        UsersDays[_lsh]=msg.value;
        IWETH(WETH).deposit{value: msg.value}();
    }
    function ContractWithdrawal(address to,uint amountETH)public{
        require(senderLooks[msg.sender],"No permission to issue additional beb");
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
      
    function getRecord(uint _lsh)public view returns(uint) {
       return UsersDays[_lsh];
    }
    function getWETH()public view returns(uint) {
       return WETH.balance;
    }
}
library TransferHelper {
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}