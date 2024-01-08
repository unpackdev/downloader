// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



/*

.___       .__                 .__  __                               ___________     __                         
|   | ____ |  |__   ___________|__|/  |______    ____   ____  ____   \__    ___/___ |  | __ ____   ____   ______
|   |/    \|  |  \_/ __ \_  __ \  \   __\__  \  /    \_/ ___\/ __ \    |    | /  _ \|  |/ // __ \ /    \ /  ___/
|   |   |  \   Y  \  ___/|  | \/  ||  |  / __ \|   |  \  \__\  ___/    |    |(  <_> )    <\  ___/|   |  \\___ \ 
|___|___|  /___|  /\___  >__|  |__||__| (____  /___|  /\___  >___  >   |____| \____/|__|_ \\___  >___|  /____  >
         \/     \/     \/                    \/     \/     \/    \/                      \/    \/     \/     \/ 

 @website https://inheritancetokens.com/
 @company ScarceBytes, LLC.

*/

import "./ERC1155PresetMinterPauser.sol";

contract InheritanceToken is ERC1155PresetMinterPauser {
    constructor() public ERC1155PresetMinterPauser("https://inheritancetokens.com/api/inheritance/{id}.json") {}
}