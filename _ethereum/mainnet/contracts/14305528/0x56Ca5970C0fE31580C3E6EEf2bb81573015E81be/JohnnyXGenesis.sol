//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./IERC2981.sol";
import "./ReentrancyGuard.sol";

/// @notice JohnnyXGenesis contract manages the NFT(s) for JohnnysKicks_ brand
///   for his genesis NFT launch.
contract JohnnyXGenesis is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _totalMinted;

    /// @notice Maximum Number of NFTs that can be minted in this collection.
    uint256 public constant MAX_SUPPLY = 500;
    /// @notice Price per initial mint
    uint256 public constant PRICE = 0.15 ether;
    /// @notice  Maximum Number of NFTs that can be minted at once
    uint256 public constant MAX_PER_MINT = 2;
    /// @notice IPFS URI of the base ERC721 tokens
    string public baseTokenURI;
    /// @notice Boolean flag for disabling minting
    bool public isActive = false;
    /// @notice address all royalty payments are sent
    address public royalties;
    /// @notice address all minting payments are sent
    address public beneficiary;

    /// @notice OpenZepplin requires this function to exist if we are to update the baseUri after contract launch
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice Globally accessible setter for the Base URI. Allows the contract owner to update the
    /// IPFS address if required
    /// @param _baseTokenURI base URI for the IPFS data
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @dev Sets token royalties
    /// @param _royaltiesAddress recipient of the royalties
    function setRoyalties(address _royaltiesAddress) public onlyOwner {
        royalties = _royaltiesAddress;
    }

    /// @notice allows control over the minting process
    function setActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    /// @notice sets the beneficiary address
    function setBeneficiary(address _beneficiaryAddress) public onlyOwner {
        beneficiary = _beneficiaryAddress;
    }

    constructor(
        address _royaltyAddress,
        address _beneficiary,
        string memory _initialBaseURI
    ) ERC721("JohnnyX NFT Collection", "JohnnyX") {
        setRoyalties(_royaltyAddress);
        setBeneficiary(_beneficiary);
        setBaseURI(_initialBaseURI);
    }

    /// @notice Reserves 10 NFTS for the owner as long as supply exists
    function reserveNFTs() public onlyOwner {
        require(
            _totalMinted.current().add(10) <= MAX_SUPPLY,
            "Not enough NFTs left to reserve."
        );

        for (uint256 i = 0; i < 10; i++) {
            _mintSingleNFT();
        }
    }

    /// @notice Mints a passed in amount of NFTs
    /// @param _count total count of mintable nfts, currently set to a maximum of 2
    function mintNFTs(uint256 _count) public payable nonReentrant {
        require(isActive, "Sale is closed");
        require(
            _totalMinted.current().add(_count) <= MAX_SUPPLY,
            "Not enough NFTs left!"
        );
        require(_count > 0 && _count <= MAX_PER_MINT, "Cannot mint NFTs.");
        require(msg.value >= PRICE.mul(_count), "Not enough ether.");

        for (uint256 i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    /// @notice private function allowing minting of a single NFT
    function _mintSingleNFT() private {
        _safeMint(msg.sender, _totalMinted.current());
        _totalMinted.increment();
    }

    /// @notice Allows the owner of the contract to withdraw any ether in its balance
    function withdraw() public onlyOwner {
        payable(beneficiary).transfer(address(this).balance);
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev Callers can derive the royalty amount given a sale price, this method is defined in IERC2981
    /// @param {} this is a placheholder for a tokenId, for our contract all loyalties are the same across tokens
    /// @param _salePrice the salePrice of the token
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        royaltyAmount = (_salePrice / 100) * 10;
        return (royalties, royaltyAmount);
    }

    ///@notice returns the current counter, returing the totaly supply minted
    function totalSupply() public view returns (uint256) {
        return _totalMinted.current();
    }
}
