// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./IFactoryERC721.sol";
import "./Token.sol";
import "./IAllowance.sol";

contract TokenFactory is IFactoryERC721, Ownable {
    using SafeMath for uint256;
    using Strings for string;
    address public proxyRegistryAddress;
    address public tokenAddress;

    string private uri = 'ipfs://QmbKmRGd81YwB8YUFDh3NJgUJ3LZWpA5mqKX6vfELsFKvS/';
    uint256 TOKENS_NUM_OPTIONS = 201;
    uint256 lastIndex;

    constructor(address _proxyRegistryAddress, address _tokensAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        tokenAddress = _tokensAddress;
        fireTransferEvents(address(0), owner());
    }

    function numOptions() public view override returns (uint256) {
        return TOKENS_NUM_OPTIONS;
    }

    function name() external pure override returns (string memory) {
        return 'No War In Ukraine Fund';
    }

    function symbol() external pure override returns (string memory) {
      return 'NWIUF';
    }

    function supportsFactoryInterface() public pure override returns (bool) {
        return true;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);

        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 1; i < TOKENS_NUM_OPTIONS; i++) {
            emit Transfer(_from, _to, i);
        }
        lastIndex = TOKENS_NUM_OPTIONS - 1;
    }

    //Function to add new tokens to the existing collection
    function addTokens(uint256 amount) public onlyOwner {
        TOKENS_NUM_OPTIONS = TOKENS_NUM_OPTIONS + amount;
        for (uint256 i = lastIndex; i < TOKENS_NUM_OPTIONS; i++) {
            emit Transfer(address(0), owner(), i);
        }
        lastIndex = TOKENS_NUM_OPTIONS - 1;
    }

    function tokenURI(uint256 _optionId) external view override returns (string memory) {
        return getUri(_optionId);
    }

    function getUri(uint256 _optionId) internal view returns (string memory) {
        string memory base = _baseURI();
        return string(abi.encodePacked(base, Strings.toString(_optionId)));
    }

    function _baseURI() internal view virtual returns (string memory) {
        return uri;
    }

    function setUri(string memory newUri) public onlyOwner {
        uri = newUri;
    }

    // mint for token
    function mint(uint256 _optionId, address _toAddress) public override returns (uint256) {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == _msgSender() || owner() == _msgSender()
        );
        require(canMint(_optionId));
        Token(tokenAddress).mintTo(_toAddress, _optionId);
        emit MintSucceed(_toAddress);
        return _optionId;
    }

    function canMint(uint256 _optionId) public view override returns (bool) {
        if (_optionId >= TOKENS_NUM_OPTIONS) {
            return false;
        }
        uint256 tokenSupply = Token(tokenAddress).totalSupply();
        uint256 numItemsAllocated = 1;
        return tokenSupply < (TOKENS_NUM_OPTIONS - numItemsAllocated);
    }

    /**
     * @dev Transfers token from contract address to specified user
     * to get things to work automatically on OpenSea.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        mint(_tokenId, _to);
    }

    /**
     * @dev Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     * Hack to get things to work automatically on OpenSea.
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (owner() == _owner && address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return false;
    }

    /**
     * @dev Returns owner of token
     * Hack to get things to work automatically on OpenSea.
     */
    function ownerOf(uint256) external view returns (address _owner) {
        return owner();
    }
}
