// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";

contract ATCCMultiplierCard is
    ERC1155SupplyUpgradeable,
    ERC1155BurnableUpgradeable,
    OwnableUpgradeable
{
    using StringsUpgradeable for string;

    uint256 public constant MAX_SUPPLY = 720;
    //10x
    uint256 public constant CARD_1 = 1;
    //20x
    uint256 public constant CARD_2 = 2;
    //50x
    uint256 public constant CARD_3 = 3;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    //wallet to receive ETH
    address public wallet;

    //supply minted by token id
    mapping(uint256 => uint256) public tokenMinted;
    //price by token id
    mapping(uint256 => uint256) public cardPrice;
    mapping(uint256 => string) private _tokenUri;

    function initialize(
        string calldata _baseUri,
        string calldata _uri1,
        string calldata _uri2,
        string calldata _uri3,
        address _wallet
    ) external initializer {
        __Ownable_init();
        __ERC1155_init(_baseUri);
        __ERC1155Supply_init();
        __ERC1155Burnable_init();
        wallet = _wallet;
        name = "ATCC Multiplier Card";
        symbol = "ATCCx";
        _tokenUri[CARD_1] = _uri1;
        emit URI(_uri1, CARD_1);
        _tokenUri[CARD_2] = _uri2;
        emit URI(_uri2, CARD_2);
        _tokenUri[CARD_3] = _uri3;
        emit URI(_uri3, CARD_3);
        cardPrice[CARD_1] = 1.8 ether;
        cardPrice[CARD_2] = 3.6 ether;
        cardPrice[CARD_3] = 9 ether;
    }

    function setPrice(
        uint256 _price1,
        uint256 _price2,
        uint256 _price3
    ) external onlyOwner {
        cardPrice[CARD_1] = _price1;
        cardPrice[CARD_2] = _price2;
        cardPrice[CARD_3] = _price3;
    }

    function airdrop(
        address[] calldata receivers,
        uint256[] calldata _quantities,
        uint256[] calldata _ids
    ) external onlyOwner {
        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 _id = _ids[i];
            uint256 _quantity = _quantities[i];
            _beforeMint(_id, _quantity);
            tokenMinted[_id] += _quantity;
            _mint(receivers[i], _id, _quantity, "");
        }
    }

    function _beforeMint(uint256 _id, uint256 _quantity) internal view {
        require(
            tokenMinted[_id] + _quantity <= MAX_SUPPLY,
            "Exceeds max supply limit"
        );
        require(
            _id == CARD_1 || _id == CARD_2 || _id == CARD_3,
            "Invalid token id"
        );
    }

    /**
     * @dev Mints some amount of tokens to an address
     * @param _to          Address of the future owner of the token
     * @param _id          Token ID to mint
     * @param _quantity    Amount of tokens to mint
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity
    ) external payable {
        _beforeMint(_id, _quantity);
        require(msg.value >= cardPrice[_id] * _quantity, "Insufficient ETH");
        tokenMinted[_id] += _quantity;
        _mint(_to, _id, _quantity, "");
    }

    /**
     * @dev Mint tokens for each id in _ids
     * @param _to          The address to mint tokens to
     * @param _ids         Array of ids to mint
     * @param _quantities  Array of amounts of tokens to mint per id
     */
    function batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities
    ) external payable {
        uint256 _totalPrice;
        for (uint256 i; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            uint256 _quantity = _quantities[i];
            _beforeMint(_id, _quantity);
            _totalPrice += cardPrice[_id] * _quantity;
            tokenMinted[_id] += _quantity;
        }
        require(msg.value >= _totalPrice, "Insufficient ETH");
        _mintBatch(_to, _ids, _quantities, "");
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155SupplyUpgradeable, ERC1155Upgradeable) {
        ERC1155SupplyUpgradeable._beforeTokenTransfer(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function setTokenUri(uint256 _id, string calldata _uri) external onlyOwner {
        _tokenUri[_id] = _uri;
    }

    function updateWallet(address _wallet) external onlyOwner {
        wallet = _wallet;
    }

    function withdrawMoney() external onlyOwner {
        _withdraw();
    }

    function _withdraw() internal {
        uint256 bal = address(this).balance;
        (bool success1, ) = wallet.call{value: bal}("");
        require(success1, "Transfer failed.");
    }

    function uri(uint256 _id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(exists(_id), "Non existent NFT");
        return _tokenUri[_id];
    }
}
