// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";  

//////////////////////////////////////////////////////////
///        _                 _ _                       ///
///   __ _| |__   ___  _   _| | |_ _____      ___ __   ///
///  / _` | '_ \ / _ \| | | | | __/ _ \ \ /\ / / '_ \  ///
/// | (_| | | | | (_) | |_| | | || (_) \ V  V /| | | | ///
///  \__, |_| |_|\___/ \__,_|_|\__\___/ \_/\_/ |_| |_| ///
///  |___/                                             ///
///                                                    ///
//////////////////////////////////////////////////////////

contract Ghoultown is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant FREE_MINT_AMOUNT = 777;
    uint256 public constant MINT_LIMIT = 10;
    uint256 public constant MINT_PRICE = 0.005 ether;
    
    string public baseURI;

    constructor() payable ERC721A("ghoultown", "GHOUL") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _new) external onlyOwner {
        baseURI = _new;
    }

    function mint(uint256 _amount) external payable {
        require(totalSupply() + _amount < MAX_SUPPLY, "ghoultown: mint would exceed total supply");
        require(_amount > 0 && _amount <= MINT_LIMIT, "ghoultown: mint amount too high");
        require(msg.value >= (MINT_PRICE * _amount), "ghoultown: insufficient eth sent");

        _mint(msg.sender, _amount);
    }

    function freeMint() external {
        require(totalSupply() < FREE_MINT_AMOUNT, "ghoultown: free mints exhausted");
        require(_numberMinted(msg.sender) <= MINT_LIMIT, "ghoultown: free mint limit reached");

        _mint(msg.sender, 1);
    }

    function withdraw(address payable to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }
}
