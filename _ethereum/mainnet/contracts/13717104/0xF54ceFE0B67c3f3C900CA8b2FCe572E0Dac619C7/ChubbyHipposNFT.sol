// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import "./ERC1155PresetMinterPauserUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ERC1155.sol";
import "./AccessControlEnumerable.sol";
import "./OwnableUpgradeable.sol";
import "./IWatermelonToken.sol";

/**
 * @title ChubbyHippos contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic interface
 */
contract ChubbyHipposNFT is ERC721Upgradeable, OwnableUpgradeable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint oneMintPrice;
    uint twoMintPrice;
    uint threeMintPrice;
    uint fourMintPrice;

    uint16 maxSupply;
    uint16 totalMinted;
    uint16 totalReserved;
    uint16 maxMintable;
    bool PAUSED;
    bool REVEALED;

    string baseExtension;
    string baseUri;
    string notRevealedUri;

    IWatermelonToken watermelonToken;

    function init() initializer public {
        __Ownable_init();
        __ERC721_init("ChubbyHippos", "CHUBBY");

        oneMintPrice = 0.08 ether;
        twoMintPrice = 0.14 ether;
        threeMintPrice = 0.18 ether;
        fourMintPrice = 0.2 ether;

        maxSupply = 4444;
        totalReserved = 144;
        PAUSED = false;
        REVEALED = false;

        baseExtension = ".json";
        notRevealedUri = "https://chubbyhippos.mypinata.cloud/ipfs/QmTXZXXYXWiQHAo7jcqoKJeak5xFAqjsTU9tv9RK2fvAp1";
    }

    /***************************************
     *                                     *
     *            Contract funds           *
     *                                     *
     ***************************************/

    /*
     * Withdraw eth from the contract
     */
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /*
     * Check balance of the contract
     */
    function checkBalance() public view onlyOwner returns (uint) {
        return address(this).balance;
    }

    /***************************************
     *                                     *
     *          Contract settings          *
     *                                     *
     ***************************************/

//    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
//        return interfaceId == type(IERC721Upgradeable).interfaceId ||
//                interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
//                super.supportsInterface(interfaceId);
//    }

    /*
     * Set's the URI in case there's a need to be changed
     */
    function setBaseUri(string memory URIParam) public onlyOwner {
        baseUri = URIParam;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    /*
     * Set's the notRevealedUri in case there's a need to be changed
     */
    function setNotRevealedURI(string memory notRevealedURIParam) public onlyOwner {
        notRevealedUri = notRevealedURIParam;
    }

    /*
    * Toggle of token URI's reveal
    */
    function toggleReveal() public onlyOwner {
        REVEALED = !REVEALED;
    }

    /*
    * Toggle of token URI's reveal
    */
    function togglePause() public onlyOwner {
        PAUSED = !PAUSED;
    }

    /***************************************
     *                                     *
     *          Emergency settings         *
     *                                     *
     ***************************************/

    /*
     * Set's the mint price in case the eth price fluctuates too much
     */
    function setMintPrice(uint onePrice, uint twoPrice, uint threePrice, uint fourPrice) public onlyOwner {
        oneMintPrice = onePrice;
        twoMintPrice = twoPrice;
        threeMintPrice = threePrice;
        fourMintPrice = fourPrice;
    }

    /*
     * Set's the max supply, this really shouldn't be used but it's here in case there are some community needs.
     */
    function setMaxSupply(uint maxSupplyParam) public onlyOwner {
        maxSupply = uint16(maxSupplyParam);
    }

    /*
     * Get's the max supply.
     */
    function getMaxSupply() public view returns (uint) {
        return maxSupply;
    }

    /*
     * Set's the max mintable, this really shouldn't be used but it's here in case there are some community needs.
     */
    function setMaxReserved(uint maxReservedParam) public onlyOwner {
        totalReserved = uint16(maxReservedParam);
    }

    /*
     * Get's the max mintable.
     */
    function getMaxReserved() public view returns (uint) {
        return totalReserved;
    }

    function setWatermelonTokenAddress(address _address) external onlyOwner {
        watermelonToken = IWatermelonToken(_address);
    }

    /***************************************
     *                                     *
     *            Contract Logic           *
     *                                     *
     ***************************************/

    /**
     * Reserve some tokens
     */
    function reserveTokens(uint amount) public onlyOwner {
        require(uint256(totalMinted).add(amount) <= uint256(maxSupply), "Purchase exceeds max supply of Mintable Tokens");

        totalReserved -= uint16(amount);
        safeMint(amount);
    }

    /**
    * Mint
    */
    function mintOne() public payable {
        mint(1, oneMintPrice);
    }

    function mintTwo() public payable {
        mint(2, twoMintPrice);
    }

    function mintThree() public payable {
        mint(3, threeMintPrice);
    }

    function mintFour() public payable {
        mint(4, fourMintPrice);
    }

    function mint(uint amount, uint cost) internal {
        require(!PAUSED, "Minting is currently paused. Check later.");
        require(uint256(totalMinted).add(totalReserved).add(amount) <= uint256(maxSupply), "Purchase exceeds max supply of Mintable Tokens");
        require(cost <= msg.value, "Ether value sent is not correct.");

        safeMint(amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (REVEALED == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

    /***************************************
     *                                     *
     *         Underlying structure        *
     *                                     *
     ***************************************/

    function totalSupply() external view returns (uint256){
        return totalMinted;
    }

    function calculatedSupply() external view returns (uint256) {
        return totalMinted + totalReserved;
    }

    /**
     * Send mint to sender's account.
     */
    function safeMint(uint amount) private {
        for (uint i = 0; i < amount; i++) {
            uint mintIndex = totalMinted + i;

            if (totalMinted < maxSupply) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        totalMinted += uint16(amount);
    }

    /***************************************
     *                                     *
     *               Overrides             *
     *                                     *
     ***************************************/

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        watermelonToken.updateRewards(from, to);
    }

}