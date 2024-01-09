//      __  __ ____   __     _  ____   ___ __  __
//     / / / // __ \ / /    (_)/ __ \ /   |\ \/ /
//    / /_/ // / / // /    / // / / // /| | \  / 
//   / __  // /_/ // /___ / // /_/ // ___ | / /  
//  /_/ /_/ \____//_____//_//_____//_/  |_|/_/   
//     ______ ___   ______ _____                 
//    / ____//   | /_  __// ___/                 
//   / /    / /| |  / /   \__ \                  
//  / /___ / ___ | / /   ___/ /                  
//  \____//_/  |_|/_/   /____/                   
//                                               

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract HolidayCats is ERC721, Ownable {

    uint256 public constant PRICE = .03 ether;
    uint256 public constant SUPPLY = 5500;
    
    uint256 public totalSupply = 0;
    bool public revealed = false;
    bool public minting = false;
    
    string private uri = "";

    constructor(string memory _uri) ERC721("HolidayCats", "HOLICATS") {
        uri = _uri;
    }

    // -- MINT -- //

    function mint(uint256 _count) public payable
    {
        mint(msg.sender, _count);
    }

    function mint(address _to, uint256 _count) public payable 
    {
        require(minting, 'SALE_NOT_LIVE');
        require(_count <= 20, 'EXCEEDED_TX_MAX');
        require(_count + totalSupply <= SUPPLY, 'SOLD_OUT');
        require(_count * PRICE <= msg.value, 'INSUFFICIENT_ETHER');

        // start id at 1
        uint256 id = totalSupply + 1;

        for (uint256 i = 0; i < _count; i++) {
            _safeMint(_to, id + i);
        }

        totalSupply = totalSupply + _count;
    }

    // -- TOKEN INFORMATION -- //

    // @notice returns token-specific URI only after reveal
    function tokenURI(uint256 _id) public view virtual override
    returns (string memory)
    {
        require(_exists(_id), "ERC721Metadata: URI query for nonexistent token");

        if (revealed)
        {
            return bytes(uri).length > 0 ? string(abi.encodePacked(uri, Strings.toString(_id))) : "";
        }
        else
        {
            return bytes(uri).length > 0 ? string(uri) : "";
        }
    }

    // -- MANAGEMENT -- //

    // @dev set when uri is updated to point to revealed images
    function reveal(bool _revealed) external onlyOwner
    {
        revealed = _revealed;
    }
    
    // @dev sets the base uri used by tokenURI()
    function setBaseURI(string calldata _uri) external onlyOwner 
    {
        uri = _uri;
    }

    // @dev enables/disables the minting function
    function flipSaleState() external onlyOwner 
    {
        minting = !minting;
    }

    // @dev withdraw ether from the contract
    function withdraw() external onlyOwner 
    {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "TRANSFER_FAILED");
    }

    // @dev withdraw ERC20s sent to the contract
    function withdrawToken(address _token) external onlyOwner 
    {
        bool success = IERC20(_token).transfer(
            owner(),
            IERC20(_token).balanceOf(address(this))
        );
        require(success, "TRANSFER_FAILED");
    }
}
