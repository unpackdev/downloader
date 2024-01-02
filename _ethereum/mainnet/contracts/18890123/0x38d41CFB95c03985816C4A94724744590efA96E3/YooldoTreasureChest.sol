// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./AccessControl.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./IONFT721.sol";
import "./ONFT721.sol";

contract YooldoTreasureChest is IONFT721, ONFT721, ERC721Enumerable, AccessControl {
    mapping(address => uint) public whitelistedAddresses;
    using Counters for Counters.Counter;
    uint public startMintId;
    uint public endMintId;
    Counters.Counter private _tokenIdCounter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint public saleFlag;
    bool public isLocked;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _minGasToTransfer,
        address _layerZeroEndpoint
    ) ONFT721(_name, _symbol, _minGasToTransfer, _layerZeroEndpoint) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function safeMint(address to) internal {
        uint256 tokenId = startMintId + _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function lockContract() public onlyOwner {
        isLocked = true;   
    }

    function switchSale(uint mode) external onlyOwner {
        // 0 = pause sale | 1 = pre-mint | 2 = public-mint
        require(mode >= 0 && mode <= 2, "YooldoTreasureChest: Invalid sale mode");
        require(!isLocked, "YooldoTreasureChest: Contract is locked");
        saleFlag = mode;
    }

    function updateIdRange(uint startId, uint endId) external onlyOwner {
        require(!isLocked, "YooldoTreasureChest: Contract is locked. Can't mint anymore");
        startMintId = startId;
        endMintId = endId;
    }

    function updateWhitelistBatch(address[] calldata _addresses, uint _amount) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            whitelistedAddresses[_addresses[i]] = _amount;
        }
    }

    function preMint(address to) external {
        require(saleFlag == 1, "YooldoTreasureChest: Pre-mint is not available");
        require(whitelistedAddresses[to] > 0, "YooldoTreasureChest: Address is not whitelisted");
        require(_tokenIdCounter.current() < endMintId, "YooldoTreasureChest: All NFTs have been minted");

        safeMint(to);

        whitelistedAddresses[to] -= 1;
    }

    function publicMint(address to) external {
        require(saleFlag == 2, "YooldoTreasureChest: Public-mint is not available");
        require(_tokenIdCounter.current() < endMintId, "YooldoTreasureChest: All NFTs have been minted");

        safeMint(to);
    }

    function getMintableAmountsByAddress(address _address) external view returns (uint) {
        return whitelistedAddresses[_address];
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://app.yooldo.gg/api/freemint/treasure-chest/";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ONFT721, IERC165, ERC721Enumerable, AccessControl) returns (bool) {
        return interfaceId == type(IONFT721).interfaceId || super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) return new uint256[](0);
		else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = 0; index < tokenCount; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}

	function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override (ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, firstTokenId,batchSize );
    }
}
