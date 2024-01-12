// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

// Import this file to use console.log
import "./Ownable.sol";
import "./AccessControl.sol";
import "./IAccessControl.sol";
import "./ECDSALibrary.sol";
import "./ERC721A.sol";
import "./IERC721A.sol";
import "./console.sol";

contract Ankh is ERC721A, Ownable, AccessControl {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant FREE_SIGNER_ROLE = keccak256("FREE_SIGNER_ROLE");

    // base token URI
    string private _baseTokenURI;
    // Has the URI been frozen for ever
    bool public isUriFrozenForEver;

    // nonce used for free mints
    mapping(address => uint256) private nonces;

    // presale time
    uint256 private _saleTime = 0x62DD5E70;

    // token prices
    uint256 private _tokenPriceOG = 0.2 ether;
    uint256 private _tokenPriceWhitelist = 0.2 ether;
    uint256 private _tokenPricePublic = 0.25 ether;

    // collection's initial maximum supply
    uint256 private _maxSupply = 4500;

    // max mint quantity per transaction
    uint256 private _maxOgMintPerTx = 5;
    uint256 private _maxWhitelistMintPerTx = 3;
    uint256 private _maxPublicMintPerTx = 3;

    // payment splitter
    uint256 internal constant totalShares = 1000;
    uint256 internal totalReleased;
    mapping(address => uint256) internal released;
    mapping(address => uint256) internal shares;
    address internal constant project = 0xf7006AF0E8014567bbE5Cfd7b26e04E6CcaA90B8; // temporary
    address internal constant shareHolder2 = 0x10045a5D7F63F6376205081a7Fa1424ad4920926;
    address internal constant shareHolder3 = 0xe5d2c3eb042aD8C577F70832525656a37749A7F7;
    
    constructor() ERC721A("ANKH", "ANKH") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SIGNER_ROLE, 0xF4F2cbC6FE2e836Fe5a68874D381A89968553051);

        transferOwnership(0x44eEE1B320879768226CE7C2d48455f06e006BFf);

        shares[project] = 905;
        shares[shareHolder2] = 70;
        shares[shareHolder3] = 25;

        _safeMint(project, 1);

        // set unrevealed metadata
        _baseTokenURI = "ipfs://QmYdWbhHLCELSo3HCFUGf7RCsk6wNeYqkqi94qKC3MoaG4/";
    }

    /*
     * mint tokens as an OG
     *
     * @param _quantity: quantity to mint
     * @param _signature: oglist signature
     *
     * Error messages:
     *  - A1: "Wrong price"
     *  - A2: "Trying to mint too many tokens"
     *  - A3: "Max supply has been reached"
     *  - A4: "Mint has not started yet"
     *  - A5: "Wrong signature"
     */
    function ogMint(uint256 _quantity, bytes calldata _signature) external payable {
      require(msg.value == _tokenPriceOG * _quantity, "A1");
      require(_quantity <= _maxOgMintPerTx, "A2");
      require(totalSupply() + _quantity <= _maxSupply, "A3");
      require(block.timestamp > _saleTime, "A4");

      require(hasRole(SIGNER_ROLE, ECDSALibrary.recover(abi.encodePacked(msg.sender, "OG"), _signature)), "A5");

      _safeMint(msg.sender, _quantity);
    }

    /*
     * mint tokens as Whitelisted
     *
     * @param _quantity: quantity to mint
     * @param _signature: whitelist signature
     *
     * Error messages:
     *  - A1: "Wrong price"
     *  - A2: "Trying to mint too many tokens"
     *  - A3: "Max supply has been reached"
     *  - A4: "Mint has not started yet"
     *  - A5: "Wrong signature"
     */
    function whitelistMint(uint256 _quantity, bytes calldata _signature) external payable {
      require(msg.value == _tokenPriceWhitelist * _quantity, "A1");
      require(_quantity <= _maxWhitelistMintPerTx, "A2");
      require(totalSupply() + _quantity <= _maxSupply, "A3");
      require(block.timestamp > _saleTime, "A4");

      require(hasRole(SIGNER_ROLE, ECDSALibrary.recover(abi.encodePacked(msg.sender, "WL"), _signature)), "A5");

      _safeMint(msg.sender, _quantity);
    }

    /*
     * mint tokens in public
     *
     * @param _quantity: quantity to mint
     *
     * Error messages:
     *  - A1: "Wrong price"
     *  - A2: "Trying to mint too many tokens"
     *  - A3: "Max supply has been reached"
     *  - A4: "Mint has not started yet"
     */
    function publicMint(uint256 _quantity) external payable {
      require(msg.value == _tokenPricePublic * _quantity, "A1");
      require(_quantity <= _maxPublicMintPerTx, "A2");
      require(totalSupply() + _quantity <= _maxSupply, "A3");
      require(block.timestamp > _saleTime, "A4");

      _safeMint(msg.sender, _quantity);
    }

    /*
     * mint tokens as free claims
     *
     * @param _quantity: quantity to mint
     * @param _signature: free claim signature
     *
     * Error messages:
     *  - A2: "Trying to mint too many tokens"
     *  - A3: "Max supply has been reached"
     *  - A5: "Wrong signature"
     */
    function freeClaim(uint256 _quantity, bytes calldata _signature) external {
      require(_quantity <= _maxPublicMintPerTx, "A2");
      require(totalSupply() + _quantity <= _maxSupply, "A3");

      uint256 nonce = nonces[msg.sender] + 1;
      require(hasRole(FREE_SIGNER_ROLE, ECDSALibrary.recover(abi.encodePacked(msg.sender, _quantity, nonce), _signature)), "A5");
      nonces[msg.sender] += 1;

      _safeMint(msg.sender, _quantity);
    }

    /*
     * airdrop tokens to address
     *
     * @param _quantity: quantity to airdrop
     * @param _to: receiver of the tokens
     *
     * Error messages:
     *  - A3: "Max supply has been reached"
     */
    function airdrop(uint256 _quantity, address _to) external onlyOwner {
      require(totalSupply() + _quantity <= _maxSupply, "A3");

      _safeMint(_to, _quantity);
    }

    /*
     * set maximum mint quantity per transactions
     *
     * @param _newMaxOgMint: new value for maximum OG mint per transaction
     * @param _newMaxWhitelistMint: new value for maximum whitelist mint per transaction
     * @param _newMaxPublicMint: new value for maximum public mint per transaction
     */
    function setMaxMintsPerTx(
      uint256 _newMaxOgMint, 
      uint256 _newMaxWhitelistMint, 
      uint256 _newMaxPublicMint
    ) external onlyOwner {
      _maxOgMintPerTx = _newMaxOgMint;
      _maxWhitelistMintPerTx = _newMaxWhitelistMint;
      _maxPublicMintPerTx = _newMaxPublicMint;
    }

    /*
     * change price of tokens
     *
     * @param _newTokenPriceOg: new value for OG mint price
     * @param _newTokenPriceWhitelist: new value for whitelist mint price
     * @param _newTokenPricePublic: new value for public mint price
     */
    function setSalePrices(
      uint256 _newTokenPriceOg, 
      uint256 _newTokenPriceWhitelist, 
      uint256 _newTokenPricePublic
    ) external onlyOwner {
      _tokenPriceOG = _newTokenPriceOg;
      _tokenPriceWhitelist = _newTokenPriceWhitelist;
      _tokenPricePublic = _newTokenPricePublic;
    }

    /*
     * change sale time
     *
     * @param _newTime: new sale time
     */
    function setSaleTime(uint256 _newTime) external onlyOwner {
      _saleTime = _newTime;
    }

    /*
     * permanently reduce maximum supply of the collection
     *
     * @param _newMaxSupply: new maximum supply
     *
     * Error messages:
     *  - A6: "Can not increase the maximum supply"
     *  - A7: "Can not set the new maximum supply under the current supply"
     */
    function reduceMaxSupply(uint256 _newMaxSupply) external onlyOwner {
      require(_newMaxSupply < _maxSupply, "A6");
      require(_newMaxSupply >= totalSupply(), "A7");

      _maxSupply = _newMaxSupply;
    }

    /*
     * get prices of tokens
     *
     * @return _tokenPriceOG: price of the tokens when OG
     * @return _tokenPriceWhitelist: price of the tokens when whitelist
     * @return _tokenPricePublic: price of the tokens when public
     */
    function getPrices() external view returns(uint256, uint256, uint256) {
      return (_tokenPriceOG, _tokenPriceWhitelist, _tokenPricePublic);
    }

    /*
     * get maximum supply of the collection
     *
     * @return _maxSupply: maximum supply of the collection
     */
    function getMaxSupply() external view returns(uint256) {
      return _maxSupply;
    }

    /*
     * get time of the sale
     *
     * @return _saleTime: time of the sale
     */
    function getSaleTime() external view returns(uint256) {
      return _saleTime;
    }

    /*
     * get maximum mints per transaction for each sale type
     *
     * @return _maxOgMintPerTx: maximum OG mint per transaction
     * @return _maxWhitelistMintPerTx: maximum whitelist mint per transaction
     * @return _maxPublicMintPerTx: maximum public mint per transaction
     */
    function getMaxMintsPerTx() external view returns(uint256, uint256, uint256) {
      return (_maxOgMintPerTx, _maxWhitelistMintPerTx, _maxPublicMintPerTx);
    }

    /*
     * get the nonce of an account
     *
     * @param _account: account for which to recover the nonce
     *
     * @return nonces[_account]: nonce of _account
     */
    function getNonce(address _account) external view returns(uint256) {
      return nonces[_account];
    }

    /*
     * burn a token
     *
     * @param _tokenId: tokenId of the token to burn
     *
     * Error messages:
     *  - A8: "You don't own this token"
     */
    function burn(uint256 _tokenId) external {
      require(ownerOf(_tokenId) == msg.sender, "A8");
      
      _burn(_tokenId);
    }

    /*
     * freezes uri of tokens
     *
     * Error messages:
     * - A9 : "URI already frozen"
     */
    function freezeMetadata() external onlyOwner {
        require(!isUriFrozenForEver, "A9");
        isUriFrozenForEver = true;
    }

    /*
     * override of the baseURI to use private variable _baseTokenURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /*
     * change base URI of tokens
     *
     * Error messages:
     * - A10 : "URI has been frozen"
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        require(!isUriFrozenForEver, "A10");
        _baseTokenURI = baseURI;
    }

    /**
     * overrides start tokenId
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * Withdraw contract's funds
     *
     * Error messages:
     * - A11 : "No shares for this account"
     * - A12 : "No remaining payment"
     */
    function withdraw(address account) external {
        require(shares[account] > 0, "A11");

        uint256 totalReceived = address(this).balance + totalReleased;
        uint256 payment = (totalReceived * shares[account]) /
            totalShares -
            released[account];

        released[account] = released[account] + payment;
        totalReleased = totalReleased + payment;

        require(payment > 0, "A12");

        payable(account).transfer(payment);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
      return
      interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
      interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
      interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
      interfaceId == type(IAccessControl).interfaceId;
    }
}
