contract IOracleFactory {
    address immutable public uniswapV2Factory;
    address immutable public albtAddress;
    address immutable public pairedTokenAddress;
    address immutable public pairedTokenAlbtOracleAddress;

    mapping(address => address) public oracleByToken;

    constructor () {
        uniswapV2Factory = address(0);
        albtAddress = address(0);
        pairedTokenAddress = address(0);
        pairedTokenAlbtOracleAddress = address(0);
    }

    function createOracle (address _userToken) public {}
}