//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

// ============ Imports ============

/// import "./IERC721.sol";
/// import "./ERC1155.sol";
import "./IERC721.sol";
import "./ERC1155.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Ownable.sol";


import "./PuzlPunk.sol";
import "./PacksRegistry.sol";


library Errors {
    string constant DoesNotOwnPuzlpack = "you do not own the puzlpack for this airdrop";
    string constant IsNotPuzl = "msg.sender is not the puzl contract";
    string constant IsNotPuzlPart = "not puzl part";
}

/// @title Puzl Tokens
/// @author Georgios Konstantopoulos
/// @notice Allows "opening" your ERC721 Puzl packs and extracting the items inside it
/// The created tokens are ERC1155 compatible, and their on-chain SVG is their name
contract PuzlUnpack is ERC1155, Ownable {
    // The OG Puzl packs contract
    IERC721 immutable puzl;
   

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _partIdTracker;
  
    address public creatorAddress = msg.sender;

    uint256 public constant MINT_PRICE = 1 * 10**17;

    address public PUZL_PUNK;
    address public PACK_REGISTRY;

    string private baseURI = "https://prereveal.puzlpunks.com/part/";

    constructor(
        address _puzl,
        address _puzlPunk,
        address _packRegistry
    ) ERC1155("") {
        puzl = IERC721(_puzl);
        PUZL_PUNK = _puzlPunk;
        PACK_REGISTRY = _packRegistry;
        name = "PuzlPunk Racer";
        symbol = "PUZLRacer";
    }

     event CreatePart(uint256 indexed id);

    function _mintedParts() internal view returns (uint) {
        return _partIdTracker.current();
    }

    function updatePuzlPunkCollection(address _puzlPunk) public onlyOwner {
        PUZL_PUNK = _puzlPunk;
    }
     function updatePackRegistry(address _packRegistry) public onlyOwner {
        PACK_REGISTRY = _packRegistry;
    }


    /// @notice Transfers the erc721 pack from your account to the contract and then
    /// opens it. Use it if you have already approved the transfer, else consider
    /// just transferring directly to the contract and letting the `onERC721Received`
    /// do its part
    function open(uint256 tokenId) external {
        puzl.safeTransferFrom(msg.sender, address(this), tokenId);
    }

    function makePunk(uint256[] calldata _ids, uint256[] calldata _amts, string calldata tokenURI) public payable returns(bool){
        require(msg.value >= MINT_PRICE, "Value below price");
        _safeBatchTransferFrom(msg.sender, address(this), _ids, _amts, "");
        PuzlPunk(PUZL_PUNK).mintPunk(msg.sender, tokenURI);
        return true;
    }


    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creatorAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }


    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns(bytes4) {
        require(msg.sender == address(this), Errors.IsNotPuzlPart);
        return PuzlUnpack.onERC1155BatchReceived.selector;
    }



    /// @notice ERC721 callback which will open the pack
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        // only supports callback from the supported Puzl contracts
        require( PacksRegistry(PACK_REGISTRY).isValid721Contract(msg.sender), Errors.IsNotPuzl);
        // require(msg.sender == address(puzl), Errors.IsNotPuzl);
        open(from, tokenId);
        return PuzlUnpack.onERC721Received.selector;
    }


     /// @notice Opens your puzl pack and mints you 8 ERC-1155 tokens for each item
    /// in that pack
    function open(address who, uint256 tokenId) private {
        // NB: We patched ERC1155 to expose `_balances` so
        // that we can manually mint to a user, and manually emit a `TransferBatch`
        // event. If that's unsafe, we can fallback to using _mint
        // uint id = _mintedParts();
        // _partIdTracker.increment();
        // _mint(who, id, 1, bytes('punk'));
        uint256[] memory ids = new uint256[](9);
        uint256[] memory amounts = new uint256[](9);
        ids[0] = (100 + tokenId);
        ids[1] = (200 + tokenId);
        ids[2] = (300 + tokenId);
        ids[3] = (400 + tokenId);
        ids[4] = (500 + tokenId);
        ids[5] = (600 + tokenId);
        ids[6] = (700 + tokenId);
        ids[7] = (800 + tokenId);
        ids[8] = (900 + tokenId);
        for (uint256 i = 0; i < ids.length; i++) {
            amounts[i] = 1;
            _mintAPart(who, ((100*i) + tokenId));
        }
    }

     function _mintAPart(address _to, uint256 tokenIdPair) private {
         uint id = _mintedParts();
        _partIdTracker.increment();
        _mint(_to, tokenIdPair, 1, "");
        // _safeTransferFrom(address(this), _to, tokenIdPair, 1, "");
        emit CreatePart(id);
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    function uri(uint256 _tokenId) override public view returns (string memory) {
        return tokenURI(_tokenId);
    }

    function contractURI(uint256 _tokenId) public view returns (string memory) {
        return tokenURI(_tokenId);
    }

     function tokenURI(uint256 _tokenId) public view returns (string memory) {
        string memory currentBaseURI = _baseURI();
        string memory token;
        token = toString(_tokenId);
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, token)) : "";
     }
    
}