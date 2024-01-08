// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./IERC2981.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./EnumerableMap.sol";
import "./console.sol";

/////////////////////////////////////////////////////////////
//                _   _ _______ _    _ _____   ____        //
//          /\   | \ | |__   __| |  | |  __ \ / __ \       //
//         /  \  |  \| |  | |  | |__| | |__) | |  | |      //
//        / /\ \ | . ` |  | |  |  __  |  _  /| |  | |      //
//       / ____ \| |\  |  | |  | |  | | | \ \| |__| |      //
//      /_/    \_\_| \_|  |_|  |_|  |_|_|  \_\\____/       //
//                                                         //
//                 #######                                 //
//               #   ####       ####     ###############   //
//      ########  ##  ##      #########################    //
//        ##########        ######################         //
//         ########           ###################          //
//          ###            #####  ##############  #        //
//            #####        #######  ##########             //
//             ######        ####          ##              //
//              #####        #### #           #####        //
//              ###           ##                ###  #     //
//              ##                                         //
/////////////////////////////////////////////////////////////

contract Anthro is ERC721, Ownable, ERC721URIStorage, IERC2981, AccessControl {
    using SafeMath for uint256;
    using Strings for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(bytes4 => bool) internal supportedInterfaces;

    Counters.Counter private _tokenIds;

    // Store Hashes for IPFS
    mapping(string => uint256) private hashes;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // ONLY 100 ANTHRO WILL EVER EXIST
    uint256 public maxAnthro = 100;

    string private _openseaURI = "https://anthro.mypinata.cloud/ipfs/QmazjjExs9U4XZZDd6Shhs8t6fuNVz2Ze3uNjMuUf3cB38";

    string private _baseURIextended = "https://anthro.mypinata.cloud/ipfs/";

    address private _artist;

    // This is 10%
    uint256 private _royaltyAmount = 1000;

    constructor(string memory name, string memory symbol, address artist) ERC721(name, symbol) {
      _artist = artist;
      _setupRole(ADMIN_ROLE, artist);
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      supportedInterfaces[this.supportsInterface.selector] = true;
    }

    function adminMint(string memory hash, string memory metadata) public onlyRole(ADMIN_ROLE) {
        _safeMint(msg.sender, hash, metadata);
    }

    function ownerMint(string memory hash, string memory metadata) public onlyOwner {
        _safeMint(msg.sender, hash, metadata);
    }

    function updateOpenseaMetadata(string memory newURI) public onlyOwner {
      _openseaURI = newURI;
    }

    function updateMetadata(uint256 tokenId, string memory metadata) public onlyOwner {
      require(msg.sender == owner() || msg.sender == _artist);
      _setTokenURI(tokenId, metadata);
    }

    function updateIpfsURL(string memory newURI) public onlyOwner {
        _baseURIextended = newURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function contractURI() public view returns (string memory) {
        return _openseaURI;
    }

    function updateRoyalty(uint256 amount) public onlyOwner {
        _royaltyAmount = amount;
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override(IERC2981) returns (
        address receiver,
        uint256 royaltyAmount
    ) {
      return (_artist, _royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override(
      AccessControl, IERC165, ERC721) returns (bool) {
        return supportedInterfaces[interfaceID];
    }

    function _safeMint(address minter, string memory hash, string memory metadata) internal {
        require(minter == owner() || minter == _artist);

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        require(tokenId < maxAnthro, "No More Anthro to create!");

        require(hashes[hash] != 1, "Already exists with IPFS hash");
        hashes[hash] = 1;


        _safeMint(minter, tokenId);
        _setTokenURI(tokenId, metadata);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
      // We don't any one to burn an Anthro!
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual override {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) { }
}
