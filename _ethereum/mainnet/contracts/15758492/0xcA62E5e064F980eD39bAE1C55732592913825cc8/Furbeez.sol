// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC1155.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./ContextMixin.sol";

contract Furbeez is ERC1155, IERC2981, Ownable, Pausable, ContextMixin {
    using Strings for uint256;

    mapping(uint256 => mapping(address => uint256)) private _balances;

    uint256 public constant MAX_ID_PLUS_ONE = 10001;
    uint256 public constant MINT_SINGLE_PRICE = 0.02 ether;
    uint256 public constant MINT_MULTIPLE_PRICE = 0.01 ether;
    uint256 public currentIndex = 1;

    address private _owner;
    string public constant name = "Furbeez";
    string public constant symbol = "FBZ";
    string public constant baseURI = "ipfs://bafybeiathbslfrtpv2wj5qxhnqerevkpnzsblk7z7iy3paqrwfnokxy37q/";

    constructor() ERC1155("") {
        _owner = owner();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint() external payable {
        uint256 _currentIndex = currentIndex;
        require(_currentIndex < MAX_ID_PLUS_ONE, "Not enough NFTs left to reserve");
        require(msg.value >= MINT_SINGLE_PRICE, "Not enough ether");
        require(msg.sender == tx.origin, "No smart contracts");

        _mint(msg.sender, _currentIndex, 1, "");
        unchecked {
            _currentIndex++;
        }
        currentIndex = _currentIndex;
    }

    function mintMultiple(uint256 quantity) external payable {
        uint256 _currentIndex = currentIndex;
        require(quantity > 4 && quantity < 21, "Incorrect quantity");
        require(_currentIndex < MAX_ID_PLUS_ONE);
        require(_currentIndex + quantity < MAX_ID_PLUS_ONE, "Not enough NFTs left to reserve");
        require(msg.value >= MINT_MULTIPLE_PRICE * quantity, "Not enough ether");
        require(msg.sender == tx.origin, "No smart contracts");

        uint256[] memory _amounts = new uint256[](quantity);
        uint256[] memory _ids = new uint256[](quantity);

        for (uint i = 0; i < quantity; i++) {
            _ids[i] = _currentIndex + i;
            _amounts[i] = 1;
        }

        unchecked {
            _currentIndex + quantity;
        }
        currentIndex = _currentIndex;
        _mintBatch(msg.sender, _ids, _amounts, "");
    }

    function reserve() public onlyOwner {
        uint256 _currentIndex = currentIndex;
        require(_currentIndex + 100 < MAX_ID_PLUS_ONE, "Not enough NFTs left to reserve");

        uint256[] memory _amounts = new uint256[](100);
        uint256[] memory _ids = new uint256[](100);
        
        for (uint i = 0; i < 100; i++) {
            _ids[i] = _currentIndex;
            _amounts[i] = 1;
            unchecked {
                _currentIndex++;
            }
        }

        currentIndex = _currentIndex;
        _mintBatch(_owner, _ids, _amounts, "");
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        uint256[] memory _amounts = new uint256[](ids.length);

        for (uint i = 0; i < ids.length; i++) {
            _amounts[i] = 1;
        }

        super._beforeTokenTransfer(operator, from, to, ids, _amounts, data);
    }

    function uri(uint256 id) public view virtual override returns(string memory) {
        require(id < MAX_ID_PLUS_ONE, "Invalid id");
        return string(abi.encodePacked(baseURI, id.toString(), ".json"));
    }

    function totalSupply() public view returns (uint256 _currentIndex) {
        return currentIndex - 1;
    }

    /** @dev EIP2981 royalties implementation. */

    // Maintain flexibility to modify royalties recipient (could also add basis points).
    function _setRoyalties(address newRecipient) internal {
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        _owner = newRecipient;
    }

    function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_owner, (_salePrice * 1000) / 10000);
    }

    // EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    /** @dev Meta-transactions override for OpenSea. */

    function _msgSender() internal override view returns (address) {
        return ContextMixin.msgSender();
    }

    /** @dev Contract-level metadata for OpenSea. */

    // Update for collection-specific metadata.
    function contractURI() public pure returns (string memory) {
        return baseURI; // Contract-level metadata for ParkPics
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}