// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";

/// @title Super Wild Club NFTs collection
/// @author cd33
contract SuperWildClub is
    Ownable,
    ERC721A,
    ERC721AQueryable,
    ERC2981,
    PaymentSplitter
{
    enum Step {
        Before,
        WhitelistSale,
        PublicSale
    }

    Step public sellingStep;

    // Number of addresses in the PaymentSplitter
    uint8 private teamLength;

    uint8 public whitelistLimitBalance = 10;
    uint16 public MAX_SUPPLY = 6530;
    uint256 public whitelistSalePrice = 0.2 ether;
    uint256 public publicSalePrice = 0.25 ether;

    string private baseURI;

    bytes32 private merkleRoot;

    // To avoid a buyer transferring his NFT to another wallet and buying again, during the whitelist
    mapping(address => uint8) public amountNftWhitelistPerWallet;

    /**
     * @notice Constructor of the contract ERC721A.
     * @param _team Addresses of the team members.
     * @param _teamShares Percentages of each member.
     * @param _merkleRoot Used for the whitelist.
     * @param _baseURI Metadatas for the ERC1155.
     */
    constructor(
        address[] memory _team,
        uint256[] memory _teamShares,
        bytes32 _merkleRoot,
        string memory _baseURI
    ) ERC721A("SuperWildClub", "SWC") PaymentSplitter(_team, _teamShares) {
        merkleRoot = _merkleRoot;
        baseURI = _baseURI;
        teamLength = uint8(_team.length);
        _setDefaultRoyalty(address(this), 750);
    }

    /**
     * @notice Enables only externally owned accounts (= users) to mint.
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is a contract");
        _;
    }

    /**
     * @notice Allows to change the step of the contract.
     * @param _step New step.
     */
    function setStep(uint8 _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    /**
     * @notice Allows to change the price of the whitelist.
     * @param _price New price.
     */
    function setPriceWhitelist(uint256 _price) external onlyOwner {
        whitelistSalePrice = _price;
    }

    /**
     * @notice Allows to change the price of the public sale.
     * @param _price New price.
     */
    function setPricePublic(uint256 _price) external onlyOwner {
        publicSalePrice = _price;
    }

    /**
     * @notice Change the base URI.
     * @param _newBaseURI New base URI.
     **/
    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Change the token's metadatas URI, override for OpenSea traits compatibility.
     * @param _tokenId Id of the token.
     * @return string Token's metadatas URI.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "NFT doesn't exist");
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, _toString(_tokenId), ".json")
                )
                : "";
    }

    // MINT
    /**
     * @notice Mint NFT during the whitelist.
     * @param _quantity Number of tokens to mint.
     * @param _proof Merkle Proof.
     */
    function whitelistSaleMint(uint8 _quantity, bytes32[] calldata _proof)
        external
        payable
        callerIsUser
    {
        require(sellingStep == Step.WhitelistSale, "Whitelist sale not active");
        require(_isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(
            amountNftWhitelistPerWallet[msg.sender] + _quantity <=
                whitelistLimitBalance,
            "Limited number per wallet"
        );
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Sold out");
        require(
            msg.value >= _quantity * whitelistSalePrice,
            "Not enough funds"
        );
        amountNftWhitelistPerWallet[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice Crossmint during the whitelist.
     * @param _to Address that will receive the NFT.
     * @param _quantity Number of tokens to mint.
     * @param _proof Merkle Proof.
     */
    function crossmintWhitelist(address _to, uint8 _quantity, bytes32[] calldata _proof) public payable {
        require(
            msg.sender == 0xdAb1a1854214684acE522439684a145E62505233,
            "This function is for Crossmint only."
        );
        require(sellingStep == Step.WhitelistSale, "Whitelist sale not active");
        require(_isWhiteListed(_to, _proof), "Not whitelisted");
        require(
            amountNftWhitelistPerWallet[_to] + _quantity <=
                whitelistLimitBalance,
            "Limited number per wallet"
        );
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Sold out");
        require(
            msg.value >= _quantity * whitelistSalePrice,
            "Not enough funds"
        );
        amountNftWhitelistPerWallet[_to] += _quantity;
        _safeMint(_to, _quantity);
    }

    /**
     * @notice Mint NFTs during the public sale.
     * @param _quantity Number of tokens to mint.
     */
    function publicSaleMint(uint8 _quantity) external payable callerIsUser {
        require(sellingStep == Step.PublicSale, "Public sale not active");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Sold out");
        require(msg.value >= _quantity * publicSalePrice, "Not enough funds");
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice Crossmint during the public sale.
     * @param _to Address that will receive the NFT.
     * @param _quantity Number of tokens to mint.
     */
    function crossmintPublicSale(address _to, uint8 _quantity) public payable {
        require(
            msg.sender == 0xdAb1a1854214684acE522439684a145E62505233,
            "This function is for Crossmint only."
        );
        require(sellingStep == Step.PublicSale, "Public sale not active");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Sold out");
        require(msg.value >= _quantity * publicSalePrice, "Not enough funds");
        _safeMint(_to, _quantity);
    }

    /**
     * @notice Allows the owner to offer NFTs.
     * @param _to Receiving address.
     * @param _quantity Number of tokens to mint.
     */
    function gift(address _to, uint8 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Sold out");
        _safeMint(_to, _quantity);
    }

    // WHITELIST
    /**
     * @notice Change Merkle root to update the whitelist.
     * @param _merkleRoot Merkle Root.
     **/
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Return true or false if the account is whitelisted or not.
     * @param _account User's account.
     * @param _proof Merkle Proof.
     * @return bool Account whitelisted or not.
     **/
    function _isWhiteListed(address _account, bytes32[] calldata _proof)
        internal
        view
        returns (bool)
    {
        return _verify(_leafHash(_account), _proof);
    }

    /**
     * @notice Return the account hashed.
     * @param _account Account to hash.
     * @return bytes32 Account hashed.
     **/
    function _leafHash(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    /**
     * @notice Returns true if a leaf can be proven to be part of a Merkle tree defined by root.
     * @param _leaf Leaf.
     * @param _proof Merkle Proof.
     * @return bool Be part of the Merkle tree or not.
     **/
    function _verify(bytes32 _leaf, bytes32[] memory _proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    // ROYALTIES
    /**
     * @notice EIP2981 set royalties.
     * @dev Changes the receiver and the percentage of the royalties.
     * @param _receiver Address of receiver.
     * @param _feeNumerator Percentage of royalty.
     **/
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /**
     * @notice Returns true if this contract implements the interface IERC2981.
     * @param interfaceId Id of the interface.
     * @return bool Implements IERC2981 or not.
     **/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @notice Release money from all accounts.
     **/
    function releaseAll() external {
        for (uint8 i = 0; i < teamLength; i++) {
            release(payable(payee(i)));
        }
    }

    /**
     * @notice Release specific token from all accounts.
     **/
    function releaseSpecificToken(IERC20 _token) external {
        for (uint8 i = 0; i < teamLength; i++) {
            release(_token, payee(i));
        }
    }
}
