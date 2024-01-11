// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721A.sol";
import "Ownable.sol";

contract WAGSHEET is ERC721A, Ownable {

    uint256 constant public MAX_SUPPLY = 1666;
    uint256 constant public MAX_MINTS_PER_WALLET = 5;
    string baseURI;
    mapping(address => uint256) addressToNumMinted;

    constructor() ERC721A("WAGSHEET", "WAGSHEET", MAX_MINTS_PER_WALLET) Ownable(){}

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /// @notice Somebody once told me the world is gonna rug me
    /// @dev I ain't the sharpest tool in the shed
    /// @dev She was looking kind of dumb with her finger and her thumb
    /// @dev In the shape of an "L" on her forehead
    /// @dev Well the years start coming and they don't stop coming
    /// @dev Fed to the rules and I hit the ground running
    /// @dev Didn't make sense not to live for fun
    /// @dev Your brain gets smart but your head gets dumb
    /// @dev So much to do, so much to see
    /// @dev So what's wrong with taking the back SHEETs?
    /// @dev You'll never know if you don't go
    /// @dev You'll never shine if you don't glow
    /// @dev Hey now, you're an all-star, get your game on, go play
    /// @dev Hey now, you're a rock star, get the show on, get paid
    /// @dev And all that glitters is gold
    /// @dev Only shooting stars break the mold
    /// @param amount Max 5 per wallet you greedy degen
    function mint(uint256 amount) external {
        require(totalSupply() + amount <= MAX_SUPPLY, "There aren't that many available");
        require(addressToNumMinted[msg.sender] + amount <= MAX_MINTS_PER_WALLET, "You can only mint 5 per wallet");

        addressToNumMinted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function _baseURI() internal view override returns(string memory) {
        return baseURI;
    }
}
