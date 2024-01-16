// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract Confetti is ERC1155, ERC1155Supply, Ownable, ReentrancyGuard {
    using Strings for uint256;

    enum Type {
        Sketch,
        Ruby9100M,
        BAFTA_Exclusive,
        Green,
        Yellow,
        Blue,
        Red,
        Pink
    }

    uint256 public constant MAX_SUPPLY = 2222;
    uint256 public constant AMOUNT_FOR_FREEMINT = 200;
    uint256 public constant AMOUNT_FOR_MARKETING = 100;

    uint256 public numberMinted;
    uint256 public maxPerAddressForFree = 1;
    uint256 public maxPerAddressForPublic = 3;

    mapping(Type => uint256) public maxSupplyForTokenId;
    uint256 public publicSaleTime;
    bool public devMinted = false;

    mapping(address => uint256) private _count;

    string private _name;

    string private _symbol;

    address private _flowerAddress;

    mapping(uint256 => string) private _tokenURIs;

    Type[8] private _types = [
        Type.Sketch,
        Type.Ruby9100M,
        Type.BAFTA_Exclusive,
        Type.Green,
        Type.Yellow,
        Type.Blue,
        Type.Red,
        Type.Pink
    ];

    Type[] private _availableTypes = [
        Type.Green,
        Type.Yellow,
        Type.Blue,
        Type.Red,
        Type.Pink
    ];

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        uint256 publicSaleTime_
    ) ERC1155(uri_) {
        _name = name_;
        _symbol = symbol_;
        publicSaleTime = publicSaleTime_;

        maxSupplyForTokenId[Type.Sketch] = 1;
        maxSupplyForTokenId[Type.Ruby9100M] = 1;
        maxSupplyForTokenId[Type.BAFTA_Exclusive] = 20;
        maxSupplyForTokenId[Type.Green] = 440;
        maxSupplyForTokenId[Type.Yellow] = 440;
        maxSupplyForTokenId[Type.Blue] = 440;
        maxSupplyForTokenId[Type.Red] = 440;
        maxSupplyForTokenId[Type.Pink] = 440;
    }

    function _pickRandomType(uint256 lastTokenType_) private returns (uint256) {
        uint256 tokenType = uint256(
            keccak256(
                abi.encodePacked(
                    tx.origin,
                    blockhash(block.number),
                    block.timestamp,
                    lastTokenType_
                )
            )
        ) % _availableTypes.length;
        Type t = _availableTypes[tokenType];

        if (totalSupply(tokenType) >= maxSupplyForTokenId[t]) {
            for (uint i = 0; i < _availableTypes.length; i++) {
                if (_availableTypes[i] == t) {
                    _availableTypes[i] = _availableTypes[
                        _availableTypes.length - 1
                    ];
                    _availableTypes.pop();
                }
            }
            return _pickRandomType(tokenType);
        }
        return uint256(t);
    }

    function price() public view returns (uint256) {
        return
            numberMinted < AMOUNT_FOR_FREEMINT + AMOUNT_FOR_MARKETING
                ? 0
                : 0.1 ether;
    }

    function devMint(address recipient) external onlyOwner {
        require(!devMinted, "Already minted");
        require(
            numberMinted + AMOUNT_FOR_MARKETING <= MAX_SUPPLY,
            "Over max supply"
        );

        devMinted = true;

        uint256[] memory ids = new uint256[](3);
        uint256[] memory amounts = new uint256[](3);

        ids[0] = uint256(Type.Sketch);
        ids[1] = uint256(Type.Ruby9100M);
        ids[2] = uint256(Type.BAFTA_Exclusive);
        amounts[0] = maxSupplyForTokenId[Type.Sketch];
        amounts[1] = maxSupplyForTokenId[Type.Ruby9100M];
        amounts[2] = maxSupplyForTokenId[Type.BAFTA_Exclusive];

        _mintBatch(recipient, ids, amounts, "");
        numberMinted += 22;

        for (uint i = 0; i < AMOUNT_FOR_MARKETING - 22; i++) {
            uint256 tokenType = _pickRandomType(numberMinted);

            _mint(recipient, tokenType, 1, "");
            numberMinted++;
        }
    }

    function mint(uint256 quantity) external payable {
        require(msg.sender == tx.origin, "Only EOA");
        require(block.timestamp >= publicSaleTime, "Public sale has not begun yet");
        require(numberMinted + quantity <= MAX_SUPPLY, "Exceeded max supply");
        require(_count[msg.sender] == 0, "Already minted");

        uint256 cost = price() * quantity;
        require(msg.value >= cost, "Need to send more eth");

        _count[msg.sender] = quantity;
        if (price() == 0) {
            require(quantity <= maxPerAddressForFree, "Quantity to mint too high");
        } else {
            require(quantity <= maxPerAddressForPublic, "Quantity to mint too high");
        }

        for (uint i = 0; i < quantity; i++) {
            uint256 tokenType = _pickRandomType(numberMinted);
            _mint(msg.sender, tokenType, 1, "");
            numberMinted++;
        }

        if (msg.value > 0) {
            refundIfOver(cost);
        }
    }

    function refundIfOver(uint256 cost) private {
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool _success, ) = msg.sender.call{value: address(this).balance}("");
        require(_success, "Transfer failed");
    }

    function setURI(string memory newURI) external onlyOwner {
        _setURI(newURI);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return bytes(super.uri(tokenId)).length > 0 ? string(abi.encodePacked(super.uri(tokenId), tokenId.toString(), '.json')) : super.uri(tokenId);
    }

    function setPublicSaleTime(uint256 publicSaleTime_) external onlyOwner {
        publicSaleTime = publicSaleTime_;
    }

    function setMaxPerAddressForFree(uint256 amount) external onlyOwner {
        maxPerAddressForFree = amount;
    }

    function setMaxPerAddressForPublic(uint256 amount) external onlyOwner {
        maxPerAddressForPublic = amount;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
