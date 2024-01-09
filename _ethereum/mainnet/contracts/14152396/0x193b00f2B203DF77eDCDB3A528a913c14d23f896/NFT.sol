// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./SafeMath.sol";

// @title  Main NFT Contract
// @notice In addition to the standard ERC721 interface, this contract implements
//         a merkle tree based pre-sale function that allows white listed users to
//         purchase the NFT at a discount.
//
contract NFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;
    using MerkleProof for bytes32[];
    using ECDSA for bytes32;


    ///////////////////////////////////////////////////////

    // Accounts: // constant
    address public withdrawAddress1 = 0x693Fa3B763018F959a80037307B1ff70f9692e4A;
    address public withdrawAddress2;

    // Token Supply:
    uint256 public MaxSupply = 2022;
    uint256 public MaxGiftSupply = 50;
    uint256 public MaxMintPreSale = 1;    // max: pre sale
    uint256 public MaxMintPublic = 3;     // max: public


    // Mint Price:
    uint256 public PreSaleMintPrice = 0.05 ether;
    uint256 public PublicMintPrice = 0.1 ether;

    // Mint Count:
    uint256 public GiftMintCount;

    // Sale Status
    bool public IsDisabled;               // stop
    bool public IsMetaLocked;             // not show metadata
    bool public PreSaleStatus = true;     // sale: pre
    bool public PublicSaleStatus;         // sale: public

    //
    // pre-sale related
    //
    bytes32 private _merkleRoot;
    mapping(address => bool) public PreSaleMinted; // whitelist

    // whole contract related
    string private _baseTokenURI;


    ///////////////////////////////////////////////////////

    // Events
    event PublicSaleActivation(bool isActive); // public sale
    event PreSaleActivation(bool isActive);    //  pre sale


    ///////////////////////////////////////////////////////

    /// nft name:
    constructor() ERC721("Peppa Pig", "PPG") {}


    ///////////////////////////////////////////////////////

    /* *********************************************** */
    /*               USER FUNCTIONS                   */
    /* *********************************************** */

    // @notice This function can be called by whitelisted users to purchase ONE NFT
    //         at a discounted price.
    // @notice The whitelist mechanism is based on merkle proof; see details in the link below
    //         https://docs.openzeppelin.com/contracts/3.x/api/cryptography#MerkleProof
    // @param  proof - merkle proof to verify that msg.sender is indeed in the whitelist
    // @param  amount - the actual amount the user wants to buy
    function mintPreSale(
        address _to,
        bytes32[] memory proof,
        uint256 count
    ) external payable nonReentrant {
        // check:
        require(!IsDisabled, "the contract is disabled");
        // pre sale:
        require(PreSaleStatus, "PreSale must be active");
        // check root:
        require(_merkleRoot != "", "merkleRoot not set");
        // check mint:
        require(count <= MaxMintPreSale, "max mint amount");

        // check whitelist tree:
        require(
            proof.verify(
                _merkleRoot,
                keccak256(abi.encodePacked(_to)) // todo: need check
            ),
            "failed to verify merkle root"
        );

        // check mint status:
        require(
            !PreSaleMinted[_to],
            "this address has minted its presale already"
        );

        // check price:
        require(
            msg.value >= PreSaleMintPrice * count,
            "Sent ether value is incorrect"
        );

        // set address:
        PreSaleMinted[_to] = true;

        // mint:
        for (uint256 i = 0; i < count; i++) {
            _safeMint(_to, totalSupply());
        }
    }


    //////////////////////////////////////////////////////

    // public mint:
    function mint(address to, uint256 count) external payable {
        // check:
        require(!IsDisabled, "the contract is disabled");
        // check status:
        require(PublicSaleStatus, "Sale must be active");
        // check max buy:
        require(count <= MaxMintPublic, "exceeds maximum purchase amount");
        // check max supply:
        require(totalSupply() + count <= MaxSupply, "exceeds max supply");
        // check price:
        require(
            msg.value >= PublicMintPrice * count,
            "Sent ether value is incorrect"
        );

        // mint:
        for (uint256 i = 0; i < count; i++) {
            _safeMint(to, totalSupply());
        }
    }

    //////////////////////////////////////////////////////

    // @notice This function can be called to retrieve the tokenURI
    // @param  tokenId - the unique identifier for one NFT
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory base = _baseURI();
        require(bytes(base).length != 0, "baseURI not set");


        // pre sale:
        //        if (PreSaleStatus) {
        //            return string(abi.encodePacked(base));
        //        }

        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }


    /* *********************************************** */
    /*               ADMIN FUNCTIONS                   */
    /* *********************************************** */


    // @notice This function sets the BaseURI for this NFT collection
    //         All the URIs will be in the format of <BASE_URI>/<TOKEN_ID>
    //         See function tokenURI for implementation
    // @param  baseURI_ - the base URI of a NFT's token URI
    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(!IsMetaLocked, "Contract metadata methods are locked");
        _baseTokenURI = baseURI_;
    }

    // @notice This function sets the merkle root to verify whether the msg.sender
    //         is in the predetermined whitelist
    // @notice The merkle root can be generated by ./merkle/merkle.js. Please refer
    //         to that source code for merkle tree calculation
    // @param  root - the merkle root
    function setMerkleRoot(bytes32 root) external onlyOwner {
        _merkleRoot = root;
    }

    // @notice This function sets the disabled state, in order to disable/enable minting
    // @param  isDisabled - the disabled state
    function setDisabled(bool status) external onlyOwner {
        IsDisabled = status;
    }

    // metadata:
    function setMetadataLock(bool status) external onlyOwner {
        IsMetaLocked = status;
    }

    ///////////////////////////////////////////////////////

    // event: pre sale
    function updatePreSaleStatus() external onlyOwner {
        PreSaleStatus = !PreSaleStatus;
        emit PreSaleActivation(PreSaleStatus);
    }

    // public:
    function updatePublicSaleStatus() external onlyOwner {
        PublicSaleStatus = !PublicSaleStatus;
        emit PublicSaleActivation(PublicSaleStatus);
    }

    // set all:
    function updateAll(
        uint256 _preSalePrice,
        uint256 _publicSalePrice,
        uint256 _maxMintPreSale,
        uint256 _maxMintPublic,
        uint256 _maxSupply
    ) external onlyOwner {
        PreSaleMintPrice = _preSalePrice;
        PublicMintPrice = _publicSalePrice;
        MaxMintPreSale = _maxMintPreSale;
        MaxMintPublic = _maxMintPublic;
        MaxSupply = _maxSupply;
    }

    // withdraw address:
    function updateWithdrawAddress(address to1, address to2) external onlyOwner {
        withdrawAddress1 = to1;
        withdrawAddress2 = to2;
    }

    ///////////////////////////////////////////////////////

    // Minting
    function ownerMint(address _to, uint256 _count) external onlyOwner {
        // max:
        require(
            GiftMintCount + _count <= MaxGiftSupply,
            "exceeds max private supply"
        );

        // max:
        require(totalSupply() + _count <= MaxSupply, "exceeds max supply");

        /// mint:
        for (uint256 i = 0; i < _count; i++) {
            // count:
            GiftMintCount++;

            _safeMint(_to, totalSupply());
        }
    }


    ///////////////////////////////////////////////////////

    //
    // @notice This function allows the contract owner to withdraw the eth in this contract
    //
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance can't be zero");

        payable(msg.sender).transfer(balance);
    }

    function _withdraw(address _address, uint256 _amount) private onlyOwner {
        (bool success,) = payable(_address).call{value : _amount}("");
        require(success, "Withdraw failed.");
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Withdraw balance can't be zero");

        // withdraw: 80%
        _withdraw(withdrawAddress1, balance * 8 / 10);

        // withdraw: 20%
        _withdraw(owner(), address(this).balance);
    }


    ///////////////////////////////////////////////////////

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */


    // base url:
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}
