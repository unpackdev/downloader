pragma solidity 0.8.12;

import "Ownable.sol";
import "ERC1155.sol";
import "Address.sol";


contract UANFT is ERC1155, Ownable {

    struct PublicMintData {
        uint256 mintPrice;
        bool enabled;
        bool created;
    }

    mapping(uint256 => PublicMintData) public tokenData;
    mapping(uint256 => string) private tokenUris;

    address public recipient;

    event RecipientChanged (address recipient);

    constructor() ERC1155("") {}

    function publicMint(uint256 tokenId, uint256 amount) external payable {
        PublicMintData storage mintData = tokenData[tokenId];
        require(mintData.enabled, "Minting not enabled");
        require(msg.value * amount >= mintData.mintPrice * amount, "Insuficcient funds");
        require(recipient != address(0), "Recipient not set");
        
        Address.sendValue(payable(recipient), msg.value);

        _mint(msg.sender, tokenId, amount, "");
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenData[tokenId].created, "Token not created");
        return tokenUris[tokenId];
    }

    function createToken(
        uint256 tokenId,
        uint256 mintPrice, 
        string memory tokenUri
    ) external onlyOwner {
        require(!tokenData[tokenId].created, "Token already created");
        require(bytes(tokenUri).length > 0, "URI required");

        tokenData[tokenId] = PublicMintData({
            mintPrice: mintPrice,
            enabled: true,
            created: true
        });
        tokenUris[tokenId] = tokenUri;
    }

    function toggleToken(uint256 tokenId, bool enabled) external onlyOwner {
        require(tokenData[tokenId].created, "Token not created");
        tokenData[tokenId].enabled = enabled;
    }

    function setRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Null address");
        recipient = newRecipient;
        emit RecipientChanged(newRecipient);
    }

}


