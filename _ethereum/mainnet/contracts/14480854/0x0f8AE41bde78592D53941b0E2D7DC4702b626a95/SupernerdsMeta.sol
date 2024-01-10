// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Counters.sol";
import "./ERC721.sol";
import "./AccessControl.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./ERC721Enumerable.sol";

contract SupernerdsMeta is
    ERC721Enumerable,
    AccessControl,
    ERC2981ContractWideRoyalties
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public _baseTokenURI = "";

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public _totalCap = 5555; //total number of tokens
    uint256 public _availableForSale = 5154; // _totalCap - _availableForSale
    uint256 public _reserveTokens = 401; //reserve tokens for Alpha Holders

    uint256 public royaltyValue = 60000000000000000; // Royalty 6% in eth decimals
    //TODO change address
    address public royaltyRecipient; // Royalty Recipient Main wallet (OpenSea)

    uint256 public _mintedSale; //token minted in the all the sales
    uint256 public _mintedReserved; // token minted for the alpha nerd hodlers

    constructor() ERC721("Supernerds Meta", "Supernerds Meta") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    /// @dev Sets the royalty value and recipient
    /// @notice Only admin can call the function
    /// @param recipient The new recipient for the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function setRoyalties(address recipient, uint256 value) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "only admin allowed");
        require(
            recipient != 0x0000000000000000000000000000000000000000,
            "S16NFT: Royalty recipient address cannot be Zero Address"
        );
        require(value > 0, "S16NFT: invalid royalty percentage");
        _setRoyalties(recipient, value);

        royaltyRecipient = recipient;
        royaltyValue = value;
    }

    function cap() external view returns (uint256) {
        return _totalCap;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not a admin"
        );

        _baseTokenURI = baseURI;
    }

    function mint(address _mintTo) external returns (bool) {
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
        require(_mintTo != address(0), "ERC721: mint to the zero address");
        _tokenIds.increment();
        uint256 totalSupply = totalSupply();
        require(_mintedSale <= _availableForSale, "sale minting completed");
        require(
            totalSupply + 1 <= _totalCap,
            "Cap reached, maximum 5555 mints possible"
        );

        _safeMint(_mintTo, _tokenIds.current());
        _mintedSale++;

        return true;
    }

    function mintReserve(address _mintTo) external returns (bool) {
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
        require(_mintTo != address(0), "ERC721: mint to the zero address");
        _tokenIds.increment();
        uint256 totalSupply = totalSupply();
        require(_mintedReserved <= _reserveTokens, "reserved sale completed");
        require(
            totalSupply + 1 <= _totalCap,
            "Cap reached, maximum 5555 mints possible"
        );
        _safeMint(_mintTo, _tokenIds.current());

        _mintedReserved++;

        return true;
    }
}
