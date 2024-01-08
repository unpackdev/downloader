
pragma solidity >=0.5.0 <0.7.0;

interface IRegistry {
    
    function get_virtual_price_from_lp_token(address) external view returns(uint256);

}
