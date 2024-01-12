// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";


interface Devcon2Token {
    function balanceOf(address _owner) external returns (uint256);
    function allowance(address _owner, address _spender) external returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

contract TokenBox is Ownable {

    function Send(address recipient, Devcon2Token devconInt) public onlyOwner returns (bool) {
        return devconInt.transfer(recipient, devconInt.balanceOf(address(this)));
    }
}

contract WrappedDevcon2Token is ERC721, ERC721Enumerable, Ownable {

    event Wrapped(uint256 indexed pairId, address indexed owner);
    event Unwrapped(uint256 indexed pairId, address indexed owner);

    Devcon2Token devconInt = Devcon2Token(0x0a43eDfE106D295e7C1e591A4B04B5598AF9474C);
    
    mapping(uint256 => address) public tokenBoxes;
    
    constructor() ERC721("WrappedDevcon2Token", "WD2T") {}

    function Wrap() public {
        uint256 tokenId = devconInt.balanceOf(msg.sender);

        require(tokenId != 0, "There is no token to wrap.");
        require(!_exists(tokenId), "Token is already wrapped.");
        require(devconInt.allowance(msg.sender, address(this)) == tokenId, "Wrapper does not have permission to transfer.");
        
        // create a box for the token if one doesn't already exist
        if (tokenBoxes[tokenId] == address(0)) {
            tokenBoxes[tokenId] = address(new TokenBox());
        }

        require(devconInt.balanceOf(tokenBoxes[tokenId]) == 0, "Token box is not empty.");

        // transfer token to the box
        if (devconInt.transferFrom(msg.sender, tokenBoxes[tokenId], tokenId)) {
            _mint(msg.sender, tokenId);
            emit Wrapped(tokenId, msg.sender);
        }
    }
        
    function Unwrap(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist.");
        require(msg.sender == ownerOf(tokenId), "You are not the owner.");
        require(devconInt.balanceOf(msg.sender) == 0, "Destination address is not empty.");
        
        // transfer token from the box
        if (TokenBox(tokenBoxes[tokenId]).Send(msg.sender, devconInt)) {
            _burn(tokenId);
            emit Unwrapped(tokenId, msg.sender);
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://devcon.ethyearone.com/";
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}