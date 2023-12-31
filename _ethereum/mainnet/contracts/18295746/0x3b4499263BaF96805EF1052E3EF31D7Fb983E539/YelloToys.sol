// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./ERC2981.sol";

contract YelloToys is Ownable, ERC721, ERC721Enumerable, ReentrancyGuard, ERC2981 {
    using Counters for Counters.Counter;

    /**
     * @dev Toys mapping
     * poolStartIds 0 means bridging is closed for this toy
     * modelId maps toyId to modelId
     * mintPrice needs to be > 0 to open mint
     */
    mapping(uint256 => Toy) public toys;
    struct Toy {
        Counters.Counter poolStartId;
        uint256 modelId;
        uint256 mintPrice;
    }

    /**
     * @dev Bridge Open or Close
     */
    bool public bridgeOpen;

    /**
     * @dev Bridge shiping and handling fee
     */
    uint256 public bridgeFee;

    /**
     * @dev Bridge multiplier, num_models * bridgeMul is required for num_toys
     */
    uint256 public bridgeMul;

    /**
     * @dev Mint Open or Close
     */
    bool public mintOpen;

    /**
     * @dev Max number of toys per bridge
     */
    uint256 public maxAmountPerBridge;

    /**
     * @dev Base token URI
     */
    string private baseTokenURI;

    /**
     * @dev YelloModels Contract
     */
    YelloModelsContract public yelloModels;

    constructor(
        uint256 _bridgeFee,
        uint256 _maxAmountPerBridge,
        uint256 _bridgeMul,
        uint256[] memory _toyIds,
        uint256[] memory _poolStartIds,
        uint256[] memory _modelIds,
        address yelloModelsAddr
    ) ERC721('YELLO Toys', 'YLT') {
        require(_bridgeFee > 0, 'Fee is 0');
        require(_maxAmountPerBridge > 0, 'maxPB is 0');
        require(_bridgeMul > 0, 'Mul is 0');
        require(_toyIds.length == _poolStartIds.length && _toyIds.length == _modelIds.length, 'Lengths not equal');

        bridgeFee = _bridgeFee;
        maxAmountPerBridge = _maxAmountPerBridge;
        bridgeMul = _bridgeMul;

        for (uint256 i = 0; i < _toyIds.length; ) {
            toys[_toyIds[i]].poolStartId._value = _poolStartIds[i];
            toys[_toyIds[i]].modelId = _modelIds[i];

            unchecked {
                ++i;
            }
        }

        yelloModels = YelloModelsContract(yelloModelsAddr);

        // Set royalty receiver to the contract creator,
        // at 10% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 1000);
    }

    /**
     * @dev validates caller is not from contract
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'Caller is contract');
        _;
    }

    /**
     * @dev for marketing etc.
     */
    function devMint(uint256[] calldata toyIds, uint256[] calldata amounts) external onlyOwner {
        require(toyIds.length == amounts.length, 'Lengths not equal');

        for (uint256 i = 0; i < toyIds.length; ) {
            for (uint256 j = 0; j < amounts[i]; ) {
                _safeMint(msg.sender, toys[toyIds[i]].poolStartId.current());
                toys[toyIds[i]].poolStartId.increment();

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev bridge Yello Models to Toys
     */
    function bridge(uint256[] calldata toyIds, uint256[] calldata amounts) external payable callerIsUser nonReentrant {
        require(bridgeOpen, 'Not open');
        require(toyIds.length == amounts.length, 'Lengths not equal');

        uint256 totalAmount;
        for (uint256 i = 0; i < toyIds.length; ) {
            Toy storage ty = toys[toyIds[i]];

            uint256 amount = amounts[i];
            totalAmount += amount;

            require(ty.poolStartId.current() > 0, 'Bridge: token closed');
            require(amount > 0, 'Amount 0');
            require(yelloModels.balanceOf(msg.sender, ty.modelId) * bridgeMul >= amount, 'Insufficient yello amount');

            yelloModels.burn(msg.sender, ty.modelId, amount * bridgeMul);

            for (uint256 j = 0; j < amount; ) {
                _safeMint(msg.sender, ty.poolStartId.current());
                ty.poolStartId.increment();

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        require(totalAmount <= maxAmountPerBridge, 'Too many to bridge');
        require(msg.value >= bridgeFee * totalAmount, 'Need more ETH');
    }

    /**
     * @dev mint Yello Toys
     */
    function publicMint(
        uint256[] calldata toyIds,
        uint256[] calldata amounts
    ) external payable callerIsUser nonReentrant {
        require(mintOpen, 'Not open');
        require(toyIds.length == amounts.length, 'Lengths not equal');

        uint256 totalAmount;
        uint256 totalMintPrice;
        for (uint256 i = 0; i < toyIds.length; ) {
            Toy storage ty = toys[toyIds[i]];
           
            uint256 amount = amounts[i];
            totalAmount += amount;
            totalMintPrice += ty.mintPrice * amount;

            require(ty.poolStartId.current() > 0, 'Mint: token closed');
            require(amount > 0, 'Amount 0');
            require(ty.mintPrice > 0, 'Mint Price 0');

            for (uint256 j = 0; j < amount; ) {
                _safeMint(msg.sender, ty.poolStartId.current());
                ty.poolStartId.increment();

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        require(totalAmount <= maxAmountPerBridge, 'Too many to mint');
        require(msg.value >= totalMintPrice + bridgeFee * totalAmount, 'Need more ETH');
    }

    /**
     * @dev set bridgeOpen Open or Close
     */
    function setBridgeOpen(bool _bridgeOpen) external onlyOwner {
        bridgeOpen = _bridgeOpen;
    }

    /**
     * @dev set bridge fee
     */
    function setBridgeFee(uint256 _bridgeFee) external onlyOwner {
        bridgeFee = _bridgeFee;
    }

    /**
     * @dev set maxAmountPerBridge
     */
    function setMaxAmountPerBridge(uint256 _maxAmountPerBridge) external onlyOwner {
        maxAmountPerBridge = _maxAmountPerBridge;
    }

    /**
     * @dev set bridgeMul
     */
    function setBridgeMul(uint256 _bridgeMul) external onlyOwner {
        bridgeMul = _bridgeMul;
    }

    /**
     * @dev set mintOpen Open or Close
     */
    function setMintOpen(bool _mintOpen) external onlyOwner {
        mintOpen = _mintOpen;
    }

    /**
     * @dev edit toy token pool start id
     */
    function editPoolStartId(uint256 _id, uint256 _poolStartId) external onlyOwner {
        toys[_id].poolStartId._value = _poolStartId;
    }

    /**
     * @dev edit toy model id
     */
    function editModelId(uint256 _id, uint256 _modelId) external onlyOwner {
        toys[_id].modelId = _modelId;
    }

    /**
     * @dev edit toy mintPrice
     */
    function editToyMintPrice(uint256 _id, uint256 _mintPrice) external onlyOwner {
        toys[_id].mintPrice = _mintPrice;
    }

    /**
     * @dev view base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev set base URI
     */
    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
     * @dev set models contract address
     */
    function setYelloModelsAddress(address _yelloModelsAddr) external onlyOwner {
        yelloModels = YelloModelsContract(_yelloModelsAddr);
    }

    /**
     * @dev get tokens owned by address
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);

        for (uint256 i = 0; i < balance; ) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
            unchecked {
                ++i;
            }
        }

        return tokenIds;
    }

    /**
     * @dev withdraw money to owner
     */
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Transfer failed');
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * @dev For ERC2981
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}

interface YelloModelsContract {
    function burn(address account, uint256 id, uint256 value) external;

    function balanceOf(address account, uint256 id) external view returns (uint256);
}
