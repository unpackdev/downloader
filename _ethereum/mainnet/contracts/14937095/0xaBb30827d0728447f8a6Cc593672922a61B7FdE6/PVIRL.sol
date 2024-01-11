// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";

/*
* @title ERC1155 token for PV IRL events
*
* @author Niftydude
*/
contract PVIRL is ERC1155Burnable, Ownable  {
    
    struct NoTransferWindow {
        uint256 start;
        uint256 end;
    }

    mapping(uint256 => NoTransferWindow) public noTransferWindows;

    string public name_;
    string public symbol_;         

    constructor(
        string memory _name, 
        string memory _symbol,  
        string memory _uri
    ) ERC1155(_uri)  {
        name_ = _name;
        symbol_ = _symbol;
    }                       

    /**
    * @notice edit no transfer window for a specific token
    * 
    * @param _tokenId the index of the stage to change
    * @param _windowStart UNIX timestamp for window opening time
    * @param _windowEnd UNIX timestamp for window closing time
    */
    function editNoTransferWindow(
        uint256 _tokenId,
        uint256 _windowStart,
        uint256 _windowEnd     
    ) external onlyOwner {   
        noTransferWindows[_tokenId] = NoTransferWindow(_windowStart, _windowEnd);
    }                     

    /**
     * @notice Mints the given amounts of specified token id to specified receiver addresses
     * 
     * @param _receiver the receiving wallets
     * @param _tokenId the token id to mint
     * @param _amount the amounts of tokens to mint
     */
    function mintMany (address[] calldata _receiver, uint256 _tokenId, uint256[] calldata _amount) external onlyOwner {
        for(uint256 i; i < _receiver.length;) {
            _mint(_receiver[i], _tokenId, _amount[i], "");        

            unchecked {
                i++;
            }
        }
    } 

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }      

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    } 

    function uri(uint256 _id) public view override returns (string memory) {            
            return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }    

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for(uint256 i; i < ids.length;) {
            NoTransferWindow memory noTransferWindow = noTransferWindows[ids[i]];
            require(block.timestamp < noTransferWindow.start || block.timestamp > noTransferWindow.end, "token transfer while paused");

            unchecked {i++;}
        }
    }    
}