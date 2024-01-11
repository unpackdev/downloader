//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract WrappedXCOPY is ERC721("Wrapped Fan Bits XCOPY", "wXCOPY"), Ownable {
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    IERC721 public constant FAN_BITS_CONTRACT =
        IERC721(0xe897E5953EF250BD49875Fe7A48254def92730B9);

    string private _baseTokenURI;

    event BurnedOriginal(uint256 indexed tokenId);
    event Unwrapped(uint256 indexed tokenId);
    event Wrapped(uint256 indexed tokenId);

    constructor(string memory baseTokenURI) {
        setBaseTokenURI(baseTokenURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    modifier isValidTokenId(uint256 tokenId) {
        bool isValid = (tokenId >= 1685 && tokenId <= 1701) ||
            (tokenId >= 1703 && tokenId <= 1709) ||
            tokenId == 1711 ||
            (tokenId >= 1713 && tokenId <= 1717) ||
            (tokenId >= 1719 && tokenId <= 1729) ||
            tokenId == 1731 ||
            (tokenId >= 1732 && tokenId <= 1789);
        require(isValid, "This is not a valid XCOPY token");
        _;
    }

    function wrap(uint256 tokenId) external isValidTokenId(tokenId) {
        FAN_BITS_CONTRACT.transferFrom(_msgSender(), address(this), tokenId);
        _mint(_msgSender(), tokenId);
        emit Wrapped(tokenId);
    }

    function unwrap(uint256 tokenId) external {
        require(ownerOf(tokenId) == _msgSender(), "You do not own this token!");
        _burn(tokenId);
        FAN_BITS_CONTRACT.transferFrom(address(this), _msgSender(), tokenId);
        emit Unwrapped(tokenId);
    }

    function burnOriginalTokens(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            FAN_BITS_CONTRACT.transferFrom(
                _msgSender(),
                BURN_ADDRESS,
                tokenIds[i]
            );
            emit BurnedOriginal(tokenIds[i]);
        }
    }
}
