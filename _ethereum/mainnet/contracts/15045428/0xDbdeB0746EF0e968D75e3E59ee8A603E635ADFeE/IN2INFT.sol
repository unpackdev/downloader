//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract OurHouseNFT is ERC721URIStorage, Ownable, ERC721Enumerable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _VIPtokens;

    address payable private _owner;
    uint256 public maxSupply = 1980; 
    uint256 public VIPSupply = 150;

    uint256 private price = 150000000000000000; // 0.15 Ether

    //structure for containing contract status
    struct ContractStatus {
        bool isActive;
        bool isPublic;
    }
    //if sale is not active, minting is blocked
    bool public isSaleActive = true;
    //if sale is not public, whitelisting is required.
    bool public isSalePublic = false;

    address OurHouseVault = 0xB059B2b5C9c33708A6e0360e4b6E9c60feBF8024;
    address OurHouse = 0x83f1448F5E82025AFa7e924bDCfC797A89282a57;

    //Admin and whitelist
    address[] whitelist;
    address[] admins;
    address[] superAdmins;

    //URI containing preview metadata
    string previewURI = "https://ipfs.io/ipfs/QmQz77orjqB4pgD9W7XmZvFnbTLPeHjewYXX4r6CNDBgcZ/oh/mdata.json";

    function findAddress(address _address, address[] storage arr)
        internal
        view
        returns (int256)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (_address == arr[i]) {
                return int256(i);
            }
        }
        return -1;
    }

    function remove(uint256 index, address[] storage arr) internal {
        arr[index] = arr[arr.length - 1];
        arr.pop();
    }

    constructor() ERC721("Our House NFT", "OHG") {
        superAdmins.push(owner());
        admins.push(owner());
        superAdmins.push(OurHouse);
        admins.push(OurHouse);
    }

    //First layer of Security, using super admins to use specific functions
    function addSuperAdmin(address adminAddress) public onlyOwner {
        superAdmins.push(adminAddress);
        admins.push(adminAddress);
    }

    function addSuperAdmins(address[] memory adminAddresses) public onlyOwner {
        if (adminAddresses.length > 0) {
            for (uint256 i = 0; i < adminAddresses.length; i++) {
                superAdmins.push(adminAddresses[i]);
                admins.push(adminAddresses[i]);
            }
        }
    }

    function deleteSuperAdmin(address adminAddress) public onlyOwner {
        int256 superAdminIndex = findAddress(adminAddress, superAdmins);
        if (superAdminIndex != -1) {
            remove(uint256(superAdminIndex), superAdmins);
        }
        int256 adminIndex = findAddress(adminAddress, admins);
        if (adminIndex != -1) {
            remove(uint256(adminIndex), admins);
        }
    }

    function verifySuperAdmin(address adminAddress) public view returns (bool) {
        return findAddress(adminAddress, superAdmins) != -1;
    }

    function listSuperAdmin() public view returns (address[] memory) {
        return superAdmins;
    }

    modifier isSuperAdmin(address adminAddress) {
        require(
            verifySuperAdmin(adminAddress),
            "You need to have admin priviliges"
        );
        _;
    }

    //Second layer of Security, using admins for whitelisting and also controlling the sale properties
    function addAdmin(address adminAddress) public isSuperAdmin(msg.sender) {
        admins.push(adminAddress);
    }

    function addAdmins(address[] memory adminAddresses)
        public
        isSuperAdmin(msg.sender)
    {
        if (adminAddresses.length > 0) {
            for (uint256 i = 0; i < adminAddresses.length; i++) {
                admins.push(adminAddresses[i]);
            }
        }
    }

    function deleteAdmin(address adminAddress) public isSuperAdmin(msg.sender) {
        int256 adminIndex = findAddress(adminAddress, admins);
        if (adminIndex != -1) {
            remove(uint256(adminIndex), admins);
        }
    }

    function verifyAdmin(address adminAddress) public view returns (bool) {
        return findAddress(adminAddress, admins) != -1;
    }

    function listAdmins() public view returns (address[] memory) {
        return admins;
    }

    modifier isAdmin(address adminAddress) {
        require(verifyAdmin(adminAddress), "You need to have admin priviliges");
        _;
    }

    //Code for implementation of whitelisting
    function addUser(address _addressToWhitelist) public isAdmin(msg.sender) {
        whitelist.push(_addressToWhitelist);
    }

    function addUsers(address[] memory _WhitelistedAddresses)
        public
        isAdmin(msg.sender)
    {
        if (_WhitelistedAddresses.length > 0) {
            uint256 i = 0;
            for (i = 0; i < _WhitelistedAddresses.length; i++) {
                whitelist.push(_WhitelistedAddresses[i]);
            }
        }
    }

    function deleteUser(address _whitelistedAddress)
        public
        isAdmin(msg.sender)
    {
        int256 whitelistIndex = findAddress(_whitelistedAddress, whitelist);
        if (whitelistIndex != -1) {
            remove(uint256(whitelistIndex), whitelist);
        }
    }

    function verifyUser(address _whitelistedAddress)
        public
        view
        returns (bool)
    {
        return findAddress(_whitelistedAddress, whitelist) != -1;
    }

    function listUsers() public view returns (address[] memory) {
        return whitelist;
    }

    // smartcontract selling status
    function flipSaleStatus() public isAdmin(msg.sender) {
        isSaleActive = !isSaleActive;
    }

    //Set sale to public or private
    function flipSaleAccessibility() public isAdmin(msg.sender) {
        isSalePublic = !isSalePublic;
    }

    //Get both sale status values
    function getContractStatus() public view returns (ContractStatus memory) {
        ContractStatus memory cs = ContractStatus(isSaleActive, isSalePublic);
        return cs;
    }

    function updatePrice(uint256 updatedPrice) public isSuperAdmin(msg.sender) {
        price = updatedPrice;
    }

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    function getOwner() public view returns (address) {
        return owner();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(OurHouseVault).transfer(balance);
    }

    function safeMint() public payable returns (uint256) {
        uint256 tokenId = _tokenIds.current();
        require(
            verifyUser(msg.sender) || isSalePublic,
            "You need to be whitelisted or wait for the minting to go public"
        );
        require(msg.value >= price, "Not enough funds sent.");
        require(isSaleActive, "Sale is not active");
        require(totalSupply() < maxSupply, "All tokens are minted!");
        _tokenIds.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(
            tokenId,
            previewURI
        );
        return tokenId;
    }

    function _premiumMint() private returns (uint256) {
        uint256 tokenId = _tokenIds.current();
        require(_VIPtokens.current() < VIPSupply, "Sale is not active");
        require(totalSupply() < maxSupply, "All tokens are minted!");
        _tokenIds.increment();
        _VIPtokens.increment();
        _safeMint(OurHouseVault, tokenId);
        _setTokenURI(
            tokenId,
            previewURI
        );
        return tokenId;
    }

    function premiumMint(uint256 NumOfTokens)
        public
        isSuperAdmin(msg.sender)
        returns (uint256[] memory)
    {
        uint256[] memory outlist = new uint256[](NumOfTokens);
        if (NumOfTokens > 0) {
            for (uint256 i = 0; i < NumOfTokens; i++) {
                outlist[i] = _premiumMint();
            }
        }
        return outlist;
    }

    function updateURI(uint256 tokenid, string memory tokenuri) public isSuperAdmin(msg.sender) {
        _setTokenURI(tokenid,tokenuri);
    }

    function updateURIs(uint256 start, uint256 len, string[] memory uris)
        public
        isSuperAdmin(msg.sender)
    {
        if (len > 0 ) {
            for (uint256 i = 0; i < len; i++) {
                _setTokenURI(i+start, uris[i] );
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function transferOwnership(address newOwner)
        public
        override(Ownable)
        onlyOwner
    {
        newOwner = OurHouse;
        _transferOwnership(newOwner);
    }

}
