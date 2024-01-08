// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.3;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./console.sol";
import "./ProxyRegistry.sol";
import "./IRoyalties.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract NFT1687Collection is ERC721Enumerable, Ownable, ReentrancyGuard, AccessControl, IRoyalties {
    using SafeMath for uint256;
    using Address for address;
    using Address for address payable;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public MAX_TOTAL_MINT;
    string private _contractURI;
    string private _placeholderURI;
    string private _baseTokenURI;
    address private _raribleRoyaltyAddress;
    address private _openSeaProxyRegistryAddress;
    uint256 private _currentTokenId = 0;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxTotalMint,
        string memory contractURIStr,
        string memory placeholderURI,
        address raribleRoyaltyAddress,
        address openSeaProxyRegistryAddress
    ) ERC721(name, symbol) {
        MAX_TOTAL_MINT = maxTotalMint;
        _contractURI = contractURIStr;
        _placeholderURI = placeholderURI;
        _raribleRoyaltyAddress = raribleRoyaltyAddress;
        _openSeaProxyRegistryAddress = openSeaProxyRegistryAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // ADMIN
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setContractURI(string memory uri) external onlyOwner {
        _contractURI = uri;
    }

    function setRaribleRoyaltyAddress(address addr) external onlyOwner {
        _raribleRoyaltyAddress = addr;
    }

    function setOpenSeaProxyRegistryAddress(address addr) external onlyOwner {
        _openSeaProxyRegistryAddress = addr;
    }


    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // PUBLIC

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return  string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    function getRaribleV2Royalties(uint256 id) override external view returns (LibPart.Part[] memory result) {
        result = new LibPart.Part[](1);

        result[0].account = payable(_raribleRoyaltyAddress);
        result[0].value = 10000; // 100% of royalty goes to defined address above.
        id; // avoid unused param warning
    }

    function getInfo() external view returns (
        uint256 totalSupply,
        uint256 senderBalance,
        uint256 maxTotalMint
    ) {
        return (
            this.totalSupply(),
            this.balanceOf(msg.sender),
            MAX_TOTAL_MINT
        );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable, AccessControl)
    returns (bool)
    {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
    override
    public
    view
    returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_openSeaProxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
    
   
    function mint(address to, uint256 count)  external onlyOwner {
        // Make sure minting is allowed
        requireMintingConditions(count);

        for (uint256 i = 0; i < count; i++) {
            uint256 newTokenId = _getNextTokenId();
            _safeMint(to, newTokenId);
            _incrementTokenId();
        }
    }


    function transferFromBulk(
        address from,
        address to,
        uint256[] memory tokenIds
    ) public virtual {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            //solhint-disable-next-line max-line-length
            require(_isApprovedOrOwner(_msgSender(), tokenIds[i]), "ERC721: transfer caller is not owner nor approved");
            _transfer(from, to, tokenIds[i]);
        }
    }

    // PRIVATE
    function requireMintingConditions( uint256 count) internal view {
        // Total minted tokens must not exceed maximum supply
        require(totalSupply() + count <= MAX_TOTAL_MINT, "BASE_COLLECTION/EXCEEDS_MAX_SUPPLY");
    }

    /**
     * Calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * Increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId++;
    }
}
