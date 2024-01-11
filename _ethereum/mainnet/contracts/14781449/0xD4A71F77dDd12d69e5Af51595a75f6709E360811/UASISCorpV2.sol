// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./ECDSA.sol";

contract UASISCorpV2 is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    string public constant name = "UASIS CORP";
    string public constant symbol = "UASIS";

    uint256 public constant MAX_SUPPLY = 8888;

    address public signAddress;

    uint256 public mintIndex = 0;
    uint256 public swapIndex = 0;
    uint256 public totalTokensSupply = 0;

    mapping(uint256 => uint256) private _signatureIds;
    mapping(uint256 => uint256) private _swapSignatureIds;

    constructor(
        string memory newURI,
        address _signAddress
    ) ERC1155(newURI) {
        signAddress = _signAddress;
    }

    function mint(
        uint256 price,
        uint256 tokenId,
        uint256 amount,
        uint256 signatureId,
        bytes memory signature
    ) public payable {
        require(
            checkLimitNotReached(tokenId),
            "Max limit reached"
        );

        require(
            _signatureIds[signatureId] == 0,
            "signatureId already used"
        );

        require(
            checkMintSignature(msg.sender, price, tokenId, amount, signatureId, signature) == signAddress,
            "Not authorized to mint"
        );

        require(
            msg.value == price * amount,
            "Ether value sent is not correct"
        );

        _signatureIds[signatureId] = 1;
        mintIndex++;

        if (!exists(tokenId)) {
            totalTokensSupply++;
        }

        _mint(msg.sender, tokenId, amount, "");
    }

    function swapToken(
        uint256 tokenId,
        uint256 newTokenId,
        uint256 amount,
        uint256 newAmount,
        uint256 swapSignatureId,
        bytes memory signature
    ) public {
        require(
            _swapSignatureIds[swapSignatureId] == 0,
            "swapSignatureId already used"
        );

        require(
            checkSwapSignature(msg.sender, tokenId, newTokenId, amount, newAmount, swapSignatureId, signature) == signAddress,
            "Not authorized to swap"
        );

        _swapSignatureIds[swapSignatureId] = 1;
        swapIndex++;

        burn(msg.sender, tokenId, amount);
        _mint(msg.sender, newTokenId, newAmount, "");
    }

    function mintBatch(
        uint256 tokenId,
        address[] memory to,
        uint256[] memory amounts
    ) public onlyOwner {
        require(
            checkLimitNotReached(tokenId),
            "Max limit reached"
        );

        if (!exists(tokenId)) {
            totalTokensSupply++;
        }

        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], tokenId, amounts[i], "");
        }
    }

    function setURI(string memory newURI) public onlyOwner {
        _setURI(newURI);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function checkMintSignature(
        address wallet,
        uint256 price,
        uint256 tokenId,
        uint256 amount,
        uint256 signatureId,
        bytes memory signature
    ) public pure returns (address) {
        return ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encode(wallet, price, tokenId, amount, signatureId))
            ), signature
        );
    }

    function checkSwapSignature(
        address wallet,
        uint256 tokenId,
        uint256 newTokenId,
        uint256 amount,
        uint256 newAmount,
        uint256 signatureId,
        bytes memory signature
    ) public pure returns (address) {
        return ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encode(wallet, tokenId, newTokenId, amount, newAmount, signatureId))
            ), signature
        );
    }

    function checkLimitNotReached(uint256 tokenId) internal view returns (bool) {
        if (!exists(tokenId)) {
            return totalTokensSupply + 1 <= MAX_SUPPLY;
        }

        return true;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

}
