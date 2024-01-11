// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Strings.sol";

error ContractPaused();

contract GameboyCodaContract is ERC721A, ReentrancyGuard, Ownable, Pausable {
    using Strings for uint256;

    // var for token uri
    string public uriPrefix;
    string public uriSuffix = ".json";
  
    // switch for sale active
    bool public isSaleActive = false;

    // free first
    // to the public price before the public
    uint256 public price = 0 ether;

    // 3000 for free
    uint256 public maxSupply = 3000;

    uint256 public maxAllowedMints = 2;

    constructor() ERC721A("GameboyKoda", "GBK") {
        setUriPrefix("ipfs://__CID__/");
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : "";
    }

    // function for pause
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        if (paused()) revert ContractPaused();
    }

    // function for mint
    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        require(price != _newMintPrice, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        price = _newMintPrice;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(maxSupply != _maxSupply, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        maxSupply = _maxSupply;
    }

    function setPublic() public onlyOwner {
        price = 0.005 ether;
        maxSupply = 9854;
    }

    function setSaleState(bool _saleActiveState) public onlyOwner {
        require(isSaleActive != _saleActiveState, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        isSaleActive = _saleActiveState;
    }

    function setMaxAllowMints(uint256 _maxAllowedMints) public onlyOwner {
        require(maxAllowedMints != _maxAllowedMints, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        maxAllowedMints = _maxAllowedMints;
    }

    function mint(
        uint256 _mintAmount
    ) external payable virtual nonReentrant {
        require(isSaleActive, "SALE_IS_NOT_ACTIVE");
        require(_mintAmount > 0 && _mintAmount <= maxAllowedMints, "INVALID_MINT_AMOUNT");
        unchecked {
            require(_numberMinted(msg.sender) + _mintAmount <= maxAllowedMints, "MINT_TOO_MUCH");
            require(totalSupply() + _mintAmount <= maxSupply, "NOT_ENOUGH_MINTS_AVAILABLE");
        }
        if (price != 0) {
             // Imprecise floats are scary, adding margin just to be safe to not fail txs
            require(msg.value >= ((price * _mintAmount) - 0.0001 ether) && msg.value <= ((price * _mintAmount) + 0.0001 ether), "INVALID_PRICE");
        }
        // ALL checks passed
        _safeMint(msg.sender, _mintAmount);
    }

    function gift(address _receiver, uint256 _mintAmount) external onlyOwner {
        unchecked {
            // Uncheck reason as same as mint
            require(totalSupply() + _mintAmount <= maxSupply, "MINT_TOO_LARGE");
        }
        _safeMint(_receiver, _mintAmount);
    }

    /**
     * @notice Allow contract owner to withdraw to specific accounts
     */
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(0xDCa454ec78ba5463F3Ac713982291C58790bc85D).send(balance));
    }
}