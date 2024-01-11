// SPDX-License-Identifier: MIT
//
// ██╗  ██╗ █████╗ ██████╗ ██████╗ ██╗   ██╗                                         
// ██║  ██║██╔══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝                                         
// ███████║███████║██████╔╝██████╔╝ ╚████╔╝                                          
// ██╔══██║██╔══██║██╔═══╝ ██╔═══╝   ╚██╔╝                                           
// ██║  ██║██║  ██║██║     ██║        ██║                                            
// ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝        ╚═╝                                            
//                                                                                   
// ███████╗███╗   ██╗ ██████╗██████╗ ██╗   ██╗██████╗ ████████╗██╗ ██████╗ ███╗   ██╗
// ██╔════╝████╗  ██║██╔════╝██╔══██╗╚██╗ ██╔╝██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
// █████╗  ██╔██╗ ██║██║     ██████╔╝ ╚████╔╝ ██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║
// ██╔══╝  ██║╚██╗██║██║     ██╔══██╗  ╚██╔╝  ██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║
// ███████╗██║ ╚████║╚██████╗██║  ██║   ██║   ██║        ██║   ██║╚██████╔╝██║ ╚████║
// ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
//                                                                                   
//  █████╗     ██████╗ ██╗████████╗    ███████╗ ██████╗ ██╗   ██╗███╗   ██╗██████╗   
// ██╔══██╗    ██╔══██╗██║╚══██╔══╝    ██╔════╝██╔═══██╗██║   ██║████╗  ██║██╔══██╗  
// ╚█████╔╝    ██████╔╝██║   ██║       ███████╗██║   ██║██║   ██║██╔██╗ ██║██║  ██║  
// ██╔══██╗    ██╔══██╗██║   ██║       ╚════██║██║   ██║██║   ██║██║╚██╗██║██║  ██║  
// ╚█████╔╝    ██████╔╝██║   ██║       ███████║╚██████╔╝╚██████╔╝██║ ╚████║██████╔╝  
//  ╚════╝     ╚═════╝ ╚═╝   ╚═╝       ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═════╝   
//
pragma solidity ^0.8.15;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract HappyEncryption is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    using Strings for uint;

    uint256 public constant defaultMaxSupply = 1000;
    mapping(uint256 => uint256) public maxSupplies;

    mapping(uint256 => string) public tokenURIs;

    address public royaltyReceiver;
    uint256 public constant secondarySaleRoyalty = 10_00000; // 10.0%
    uint256 public constant modulo = 100_00000; // precision 100.00000%

    constructor() ERC1155("") {
        royaltyReceiver = msg.sender;
    }

    function setMaxSupply(uint256 id, uint256 maxSupply) public onlyOwner {
        require(maxSupplies[id] == 0, "Already set");
        maxSupplies[id] = maxSupply;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _setURI(uri);
    }

    function setTokenURI(uint256 id, string memory uri) public onlyOwner {
        tokenURIs[id] = uri;
        emit URI(uri, id);
    }

    function baseURI() public view virtual returns (string memory) {
        return super.uri(0);
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return _tokenURI(id);
    }

    function _tokenURI(uint256 id) internal view virtual returns (string memory) {
        string memory tokenURI = tokenURIs[id];
        string memory base = baseURI();
        if (bytes(base).length == 0) {
            return tokenURI;
        }
        if (bytes(tokenURI).length > 0) {
            return tokenURI;
        }
        return string(abi.encodePacked(base, id.toString()));
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        require(super.totalSupply(id) + amount <= (maxSupplies[id] > 0 ? maxSupplies[id] : defaultMaxSupply), "Exceed max supply");
        _mint(account, id, amount, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c || // ERC165 Interface ID for ERC1155MetadataURI
            interfaceId == 0x2a55205a; // ERC165 Interface ID for ERC2981
    }

    // ERC-2981
    function royaltyInfo(uint256 /* _tokenId */, uint256 _value) external view returns (address _receiver, uint256 _royaltyAmount) {
        _receiver = royaltyReceiver;
        _royaltyAmount = (_value / modulo) * secondarySaleRoyalty;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
