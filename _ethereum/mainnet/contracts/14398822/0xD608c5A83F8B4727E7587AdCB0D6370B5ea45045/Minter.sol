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

interface IMintPass {
    function whitelisted(address _address) external view returns (bool);
}

contract Minter is Ownable {
    uint256 public availableSupply = 6337;

    uint256 public constant WL_PRICE = 0.15 ether;
    uint256 public constant PUBLIC_PRICE = 0.17 ether;
    uint256 public constant MAX_PER_TX = 5;
    uint256 public MAX_PER_WALLET = 5;

    bool public mintEnded = false;
    bool public mintPaused = true;
    bool public whitelistedOnly = true;

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
        require(mintEnded == false, "Minting has ended");
        if (whitelistedOnly == true) {
            require(whitelisted[msg.sender] == true, "Address not whitelisted");
            require(
                mintedSale[msg.sender] + _quantity <= MAX_PER_WALLET,
                "Exceeds max per wallet"
            );
            require(msg.value >= WL_PRICE * _quantity, "Insufficient funds");
        } else {
            require(
                mintedSale[msg.sender] + _quantity <= MAX_PER_WALLET,
                "Exceeds max per wallet"
            );
            require(
                msg.value >= PUBLIC_PRICE * _quantity,
                "Insufficient funds"
            );
        }
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
     * @dev Sets the addresses that are allowed to mint during wl-only
     */

    function setWhitelisted(address[] memory _addresses, bool _state)
        external
        onlyOwner
    {
        for (uint256 i; i < _addresses.length; i++) {
            whitelisted[_addresses[i]] = _state;
        }
    }

    /**
     * @dev Close sale permanently
     */

    function endMint() external onlyOwner {
        mintEnded = true;
    }

    /**
     * @dev Pause/unpause sale
     */

    function setPaused(bool _state) external onlyOwner {
        mintPaused = _state;
    }

    /**
     * @dev Set state to wl-only sale
     */

    function setWhitelistedOnly(bool _state) external onlyOwner {
        whitelistedOnly = _state;
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

}
