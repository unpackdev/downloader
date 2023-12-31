// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC721A.sol";
import "./ERC2981.sol";
import "./Ownable.sol";

contract DCLUB_Token is ERC721A, ERC2981, Ownable {
    uint256 private immutable ABSOLUTE_MAX;

    string public BASE_URI;
    uint256 public maxSupply;
    bool public maxSupplyLocked;
    address public minter;

    constructor(
        uint256 _absoluteMax,
        uint256 _maxSupply,
        address _royaltyReceiver,
        uint96 _royaltyFeeNumerator
    ) ERC721A("DeliciousClub", "DCLUB") {
        ABSOLUTE_MAX = _absoluteMax;
        maxSupply = _maxSupply;
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeNumerator);
    }

    modifier canMint(uint256 quantity) {
        require(quantity > 0, "DCLUB: Quantity must be larger than 0.");
        require(_totalMinted() + 1 <= maxSupply, "DCLUB: Mint has sold out.");
        require(
            _totalMinted() + quantity <= maxSupply,
            "DCLUB: Mint will exceed max supply."
        );
        _;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function mint(
        address receiver,
        uint256 quantity
    ) external canMint(quantity) {
        require(minter == _msgSender(), "DCLUB: Caller is not the minter.");
        _mint(receiver, quantity);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function lockMaxSupply() external onlyOwner {
        require(!maxSupplyLocked, "DCLUB: Supply already locked.");
        maxSupplyLocked = true;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(!maxSupplyLocked, "DCLUB: Supply is locked.");
        require(
            _maxSupply <= ABSOLUTE_MAX,
            "DCLUB: Max supply cannot be higher than the absolute max."
        );
        require(
            _maxSupply >= _totalMinted(),
            "DCLUB: Max supply cannot be lower than total minted."
        );
        maxSupply = _maxSupply;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        BASE_URI = _newBaseURI;
    }

    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "DCLUB: Minter cannot be zero.");
        minter = _minter;
    }

    function setRoyalty(address _receiver, uint96 _value) external onlyOwner {
        _setDefaultRoyalty(_receiver, _value);
    }
}
