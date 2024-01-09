// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Assemblage NFT
/// @notice Assemblage arranges objects found on the Ethereum blockchain.
/// @author: dreerr.eth

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//    █████╗ ███████╗███████╗███████╗███╗   ███╗██████╗ ██╗      █████╗  ██████╗ ███████╗ //
//   ██╔══██╗██╔════╝██╔════╝██╔════╝████╗ ████║██╔══██╗██║     ██╔══██╗██╔════╝ ██╔════╝ //
//   ███████║███████╗███████╗█████╗  ██╔████╔██║██████╔╝██║     ███████║██║  ███╗█████╗   //
//   ██╔══██║╚════██║╚════██║██╔══╝  ██║╚██╔╝██║██╔══██╗██║     ██╔══██║██║   ██║██╔══╝   //
//   ██║  ██║███████║███████║███████╗██║ ╚═╝ ██║██████╔╝███████╗██║  ██║╚██████╔╝███████╗ //
//   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝     ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝ //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./IERC1155.sol";
import "./IERC2981.sol";
import "./ERC165Checker.sol";

contract Assemblage is ERC721Enumerable, Ownable, IERC2981 {
    using ERC165Checker for address;
    using Strings for uint256;

    uint256 public immutable maxSupply;
    uint256 private _mintPrice;
    bool private _mintEnabled;
    string private _currentBaseURI;
    uint256 private _royaltyAmount;

    struct FreemintItem {
        address minter;
        uint256 amount;
    }
    mapping(address => uint256) public freemints;

    struct SourceToken {
        address sourceContract;
        uint256 sourceTokenId;
    }
    mapping(uint256 => SourceToken) public sourceTokens;
    mapping(address => mapping(uint256 => bool)) public sourceTokenMinted;
    event SourceTokenMinted(SourceToken, uint256 tokenId, address to);

    event PrintOrdered(address from, uint256 amount);

    constructor(
        string memory _initialBaseURI,
        FreemintItem[] memory _initialFreemints
    ) ERC721("Assemblage", "ABL") {
        _currentBaseURI = _initialBaseURI;
        _mintPrice = 0.08 ether;
        _mintEnabled = false;
        _royaltyAmount = 770;
        maxSupply = 7921;
        setFreemints(_initialFreemints);
    }

    // ███╗   ███╗██╗███╗   ██╗████████╗██╗███╗   ██╗ ██████╗
    // ████╗ ████║██║████╗  ██║╚══██╔══╝██║████╗  ██║██╔════╝
    // ██╔████╔██║██║██╔██╗ ██║   ██║   ██║██╔██╗ ██║██║  ███╗
    // ██║╚██╔╝██║██║██║╚██╗██║   ██║   ██║██║╚██╗██║██║   ██║
    // ██║ ╚═╝ ██║██║██║ ╚████║   ██║   ██║██║ ╚████║╚██████╔╝
    // ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝

    /** @dev Mints NFTs
     * @param sourceContract Contract Address of source NFT
     * @param sourceTokenId Token ID of source NFT
     */
    function mint(address sourceContract, uint256 sourceTokenId)
        public
        payable
    {
        // Check if minting is enabled
        require(mintEnabled(), "Minting is not enabled");

        // Check if there is supply
        require(totalSupply() < maxSupply, "Supply is exhausted");

        // Check if token already exists
        require(
            sourceTokenMinted[sourceContract][sourceTokenId] == false,
            "This token was already minted"
        );

        // Owner and Freemint can mint for free, mintPrice() takes care of it
        require(msg.value >= mintPrice(), "Insufficient value for mint");

        // Check if sender owns Token
        if (sourceContract.supportsInterface(0x80ac58cd)) {
            // IS ERC-721
            require(
                IERC721(sourceContract).ownerOf(sourceTokenId) == msg.sender,
                "You do not own this source token"
            );
        } else if (sourceContract.supportsInterface(0xd9b67a26)) {
            // IS ERC-1155
            require(
                IERC1155(sourceContract).balanceOf(msg.sender, sourceTokenId) >
                    0,
                "You do not own this source token"
            );
        }

        // END OF REQUIREMENTS

        // Get next tokenId
        uint256 tokenId = totalSupply();

        // Deduct from freemint
        if ((freemints[msg.sender] > 0)) {
            freemints[msg.sender] -= 1;
        }

        // Mint token
        _safeMint(msg.sender, tokenId);

        // Add to source token list
        SourceToken memory sourceToken = SourceToken(
            sourceContract,
            sourceTokenId
        );
        sourceTokens[tokenId] = sourceToken;
        sourceTokenMinted[sourceContract][sourceTokenId] = true;

        // Emit event SourceTokenMinted
        emit SourceTokenMinted(sourceToken, tokenId, msg.sender);
    }

    /** @dev Checks if minting is enabled
     */
    function mintEnabled() public view returns (bool) {
        if (msg.sender == owner() || (freemints[msg.sender] > 0)) {
            return true;
        } else {
            return _mintEnabled;
        }
    }

    /**
     * @dev Turn minting on / off
     * @param newMintingState New price
     */
    function setMinting(bool newMintingState) public onlyOwner {
        _mintEnabled = newMintingState;
    }

    /** @dev Check the mint price
     */
    function mintPrice() public view returns (uint256) {
        if (msg.sender == owner() || (freemints[msg.sender] > 0)) {
            return 0;
        } else {
            return _mintPrice;
        }
    }

    /**
     * @dev Set price of Token
     * @param newMintPrice New price
     */
    function setMintPrice(uint256 newMintPrice) public onlyOwner {
        _mintPrice = newMintPrice;
    }

    // ███╗   ███╗███████╗████████╗ █████╗ ██████╗  █████╗ ████████╗ █████╗
    // ████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗
    // ██╔████╔██║█████╗     ██║   ███████║██║  ██║███████║   ██║   ███████║
    // ██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║  ██║██╔══██║   ██║   ██╔══██║
    // ██║ ╚═╝ ██║███████╗   ██║   ██║  ██║██████╔╝██║  ██║   ██║   ██║  ██║
    // ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝

    /** @dev Get the current base URI
     * @return _currentBaseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    /** @dev Update the base URI
     * @param newBaseURI New value of the base URI
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _currentBaseURI = newBaseURI;
    }

    /**
     * @dev Contract Metadata
     */
    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, "contract.json"))
                : "";
    }

    // ███████╗██████╗ ███████╗███████╗███╗   ███╗██╗███╗   ██╗████████╗███████╗
    // ██╔════╝██╔══██╗██╔════╝██╔════╝████╗ ████║██║████╗  ██║╚══██╔══╝██╔════╝
    // █████╗  ██████╔╝█████╗  █████╗  ██╔████╔██║██║██╔██╗ ██║   ██║   ███████╗
    // ██╔══╝  ██╔══██╗██╔══╝  ██╔══╝  ██║╚██╔╝██║██║██║╚██╗██║   ██║   ╚════██║
    // ██║     ██║  ██║███████╗███████╗██║ ╚═╝ ██║██║██║ ╚████║   ██║   ███████║
    // ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝

    /** @dev Add an address to the freemint
     * @param _array array of freemint struct
     */
    function setFreemints(FreemintItem[] memory _array) public onlyOwner {
        for (uint256 i = 0; i < _array.length; i++) {
            freemints[_array[i].minter] = _array[i].amount;
        }
    }

    /** @dev Add an address to the freemint
     * @param _array array of addresses, everybody gets one
     */
    function setFreemintAddresses(address[] calldata _array) public onlyOwner {
        for (uint256 i = 0; i < _array.length; i++) {
            freemints[_array[i]] = 1;
        }
    }

    // ██████╗  ██████╗ ██╗   ██╗ █████╗ ██╗  ████████╗██╗███████╗███████╗
    // ██╔══██╗██╔═══██╗╚██╗ ██╔╝██╔══██╗██║  ╚══██╔══╝██║██╔════╝██╔════╝
    // ██████╔╝██║   ██║ ╚████╔╝ ███████║██║     ██║   ██║█████╗  ███████╗
    // ██╔══██╗██║   ██║  ╚██╔╝  ██╔══██║██║     ██║   ██║██╔══╝  ╚════██║
    // ██║  ██║╚██████╔╝   ██║   ██║  ██║███████╗██║   ██║███████╗███████║
    // ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝   ╚═╝╚══════╝╚══════╝

    /**
     * @dev Set contract wide royalties
     * @param amount royalties value (between 0 and 10000)
     */
    function setRoyaltyAmount(uint256 amount) external onlyOwner {
        _royaltyAmount = amount;
    }

    // EIP2981 standard royalties query
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (owner(), (_salePrice / 10000) * _royaltyAmount);
    }

    // EIP2981 standard Interface return. Adds to ERC721 and ERC165 Interface returns.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    // ███████╗████████╗██╗  ██╗
    // ██╔════╝╚══██╔══╝██║  ██║
    // █████╗     ██║   ███████║
    // ██╔══╝     ██║   ██╔══██║
    // ███████╗   ██║   ██║  ██║
    // ╚══════╝   ╚═╝   ╚═╝  ╚═╝

    /** @dev Order prints from the frontend
     */
    function orderPrints() public payable {
        require(msg.value > 0, "Insufficient value");
        emit PrintOrdered(msg.sender, msg.value);
    }

    /**
     * @dev Withdraw ether to owner's wallet
     */
    function withdrawEth() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
