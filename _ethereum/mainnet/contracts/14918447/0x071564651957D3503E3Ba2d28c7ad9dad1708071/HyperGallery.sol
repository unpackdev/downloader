// SPDX-License-Identifier: MIT
/*  
    Hyper Gallery /2022 
*/
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Supply.sol";

abstract contract DemiHolder {
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

abstract contract HFSHolder {
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

abstract contract LootexHolder {
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract HyperGallery is ERC1155, Ownable, ERC1155Supply {

    DemiHolder private demi;
    HFSHolder private hfs;  
    LootexHolder private lootex;

    bool public isMINT1Active = false;
    bool public isMINT2Active = false;
    bool public isMINT3Active = false;
    bool public isMINT4Active = false;
    bool public isMINT5Active = false;
    bool public isMINT6Active = false;
    bool public isMINT7Active = false;
    bool public isMINT8Active = false;
    bool public isMINT9Active = false;

    mapping(address => bool) private _blackList1;
    mapping(address => bool) private _blackList2;
    mapping(address => bool) private _blackList3;
    mapping(address => bool) private _blackList4;
    mapping(address => bool) private _blackList5;
    mapping(address => bool) private _blackList6;
    mapping(address => bool) private _blackList7;
    mapping(address => bool) private _blackList8;
    mapping(address => bool) private _blackList9;

    constructor(address dependentContractAddress1, address dependentContractAddress2, address dependentContractAddress3)
        ERC1155("https://hypersensehuman.io/HyperGallery/{id}.json")
    {   
        demi = DemiHolder(dependentContractAddress1);
        hfs = HFSHolder(dependentContractAddress2);
        lootex = LootexHolder(dependentContractAddress3);
    }

    modifier onlyRealUser() {
    require(msg.sender == tx.origin, "Oops. Something went wrong !");
    _;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint_ep1(address account, bytes memory data)
        public
        onlyRealUser
    {    
        require(isMINT1Active, "MINT is not active");
        require(_blackList1[msg.sender] == false, "You can only mint one time per wallet"); 
         _blackList1[msg.sender] = true;
        _mint(account, 1, 1, data);
    }

    function mint_ep2_alliance(address account, bytes memory data)
        public
        onlyRealUser
    {
        require(isMINT2Active, "MINT is not active");
        require(_blackList2[msg.sender] == false, "You can only mint one time per wallet"); 
        uint hfs_balance = hfs.balanceOf(msg.sender);
        uint demi_balance = demi.balanceOf(msg.sender);
        uint lootex_balance = lootex.balanceOf(msg.sender);
        require(hfs_balance > 0 || demi_balance > 0 || lootex_balance > 0, "You must hold at least one alliance NFT");
         _blackList2[msg.sender] = true;
        _mint(account, 2, 1, data);
    }

    function mint_ep3(address account, bytes memory data)
        public
        onlyRealUser
    {    
        require(isMINT3Active, "MINT is not active");
        require(_blackList3[msg.sender] == false, "You can only mint one time per wallet"); 
         _blackList3[msg.sender] = true;
        _mint(account, 3, 1, data);
    }

    function mint_ep4_alliance(address account, bytes memory data)
        public
        onlyRealUser
    {
        require(isMINT4Active, "MINT is not active");
        require(_blackList4[msg.sender] == false, "You can only mint one time per wallet"); 
        uint hfs_balance = hfs.balanceOf(msg.sender);
        uint demi_balance = demi.balanceOf(msg.sender);
        uint lootex_balance = lootex.balanceOf(msg.sender);
        require(hfs_balance > 0 || demi_balance > 0 || lootex_balance > 0, "You must hold at least one alliance NFT");
         _blackList4[msg.sender] = true;
        _mint(account, 4, 1, data);
    }

    function mint_ep5(address account, bytes memory data)
        public
        onlyRealUser
    {    
        require(isMINT5Active, "MINT is not active");
        require(_blackList5[msg.sender] == false, "You can only mint one time per wallet"); 
         _blackList5[msg.sender] = true;
        _mint(account, 5, 1, data);
    }

    function mint_ep6_alliance(address account, bytes memory data)
        public
        onlyRealUser
    {
        require(isMINT6Active, "MINT is not active");
        require(_blackList6[msg.sender] == false, "You can only mint one time per wallet"); 
        uint hfs_balance = hfs.balanceOf(msg.sender);
        uint demi_balance = demi.balanceOf(msg.sender);
        uint lootex_balance = lootex.balanceOf(msg.sender);
        require(hfs_balance > 0 || demi_balance > 0 || lootex_balance > 0, "You must hold at least one alliance NFT");
         _blackList6[msg.sender] = true;
        _mint(account, 6, 1, data);
    }

    function mint_ep7(address account, bytes memory data)
        public
        onlyRealUser
    {    
        require(isMINT7Active, "MINT is not active");
        require(_blackList7[msg.sender] == false, "You can only mint one time per wallet"); 
         _blackList7[msg.sender] = true;
        _mint(account, 7, 1, data);
    }

    function mint_ep8_alliance(address account, bytes memory data)
        public
        onlyRealUser
    {
        require(isMINT8Active, "MINT is not active");
        require(_blackList8[msg.sender] == false, "You can only mint one time per wallet"); 
        uint hfs_balance = hfs.balanceOf(msg.sender);
        uint demi_balance = demi.balanceOf(msg.sender);
        uint lootex_balance = lootex.balanceOf(msg.sender);
        require(hfs_balance > 0 || demi_balance > 0 || lootex_balance > 0, "You must hold at least one alliance NFT");
         _blackList8[msg.sender] = true;
        _mint(account, 8, 1, data);
    }

    function mint_ep9(address account, bytes memory data)
        public
        onlyRealUser
    {    
        require(isMINT9Active, "MINT is not active");
        require(_blackList9[msg.sender] == false, "You can only mint one time per wallet"); 
         _blackList9[msg.sender] = true;
        _mint(account, 9, 1, data);
    }

    function setMINT1(bool action) public onlyOwner {
    isMINT1Active = action;
    }

    function setMINT2(bool action) public onlyOwner {
    isMINT2Active = action;
    }

    function setMINT3(bool action) public onlyOwner {
    isMINT3Active = action;
    }

    function setMINT4(bool action) public onlyOwner {
    isMINT4Active = action;
    }

    function setMINT5(bool action) public onlyOwner {
    isMINT5Active = action;
    }

    function setMINT6(bool action) public onlyOwner {
    isMINT6Active = action;
    }

    function setMINT7(bool action) public onlyOwner {
    isMINT7Active = action;
    }

    function setMINT8(bool action) public onlyOwner {
    isMINT8Active = action;
    }

    function setMINT9(bool action) public onlyOwner {
    isMINT9Active = action;
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }
  
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
