pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

interface OrFeedInterface {
  function getExchangeRate(string calldata fromSymbol, string calldata toSymbol, string calldata venue, uint256 amount) external view returns(uint256);
  function getTokenDecimalCount(address tokenAddress) external view returns(uint256);
  function getTokenAddress(string calldata symbol) external view returns(address);
  function getSynthBytes32(string calldata symbol) external view returns(bytes32);
  function getForexAddress(string calldata symbol) external view returns(address);
  function arb(address fundsReturnToAddress, address liquidityProviderContractAddress, string[] calldata tokens, uint256 amount, string[] calldata exchanges) external payable returns(bool);
}
interface ERC20GasToken {
  function name() external view returns(string memory);
  function freeFromUpTo(address from, uint256 value) external returns(uint256 freed);
  function approve(address spender, uint256 value) external returns(bool success);
  function totalSupply() external view returns(uint256 supply);
  function transferFrom(address from, address to, uint256 value) external returns(bool success);
  function decimals() external view returns (uint8);
  function freeFrom(address from, uint256 value) external returns(bool success);
  function freeUpTo(uint256 value) external returns(uint256 freed);
  function balanceOf(address owner) external view returns(uint256 balance);
  function symbol() external view returns(string memory);
  function mint(uint256 value) external;
  function transfer(address to, uint256 value) external returns(bool success);
  function free(uint256 value) external returns(bool success);
  function allowance(address owner, address spender) external view returns(uint256 remaining);
}
contract arbit3poContractV4 {
    address owner;
    OrFeedInterface orfeed= OrFeedInterface(0x8316B082621CFedAB95bf4a44a1d4B64a6ffc336);
    ERC20GasToken gasToken = ERC20GasToken(0x0000000000b3F879cb30FE243b4Dfee438691c04);
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function withdrawBalance() public onlyOwner returns(bool) {
        uint amount = address(this).balance;
        msg.sender.transfer(amount);
        return true;
    }
    constructor() public payable {
        owner = msg.sender;
    }
    function doAnArb(address _fundsReturnAddress,  address _liquidityAddress, string[] memory _tokens, uint256 _amount, string[] memory _exchanges) public onlyOwner payable returns (bool) {
        bool result = orfeed.arb(_fundsReturnAddress, _liquidityAddress, _tokens, _amount, _exchanges);
        if(gasToken.balanceOf(address(this)) > 0) {
            gasToken.freeFromUpTo(address(this), gasToken.balanceOf(address(this)));
        }
        return result;
    }
    function getExchangeRate(string memory _base, string memory _to, string memory _exchange, uint _amount) public view returns(uint) {
        return orfeed.getExchangeRate(_base, _to, _exchange, _amount);
    }
}