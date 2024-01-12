//SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ERC721A.sol";

import "./RoyaltiesResolver.sol";

contract Mooresque is ERC721A, Ownable {

    using Strings for uint256;
    using SafeERC20 for IERC20;

    event RoyaltiesConfigured(address indexed resolver);
    event BaseURISet(string baseUri);
    event Frozen();

    // Errors
    string private constant ZERO_ADDRESS = "Zero address provided";
    string private constant IMMUTABLE = "The contract has been frozen in time";

    // Pausing
    bool public frozen = false;

    // URI resolving
    string public baseURI_ = '';

    // Royalties
    // truncated keccak256("royaltyInfo(uint256,uint256)")
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address public royaltiesResolver;

    /**
     * Constructor, not special features.
     */
    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {
    }

    /**
     * An owner method to mint Mooresques.
     */
    function mint(address _to, uint256 _number) public onlyOwner {
        require(!frozen, IMMUTABLE);
        _safeMint(_to, _number);
    }

    /**
     * An owner method for changing the base URI.
     */
    function setBaseURI(string calldata base) public onlyOwner {
        require(!frozen, IMMUTABLE);
        baseURI_ = base;
        emit BaseURISet(base);
    }

    /**
     * Override for the base URI method.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    /**
     * Freezes minting and the base URI changes.
     */
    function freeze() public onlyOwner {
        frozen = true;
        emit Frozen();
    }

    /**
     * Sends funds to the caller (only owner).
     */
    function drain(address _token, uint256 _amount) public onlyOwner {
        if (_token == address(0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20(_token).transfer(msg.sender, _amount);
        }
    }

    /**
     * ERC2981 support. Returns the royalty information. Uses a replaceable resolver
     * for modifying it.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view returns (address, uint256) {
        return RoyaltiesResolver(royaltiesResolver).royaltyInfo(_tokenId, _salePrice);
    }

    /**
     * ERC165 indication of the ERC2981 interface support.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    /**
     * An owner method for setting the roalty resolver.
     */
    function configureRoyalties(address _resolver) public onlyOwner {
        require(_resolver != address(0), ZERO_ADDRESS);
        royaltiesResolver = _resolver;
        emit RoyaltiesConfigured(_resolver);
    }

    /**
     * To change the starting tokenId, please override this function.
     * We want to start numbering from 1.
     */
    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }
}

