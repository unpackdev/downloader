/**
 SPDX-License-Identifier: GPL-3.0
*/
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Signature.sol";
import "./ERC721ABurnable.sol";


error CallerIsContract();
error SaleNotActive();
error SoldOut();
error InvalidQuantity();


contract ExtractsOfSin is
    ERC721ABurnable,
    Ownable,
    Signature
{
    /** VARIABLES **/
    uint public maxSupply = 5000;
    uint constant public MAX_MINT_COUNT_PER_TXN = 30;
    string private customBaseURI;
    address private dev = 0x215De00630F5E89C3A219D2771e55dc49F28489f;
    enum SaleState {
        CLOSED,
        PUBLIC
    }
    SaleState public saleState = SaleState.CLOSED;
    mapping(bytes => bool) public usedSignatures;

    /* EVENTS **/
    event TokensMinted(address indexed to, uint256 indexed amount);
    event SaleStateChanged(address indexed by, uint8 indexed to);
    event MetadataLinkChanged(address indexed by, string indexed to);

    constructor(bool isPaying, uint256 deploymentPrice) ERC721A("Extracts Of Sin", "SIN") payable {
        if(isPaying){
            require(msg.value >= deploymentPrice);
            payable(dev).transfer(address(this).balance);
        }
    }

    /** MINTING **/
    function mint(uint64 count, bytes calldata signature, string calldata nonce) external payable requiresSignature(signature,nonce) {
        if (saleState != SaleState.PUBLIC) revert SaleNotActive();
        if (tx.origin != msg.sender) revert CallerIsContract();
        if (count > MAX_MINT_COUNT_PER_TXN) revert InvalidQuantity();
        if (_nextTokenId() + (count - 1) > maxSupply) revert SoldOut();
        if (usedSignatures[signature]) revert InvalidSignature();

        _mint(msg.sender, count);
        emit TokensMinted(msg.sender, count);
        usedSignatures[signature] = true;
    }

    function freeMintToAddress(address account, uint256 count) external onlyOwner {
        if (count > MAX_MINT_COUNT_PER_TXN) revert InvalidQuantity();
        if (_nextTokenId() + (count - 1) > maxSupply) revert SoldOut();
        _mint(account, count);
        emit TokensMinted(account, count);
    }
    
    /** SIGNATURE **/
    function checkSignature(bytes calldata signature, string calldata nonce)
        public
        view
        requiresSignature(signature,nonce)
        returns (bool)
    {
        return true;
    }

    /** ADMIN FUNCTIONS **/
    /**
     * @notice Sets sale state to CLOSED (0), PUBLIC (1), PRESALE (2) if applicable.
     */
    function setSaleState(uint8 state) external onlyOwner {
        require(state >= 0 && state < 3);
        saleState = SaleState(state);
        emit SaleStateChanged(msg.sender, state);
    }

    /**
     * @dev Set IPFS folder link
     */
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        customBaseURI = newBaseURI;
        emit MetadataLinkChanged(msg.sender, newBaseURI);
    }

    /**
     * @dev Set new dev wallet
     */
    function setDev(address newDev) external {
        require(msg.sender == dev, "Only dev can call");
        require(newDev != address(0));
        dev = newDev;
    }

    /** OVERRIDES **/
    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    /**
     * @dev minting starts at token ID #1
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /** RELEASE PAYOUT **/
    function withdraw() external onlyOwner {
        payable(dev).transfer((address(this).balance) * 5 / 100);
        payable(owner()).transfer(address(this).balance);
    }
}