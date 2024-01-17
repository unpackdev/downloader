// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721Pausable.sol";
import "./ERC2981.sol";
import "./ERC721A.sol";

import "./MintSchedule.sol";

contract Hoom is
    Ownable,
    Pausable,
    ERC721A,
    ERC2981,
    MintSchedule
{
    uint256 public maxSupply = 4000;
    uint256 public maxPerAddress = 5;
    uint256 public cost = 0 ether;
    uint256 public preMintCost = 0 ether;
    mapping(address => uint256) public publicList;
    mapping(address => uint256) public whiteList;

    string private contractMetaURI;
    string private baseURI;

    address public royaltyAddress;
    uint96 public royaltyFee = 250;

    constructor(
        string memory _name,
        string memory _symbol,
        address _bulkTransferAddress
    ) ERC721A(_name, _symbol) {
        royaltyAddress = msg.sender;
        _setDefaultRoyalty(msg.sender, royaltyFee);
        // Internal mint 500 for team
        _mintERC2309(_bulkTransferAddress, 500);
        for (uint256 i; i < 100; ++i) {
            _initializeOwnershipAt(i * 5);
        }
    }

    function preMint(uint256 _mintAmount)
        external
        isPreMintActive
        callerIsUser
        whenNotPaused
        payable
    {
        require(
            whiteList[msg.sender] >= _mintAmount,
            "Not whiteListed."
        );
        uint256 _cost = preMintCost * _mintAmount;
        mintCheck(_mintAmount,  _cost);

        whiteList[msg.sender] -= _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount)
        external
        isPublicMintActive
        callerIsUser
        whenNotPaused
        payable
    {
        require(
            publicList[msg.sender] + _mintAmount <= maxPerAddress,
            "Exceed max per address!"
        );
        uint256 _cost = cost * _mintAmount;
        mintCheck(_mintAmount,  _cost);

        publicList[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }
    
    function mintCheck(
        uint256 _mintAmount,
        uint256 _cost
    ) private view {
        require(_mintAmount > 0, "Mint amount cannot be zero.");
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Exceed max supply!"
        );
        require(msg.value >= _cost, "Not enough funds.");
    }
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Not user!");
        _;
    }

    function airdrop(address[] calldata receivers) external onlyOwner {
        require(
            totalSupply() + receivers.length <= maxSupply,
            "Exceed max limit"
        );

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], 1);
        }
    }

    function setContractURI(string calldata URI) external onlyOwner {
        contractMetaURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return contractMetaURI;
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }

    function withdrawAll() external onlyOwner  {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Withdraw: No amount");
        payable(msg.sender).transfer(contractBalance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addWhiteList(address[] calldata receivers, uint256[] calldata maxMint) external onlyOwner {
        for (uint256 i = 0; i < receivers.length; i++) {
            whiteList[receivers[i]] = maxMint[i];
        }
    }

    /**
     * @notice Change the max per address for the collection.
     */
    function setMaxPerAddress(uint256 _maxPerAddress) external onlyOwner {
        maxPerAddress = _maxPerAddress;
    }

    /**
     * @notice Change the max supply for the collection.
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(
            totalSupply() <= _maxSupply,
            "Max supply must be larger than current minted quantity."
        );
        maxSupply = _maxSupply;
    }

    /**
     * @notice Change the individual cost for the collection
     */
    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    /**
     * @notice Change the individual pre-mint cost for the collection
     */
    function setPreCost(uint256 _preMintCost) external onlyOwner {
        preMintCost = _preMintCost;
    }

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}