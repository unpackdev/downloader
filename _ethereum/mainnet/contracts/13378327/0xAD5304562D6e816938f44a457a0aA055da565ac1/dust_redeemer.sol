pragma solidity ^0.8.0;

interface dust_redeemer {
    function redeem(DustBusterPro memory general) external returns (uint256) ;
    function balanceOf(address token, address vault) external view returns(uint256);
}


struct DustBusterPro {
    string  name;
    address vault;
    address token;
    uint256 random;
    address recipient;
    address handler;
    uint256 position;
    uint256 token_id;
    bool    redeemed;
}