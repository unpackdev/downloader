// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Owned.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721.sol";

contract SoupcansNFT is ERC721, Owned, ReentrancyGuard {
    /// @dev of the form ipfs://wefewewr/
    string public baseTokenURI;
    /// @dev true id mint has started
    bool public mintStart;
    /// @dev mint price
    /// @dev in wei
    uint256 public price;
    /// @dev mint id
    uint256 public mintId;
    /// @dev reserved for private auction
    uint256 public constant RESERVED_PRIVATE = 10;
    /// @dev total supply
    uint256 public constant TOTAL_SUPPLY = 1000;

    constructor(string memory _baseTokenURI) ERC721("Soupcans", "SOUP") Owned(msg.sender) {
        baseTokenURI = _baseTokenURI;
    }

    /*//////////////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////////////*/

    /// @notice set uri for this contract
    /// @dev only owner can call it
    /// @param _baseTokenURI new ipfs hash
    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @notice start/stop mint
    function toggleMint(bool toggle) external onlyOwner {
        mintStart = toggle;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function mintForAuction() public onlyOwner {
        if (mintId < RESERVED_PRIVATE) {
            mintId++;
            _mint(msg.sender, mintId);
        }
    }

    /// @notice withdraw eth
    /// @dev only owner can call it
    function withdraw(address payable to) public onlyOwner {
        (bool success, ) = payable(to).call{value: address(this).balance}("");
        require(success, "TRY DIFFERENT ADDRESS");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return string.concat(baseTokenURI, Strings.toString(tokenId), ".json");
    }

    /*//////////////////////////////////////////////////////////////////////
                                MINT
    //////////////////////////////////////////////////////////////////////*/

    /// @notice mint called by msg.sender
    /// @dev mint must have started
    function mint() public payable nonReentrant {
        require(mintStart, "MINT HAS NOT STARTED");
        require(msg.value >= price, "MINT PRICE MORE THAN ETH SENT");
        require(mintId < TOTAL_SUPPLY, "SOLD OUT");
        mintId++;
        _mint(msg.sender, mintId);
    }

    receive() external payable {}
}
