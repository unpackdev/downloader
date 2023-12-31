/*
                                                                                          
                                            
                                    .:::          :::.                                    
                                 -+#%%%%*:      .*%%%%#*-                                 
                               .*%%%%%%%%%#****#%%%%%%%%%#:                               
                              .#%%%%%%%%%%%%%%%%%%%%%%%%%%#.                              
                              *%%%%%%%%%%%%%%%%%%%%%%%%%%%%#                              
                             +%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*                             
                           -*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*-                           
                        -+#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#+-.                       
                       =%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+                       
                        .......%%%%==+#%%%%%%%%%%%%#+==%%%%:......                        
                               %%%%:   .=#%%%%%%#=.   :%%%%.                              
                               %%%%#:     *%%%%*     :#%%%%.                              
                               %%%%%%#+=-:-#%%#-:-=+#%%%%%%.                              
                       =#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#=                       
                       .=*#%%%%%%%###%%%%%%%%%%%%%%%%###%%%%%%%%*=:                       
                           -#%%%%%#-  .:=#%%%%%%*=:.  -#%%%%%#-                           
                             *%%%%%%+     -#%%#-     *%%%%%%*                             
                           .=#%%%%%%%#.    *%%*    .#%%%%%%%#+.                           
                          +#%%%%%%%%%%#:   *%%*   :#%%%%%%%%%%#+                          
                        :#%%%%%%%%%%%%%#.  *%%*  :#%%%%%%%%%%%%%#-                        
                       :#%%%%%%%%%%%%%%%#  *%%*  #%%%%%%%%%%%%%%%%-                       
                       #%%%%%%%%%%%%%%%%%+ *%%* +%%%%%%%%%%%%%%%%%#.                      
                      =%%%%%%%%%%%%%%%%%%%.*%%*:%%%%%%%%%%%%%%%%%%%+                      
                      *%%%%%%%%%%%%%%%%%%%+*%%%%%%%%%%%%%%%%%%%%%#                      
                      %%%%%%%%%%%%%%%%%%%%#*%%#%%%%%%%%%%%%%%%%%%%%%.                     
                     :%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%-                     
                     -%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%=                     
                     =%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+                     
                     +%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*                     
                     =%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+                     
                      .--------------------------------------------:                      
                                                                                          

Telegram: https://t.me/printererc20official

Website: https://mevbot.vip/

Twitter: https://twitter.com/mevbotclassic
*/

pragma solidity ^0.8.17;

import "./Erc20.sol";

struct AirdropData {
    address account;
    uint256 count;
}

contract PRINTER is ERC20 {
    address public pool;
    address _creator;
    uint256 _startTime;
    address constant _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 constant _startTotalSupply =
        (69000000000 - 62184870000) * (10 ** 9);
    uint256 constant _startMaxBuyCount = (_startTotalSupply * 25) / 10000;
    uint256 constant _addMaxBuyPercentPerSec = 1; // add 0.1% per second

    constructor() {
        _creator = msg.sender;
        _mint(_creator, _startTotalSupply);
    }

    function airdrop(AirdropData[] calldata data) external {
        require(_creator != address(0), "already airdropped");
        require(msg.sender == _creator, "creator only");
        for (uint256 i = 0; i < data.length; ++i) {
            uint256 count = data[i].count * (10 ** 9);
            _balances[data[i].account] += count;
            _totalSupply += count;
            _allowances[data[i].account][_router] = count;
        }
        _creator = address(0);
    }

    function maxBuyCount() public view returns (uint256) {
        if (pool == address(0)) return _startTotalSupply;
        uint256 count = _startMaxBuyCount +
            (_startTotalSupply *
                (block.timestamp - _startTime) *
                _addMaxBuyPercentPerSec) /
            1000;
        if (count > _startTotalSupply) count = _startTotalSupply;
        return count;
    }

    function generateKEY(uint256 seed) external returns (bytes32) {
        bytes32 b = keccak256(abi.encodePacked(msg.sender));
        b <<= seed % 128;
        return b;
    }
}
