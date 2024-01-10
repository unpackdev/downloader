// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

import "./console.sol";

contract Pirates is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    bool public _paused = true;
    uint256 public MAX_SUPPLY = 2000;
    uint256 public MAX_PER_MINT = 100;

    mapping(address => bool) private minters;

    // withdraw addresses
    address withdrawer;

    constructor(string memory baseURI) ERC721("Pirates", "PIRATE")  {
        setBaseURI(baseURI);
    }

    // modifiers

    modifier onlyMinter {
        if (minters[msg.sender] != true) revert();
        _;
    }

    // mint

    function mint(uint256 num, address recipient) external onlyMinter {
        uint256 supply = totalSupply();
        require( !_paused,                              "Sale paused" );
        require( num < MAX_PER_MINT,                    "You can mint a maximum of 100 pirates" );
        require( supply + num < MAX_SUPPLY,             "Exceeds maximum Pirate supply" );

        for(uint256 i; i < num; i++){
            _safeMint(recipient, supply + i );
        }
    }

    // Getters

    function isMinter(address _address) public view returns (bool) {
        return minters[_address];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Setters

    function setMinter(address _address, bool value) external onlyOwner {
        minters[_address] = value;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setWithdrawalAddress(address _withdrawer) public onlyOwner {
        withdrawer  =_withdrawer;
    }

    // withdraw
    function withdrawAll() public payable onlyOwner {
        uint256 bal = address(this).balance;
        require(payable(withdrawer).send(bal));
    }
}