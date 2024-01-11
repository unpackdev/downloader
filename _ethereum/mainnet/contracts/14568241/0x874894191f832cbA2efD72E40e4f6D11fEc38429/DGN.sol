//SPDX-License-Identifier: MIT
/*    
8 888888888o.           ,o888888o.     b.             8 
8 8888    `^888.       8888     `88.   888o.          8 
8 8888        `88.  ,8 8888       `8.  Y88888o.       8 
8 8888         `88  88 8888            .`Y888888o.    8 
8 8888          88  88 8888            8o. `Y888888o. 8 
8 8888          88  88 8888            8`Y8o. `Y88888o8 
8 8888         ,88  88 8888   8888888  8   `Y8o. `Y8888 
8 8888        ,88'  `8 8888       .8'  8      `Y8o. `Y8 
8 8888    ,o88P'       8888     ,88'   8         `Y8o.` 
8 888888888P'           `8888888P'     8            `Yo 

ERC1155 Builder
Created by DGNs
https://twitter.com/dgn_alpha
*/

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract DGN is ERC1155, Ownable {

    //Used in struct MintInformation.
    enum MintStatus {
        Paused,    //0
        Whitelist, //1
        Public     //2
    }

    //Used after token(s) are set. If paused, no tokens can be minted.
    enum ContractStatus {
        Paused,    //0
        Active     //1
    }

    //maxSupply and publicMintLimit are set in 2 different functions. _setTokenSupply & _setPublicMintLimit.
    struct TokenInformation {
        uint currentSupply;
        uint maxSupply;
        string tokenUri;
    }

    struct MintInformation {
        MintStatus status;
        uint publicMintLimit;
    }   

    string public name;
    string public symbol;
    mapping(uint => TokenInformation) public tokenInfo;
    mapping(uint => MintInformation) public mintInfo;
    mapping(address => uint) public tokenWhitelist;
    //Limits address to publicMintLimit per token.
    mapping(address => mapping(uint256 => uint256)) private addressData;

    ContractStatus private contractStatus = ContractStatus.Paused;

    constructor() ERC1155("") {
        name = "DGN";
        symbol = "DGN";
    } 

    //Public and whitelist mint function.
    function mint(uint _id) public {
        require(msg.sender == tx.origin, "No transaction from smart contracts!"); 
        require(contractStatus != ContractStatus.Paused, "Mint is paused.");
        require(mintInfo[_id].status != MintStatus.Paused, "Mint must be active for specified ID");
        require(tokenInfo[_id].currentSupply + 1 <= tokenInfo[_id].maxSupply, "Must not exceed max supply!");
        if (mintInfo[_id].status == MintStatus.Whitelist) {
            require(tokenWhitelist[msg.sender] == _id, "Must be whitelisted for specified ID");
            tokenWhitelist[msg.sender] = 0;
        } else {
            require(addressData[msg.sender][_id] < mintInfo[_id].publicMintLimit, "Public mint limit reached");
            addressData[msg.sender][_id]++;
        }
        tokenInfo[_id].currentSupply++;
        _mint(msg.sender, _id, 1, "");
    }

    //Batch mint x amount of specified token ID.
    function ownerBatchMint(uint _id, address _to, uint _amount) external onlyOwner {
        require(_amount + tokenInfo[_id].currentSupply <= tokenInfo[_id].maxSupply, "Must not exceed max supply of ID!" );
        tokenInfo[_id].currentSupply += _amount;
         _mint(_to, _id, _amount, "");
    }

    //Sets URI for specified token ID.
    function _setTokenURI(uint _id, string memory _uri) external onlyOwner {
        tokenInfo[_id].tokenUri = _uri;
        emit URI(_uri, _id);
    }

    //Sets whitelist for specified token ID.
    function _setTokenWhitelist(address[] calldata addresses, uint8 _id) external onlyOwner {
        require(tokenInfo[_id].maxSupply != 0, "Cannot set whitelist for token that does not exist.");
        for (uint256 i = 0; i < addresses.length; i++) {
             tokenWhitelist[addresses[i]] = _id;
        }
    }

    /*Set max supply for specified token ID.
    Tokens will not be mintable UNTIL you specify ID and max supply.*/
    function _setTokenSupply(uint _id, uint _maxSupply) external onlyOwner {
        require(tokenInfo[_id].currentSupply < _maxSupply, "Current supply exceeds new supply");
        tokenInfo[_id].maxSupply = _maxSupply; 
    }

    //Sets public mint limit for a specified token ID.
    function _setPublicMintLimit(uint _id, uint _publicMintLimit) external onlyOwner {
        require(tokenInfo[_id].maxSupply != 0, "Cannot set public mint limit for token ID that doesnt exist.");
        mintInfo[_id].publicMintLimit = _publicMintLimit;
    }   

    /*Sets mint info of specified token ID.
    Sets mint status (0: Paused, 1: Whitelist, 2: Public) for specified token ID.*/
    function _setMintInfo(uint _id, MintStatus _status) external onlyOwner {
        mintInfo[_id].status = _status;
    }

    //Sets contract status (0: Paused, 1: Active)
    function _setContractStatus(ContractStatus _status) external onlyOwner {
        contractStatus = _status;
    }

    //Returns URI of specified token ID.
    function getTokenURI(uint _id) public view returns (string memory) {
        return tokenInfo[_id].tokenUri;
    }

    //Returns max supply of specified token ID.
    function getTokenMaxSupply(uint _id) public view returns (uint) {
        return tokenInfo[_id].maxSupply;
    }

    //Returns current supply of specified token ID.
    function getTokenCurrentSupply(uint _id) public view returns (uint) {
        return tokenInfo[_id].currentSupply;
    }

    //Returns publice mint limit of specified token ID.
    function getTokenPublicMintLimit (uint _id) public view returns (uint) {
        return mintInfo[_id].publicMintLimit;
    }
}