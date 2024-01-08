// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

/** OPENSEA INTERFACES */
/**
 This is a contract that can act on behalf of an Opensea
 user. It's a proxy for the user
 */
contract OwnableDelegateProxy {}

/**
 This represents Opensea's ProxyRegistry contract.
 We use it to find and approve the opensea proxy contract of each 
 user, which allows for better opensea integration like gassless listing etc.
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * Interface for yieldToken future token
 */
interface IYieldToken {
	function updateReward(address _from, address _to, uint256 _tokenId) external;
}

contract HoneyBee is AccessControl, Ownable, ERC721Enumerable {
    using SafeMath for uint256;
    using Strings for uint256;

    IYieldToken public yieldToken;

    string public _name = "Honey Bee Club";
    string public _symbol = "HBC";

    /** ADDRESSES */
    address public openseaProxyRegistryAddress;

    /** NFT DATA */
    string public baseURIString = "";
    string public preRevealBaseURIString = "";
    string public contractURIString = "https://hbc-contract-metadata.s3.amazonaws.com/contract_metadata.json";
    uint256 public nextTokenId = 1;

    /** SCHEDULING */
    uint256 public revealDate = 1640388163;

    /** ROLES */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /** MODIFIERS */

    /** EVENTS */
    event Mint(address to, uint256 amount);
    event ReceivedEther(address sender, uint256 amount);

    constructor(
        address _openseaProxyRegistryAddress
    ) ERC721(_name, _symbol) Ownable() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        openseaProxyRegistryAddress = _openseaProxyRegistryAddress;
    }

    function contractURI() public view returns (string memory) {
        return contractURIString;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURIString = _contractURI;
    }

    /**
    * @dev function to change the baseURI of the metadata
    */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURIString = _newBaseURI;
    }

    /**
    * @dev function to change the preRevealBaseURIString of the metadata
    */
    function setPreRevealURI(string memory _newURI) external onlyOwner {
        preRevealBaseURIString = _newURI;
    }

    function setRevealDate(uint256 date) external onlyOwner {
        revealDate = date;
    }

    function setYieldToken(address _address) external onlyOwner {
        yieldToken = IYieldToken(_address);
    }

    /**
    * @dev returns the baseURI for the metadata. Used by the tokenURI method.
    * @return the URI of the metadata
    */
    function _baseURI() internal override view returns (string memory) {
        return baseURIString;
    }

    /**
     * @dev returns tokenURI of tokenId based on reveal date
     * @return the URI of token tokenid
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (block.timestamp >= revealDate) {
            return super.tokenURI(tokenId);
        } else {
            return string(abi.encodePacked(preRevealBaseURIString, tokenId.toString()));
        }        
    }

     /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721Enumerable) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
    * @dev override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Create an instance of the ProxyRegistry contract from Opensea
        ProxyRegistry proxyRegistry = ProxyRegistry(openseaProxyRegistryAddress);
        // whitelist the ProxyContract of the owner of the NFT
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        if (openseaProxyRegistryAddress == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
    * @dev override msgSender to allow for meta transactions on OpenSea.
    */
    function _msgSender()
        override
        internal
        view
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (address(yieldToken) != address(0))
            yieldToken.updateReward(from, to, tokenId);
    }

    /**
    * @dev function to mint tokens to an address. Only 
    * accessible by accounts with a role of MINTER_ROLE
    * @param amount the amount of tokens to be minted
    * @param _to the address to which the tokens will be minted to
    */
    function mintTo(uint256 amount, address _to) external onlyRole(MINTER_ROLE) {
        for (uint i = 0; i < amount; i++) {
            _safeMint(_to, nextTokenId);
            nextTokenId = nextTokenId.add(1);
        }
        emit Mint(_to, amount);
    }

    /**
     * @dev function to burn token of tokenId. Only
     * accessible by accounts with a role of BURNER_ROLE
     * @param tokenId the tokenId to burn
     */
    function burn(uint256 tokenId) external onlyRole(BURNER_ROLE) {
        _burn(tokenId);
    }

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}