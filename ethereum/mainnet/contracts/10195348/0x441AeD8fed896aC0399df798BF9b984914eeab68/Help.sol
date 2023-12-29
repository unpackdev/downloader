pragma solidity ^0.6.8;

interface USDContract{
    function primary() external view returns (address payable);
    function pricerAddress() external view returns (address payable);
    function cancelRequest(bytes32 myid) external;
}

contract Secondary{
    
    address payable private USDcontractAddress = 0xD2d01dd6Aa7a2F5228c7c17298905A7C7E1dfE81;
    
    function primary() internal view returns (address payable) {
        return USDContract(USDcontractAddress).primary();
    }
    
    function pricerAddress() internal view returns (address payable) {
        return USDContract(USDcontractAddress).pricerAddress();
    }
    
}

interface token {
    function balanceOf(address input) external returns (uint256);
    function transfer(address input, uint amount) external;
}

contract Help is Secondary{

    function getLostMoney(bytes32 requestId) public {
        USDContract(pricerAddress()).cancelRequest(requestId);
    }
    
    function getStuckETH() public {
        primary().transfer(address(this).balance);
    }
    
    function getStuckTokens(address _tokenAddress) public {
        token(_tokenAddress).transfer(primary(), token(_tokenAddress).balanceOf(address(this)));
    }

}