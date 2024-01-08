pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./IERC2981.sol";

/**
 * @title Lost Avatars contract
 *
 */

contract LostAvatars is
    Ownable,
    ERC721Enumerable,
    ERC721URIStorage,
    ReentrancyGuard
{
    using SafeMath for uint256;
    // Maximum amounts of mintable tokens
    uint256 public constant maxSupply = 10000;
    // Address of the royalties recipient
    address private _royaltiesReceiver;
    // Percentage of each sale to pay as royalties
    uint256 public constant royaltiesPercentage = 8;
    uint256 public constant maxMints = 20;
    uint256 public constant presaleLimit = 6000;
    uint256 public constant reserveCount = 600;
    bool public saleIsActive = false;
    bool public presaleIsActive = false;
    uint256 private constant mintingCost = 0.05 ether;

    string public baseURI =
        "ipfs://QmQ1GjD7qvJs2V8YM2MHrGp8SRWtBi4SBoM3G4PxnApfWg/";

    address private constant withdraw1 =
        0xbD49d56Ad03fb1d35f327BF773974E12A5f3eF07; // 1/3
    address private constant withdraw2 =
        0xEBbcD978180CA04B5753c79bca4F767b7cCfeD2D; // 1/3
    address private constant withdraw3 =
        0x35381a8F26A2bdb61A190E029E93D2c611b87Ac2; // 1/3

    event MintMessage(string message);

    mapping(address => bool) private _presaleAllowlist;

    constructor(address initialRoyaltiesReceiver)
        ERC721("LostAvatars", "LOAV")
    {
        _royaltiesReceiver = initialRoyaltiesReceiver;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPresaleState() public onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    modifier onlyPresaleAllowlist() {
        require(_presaleAllowlist[msg.sender], "Not on Presale Allowlist.");
        _;
    }

    function addToAllowlist(address[] memory wallets) public onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            _presaleAllowlist[wallets[i]] = true;
        }
    }

    function isOnAllowlist(address wallet) public view returns (bool) {
        return _presaleAllowlist[wallet];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public virtual onlyOwner {
        baseURI = _newBaseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    /// @notice Getter function for _royaltiesReceiver
    /// @return the address of the royalties recipient
    function royaltiesReceiver() external view returns (address) {
        return _royaltiesReceiver;
    }

    /// @notice Changes the royalties' recipient address (in case rights are
    ///         transferred for instance)
    /// @param newRoyaltiesReceiver - address of the new royalties recipient
    function setRoyaltiesReceiver(address newRoyaltiesReceiver)
        external
        onlyOwner
    {
        require(newRoyaltiesReceiver != _royaltiesReceiver); // dev: Same address
        _royaltiesReceiver = newRoyaltiesReceiver;
    }

    /// @notice Returns a token's URI
    /// @dev See {IERC721Metadata-tokenURI}.
    /// @param tokenId - the id of the token whose URI to return
    /// @return a string containing an URI pointing to the token's ressource
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /// @notice Informs callers that this contract supports ERC2981
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Returns all the tokens owned by an address
    /// @param _owner - the address to query
    /// @return ownerTokens - an array containing the ids of all tokens
    ///         owned by the address
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory result = new uint256[](tokenCount);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            for (uint256 i = 0; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _salePrice - sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _value sale price
    function royaltyInfo(uint256 tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(
            _exists(tokenId),
            "ERC2981RoyaltyStandard: Royalty info for nonexistent token."
        );
        uint256 _royalties = (_salePrice * royaltiesPercentage) / 100;
        return (_royaltiesReceiver, _royalties);
    }

    function buyPresale(uint256 numberOfTokens)
        external
        payable
        onlyPresaleAllowlist
        nonReentrant
    {
        require(presaleIsActive, "Presale is not active.");
        require(
            numberOfTokens <= maxMints,
            "Too many tokens for one transaction."
        );
        require(
            totalSupply().add(numberOfTokens) <= presaleLimit + reserveCount,
            "Not enough pre-sale tokens left."
        );
        require(
            msg.value >= mintingCost.mul(numberOfTokens),
            "Insufficient payment."
        );
        require(!_isContract(msg.sender), "Caller cannot be contract.");
        _mint(numberOfTokens);

       
    }

    function buy(uint256 numberOfTokens) external payable nonReentrant {
        require(saleIsActive, "Sale is not active.");
        require(
            numberOfTokens <= maxMints,
            "Too many tokens for one transaction."
        );
        require(
            msg.value >= mintingCost.mul(numberOfTokens),
            "Insufficient payment."
        );
        require(!_isContract(msg.sender), "Caller cannot be contract.");
        _mint(numberOfTokens);

    }
  
    function _isContract(address _addr) internal view returns (bool) {
        uint32 _size;
        assembly {
            _size := extcodesize(_addr)
        }
        return (_size > 0);
    }

    function withdraw() external onlyOwner {
        payable(withdraw1).transfer(address(this).balance / 3);
        payable(withdraw2).transfer(address(this).balance / 2);
        payable(withdraw3).transfer(address(this).balance);
    }

    function reserve(uint256 numberOfTokens) external onlyOwner {
        _mint(numberOfTokens);
    }


     function reserveToAdress(uint256 numberOfTokens, address mintToAdress  ) external onlyOwner {
        _mintToAdress(numberOfTokens, mintToAdress);
    }

    function _mint(uint256 numberOfTokens) private {
        require(
            totalSupply().add(numberOfTokens) <= maxSupply,
            "Not enough tokens left."
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 newId = totalSupply();
            _safeMint(msg.sender, newId);
        }

        emit MintMessage("Welcome to the World of Lost Avatars.");
    }

      function _mintToAdress(uint256 numberOfTokens, address  mintToAdress) private {
        require(
            totalSupply().add(numberOfTokens) <= maxSupply,
            "Not enough tokens left."
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 newId = totalSupply();
            _safeMint(mintToAdress, newId);
        }

        emit MintMessage("Welcome to the World of Lost Avatars.");
    }
}
