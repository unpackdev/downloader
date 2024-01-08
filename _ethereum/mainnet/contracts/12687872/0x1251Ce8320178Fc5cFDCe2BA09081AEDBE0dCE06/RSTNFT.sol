//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC1155Burnable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract RSTNFT is ERC1155Burnable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    string tokenUri = "https://rst-api.vercel.app/api/item/";

    bool public isSaleOpen;

    uint256 public total = 100;
    uint256 public sold;
    uint256 public price = 0.1 ether;
    uint256 public keyTokenId = 0;

    address payable merchantAddress;

    constructor(string memory _tokenUri, address payable _merchantAddr)
        ERC1155("https://rst-api.vercel.app/api/item/")
    {
        tokenUri = _tokenUri;
        merchantAddress = _merchantAddr;
    }

    function setTokenURI(string calldata _uri) public onlyOwner {
        tokenUri = _uri;
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for all token types. It relies
     * on the token type ID substituion mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the \{id\} substring with the
     * actual token type ID.
     */
    function uri(uint256 _id) public view override returns (string memory) {
        return
            bytes(tokenUri).length > 0
                ? string(abi.encodePacked(tokenUri, _id.toString()))
                : "";
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyOwner {
        _mint(account, id, amount, data);
    }

    function setSaleOpen(bool isOpen) external onlyOwner {
        isSaleOpen = isOpen;
    }

    function purchaseNFT() external payable {
        require(isSaleOpen, "Sale not started!");
        require(sold < total, "Sold out!");
        require(msg.value >= price, "Not enough to purchase!");
        // require(
        //     balanceOf(_msgSender(), keyTokenId) == 0,
        //     "You already own NFT!"
        // );

        uint256 overPrice = msg.value.sub(price);

        if (overPrice > 0) {
            payable(_msgSender()).transfer(overPrice);
        }

        merchantAddress.transfer(price);

        sold = sold.add(1);
        _mint(_msgSender(), keyTokenId, 1, "");
    }
}
