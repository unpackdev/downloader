pragma solidity 0.6.12;

interface IMatchPair {
    
    function stake(uint256 _index, address _user,uint256 _amount) external;  // owner
    function untakeToken(uint256 _index, address _user,uint256 _amount) external returns (uint256 _tokenAmount);// owner
    // function untakeLP(uint256 _index, address _user,uint256 _amount) external returns (uint256);// owner

    function token(uint256 _index) external view  returns (address);

    //token0 - token1 Amount
    //LP0 - LP1 Amount
    // queue Token0 / token1
    function queueTokenAmount(uint256 _index) external view  returns (uint256);
    // max Accept Amount
    function maxAcceptAmount(uint256 _index, uint256 _molecular, uint256 _denominator, uint256 _inputAmount) external view returns (uint256);

}