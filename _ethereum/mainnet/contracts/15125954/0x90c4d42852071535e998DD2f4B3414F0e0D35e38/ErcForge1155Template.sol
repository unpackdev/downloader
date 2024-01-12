/*
 /$$$$$$$$                     /$$$$$$$$                                          /$$          
| $$_____/                    | $$_____/                                         |__/          
| $$        /$$$$$$   /$$$$$$$| $$     /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$      /$$  /$$$$$$ 
| $$$$$    /$$__  $$ /$$_____/| $$$$$ /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$    | $$ /$$__  $$
| $$__/   | $$  \__/| $$      | $$__/| $$  \ $$| $$  \__/| $$  \ $$| $$$$$$$$    | $$| $$  \ $$
| $$      | $$      | $$      | $$   | $$  | $$| $$      | $$  | $$| $$_____/    | $$| $$  | $$
| $$$$$$$$| $$      |  $$$$$$$| $$   |  $$$$$$/| $$      |  $$$$$$$|  $$$$$$$ /$$| $$|  $$$$$$/
|________/|__/       \_______/|__/    \______/ |__/       \____  $$ \_______/|__/|__/ \______/ 
                                                          /$$  \ $$                            
                                                         |  $$$$$$/                            
                                                          \______/                             
*/
//SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Pausable.sol";
import "./Context.sol";
import "./IErcForgeInitiable.sol";

contract ErcForge1155Template is Context, ERC1155Burnable, ERC1155Pausable, IErcForgeInitiable  {
    address public owner;

    string public name;
    string public symbol;    
    string public contractUri; 

    bool private _isInitDone = false;
    
    mapping(uint256 => uint256) private _tokenSupply;
    mapping(uint256 => uint256) private _tokenPrice;

    constructor() ERC1155("") {
        _isInitDone = true;
    }

    function init(
            address newOwner, 
            string memory newName, 
            string memory newSymbol, 
            string memory newUri, 
            string memory newContractUri) public override {         
        require(!_isInitDone, "Init was already done");      

        _setURI(newUri);
        name = newName;
        symbol = newSymbol;
        contractUri = newContractUri;        
        owner = newOwner;
        _isInitDone = true;
    }

    function setUri(
        string memory newUri
    ) public {
        require(_msgSender() == owner, "Not owner");
        _setURI(newUri);
    }

    function setContractURI(
        string memory newUri
    ) public {
        require(_msgSender() == owner, "Not owner");
        contractUri = newUri;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function setOwner(
        address newOwner
    ) public {
        require(_msgSender() == owner, "Not owner");
        owner = newOwner;
    }

    function setTokenPriceAndSupply(
        uint256[] memory ids,
        uint256[] memory prices,
        uint256[] memory supply
    ) public {
        require(_msgSender() == owner, "Not owner");
        require(ids.length == prices.length && ids.length == supply.length, "Array length mismatch");

        for (uint256 i = 0; i < ids.length; i++) {
            _tokenPrice[ids[i]] = prices[i];
            _tokenSupply[ids[i]] = supply[i];
        }
    }

    function getTokenPrices(
        uint256[] memory ids
    ) public view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            prices[i] = _tokenPrice[ids[i]];
        }
        return prices;
    }

    function getTokenSupply(
        uint256[] memory ids
    ) public view returns (uint256[] memory) {
        uint256[] memory supply = new uint256[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            supply[i] = _tokenSupply[ids[i]];
        }
        return supply;
    }

    function mint(
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public payable virtual {
        require(ids.length == amounts.length, "Array length mismatch");

        uint256 value = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            require(_tokenSupply[ids[i]] >= amounts[i], "Not enough supply");
            require(amounts[i] != 0, "Amount can not be zero");
            value += (_tokenPrice[ids[i]] * amounts[i]);
            _tokenSupply[ids[i]] -= amounts[i];
        }
        require(msg.value >= value, "Not enough eth");

        _mintBatch(_msgSender(), ids, amounts, data);
    }

    function airdrop (
        address[] memory to,
        uint256[] memory id,        
        uint256[] memory amount
    ) public virtual {
        require(_msgSender() == owner, "Not owner");
        require(to.length == id.length && to.length == amount.length, "Array length mismatch");

        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], id[i], amount[i], "");
        }
    }

    /**
     * @dev Pauses all token transfers.
     */
    function pause() public virtual {
        require(_msgSender() == owner, "Not owner");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     */
    function unpause() public virtual {
        require(_msgSender() == owner, "Not owner");
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }


    function withdraw() public {
        require(_msgSender() == owner, "Not owner");
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
