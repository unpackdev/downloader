pragma solidity 0.5.13;

interface IERC20Dai {
      function allowance(address owner, address spender) external view returns (uint256);
      function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
}

interface IAlternateReceiverBridge {
    function relayTokens(address _sender, address _receiver, uint256 _amount) external;
    function withinLimit(uint256 _amount) external view returns (bool);
}

interface IRCProxyXdai {}

contract TestRCProxyMainnet 
{
    
    IERC20Dai public dai;
    IAlternateReceiverBridge public alternateReceiverBridge;
    IRCProxyXdai public proxyXdai;
    
    uint256 internal depositNonce;
    
    event DaiDeposited(address indexed user, uint256 amount, uint256 nonce);
    
    constructor(address _alternateReceiverAddress, address _proxyXdaiAddress) public {
        alternateReceiverBridge = IAlternateReceiverBridge(_alternateReceiverAddress);
        proxyXdai = IRCProxyXdai(_proxyXdaiAddress);
    }
    
    function depositDai(uint256 _amount) external {
        _depositDai(_amount, msg.sender); 
    }

    function permitAndDepositDai(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s, uint256 _amount) external {
        require(allowed, "only possible if allowance is set");
        dai.permit(holder, spender, nonce, expiry, allowed, v, r, s);
        _depositDai(_amount, holder);
    }

    function _depositDai(uint256 _amount, address _sender) internal {
        require(dai.allowance(_sender, address(alternateReceiverBridge)) >= _amount, "Token allowance not high enough");
        require(alternateReceiverBridge.withinLimit(_amount), "deposit not within bridge limits");

        alternateReceiverBridge.relayTokens(_sender, address(proxyXdai), _amount);

        emit DaiDeposited(_sender, _amount, depositNonce++);
    }
    
}