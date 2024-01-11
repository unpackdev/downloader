// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Counters.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

contract GoldenMembers is ERC721Enumerable, AccessControl, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;
    string public uriSuffix = ".json";

    string public _baseTokenURI;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 internal _cap = 999;
    constructor() ERC721("GoldenMembers", "GoldenMembers")  {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _baseTokenURI = "https://goldenidclub.mypinata.cloud/ipfs/QmZjSucPxueWSGpkzNZueeJpZaiVLoURV3XQ8Q7DAMxeSV/";
    }
    function getCurrentTokenId() public view returns (uint256) {
        return _tokenIds.current();
    }
    function cap() external view returns (uint256) {
        return _cap;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setBaseURI(string memory baseURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        _baseTokenURI = baseURI;
    }

    function setUriSuffix(string memory _uriSuffix) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        uriSuffix = _uriSuffix;
    }
    
    function mint(address _mintTo) public returns (bool) {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        require(hasRole(MINTER_ROLE, _msgSender()) || (hasRole(DEFAULT_ADMIN_ROLE,  _msgSender())), "Caller is not a minter");
        require(_mintTo != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        require(tokenId <= _cap, "Cap reached, maximum 999 mints possible");
        _mint(_mintTo, tokenId);
        return true;
    }

    function mintBatch(address[] memory _wallets) public returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE,  _msgSender()), "Caller is not a minter");
        uint256 length = _wallets.length;
        for(uint i = 0; i < length; i++) {
            mint(_wallets[i]);
        }
        return true;
    }
}