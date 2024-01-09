/*

    ______     __  __     ______     __         ______     ______   ______                   
   /\  ___\   /\ \_\ \   /\  ___\   /\ \       /\  __ \   /\  == \ /\  ___\                  
   \ \ \____  \ \____ \  \ \ \____  \ \ \____  \ \ \/\ \  \ \  _-/ \ \___  \                 
    \ \_____\  \/\_____\  \ \_____\  \ \_____\  \ \_____\  \ \_\    \/\_____\                
     \/_____/   \/_____/   \/_____/   \/_____/   \/_____/   \/_/     \/_____/                
                                                                                             
    ______   __  __     ______     ______     ______        ______     __   __     ______    
   /\  == \ /\ \_\ \   /\  __ \   /\  ___\   /\  ___\      /\  __ \   /\ "-.\ \   /\  ___\   
   \ \  _-/ \ \  __ \  \ \  __ \  \ \___  \  \ \  __\      \ \ \/\ \  \ \ \-.  \  \ \  __\   
    \ \_\    \ \_\ \_\  \ \_\ \_\  \/\_____\  \ \_____\     \ \_____\  \ \_\\"\_\  \ \_____\ 
     \/_/     \/_/\/_/   \/_/\/_/   \/_____/   \/_____/      \/_____/   \/_/ \/_/   \/_____/


**/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./Strings.sol";

contract Cyclops_Phase1 is ERC1155, AccessControl {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private _contractURI = "https://nftscreen.art/cyclops_phase1/collection";
    string public name;
    string public symbol;
    mapping (uint256 => string) private _uris;
    address a1 = 0x7ea8800bE947d8bD26a6c4e2a2CcFe1890992C03;

    constructor() ERC1155("ipfs://") {
        name = "Cyclops Phase1";
        symbol = "CP1";
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(URI_SETTER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }


    function setContractURI(string memory contractUri) public onlyRole(URI_SETTER_ROLE) {
        _contractURI = contractUri;
    }
    function contractURI() public view returns (string memory)
    {
        return _contractURI;
    }
    function uri(uint256 tokenId) override public view returns (string memory)
    {
        return(_uris[tokenId]);
    }
     function setTokenUri(uint256 tokenId, string memory uRI)
        public onlyRole(URI_SETTER_ROLE)
     {
        _uris[tokenId] = uRI; 
    }

    // mint functions
    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public onlyRole(MINTER_ROLE)
    {
        _mint(account, id, amount, data);
    }
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public onlyRole(MINTER_ROLE)
    {
        _mintBatch(to, ids, amounts, data);
    }

    function withdraw()
    public onlyRole(DEFAULT_ADMIN_ROLE)
    {
        payable(a1).transfer(address(this).balance);
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
