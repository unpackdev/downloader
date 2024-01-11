//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract oofcity is ERC721A, Ownable, ReentrancyGuard {
    string private _metadata;
    uint256 public total = 9999;
    uint256 public allowance = 1;
    bool public open = false;
    mapping(address => uint256) public holdings;

    constructor() ERC721A("oofcity", "OOF") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _metadata;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function oof() external nonReentrant {
        uint256 currentCount = totalSupply();
        uint256 available = allowance - holdings[msg.sender];
        require(open);
        require(msg.sender == tx.origin);
        require(holdings[msg.sender] < allowance);
        require(currentCount + available <= total);
        _safeMint(msg.sender, available);
        holdings[msg.sender] += available;
    }

    function nonfedreserve(address recipient, uint256 _howmany)
        public
        onlyOwner
    {
        uint256 currentCount = totalSupply();
        require(currentCount + _howmany <= total);
        _safeMint(recipient, _howmany);
    }

    function setopen(bool _new) external onlyOwner {
        open = _new;
    }

    function setallowance(uint256 _new) external onlyOwner {
        allowance = _new;
    }

    function setmetadata(string memory _new) external onlyOwner {
        _metadata = _new;
    }

    function quantitativesqueezing() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}
