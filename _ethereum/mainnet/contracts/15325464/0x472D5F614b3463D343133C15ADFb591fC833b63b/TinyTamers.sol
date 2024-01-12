// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,  &@@&&@@&&@@@@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@(   ,&&&((&&&&(&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@&   ,&((&&&&&&&&&&&&&(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,,,&&&&&&&    &&&&&&&(&@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,,,&&&,,,  ((   ,,&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@&   &&,&  (&&&&(( &,&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@&   && ,  &    && , &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@& ((( &&&,,       ,&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&,&(&& &&&&  & (,*(, &@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&& &&&((&&(((&, (( .,&@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&,,,((((,,,&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&((((&@@@&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

/**
 * @title TinyTamers
 * @author @ScottMitchell18
 */
contract TinyTamers is ERC721AQueryable, ERC721ABurnable, Ownable {
    using Strings for uint256;

    // @dev Base uri for the nft
    string private baseURI;

    // @dev Hidden uri for the nft
    string public hiddenURI =
        "ipfs://bafybeib5mpfkszttrqvzuair6ej3t34ny4p6a3mhql4c5ec2ratxaqu6li/prereveal.json";

    // @dev The merkle root proof
    bytes32 public merkleRoot;

    // @dev The premints flag
    bool public premintsActive = true;

    // @dev The reveal flag
    bool public isRevealed = false;

    // @dev The price of a mint
    uint256 public price = 0.01 ether;

    // @dev The withdraw address
    address public treasury =
        payable(0x890f912a5f6a0FFc89F07638552A7a30EEF9DC17);

    // @dev The dev address
    address public dev = payable(0x593b94c059f37f1AF542c25A0F4B22Cd2695Fb68);

    // @dev An address mapping for free mints
    mapping(address => bool) public addressToFreeMinted;

    // @dev An address mapping for total mints
    mapping(address => uint256) public addressToMinted;

    // @dev The total max per wallet (n - 1)
    uint256 public maxPerWallet = 5;

    /*
     * @notice Mint Live ~ August 12th, 630PM EST
     * @dev Mint go live date
     */
    uint256 public liveAt = 1660343400;

    // @dev The total supply of the collection
    uint256 public maxSupply = 2001;

    constructor() ERC721A("Tiny Tamers", "TT") {
        _mintERC2309(dev, 1); // Placeholder mint
    }

    /**
     * @notice Sets the go live timestamp
     * @param _liveAt A base uri
     */
    function setLiveAt(uint256 _liveAt) external onlyOwner {
        liveAt = _liveAt;
    }

    // @dev Check if mint is live
    function isLive() public view returns (bool) {
        return block.timestamp > liveAt;
    }

    /**
     * @notice Whitelisted minting function which requires a merkle proof (max 1)
     * @param _proof The bytes32 array proof to verify the merkle root
     */
    function whitelistMint(bytes32[] calldata _proof) external {
        require(premintsActive && isLive(), "0");
        require(!addressToFreeMinted[_msgSender()], "2");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "4");
        addressToFreeMinted[_msgSender()] = true;
        _mint(_msgSender(), 1);
    }

    /**
     * @notice Mints a new TT token
     * @param _amount The number of tokens to mint
     */
    function mint(uint256 _amount) external payable {
        require(isLive(), "0");
        require(msg.value >= _amount * price, "1");
        require(addressToMinted[_msgSender()] + _amount < maxPerWallet, "2");
        require(totalSupply() + _amount < maxSupply, "3");
        addressToMinted[_msgSender()] += _amount;
        _mint(_msgSender(), _amount);
    }

    /**
     * @notice Mints a new TT tokens for owners
     */
    function ownerMint(address to, uint256 _amount) external onlyOwner {
        _mint(to, _amount);
    }

    /**
     * @dev Check if wallet has WL minted
     * @param _address mint address lookup
     */
    function hasWLMinted(address _address) public view returns (bool) {
        return addressToFreeMinted[_address];
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Returns the URI for a given token id
     * @param _tokenId A tokenId
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert OwnerQueryForNonexistentToken();
        if (!isRevealed) return hiddenURI;
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    /**
     * @notice Sets the reveal flag
     * @param _isRevealed a flag for whether the collection is revealed
     */
    function setIsRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    /**
     * @notice Sets the hidden URI of the NFT
     * @param _hiddenURI A hidden uri
     */
    function setHiddenURI(string calldata _hiddenURI) external onlyOwner {
        hiddenURI = _hiddenURI;
    }

    /**
     * @notice Sets the base URI of the NFT
     * @param _baseURI A base uri
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Sets the merkle root for the mint
     * @param _merkleRoot The merkle root to set
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Sets the pre mints active
     * @param _premintsActive The bool of premint status
     */
    function setPremintsActive(bool _premintsActive) external onlyOwner {
        premintsActive = _premintsActive;
    }

    /**
     * @notice Sets the max per wallet
     * @param _maxPerWallet The max mint count per address
     */
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice Sets the collection max supply
     * @param _maxSupply The max supply of the collection
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Sets price
     * @param _price price in wei
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @notice Sets the treasury recipient
     * @param _treasury The treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        treasury = payable(_treasury);
    }

    /**
     * @notice Withdraws funds from contract
     */
    function withdraw() public onlyOwner {
        (bool s1, ) = treasury.call{value: address(this).balance}("");
        require(s1, "Payment failed");
    }
}
