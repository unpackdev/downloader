// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract Creature is ERC721Tradable {
    event Buy(
        uint indexed idx,
        address owner,
        uint x,
        uint y,
        uint width,
        uint height
    );

    uint public constant weiPixelPrice = 210000000000000; //1000000000000000

    uint public constant pixelsPerCell = 100;

    bool[100][100] public grid;

    address contractOwner;
    address payable withdrawWallet;

    struct Ad {
        uint x;
        uint y;
        uint w;
        uint h;
    }
    mapping(uint256 => Ad) internal ads;
    constructor(address _proxyRegistryAddress,address _contractOwner, address payable _withdrawWallet)
        ERC721Tradable("btcnft.pizza", "BTCNFT", _proxyRegistryAddress)
    {
        require(_contractOwner != address(0));
        require(_withdrawWallet != address(0));

        contractOwner = _contractOwner;
        withdrawWallet = _withdrawWallet;
    }
    function buy(uint _x, uint _y, uint _width, uint _height) public payable {
        uint cost = _width * _height * pixelsPerCell * weiPixelPrice;
        require(cost > 0);
        require(msg.value >= cost);

        for(uint i=0; i<_width; i++) {
            for(uint j=0; j<_height; j++) {
                if (grid[_x+i][_y+j]) {
                    revert();
                }
                grid[_x+i][_y+j] = true;
            }
        }
        uint256 _tokenId = getNextTokenId();
        ads[_tokenId] = Ad(_x, _y, _width, _height);
        mintTo(msg.sender,_tokenId);
        emit Buy(_tokenId, msg.sender, _x, _y, _width, _height);
    }
    function getAds(uint256 _tokenId) public view returns (uint,uint,uint,uint) {
        require(_exists(_tokenId));
        return (
        ads[_tokenId].x, 
        ads[_tokenId].y, 
        ads[_tokenId].w,
        ads[_tokenId].h
        );
    }
    function withdraw() public {
        require(msg.sender == contractOwner);
        withdrawWallet.transfer(address(this).balance);
    }
    function baseTokenURI() override public pure returns (string memory) {
        return "https://btcnft.pizza/p/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://btcnft.pizza/contractURI";
    }
}
