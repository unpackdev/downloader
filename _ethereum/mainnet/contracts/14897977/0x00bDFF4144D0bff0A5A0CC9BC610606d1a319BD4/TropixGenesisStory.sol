// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Address.sol";
import "./IERC2981.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";

/*           
 *      __ _.--..--._ _
 *   .-' _/   _/\_   \_'-.
 *  |__ /   _/\__/\_   \__|
 *     |___/\_\__/  \___|             ╔═══════╗         
 *            \__/                   █|       |█        
 *            \__/                  █           █        
 *             \__/                █    ╔══      █      
 *              \__/               █  ╔╝         █      
 *           ____\__/___           █ ╔╝═══       █      
 *     . - '             ' -.       █           █        
 *    /                      \        @@@@@@@@@        
 *
 * @title ERC721 token for the Tropix Genesis 1-of-1 Story NFTs
 * @author - https://twitter.com/theincubator_
 */
contract TropixGenesisStory is ERC721A, ERC721ABurnable, ERC721AQueryable, Ownable, IERC2981 {
    uint256 public maxSupply;

    string private _baseTokenURI;

    address private _proxyRegistryAddress;
    bool public isOpenSeaProxyActive = true;

    address public royaltiesAddress;
    uint256 public royaltiesBasisPoints;
    uint256 private constant ROYALTY_DENOMINATOR = 10_000;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseTokenURI,
        address proxyRegistryAddress,
        address _royaltiesAddress,
        uint256 _royaltiesBasisPoints,
        uint256 _maxSupply
    ) ERC721A(_name, _symbol) {
        _baseTokenURI = baseTokenURI;
        _proxyRegistryAddress = proxyRegistryAddress;
        royaltiesAddress = _royaltiesAddress;
        royaltiesBasisPoints = _royaltiesBasisPoints;
        maxSupply = _maxSupply;
    }

    function mint(uint256 quantity) external onlyOwner {
        require(quantity + _totalMinted() <= maxSupply, "max supply reached");
        _safeMint(msg.sender, quantity, "");
    }

    function mintTo(address[] calldata receivers, uint256[] calldata quantities) external onlyOwner {
        require(receivers.length == quantities.length, "need to supply an equal amount of receivers and quantities");
        for (uint256 i = 0; i < receivers.length; i++) {
            require(quantities[i] + _totalMinted() <= maxSupply, "max supply reached");
            _safeMint(receivers[i], quantities[i]);
        }
    }

    /**
     * @dev To disable OpenSea gasless listings proxy in case of an issue
     */
    function toggleOpenSeaActive() external onlyOwner {
        isOpenSeaProxyActive = !isOpenSeaProxyActive;
    }

    /**
     * @notice enable OpenSea gasless listings
     * @dev Overriding `isApprovedForAll` to allowlist user's OpenSea proxy accounts
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function setRoyaltiesAddress(address _royaltiesAddress) external onlyOwner {
        royaltiesAddress = _royaltiesAddress;
    }

    function setRoyaltiesBasisPoints(uint256 _royaltiesBasisPoints) external onlyOwner {
        require(_royaltiesBasisPoints < royaltiesBasisPoints, "New royalty amount must be lower");
        royaltiesBasisPoints = _royaltiesBasisPoints;
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Non-existent token");
        return (royaltiesAddress, (salePrice * royaltiesBasisPoints) / ROYALTY_DENOMINATOR);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721A) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner {
        (bool ownerSuccess, ) = msg.sender.call{ value: address(this).balance }("");
        require(ownerSuccess, "unable to send owner value, recipient may have reverted");
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        if (_totalMinted() > 0) {
            require(newMaxSupply < maxSupply, "can't raise the max supply once the mint has started");
        }
        require(_totalMinted() != maxSupply, "max supply already reached");
        maxSupply = newMaxSupply;
    }

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    /**
     * @dev - See {ERC721A-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev - See {ERC721A-_startTokenId}.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
