// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./ICandyShop.sol";

contract CandyShop is ERC1155Pausable, Ownable, ReentrancyGuard, ICandyShop {
    struct SKU {
        uint256 id;
        uint256 price;
        string name;
    }

    struct SKUInput {
        uint256 price;
        string name;
    }

    mapping(uint256 => SKU) public inventory;
    mapping(string => uint256) public skuIds;
    bytes32[] names;
    address public chainDreamersAddress;

    function addSku(SKUInput[] memory _skus) external onlyOwner {
        for (uint256 i = 0; i < _skus.length; i++) {
            if (names.length > 0) {
                require(
                    names[skuIds[_skus[i].name]] !=
                        keccak256(bytes(_skus[i].name)),
                    "Sku already exists"
                );
            }
            uint256 tokenId = names.length;
            skuIds[_skus[i].name] = tokenId;
            names.push(keccak256(bytes(_skus[i].name)));
            inventory[tokenId] = SKU(tokenId, _skus[i].price, _skus[i].name);
        }
    }

    function setChainDreamersAddress(address _chainDreamersAddress)
        external
        onlyOwner
    {
        chainDreamersAddress = _chainDreamersAddress;
    }

    function mint(uint256 tokenId, uint256 amount)
        external
        payable
        nonReentrant
    {
        require(tokenId < names.length, "This candy does not exist yet");
        require(
            msg.value == inventory[tokenId].price * amount,
            "You have to pay the price to eat candies"
        );
        _mint(_msgSender(), tokenId, amount, "");
        setApprovalForAll(chainDreamersAddress, true);
    }

    function mintBatch(uint256[] calldata tokenIds, uint256[] calldata amounts)
        external
        payable
        nonReentrant
    {
        uint256 price;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIds[i] < names.length,
                "This candy does not exist yet"
            );
            price += inventory[tokenIds[i]].price * amounts[i];
        }

        require(msg.value == price, "You have to pay the price to eat candies");

        _mintBatch(_msgSender(), tokenIds, amounts, "");
        setApprovalForAll(chainDreamersAddress, true);
    }

    function burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external override nonReentrant {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _burn(from, tokenId, amount);
    }

    function burnBatch(
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external override nonReentrant {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _burnBatch(from, tokenIds, amounts);
    }

    constructor(string memory uri_) ERC1155(uri_) {}

    receive() external payable {}

    function withdraw() public onlyOwner {
        (bool success, ) = _msgSender().call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
