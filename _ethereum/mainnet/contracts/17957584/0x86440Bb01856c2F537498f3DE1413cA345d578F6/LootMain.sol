// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./ERC2981.sol";
import "./Strings.sol";
import "./DefaultOperatorFilterer.sol";

//                                .__        ___.
//  ____________ _______   ____    |  | _____ \_ |__   ______
//  \_  __ \__  \\_  __ \_/ __ \   |  | \__  \ | __ \ /  ___/
//   |  | \// __ \|  | \/\  ___/   |  |__/ __ \| \_\ \\___ \
//   |__|  (____  /__|    \___  >  |____(____  /___  /____  >
//              \/            \/             \/    \/     \/
//
// Apepe Loot
// the universe expands..
//

error MintEnded();
error MintNotStarted();
error MintNotReleased();
error PassTokenUsageExceeded();
error WrongMechanismUsed();
error LimitExceeded();

interface IDelegationRegistry {
    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (bool);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract ApepeLoot is
    ERC1155,
    ERC1155Burnable,
    ERC1155Supply,
    ERC2981,
    Ownable,
    DefaultOperatorFilterer
{
    IDelegationRegistry dc;
    string public name;
    string public symbol;
    string baseURI = "";
    string baseExtension = ".json";
    address payable private payoutAddress;

    struct CollectionConfig {
        address collection;
        uint256 price;
        uint16 usagePerPass;
    }

    struct TokenConfig {
        uint8 mechanism; // 0 = mint(), 1 = contractMint()
        CollectionConfig[] collectionConfigs;
        uint256 limit;
        uint256 startDate;
        uint256 endDate;
    }

    mapping(uint256 => TokenConfig) tokenConfig;
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) passTokenUsage; // passAddress => passId => tokenId => usage
    mapping(uint256 => address) public mintingContracts;
    mapping(uint256 => bool) public mintEnded;
    mapping(uint256 => uint) public minted;

    constructor(IDelegationRegistry _dc) ERC1155("") {
        name = "Apepe Loot";
        symbol = "LOOT";
        payoutAddress = payable(msg.sender);
        dc = _dc;
    }

    function getMinted(uint256 tokenId) public view returns (uint256) {
        return minted[tokenId];
    }

    function mint(
        uint256 _id,
        uint256 _quantity,
        address _passAddress,
        uint256 _passId,
        address _vault
    ) external payable {
        if (tokenConfig[_id].startDate == 0) revert MintNotReleased();
        if (tokenConfig[_id].startDate >= block.timestamp)
            revert MintNotStarted();
        if (mintEnded[_id] || block.timestamp >= tokenConfig[_id].endDate)
            revert MintEnded();
        if (tokenConfig[_id].mechanism != 0) revert WrongMechanismUsed();
        if (minted[_id] + _quantity > tokenConfig[_id].limit)
            revert LimitExceeded();

        CollectionConfig[] memory collections = tokenConfig[_id]
            .collectionConfigs;

        uint256 price;
        uint16 usagePerPass;
        address collection;

        for (uint256 i = 0; i < collections.length; i++) {
            if (collections[i].collection == _passAddress) {
                price = collections[i].price;
                collection = collections[i].collection;
                usagePerPass = collections[i].usagePerPass;
            }
        }

        require(collection != address(0), "Pass address not found");

        if (
            passTokenUsage[_passAddress][_passId][_id] + _quantity >
            usagePerPass
        ) revert PassTokenUsageExceeded();

        require(msg.value >= price, "Enter the correct amount");

        address requester = msg.sender;
        if (_vault != address(0)) {
            bool isDelegateValid = dc.checkDelegateForToken(
                requester,
                _vault,
                collection,
                _passId
            );
            require(isDelegateValid, "Invalid delegate-vault pairing");
            requester = _vault;
        }
        require(
            IERC721(collection).ownerOf(_passId) == requester,
            "Not the owner of pass id"
        );

        passTokenUsage[_passAddress][_passId][_id] += _quantity;
        minted[_id] += _quantity;
        _mint(requester, _id, _quantity, "0x00");
    }

    function contractMint(
        address _to,
        uint256 _id,
        uint256 _quantity
    ) external payable {
        require(
            msg.sender == mintingContracts[_id],
            "Can only be called from minter contract"
        );

        if (tokenConfig[_id].startDate == 0) revert MintNotReleased();
        if (block.timestamp >= tokenConfig[_id].endDate) revert MintEnded();
        if (mintEnded[_id]) revert MintEnded();
        if (tokenConfig[_id].mechanism != 1) revert WrongMechanismUsed();
        if (minted[_id] + _quantity > tokenConfig[_id].limit)
            revert LimitExceeded();

        minted[_id] += _quantity;
        _mint(_to, _id, _quantity, "0x00");
    }

    function endMint(uint256 _tokenId) external onlyOwner {
        require(!mintEnded[_tokenId], "Already Ended");
        mintEnded[_tokenId] = true;
    }

    function setURI(string memory newUri) public onlyOwner {
        baseURI = newUri;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory currentBaseURI = baseURI;

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function setMintingContract(address _addr, uint256 _id) external onlyOwner {
        mintingContracts[_id] = _addr;
    }

    function setTokenConfig(
        uint256 _tokenId,
        uint8 _mechanism,
        address[] memory _collections,
        uint256[] memory _prices,
        uint16[] memory _usagePerPasses,
        uint256 _limit,
        uint256 _startDate,
        uint256 _endDate
    ) external onlyOwner {
        require(
            (_collections.length == _prices.length) &&
                (_collections.length == _usagePerPasses.length),
            "Arrays length mismatch"
        );
        require(
            _startDate > block.timestamp,
            "Start time must be greater than the current block timestamp"
        );
        require(
            _endDate > _startDate,
            "End time must be greater than start time"
        );
        CollectionConfig[] storage collectionConfigs = tokenConfig[_tokenId]
            .collectionConfigs;
        for (uint256 i = 0; i < _collections.length; i++) {
            collectionConfigs.push(
                CollectionConfig(
                    _collections[i],
                    _prices[i],
                    _usagePerPasses[i]
                )
            );
        }
        tokenConfig[_tokenId].mechanism = _mechanism;
        tokenConfig[_tokenId].collectionConfigs = collectionConfigs;
        tokenConfig[_tokenId].limit = _limit;
        tokenConfig[_tokenId].startDate = _startDate;
        tokenConfig[_tokenId].endDate = _endDate;
    }

    function getTokenConfig(
        uint256 _tokenId
    ) external view returns (TokenConfig memory) {
        return tokenConfig[_tokenId];
    }

    function updatePayoutAddress(address _payoutAddress) external onlyOwner {
        payoutAddress = payable(_payoutAddress);
    }

    function withdraw(uint256 _amount) external onlyOwner {
        require(
            _amount <= address(this).balance && address(this).balance > 0,
            "Not enough ether to withdraw"
        );
        if (_amount == 0) {
            // withdraw all
            (bool sent, ) = payoutAddress.call{value: address(this).balance}(
                ""
            );
            require(sent, "Error while transfering");
        } else {
            // withdraw _amount
            (bool sent, ) = payoutAddress.call{value: _amount}("");
            require(sent, "Error while transfering");
        }
    }

    // For ERC2981
    function setRoyaltyInfo(
        address _receiver,
        uint96 _royaltyFeesInBips
    ) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

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

    // OperatorFilterer
    // Opensea Filter Registry

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}
