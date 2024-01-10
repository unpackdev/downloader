// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; 

import "./ERC721Burnable.sol";
import "./ERC721Royalty.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";
import "./Address.sol";

contract COLORWAYS is ERC721, ERC721Royalty, ERC721Burnable, Pausable, Ownable {
    uint256 public currentMintLimit = 33;
    uint256 public unitPrice = 100000000000000000; //0.1 ether
    string public defaultBaseURI;
    bytes32 private presaleRoot;

    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter; 

    // Switches
    bool private publicSaleActive;
    bool private preSaleActive;
    bool private whiteListOn;


    constructor(string memory _newBaseURI) ERC721("COLORWAYS", "COLORWAYS") {
        setBaseURI(_newBaseURI);
        tokenIdCounter.increment();
    }

    function _baseURI() internal view override returns (string memory) {
        return defaultBaseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        defaultBaseURI = _newBaseURI;
    }

    function setCurrentMintLimit(uint256 _currentMintLimit) public onlyOwner {
        currentMintLimit = _currentMintLimit;
    }

    function setPresaleMintHash(bytes32 _root) external onlyOwner {
        presaleRoot = _root;
    }

    function startPreSale(uint256 _unitPrice, bool _whitelistOn) external onlyOwner
    {
        require(!preSaleActive, "Private Sale Started already");
        unitPrice = _unitPrice;
        whiteListOn = _whitelistOn;
        preSaleActive = true;
    }

    function pausePreSale() external onlyOwner {
        require(preSaleActive, "Private Sale not active");
        preSaleActive = false;
    }

    function startSale(uint256 _unitPrice) external onlyOwner
    {
        require(!publicSaleActive, "Started already");
        unitPrice = _unitPrice;
        publicSaleActive = true;
    }

    function pauseSale() external onlyOwner {
        require(publicSaleActive, "Sale not active");
        publicSaleActive = false;
    }

    function safeMint(address to) private {
        _safeMint(to, tokenIdCounter.current());
        tokenIdCounter.increment();
    }

    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32 root, bytes32[] memory proof)
    internal pure returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    function presaleMint(uint256 numTokens, bytes32[] calldata proof) external payable
    {
        require(preSaleActive, "Presale not active");
        require(numTokens > 0 && numTokens <= 5, "Invalid Number of Tokens");
        require(unitPrice * numTokens <= msg.value, "Not Enough Ether");
        require((totalSupply() + numTokens) <= currentMintLimit, "Exceed Max Supply");
        require(!whiteListOn || _verify(_leaf(msg.sender), presaleRoot, proof), "Invalid address for presale mint");

        for (uint256 i = 0; i < numTokens; i++) {
            safeMint(msg.sender);
        }
    }

    function mintInternal(address [] memory to, uint256 [] memory numTokens) external onlyOwner {
        for (uint256 i = 0; i < to.length; i++) {
            require((totalSupply() + numTokens[i]) <= currentMintLimit, "Exceed Max Supply");
            for (uint256 j = 0; j < numTokens[i]; j++) {
                safeMint(to[i]);
            }
        }
    }

    function mint(uint256 numTokens) external payable {
        require(publicSaleActive, "Sale not active");
        require(numTokens > 0 && numTokens <= 5, "Invalid Number of Tokens");
        require(unitPrice * numTokens <= msg.value, "Not Enough Ether");
        require((totalSupply() + numTokens) <= currentMintLimit, "Exceed Max Supply");

        for (uint256 i = 0; i < numTokens; i++) {
            safeMint(msg.sender);
        }
    }

    function setRoyalties(address recipient, uint96 fraction) external onlyOwner {
        _setDefaultRoyalty(recipient, fraction);
    }

    function totalSupply() public view returns (uint) {
        return tokenIdCounter.current() - 1;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Royalty)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }
}
