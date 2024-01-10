//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";

/*
 _    _       _       _      __                     _    _            _     _ 
| |  | |     | |     | |    / _|                   | |  | |          | |   | |
| |  | | __ _| |_ ___| |__ | |_ __ _  ___ ___  ___ | |  | | ___  _ __| | __| |
| |/\| |/ _` | __/ __| '_ \|  _/ _` |/ __/ _ \/ __|| |/\| |/ _ \| '__| |/ _` |
\  /\  / (_| | || (__| | | | || (_| | (_|  __/\__ \\  /\  / (_) | |  | | (_| |
 \/  \/ \__,_|\__\___|_| |_|_| \__,_|\___\___||___(_)/  \/ \___/|_|  |_|\__,_|
                                                                              
                                                                              
______     _            _ _          ______                                   
| ___ \   (_)          (_) |         | ___ \                                  
| |_/ / __ _  ___  _ __ _| |_ _   _  | |_/ /_ _ ___ ___                       
|  __/ '__| |/ _ \| '__| | __| | | | |  __/ _` / __/ __|                      
| |  | |  | | (_) | |  | | |_| |_| | | | | (_| \__ \__ \                      
\_|  |_|  |_|\___/|_|  |_|\__|\__, | \_|  \__,_|___/___/                      
                               __/ |                                          
                              |___/                                           

  https://www.watchfaces.world/ | https://twitter.com/watchfacesworld

*/

contract WatchfacesPriorityPass is ERC1155, Ownable {
    uint256 public totalSupply;
    address public watchfacesContract;
    uint256 private constant TOKEN_ID = 0;

    constructor() ERC1155('https://www.watchfaces.world/api/pass/') {}

    function mint() public payable {
        require(totalSupply < 360, 'No more left');
        require(msg.sender == tx.origin, 'EOAs only');
        require(balanceOf(msg.sender, TOKEN_ID) == 0, 'One per address');
        require(msg.value == 0.036 ether, 'Wrong value');

        unchecked {
            ++totalSupply;
        }
        _mint(msg.sender, TOKEN_ID, 1, '');
    }

    function redeem(address holder) public {
        require(msg.sender == watchfacesContract, 'Should be called from main');
        _burn(holder, TOKEN_ID, 1);
    }

    // Admin

    function setWatchfacesAddress(address newAddress) public onlyOwner {
        watchfacesContract = newAddress;
    }

    function withdrawAll() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
