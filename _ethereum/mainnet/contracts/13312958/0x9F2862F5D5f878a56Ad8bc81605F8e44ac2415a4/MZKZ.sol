//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                                                                                                                                                               
// MMMMMMMM               MMMMMMMM ZZZZZZZZZZZZZZZZZZZ KKKKKKKKK    KKKKKKK ZZZZZZZZZZZZZZZZZZZ
// M:::::::M             M:::::::M Z:::::::::::::::::Z K:::::::K    K:::::K Z:::::::::::::::::Z
// M::::::::M           M::::::::M Z:::::::::::::::::Z K:::::::K    K:::::K Z:::::::::::::::::Z
// M:::::::::M         M:::::::::M Z:::ZZZZZZZZ:::::Z  K:::::::K   K::::::K Z:::ZZZZZZZZ:::::Z 
// M::::::::::M       M::::::::::M ZZZZZ     Z:::::Z   KK::::::K  K:::::KKK ZZZZZ     Z:::::Z  
// M:::::::::::M     M:::::::::::M         Z:::::Z       K:::::K K:::::K            Z:::::Z    
// M:::::::M::::M   M::::M:::::::M        Z:::::Z        K::::::K:::::K            Z:::::Z     
// M::::::M M::::M M::::M M::::::M       Z:::::Z         K:::::::::::K            Z:::::Z      
// M::::::M  M::::M::::M  M::::::M      Z:::::Z          K:::::::::::K           Z:::::Z       
// M::::::M   M:::::::M   M::::::M     Z:::::Z           K::::::K:::::K         Z:::::Z        
// M::::::M    M:::::M    M::::::M    Z:::::Z            K:::::K K:::::K       Z:::::Z         
// M::::::M     MMMMM     M::::::M ZZZ:::::Z     ZZZZZ KK::::::K  K:::::KKK ZZZ:::::Z     ZZZZZ
// M::::::M               M::::::M Z::::::ZZZZZZZZ:::Z K:::::::K   K::::::K Z::::::ZZZZZZZZ:::Z
// M::::::M               M::::::M Z:::::::::::::::::Z K:::::::K    K:::::K Z:::::::::::::::::Z
// M::::::M               M::::::M Z:::::::::::::::::Z K:::::::K    K:::::K Z:::::::::::::::::Z
// MMMMMMMM               MMMMMMMM ZZZZZZZZZZZZZZZZZZZ KKKKKKKKK    KKKKKKK ZZZZZZZZZZZZZZZZZZZ
                                                                                                                                                                                
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ERC721WithRoyalties.sol";
import "./BaseOpenSea.sol";

contract MZKZ is ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable, BaseOpenSea, ERC721WithRoyalties {

    mapping(address => bool) public approvedMinters;
    event PermanentURI(string _value, uint256 indexed _id);
    string public baseURI;

    constructor(
        string memory name_, 
        string memory symbol_,
        string memory contractURI_,
        address openseaProxyRegistry_,
        address royaltyRecipient_,
        uint256 royaltyValue_
    ) ERC721(name_, symbol_) {
        // set contract uri if present
        if (bytes(contractURI_).length > 0) {
            _setContractURI(contractURI_);
        }

        // set OpenSea proxyRegistry for gas-less trading if present
        if (address(0) != openseaProxyRegistry_) {
            _setOpenSeaRegistry(openseaProxyRegistry_);
        }

        // set Royalties on the contract
        if (address(0) != royaltyRecipient_) {
            _setRoyalties(royaltyRecipient_, royaltyValue_);
        }
    }

    modifier onlyMinter {
        require(approvedMinters[msg.sender], "Sender not approved to mint");
        _;
    }

    function updateMinter (address minter, bool canMint) public onlyOwner {
        approvedMinters[minter] = canMint;
    }

    /// @notice Allows the setting of royalties on the contract
    /// @param recipient the royalties recipient
    function setRoyaltiesRecipient(address recipient) public onlyOwner {
        _setRoyaltiesRecipient(recipient);
    }

    function mintTo(address recipient, uint256 tokenId, string memory uri) public onlyMinter {
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, uri);
        emit PermanentURI(uri, tokenId);
    }

    /// @notice Helper for the owner of the contract to set the new contract URI
    /// @dev needs to be owner
    /// @param contractURI_ new contract URI
    function setContractURI(string memory contractURI_) external onlyOwner {
        _setContractURI(contractURI_);
    }

    /// @notice Allows gas-less trading on OpenSea by safelisting the ProxyRegistry of the user
    /// @dev Override isApprovedForAll to check first if current operator is owner's OpenSea proxy
    /// @inheritdoc	ERC721
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // allows gas less trading on OpenSea
        return super.isApprovedForAll(owner, operator) || isOwnersOpenSeaProxy(owner, operator);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
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

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721, ERC721WithRoyalties)
        returns (bool)
    {
        return
            // either ERC721Enumerable
            ERC721Enumerable.supportsInterface(interfaceId) ||
            // or Royalties
            ERC721WithRoyalties.supportsInterface(interfaceId);
    }
}

