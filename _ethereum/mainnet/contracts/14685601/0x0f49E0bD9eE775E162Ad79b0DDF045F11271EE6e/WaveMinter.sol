// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";

interface ERC721Tradable {
    function mintTo(address _to, uint256 _quantity) external;

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) external;

    function setUriPrefix(string memory _uriPrefix) external;

    function transferOwnership(address _to) external;
}

contract WaveMinter is Ownable {
    uint256 public availableSupply = 5856;

    uint256 public PRICE = 0.17 ether;
    uint256 public constant MAX_PER_TX = 25;
    uint256 public MAX_PER_WALLET = 25;

    bool public mintPaused = true;

    mapping(address => uint256) public mintedSale;
    mapping(address => bool) public whitelisted;

    address public immutable erc721;

    constructor(address _erc721) {
        erc721 = _erc721;
    }

    /**
     * @dev Mint N amount of ERC721 tokens
     */
    function mint(uint256 _quantity) public payable {
        require(_quantity > 0, "Mint atleast 1 token");
        require(_quantity <= MAX_PER_TX, "Exceeds max per transaction");
        require(mintPaused == false, "Minting is currently paused");
        require(
            mintedSale[msg.sender] + _quantity <= MAX_PER_WALLET,
            "Exceeds max per wallet"
        );
        require(
            msg.value >= PRICE * _quantity,
            "Insufficient funds"
        );
        mintedSale[msg.sender] += _quantity;
        ERC721Tradable(erc721).mintTo(msg.sender, _quantity);
    }

    /**
     * @dev Withdraw ether to multisig safe
     */

    function withdraw() external onlyOwner {
        (bool os, ) = payable(0xaa75c25E17283aEf4E1099A1ad6dd8B8eF79529c).call{
            value: address(this).balance
        }("");
        require(os);
    }

    /**
     * ------------ CONFIGURATION ------------
     */

    /**
     * @dev Pause/unpause sale
     */

    function setPaused(bool _state) external onlyOwner {
        mintPaused = _state;
    }

    /**
     * @dev Recovers the ERC721 token
     */

    function recoverERC721Ownership() external onlyOwner {
        ERC721Tradable(erc721).transferOwnership(msg.sender);
    }

    /**
     * @dev Sets the amount of ERC721 can be purchased per wallet
     */

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        MAX_PER_WALLET = _maxPerWallet;
    }

    /**
     * @dev Sets the price of ERC721 can be minted for
     */

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        PRICE = _mintPrice;
    }

}
