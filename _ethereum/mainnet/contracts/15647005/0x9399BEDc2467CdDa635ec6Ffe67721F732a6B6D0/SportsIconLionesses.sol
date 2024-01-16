//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./console.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./EIP712Whitelisting.sol";
import "./ERC721A.sol";

error AboveMaxSupply();

contract SportsIconLionesses is ERC721A, EIP712Whitelisting {
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1000;

    string private baseURI;

    constructor(address whitelistSigner, string memory baseURI_)
        ERC721A("SportsIcon Lionesses", "SLS")
        EIP712Whitelisting(whitelistSigner)
    {
        baseURI = baseURI_;
    }

    function mint(
        bytes calldata signature,
        uint256 salt,
        uint16 whitelistIndex,
        uint8 amount
    )
        public
        onlyWhitelisted(signature, amount, whitelistIndex, salt)
        onlyNotWithdrawn(whitelistIndex)
        onlyBelowMaxSupply(amount)
    {
        _mint(msg.sender, amount);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    modifier onlyBelowMaxSupply(uint8 amount) {
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert AboveMaxSupply();
        }
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
