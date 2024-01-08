pragma solidity =0.6.6;

import "./Oracle.sol";

contract OracleFactory {
    address immutable public uniswapV2Factory;
    address immutable public albtAddress;
    address immutable public pairedTokenAddress;
    address immutable public pairedTokenAlbtOracleAddress;

    mapping(address => address) public oracleByToken;

    /**
     * @dev Constructor defining the initial configuration
     * @param _uniswapV2Factory Uniswap V2 Factory address
     * @param _albtAddress Address of ALBT token
     * @param _pairedTokenAddress Third token, to be compared to ALBT & user's token to calculate the decentralized price
     */
    constructor (address _uniswapV2Factory, address _albtAddress, address _pairedTokenAddress) public {
        require(_uniswapV2Factory != address(0), "UniswapV2Factory address undefined");
        require(_albtAddress != address(0), "ALBT token address undefined");
        require(_pairedTokenAddress != address(0), "Paired token address undefined");

        uniswapV2Factory = _uniswapV2Factory;
        albtAddress = _albtAddress;
        pairedTokenAddress = _pairedTokenAddress;

        pairedTokenAlbtOracleAddress = address(
            new Oracle(_uniswapV2Factory, _albtAddress, _pairedTokenAddress)
        );
    }

    function createOracle (address _userToken) public returns (address) {
        require(oracleByToken[_userToken] == address(0), "Oracle already exists");

        Oracle newOracle = new Oracle(uniswapV2Factory, pairedTokenAddress, _userToken);
        address newOracleAddress = address(newOracle);

        oracleByToken[_userToken] = newOracleAddress;

        return newOracleAddress;
    }
}