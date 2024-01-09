//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC1155U.sol";

interface ProxyRegistry {
    function proxies(address) external view returns (address);
}

interface IERC2981 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

contract Quasars is ERC1155U, IERC2981, Ownable {
    uint256 _currentTokenId = 1;
    uint256 constant MAX_TOKENS = 10_000;
    uint256 constant PRICE_WHEN_MINTING_SEVERAL_AT_A_TIME = 0.01 ether;

    string private _uri = 'https://codemakes.art/token/quasars/{id}';
    bool private _gaslessTrading = true;
    uint256 private _royaltyPartsPerMillion = 50_000;

    string public constant name = 'Quasars';
    string public constant symbol = 'QSR';

    function mint_One_4d() external {
        require(_currentTokenId <= MAX_TOKENS, 'Sold out');

        uint96 dna = uint96(uint256(keccak256(abi.encode(msg.sender, _currentTokenId, block.timestamp))));
        _mint(msg.sender, _currentTokenId, dna, '');

        unchecked {
            // Can't overflow
            _currentTokenId++;
        }
    }

    function gift_One_bca(address to) external {
        require(_currentTokenId <= MAX_TOKENS, 'Sold out');

        // NOTE: dna still derived from sender
        uint96 dna = uint96(uint256(keccak256(abi.encode(msg.sender, _currentTokenId, block.timestamp))));
        _mint(to, _currentTokenId, dna, '');

        unchecked {
            // Can't overflow
            _currentTokenId++;
        }
    }

    function mint_Several_nmW(uint256 count) external payable {
        require(count < 21, 'Max 20');
        unchecked {
            // Can't overflow
            require(_currentTokenId + count < MAX_TOKENS, 'Sold out');
            require(count * PRICE_WHEN_MINTING_SEVERAL_AT_A_TIME == msg.value, 'Wrong price');
        }

        uint256[] memory ids = new uint256[](count);
        uint96[] memory dnas = new uint96[](count);

        for (uint256 i = 0; i < count; ) {
            ids[i] = _currentTokenId + i;
            dnas[i] = uint96(uint256(keccak256(abi.encode(msg.sender, i, block.timestamp))));

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        _batchMint(msg.sender, ids, dnas, '');

        unchecked {
            // Can't overflow
            _currentTokenId += count;
        }
    }

    function totalSupply() public view returns (uint256) {
        unchecked {
            // Starts with 1
            return _currentTokenId - 1;
        }
    }

    function uri(uint256) public view override returns (string memory) {
        return _uri;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = owner();
        royaltyAmount = (salePrice * _royaltyPartsPerMillion) / 1_000_000;
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Allow easier listing for sale on OpenSea. Based on
        // https://github.com/ProjectOpenSea/opensea-creatures/blob/f7257a043e82fae8251eec2bdde37a44fee474c4/migrations/2_deploy_contracts.js#L29
        if (_gaslessTrading) {
            if (block.chainid == 4) {
                if (ProxyRegistry(0xF57B2c51dED3A29e6891aba85459d600256Cf317).proxies(owner) == operator) {
                    return true;
                }
            } else if (block.chainid == 1) {
                if (ProxyRegistry(0xa5409ec958C83C3f309868babACA7c86DCB077c1).proxies(owner) == operator) {
                    return true;
                }
            }
        }

        return super.isApprovedForAll(owner, operator);
    }

    // Admin

    function setUri(string calldata newUri) public onlyOwner {
        _uri = newUri;
    }

    function setAllowGaslessListing(bool allow) public onlyOwner {
        _gaslessTrading = allow;
    }

    function setRoyaltyPPM(uint256 newValue) public onlyOwner {
        require(newValue < 1_000_000, 'Must be < 1e6');
        _royaltyPartsPerMillion = newValue;
    }

    function thankYouForSupportingUs_o4k() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function thankYouForSupportingUsERC20_V1M(IERC20 erc20Token) public onlyOwner {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }
}
