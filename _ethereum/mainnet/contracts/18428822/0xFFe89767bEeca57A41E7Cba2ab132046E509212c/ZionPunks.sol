// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./console.sol";

// Haddad Ayale
// FULL SUPPORT FOR ISRAEL !

contract ZionPunks is ERC721A, ERC2981, Ownable, ReentrancyGuard  {

    event SaleStarted(uint _session);

    using Strings for uint;

    uint public maxSupply = 1948 ;
    uint256 public mintsPerWallet = 3;
    uint256 public price = 0.0770 ether;
    bool public saleIsActive = false;
    uint public session;

    string public baseURI;
    address private walletDonation;

    constructor(string memory name, string memory symbol, string memory _baseURI, address _royaltyReceiver) ERC721A(name, symbol) {
        baseURI = _baseURI;
        // 50% royalties only for Israel
        _setDefaultRoyalty(_royaltyReceiver, 2000);
        walletDonation = _royaltyReceiver;
    }

    function mint(address _addressBuyer, uint256 _quantity) external payable nonReentrant {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(_quantity <= mintsPerWallet, "Exceeded max token purchase");
        require(_numberMinted(msg.sender) + _quantity <= mintsPerWallet, "Exceeded max token purchase");
        require(price * _quantity <= msg.value, "Ether value sent is not correct" );
        require(totalSupply()+_quantity <= maxSupply, "Cannot mint over MAX_SUPPLY");
        _safeMint(_addressBuyer, _quantity);
    }

    /**
     * Owner-only mint function. Used to mint the team treasury.
     * @param _to Address that will receive the NFTs
     * @param _quantity Number of NFTs to mint
    */
    function ownerMint(address _to, uint256 _quantity) external onlyOwner nonReentrant {
        require(totalSupply()+_quantity <= maxSupply, "Cannot mint over MAX_SUPPLY");
        _safeMint(_to, _quantity);
    }

    /**
     * Overridden supportsInterface with IERC721 support and ERC2981 support
     * @param interfaceId Interface Id to check
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * View function to get number of total mints a user has done.
     * @param user Address to check
     */
    function totalMintCount(address user) external view returns (uint256) {
        return _numberMinted(user);
    }

    /**
     * Owner-only function to set the collection supply. This value can only be decreased.
     * @param _maxSupply The new supply count
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(maxSupply < _maxSupply, "new max supply have to be less than older");
        maxSupply = _maxSupply;
    }

    function setWalletDonation(address _walletDonation) public onlyOwner {
        walletDonation = _walletDonation;
    }

    function initialize() external onlyOwner {
        saleIsActive = true;
        session += 1;
        emit SaleStarted(session);
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setMaxPerWallet(uint256 newMaxPerWallet) external onlyOwner {
        mintsPerWallet = newMaxPerWallet;
    }


    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /*
     * TokenURI
     * tokenURI is the link to the metadatas
     */
    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    /**
     * Owner-only function to set the royalty receiver and royalty rate
     * @param receiver Address that will receive royalties
     * @param feeNumerator Royalty amount in basis points. Denominated by 10000
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function withdraw() external nonReentrant {
        require(walletDonation == msg.sender || owner() == msg.sender, "WalletDonation: caller is not the walletDonation");
        (bool success, ) = payable(walletDonation).call{
            value: address(this).balance
        }("");
        require(success, "!transfer");
    }
}
