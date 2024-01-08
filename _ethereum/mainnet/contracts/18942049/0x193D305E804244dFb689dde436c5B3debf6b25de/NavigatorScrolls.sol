// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";

contract NavigatorScrolls is ERC721A, Ownable, Pausable {
    uint256 internal constant RESERVED_SCROLLS = 100;
    uint256 public constant PUBLIC_MINTABLE_SCROLLS = 1900;
    uint256 public constant MAX_SCROLLS = 2000;
    uint256 public constant MAX_SCROLLS_PER_ADDRESS = 30;
    uint256 public constant SCROLL_PRICE = 0.10 ether;

    string public baseURI;
    string private URIExtension;

    error MaxSupplyExceeded();
    error MaxPerAddressExceeded();
    error InvalidMsgValue();

    constructor(
        string memory _uri,
        string memory _uriExt
    )
        ERC721A("Navigator Scrolls", "NAVSCROLL")
        Ownable(msg.sender)
    {
        baseURI = _uri;
        URIExtension = _uriExt;
        _pause();
    }

    function mint(uint256 _amount) external payable whenNotPaused {
        if (_totalMinted() + _amount > PUBLIC_MINTABLE_SCROLLS) revert MaxSupplyExceeded();
        if (_numberMinted(msg.sender) + _amount > MAX_SCROLLS_PER_ADDRESS) revert MaxPerAddressExceeded();
        if (msg.value < SCROLL_PRICE * _amount) revert InvalidMsgValue();

        _mint(msg.sender, _amount);
    }

    /// @notice Mints the reserved scrolls to the specified addresses
    /// @dev This function should only be called once the public mint has been completed, as it will deduct from the
    /// number of mintable scrolls.
    /// @param _amounts The amount of scrolls to mint for each address
    /// @param _receivers The addresses to mint the scrolls to
    function mintReserved(uint256[] calldata _amounts, address[] memory _receivers) external onlyOwner {
        for (uint256 i = 0; i < _amounts.length; i++) {
            _mint(_receivers[i], _amounts[i]);
        }
        if (_totalMinted() > MAX_SCROLLS) revert MaxSupplyExceeded();
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function withdraw() external onlyOwner {
        (bool success,) = payable(msg.sender).call{ value: address(this).balance }("");
        require(success, "Failed to withdraw ether");
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setURIExtension(string memory _uriExt) external onlyOwner {
        URIExtension = _uriExt;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), URIExtension));
    }
}
