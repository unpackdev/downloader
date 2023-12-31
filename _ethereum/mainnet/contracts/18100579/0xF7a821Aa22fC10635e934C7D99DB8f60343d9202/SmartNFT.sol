// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

//    _____                      __  _   ______________
//   / ___/____ ___  ____ ______/ /_/ | / / ____/_  __/
//   \__ \/ __ `__ \/ __ `/ ___/ __/  |/ / /_    / /   
//  ___/ / / / / / / /_/ / /  / /_/ /|  / __/   / /    
// /____/_/ /_/ /_/\__,_/_/   \__/_/ |_/_/     /_/     
                                                    
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./ReentrancyGuard.sol";

/// @notice Merging machine learning with non-fungible technology onchain.

contract SmartNFT is ERC721A, ERC2981, ReentrancyGuard, Ownable {
    string private _baseUri = "https://smartnft.nftearth.exchange/api/metadata?id=";
    uint256 _mintPrice = 0.05 ether;
    bool _enableSale = false;

    event AvatarCreated (
        uint256 tokenId,
        string userId,
        address minter
    );

    constructor(address _royaltyReceiver) ERC721A("SmartNFT", "AINFT") {
        _setDefaultRoyalty(_royaltyReceiver, 500);
    }

    function creatorMint(address _to, string memory _userId) public onlyOwner {
        uint256 _mintTokenId = _nextTokenId();
        _safeMint(_to, 1);
        emit AvatarCreated(_mintTokenId, _userId, _to);
    }

     function mint(address _to, string memory _userId) public payable callerIsUser {
        require(_enableSale, "Mint is closed");
        require(_mintPrice <= msg.value, "Invalid payment amount");

        uint256 _mintTokenId = _nextTokenId();
        _safeMint(_to, 1);
        emit AvatarCreated(_mintTokenId, _userId, _to);
    }

    function burn(uint256 _tokenId) public {
        _burn(_tokenId);
    }

    function setBaseUri(string memory newBaseUri) public onlyOwner {
        _baseUri = newBaseUri;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function toggleSale() external onlyOwner {
        _enableSale = !_enableSale;
    }

    function _startTokenId() internal view override virtual returns (uint256) {
      return 1;
    }

    function _baseURI() internal view override virtual returns (string memory) {
        return _baseUri;
    }

    function withdrawETH() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}