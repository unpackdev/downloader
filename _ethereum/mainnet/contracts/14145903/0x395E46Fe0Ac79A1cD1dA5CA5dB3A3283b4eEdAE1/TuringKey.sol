// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC20.sol";

/// @notice Too few tokens remain
error InsufficientTokensRemain();

/// @notice Not enough ether sent to mint
/// @param cost The minimum amount of ether required to mint
/// @param sent The amount of ether sent to this contract
error InsufficientFunds(uint256 cost, uint256 sent);

/// @notice Supply send to update is lower than the current mints count
/// @param supply Amount sent to update
/// @param tokenCount Current minst amount
error SupplyLowerThanTokenCount(uint256 supply, uint256 tokenCount);

/// @notice Supply send to update is lower than the current mints count
/// @param supply Amount sent to update
/// @param absoluteMaximumTokens hardcoded maximum number of tokens
error SupplyHigherThanAbsoluteMaximumTokens(uint256 supply, uint256 absoluteMaximumTokens);

/// @title Turing Key
/// @author GoldmanDAO
/// @dev Note that mint price and Token URI are updateable
contract TuringKey is ERC721, Ownable {
  /// @dev Base URI
    string private internalTokenURI;

    /// @dev Number of tokens
    uint256 public tokenCount;

    /// @notice The maximum number of nfts to mint, not updateable
    uint256 public constant ABSOLUTE_MAXIMUM_TOKENS = 969;

    /// @notice The actual supply of nfts. Can be updated by the owner
    uint256 public currentSupply = 200;

    /// @notice Cost to mint a token
    uint256 public publicSalePrice = 0.5 ether;

    //////////////////////////////////////////////////
    //                  MODIFIER                    //
    //////////////////////////////////////////////////

    /// @dev Checks if there are enough tokens left for minting
    modifier canMint() {
        if (tokenCount > currentSupply) {
            revert InsufficientTokensRemain();
        }
         if (publicSalePrice > msg.value) {
            revert InsufficientFunds(publicSalePrice, msg.value);
        }
        _;
    }

    //////////////////////////////////////////////////
    //                 CONSTRUCTOR                  //
    //////////////////////////////////////////////////

    /// @dev Sets the ERC721 Metadata and OpenSea Proxy Registry Address
    constructor(string memory _tokenURI) ERC721("Turing Key", "TKEY") {
      internalTokenURI = _tokenURI;
    }

    //////////////////////////////////////////////////
    //                  METADATA                    //
    //////////////////////////////////////////////////

    /// @dev Returns the URI for the given token
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return internalTokenURI;
    }

    /////////////////////////////////////////////////
    //                MINTING LOGIC                 //
    //////////////////////////////////////////////////

    /// @notice Mint a token
    /// @param to whom the token is being sent to
    function mint(address to)
        public
        virtual
        payable
        canMint() 
    {
        tokenCount++;
        _mint(to, tokenCount);
    }

    /// @notice Safe mint a token
    /// @param to whom the token is being sent to
    function safeMint(address to)
        public
        virtual
        payable
        canMint()
    {
        tokenCount++;
        _safeMint(to, tokenCount);
    }

    /// @notice Safe mint a token
    /// @param to whom the token is being sent to
    /// @param data needed for the contract to be call
    function safeMint(
        address to,
        bytes memory data
    )
        public
        virtual
        payable
        canMint()
    {
        tokenCount++;
        _safeMint(to, tokenCount, data);
    }

     //////////////////////////////////////////////////
    //                BURNING LOGIC                 //
    //////////////////////////////////////////////////

    function burn(uint256 tokenId) public virtual {
        _burn(tokenId);
    }

    //////////////////////////////////////////////////
    //                 ADMIN LOGIC                  //
    //////////////////////////////////////////////////

    /// @notice Sets the tokenURI for the membership
    function setInternalTokenURI(string memory _internalTokenURI) external onlyOwner {
        internalTokenURI = _internalTokenURI;
    }

    /// @dev Allows the owner to update the amount of memberships to be minted
    function updateCurrentSupply(uint256 _supply) public onlyOwner {
        if (_supply > ABSOLUTE_MAXIMUM_TOKENS) {
            revert SupplyHigherThanAbsoluteMaximumTokens(_supply, ABSOLUTE_MAXIMUM_TOKENS);
        } 
        if (_supply < tokenCount) {
            revert SupplyLowerThanTokenCount(_supply, tokenCount);
        }
        currentSupply = _supply;
    }

    /// @dev Allows the owner to change the prize of the membership 
    function setPublicSalePrice(uint256 _publicSalePrice) public onlyOwner {
      publicSalePrice = _publicSalePrice;
    }

    /// @dev Allows the owner to withdraw eth
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /// @dev Allows the owner to withdraw any erc20 tokens sent to this contract
    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    //////////////////////////////////////////////////
    //                 ROYALTIES                    //
    //////////////////////////////////////////////////
    // @dev Support for EIP 2981 Interface by overriding erc165 supportsInterface
    // function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
    //     return
    //         interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
    //         interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
    //         interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
    //         interfaceId == 0x2a55205a;  // ERC165 Interface ID for ERC2981
    // }

    /// @dev Royalter information
    // function royaltyInfo(uint256 tokenId, uint256 salePrice)
    //     external
    //     view
    //     returns (address receiver, uint256 royaltyAmount)
    // {
    //     receiver = address(this);
    //     royaltyAmount = (salePrice * 5) / 100;
    // }
}