// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC1155Upgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./Token.sol";

interface IPuzzLR {
    function mintBatch(uint[] memory ids, uint[] memory quantities) external;
    function purchaseAssets(address sender, uint[] calldata assetId) external;
    function setPrice(uint price) external;
}

contract PuzzLR is  ERC1155Upgradeable, ERC1155HolderUpgradeable, UUPSUpgradeable, OwnableUpgradeable   {
    IToken token;
    address public minter;
    address public deployerAddress;
    uint public price;
    uint public latestTokenId;
    string public name;
    string public symbol;

    function initialize(string memory _name, string memory _symbol, address _tokenContractAddress, string memory _uri) external initializer{
        __ERC1155_init(_uri);
        __Ownable_init();
        __UUPSUpgradeable_init();

        name = _name;
        symbol = _symbol;
        token = IToken(_tokenContractAddress);
        minter = msg.sender;
        price = 10 * 10 ** 18;

        deployerAddress = address(this);
    }
   
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner{}
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155ReceiverUpgradeable, ERC1155Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mintBatch(uint[] memory ids, uint[] memory quantities) virtual external onlyOwner 
    {
        require(ids.length == quantities.length, "ERC1155: ids and amounts length mismatch");
        _mintBatch(minter,ids,quantities,""); 

        latestTokenId = ids[ids.length-1];
      
    }
 
    function purchaseAssets(address _sender, uint[] calldata _assets) virtual public
    {
        require(msg.sender == _sender,"Unauthorized");
        require(latestTokenId > 0, "PUZZLR Unavailable");

        uint sum = _assets.length * price;
        require(token.balanceOf(_sender) >= sum,"PZLR Insufficient");

        uint[] memory amounts = new uint[](_assets.length);

        for(uint x=0;x<_assets.length;x++)
        {
            require(balanceOf(minter,_assets[x]) > 0, "Unavailable");
            amounts[x] = 1;
        }

        token.transferFrom(msg.sender, address(this), sum);
        
        safeBatchTransferFrom(minter, _sender, _assets, amounts,"0x0");
   }
   
    function setPrice(uint _price) virtual external onlyOwner {
       price = _price * 10 ** 18;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (_msgSender() == token.getUtilityAccount())
            _setApprovalForAll(minter, operator, approved);
        else
            ERC1155Upgradeable.setApprovalForAll(operator, approved);
    }

}