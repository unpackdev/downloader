// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface IERC20Lite {
    
    function transfer(address to, uint256 value) external returns (bool);
    function burn(address from, uint256 value) external;
    function mint(address to, uint256 value) external; 

}

interface IElfMetaDataHandler {    
function getTokenURI(uint16 id_, uint256 sentinel) external view returns (string memory);
}

interface ICampaigns {
function gameEngine(uint256 _campId, uint256 _sector, uint256 _level, uint256 _attackPoints, uint256 _healthPoints, uint256 _inventory, bool _useItem) external 
returns(uint256 level, uint256 rewards, uint256 timestamp, uint256 inventory);
}

interface ITunnel {
    function sendMessage(bytes calldata message_) external;
}

interface ITerminus {
    function pullCallback(address owner, uint256[] calldata ids) external;
    
}

interface IElves {
    function getSentinel(uint256 _id) external view returns(uint256 sentinel);
    function modifyElfDNA(uint256 id, uint256 sentinel) external;
    function pull(address owner_, uint256[] calldata ids) external;
    function transfer(address to, uint256 id) external;
}

interface IERC721Lite {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

interface IEthernalElves {
function presale(uint256 _reserveAmount, address _whitelister) external payable returns (uint256 id);
}
