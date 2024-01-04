pragma solidity 0.5.13;

interface IERC20Dai {
    //   function allowance(address owner, address spender) external view returns (uint256);
      function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
      function approve(address _spender, uint256 _amount) external returns (bool);
}

interface IAlternateReceiverBridge {
    function relayTokens(address _sender, address _receiver, uint256 _amount) external;
    // function withinLimit(uint256 _amount) external view returns (bool);
 }

interface IRCProxyXdai {}

contract TestRCProxyMainnet 
{
    
    IERC20Dai public dai;
    IAlternateReceiverBridge public alternateReceiverBridge;
    IRCProxyXdai public proxyXdai;
    
    uint256 internal depositNonce;
    
    event DaiDeposited(address indexed user, uint256 amount, uint256 nonce);
    
    constructor() public {
        alternateReceiverBridge = IAlternateReceiverBridge(0x4aa42145Aa6Ebf72e164C9bBC74fbD3788045016);
        dai = IERC20Dai(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        dai.approve(address(alternateReceiverBridge), 2**256 - 1);
    }
    
    function setProxyXdai(address _address) public {
        proxyXdai = IRCProxyXdai(_address);
    }
    
    function depositDai(uint256 _amount) external {
        _depositDai(_amount, msg.sender); 
    }

    function _depositDai(uint256 _amount, address _sender) internal {
        // require(dai.allowance(_sender, address(this)) >= _amount, "Token allowance not high enough");
        // require(alternateReceiverBridge.withinLimit(_amount), "deposit too low");
        require(dai.transferFrom(_sender, address(this), _amount), "Token transfer failed");
        alternateReceiverBridge.relayTokens(address(this), address(proxyXdai), _amount);
        emit DaiDeposited(_sender, _amount, depositNonce++);
    }
    
}