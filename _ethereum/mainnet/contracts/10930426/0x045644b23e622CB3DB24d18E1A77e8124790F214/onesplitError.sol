/**
 *Submitted for verification at Etherscan.io on 2020-09-19
*/

pragma solidity ^0.5.17;


interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract onesplitError {
    
    uint public out_uin = 400 ether;

    
    function set_outuin(uint _uin) public{
        require(msg.sender == 0x000000004fa9e635dBe91C83aEe357d01494936D,'not owner');
        out_uin = _uin;
    }
    
    
    function getExpectedReturn(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        external
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        ){
            uint[] memory _distribution;
            returnAmount = 1;
            distribution = _distribution;
        }
        
    function swap(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 flags
    )
        external
        payable
        returns(uint256 returnAmount){
           require(1==2,"no!");
        }
}